#!/usr/bin/env python3
"""UserPromptSubmit hook: プロンプトとの関連度が高い学習済みルールを本文ごと注入する。

見出し一覧を全件流すと additionalContext がサイズ上限を超えて persisted-output に
退避され、先頭プレビュー分しか読めなくなる。そのため関連上位のみに絞って注入する。

あわせて remember-nudge.sh がバックグラウンド判定した結果(pending)を回収して通知する。
"""
import json
import math
import os
import re
import sys
import time
import traceback
from datetime import datetime
from pathlib import Path

# ディレクトリは環境変数で差し替え可能にする(test-inject-lessons.sh が fixture を渡す)
LESSONS_DIR = Path(os.environ.get("INJECT_LESSONS_DIR") or Path.home() / ".config/claude/lessons")
STATE_DIR = Path(os.environ.get("INJECT_STATE_DIR") or Path.home() / ".claude/state")
PENDING = STATE_DIR / "remember-nudge.pending"
LOG_FILE = STATE_DIR / "inject-lessons.log"

MAX_SECTIONS = 8
MAX_BYTES = 6000
SCORE_RATIO = 0.3  # 最大スコアに対するこの比率未満は足切り
# 最大スコアが log(セクション数) * この係数 に満たなければ関連なしとみなす。
# log(N/df) が idf なので log(N) は「レア語が本文に1個ヒット」相当で、承認や相槌の
# ような短文でも偶然到達する。係数1.5でその中間に境界を置く。
# 実測(N=207, 閾値8.0): 無関係な短文の最大5.3 / 有意なプロンプト10.9〜28.1 で分離。
MIN_TOP_SCORE_FACTOR = 1.5
# スコアリングは O(トークン数 × セクション数)。ログやコードを貼り付けた長大プロンプトで
# トークンが1000超になると数百msかかるため上限を設ける。文字数の多いトークンほど具体的で
# 弁別力が高いので、長い順に採用する。
MAX_TOKENS = 120
PENDING_MAX_AGE_SEC = 900  # これより古い判定結果は陳腐化しているとみなし破棄する

# 「続けて」「y」のような短い入力では語が拾えないため、直前の assistant の発言と
# ツール呼び出しも材料にする。ただし今回の入力より弱い手掛かりなので重みを下げる。
# 大きなファイルを Read した結果の行は 64KB を超え、それだけで枠が埋まる。
# 後ろから解析して必要量で打ち切るので、広げて増えるのは読み込みの分だけ。
TRANSCRIPT_TAIL_BYTES = 1 << 20
TRANSCRIPT_MAX_CHARS = 4000
TRANSCRIPT_WEIGHT = 0.3
TOOL_INPUT_MAX_CHARS = 200

# 通知のターンでも hook は発火するが、prompt は通知文そのもので作業内容を表さない。
# 後ろ2つは handoff 記載の形で、実際の hook 入力では未採取。
NOTIFICATION_PREFIXES = (
    "<task-notification",
    "[SYSTEM NOTIFICATION",
    "Another Claude session sent a message",
    "<agent-message",
)

# 英数字列 / カタカナ2文字以上 / 漢字2文字以上。ひらがなは助詞ノイズのため対象外
TOKEN_RE = re.compile(r"[A-Za-z][A-Za-z0-9_.\-]+|[ァ-ヶー]{2,}|[一-鿿々]{2,}")
KANJI_RE = re.compile(r"^[一-鿿々]{2,}$")
ASCII_RE = re.compile(r"^[a-z0-9_.\-]+$")


def log_error(exc):
    """hook は失敗しても黙って exit するため、原因追跡用にログだけは残す。"""
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        with LOG_FILE.open("a", encoding="utf-8") as f:
            f.write(f"--- {datetime.now().isoformat()} {type(exc).__name__}: {exc}\n")
            f.write(traceback.format_exc())
    except OSError:
        pass


def tokenize(text):
    tokens = set()
    for match in TOKEN_RE.findall(text):
        if KANJI_RE.match(match):
            # 漢字列は複合語の部分一致を拾うため 2gram にも分解する
            tokens.update(match[i:i + 2] for i in range(len(match) - 1))
            tokens.add(match)
        else:
            # 文末の "completed." の句点などを語に含めると一致しなくなる
            word = match.lower().rstrip(".-")
            if len(word) >= 2:
                tokens.add(word)
    if len(tokens) > MAX_TOKENS:
        tokens = set(sorted(tokens, key=len, reverse=True)[:MAX_TOKENS])
    return tokens


