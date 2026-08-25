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

# 英数字列 / カタカナ2文字以上 / 漢字2文字以上。ひらがなは助詞ノイズのため対象外
TOKEN_RE = re.compile(r"[A-Za-z][A-Za-z0-9_.\-]+|[ァ-ヶー]{2,}|[一-鿿々]{2,}")
KANJI_RE = re.compile(r"^[一-鿿々]{2,}$")


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
            tokens.add(match.lower())
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


def score_sections(sections, prompt_tokens):
    total = len(sections)
    for token in prompt_tokens:
        df = sum(1 for s in sections if token in s["heading_key"] or token in s["body_key"])
        if df == 0:
            continue
        idf = math.log(total / df)
        if idf <= 0:
            continue  # 全セクションに出現する語は無情報
        for s in sections:
            if token in s["heading_key"]:
                s["score"] += idf * 2
            elif token in s["body_key"]:
                s["score"] += idf


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
    lines = ["【関連しそうな学習済みルール】", "以下は過去の指摘から蓄積したルール。該当する作業では必ず遵守すること。", ""]
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


def build_context(prompt):
    if not LESSONS_DIR.is_dir():
        return ""
    sections = load_sections()
    if not sections or not prompt.strip():
        return ""
    score_sections(sections, tokenize(prompt))
    picked = pick(sections)
    return render(picked) if picked else render_index(sections)


def main():
    try:
        prompt = json.load(sys.stdin).get("prompt", "")
    except (json.JSONDecodeError, ValueError):
        return

    parts = []
    pending = take_pending()
    if pending:
        parts.append(f"【前ターンの /remember 判定結果】\n{pending}")
    context = build_context(prompt)
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