def load_sections():
    sections = []
    for path in sorted(LESSONS_DIR.glob("*.md")):
        text = path.read_text(encoding="utf-8", errors="replace")
        for chunk in re.split(r"(?m)^### ", text)[1:]:
            heading, _, body = chunk.partition("\n")
            sections.append({
                "file": path.name,
                "heading": heading.strip(),
                "body": body.rstrip(),
                "heading_key": heading.lower(),
                "body_key": body.lower(),
                "score": 0.0,
            })
    return sections


def occurs(token, text):
    if token not in text:
        return False
    if not ASCII_RE.match(token):
        return True  # 漢字・カタカナは複合語の一部を拾うため部分一致のまま
    # 英字の部分一致は code が CodeBuild や codex にまで当たるため、語の境目で切る
    return re.search(rf"(?<![a-z0-9_]){re.escape(token)}(?![a-z0-9_])", text) is not None


def score_sections(sections, weighted_tokens):
    total = len(sections)
    for token, weight in weighted_tokens.items():
        hits = [(s, occurs(token, s["heading_key"]), occurs(token, s["body_key"])) for s in sections]
        df = sum(1 for _, in_heading, in_body in hits if in_heading or in_body)
        if df == 0:
            continue
        idf = math.log(total / df)
        if idf <= 0:
            continue  # 全セクションに出現する語は無情報
        for s, in_heading, in_body in hits:
            if in_heading:
                s["score"] += idf * 2 * weight
            elif in_body:
                s["score"] += idf * weight


def pick(sections):
    ranked = sorted((s for s in sections if s["score"] > 0),
                    key=lambda s: s["score"], reverse=True)
    if not ranked:
        return []
    if ranked[0]["score"] < math.log(len(sections)) * MIN_TOP_SCORE_FACTOR:
        return []
    cutoff = ranked[0]["score"] * SCORE_RATIO
    picked, used = [], 0
    for s in ranked[:MAX_SECTIONS]:
        if s["score"] < cutoff:
            break
        size = len(f"### {s['heading']}\n{s['body']}\n".encode("utf-8"))
        if picked and used + size > MAX_BYTES:
            break
        picked.append(s)
        used += size
    return picked


def render(picked):
    lines = ["【関連しそうな学習済みルール】", "以下は過去の指摘から蓄積したルール。該当する作業ではこれに従う。", ""]
    current = None
    for s in sorted(picked, key=lambda s: s["file"]):
        if s["file"] != current:
            current = s["file"]
            lines.append(f"## {current}")
        lines.append(f"### {s['heading']}")
        lines.append(s["body"])
        lines.append("")
    return "\n".join(lines)


def render_index(sections):
    counts = {}
    for s in sections:
        counts[s["file"]] = counts.get(s["file"], 0) + 1
    entries = " ".join(f"{name}({n})" for name, n in sorted(counts.items()))
    return (
        "【学習済みルール索引】今回のプロンプトに強く関連する項目は検出されず。\n"
        f"関連しそうなら {LESSONS_DIR}/ 配下を Read すること: {entries}"
    )


def take_pending():
    """remember-nudge.sh がバックグラウンドで書いた判定結果を回収する(読んだら消す)。"""
    try:
        if not PENDING.is_file():
            return ""
        age = time.time() - PENDING.stat().st_mtime
        text = PENDING.read_text(encoding="utf-8").strip()
        PENDING.unlink()
        return text if age <= PENDING_MAX_AGE_SEC else ""
    except OSError as exc:
        log_error(exc)
        return ""


def content_blocks(entry):
    message = entry.get("message")
    content = message.get("content") if isinstance(message, dict) else None
    return content if isinstance(content, (list, str)) else []


def user_prompt_text(entry):
    """ユーザーが打った入力の行なら本文を返す。ツールの結果を運ぶ user 行は None。"""
    if entry.get("type") != "user":
        return None
    content = content_blocks(entry)
    if isinstance(content, str):
        return content
    texts = [b.get("text") for b in content if isinstance(b, dict) and b.get("type") == "text"]
    return "\n".join(t for t in texts if isinstance(t, str)) if texts else None


def assistant_texts(entry):
    if entry.get("type") != "assistant" or isinstance(content_blocks(entry), str):
        return []
    texts = []
    for block in content_blocks(entry):
        if not isinstance(block, dict):
            continue
        if block.get("type") == "text" and isinstance(block.get("text"), str):
            texts.append(block["text"])
        elif block.get("type") == "tool_use" and isinstance(block.get("input"), dict):
            # Write の本文や Edit の差し替え文字列で枠を使い切らないよう、値ごとに切る
            texts.extend(str(v)[:TOOL_INPUT_MAX_CHARS] for v in block["input"].values())
    return texts


def read_recent_assistant_text(transcript_path, current_prompt):
    """transcript 末尾から、前のユーザー入力以降の assistant の発言とツール呼び出しの入力を集める。"""
    try:
        with open(transcript_path, "rb") as f:
            f.seek(0, os.SEEK_END)
            f.seek(max(0, f.tell() - TRANSCRIPT_TAIL_BYTES))
            # splitlines は JSON 文字列中の生の U+2028 でも行を割るため使わない
            lines = f.read().decode("utf-8", errors="replace").split("\n")
    except (OSError, TypeError, ValueError):
        return ""
    texts = []
    for line in reversed(lines):
        try:
            entry = json.loads(line)
        except ValueError:
            continue  # tail 読みで先頭行は途中から始まる
        if not isinstance(entry, dict):
            continue
        prompt_text = user_prompt_text(entry)
        if prompt_text is not None:
            # 今回の入力が hook より先に transcript へ書かれるかは未確認のため、どちらでも動くようにする
            if not texts and prompt_text.strip() == current_prompt.strip():
                continue
            break  # それより前は別の話題の可能性がある
        texts.extend(assistant_texts(entry))
        if sum(len(t) for t in texts) >= TRANSCRIPT_MAX_CHARS:
            break
    return "\n".join(texts)[:TRANSCRIPT_MAX_CHARS]


def build_context(prompt, transcript_path=None):
    if not LESSONS_DIR.is_dir():
        return ""
    sections = load_sections()
    if not sections or not prompt.strip():
        return ""
    prompt_tokens = {token: 1.0 for token in tokenize(prompt)}
    score_sections(sections, prompt_tokens)
    picked = pick(sections)
    if not picked and transcript_path:
        # 常に足すと、直前の発言の語数が入力を圧倒して入力と無関係な教訓が1位になる
        # (実測: CDK の質問に codex の教訓が混入)。入力だけで決まらないときに限る。
        for s in sections:
            s["score"] = 0.0
        weighted = {token: TRANSCRIPT_WEIGHT for token in tokenize(read_recent_assistant_text(transcript_path, prompt))}
        score_sections(sections, {**weighted, **prompt_tokens})
        picked = pick(sections)
    return render(picked) if picked else render_index(sections)


def is_notification(prompt):
    return prompt.lstrip().startswith(NOTIFICATION_PREFIXES)


def main():
    try:
        payload = json.load(sys.stdin)
        prompt = payload.get("prompt") or ""
    except (json.JSONDecodeError, ValueError, AttributeError):
        return
    if is_notification(prompt):
        return  # pending も次の実入力まで残す

    parts = []
    pending = take_pending()
    if pending:
        parts.append(f"【前ターンの /remember 判定結果】\n{pending}")
    context = build_context(prompt, payload.get("transcript_path"))
    if context:
        parts.append(context)
    if not parts:
        return

    json.dump({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": "\n\n".join(parts),
        }
    }, sys.stdout, ensure_ascii=False)


if __name__ == "__main__":
    # Windows の Python は stdout/stdin が cp932 になり、日本語の注入内容が
    # 文字化けして hook 側で読めなくなる。明示的に UTF-8 へ固定する。
    for stream in (sys.stdin, sys.stdout):
        try:
            stream.reconfigure(encoding="utf-8")
        except (AttributeError, ValueError):
            pass
    try:
        main()
    except Exception as exc:  # hook の失敗でプロンプト送信を阻害しない
        log_error(exc)
