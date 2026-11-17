#!/usr/bin/env python3
"""UserPromptSubmit hook: プロンプトとの関連度が高い学習済みルールを本文ごと注入する。

見出し一覧を全件流すと additionalContext がサイズ上限を超えて persisted-output に
退避され、先頭プレビュー分しか読めなくなる。そのため関連上位のみに絞って注入する。
注入した文は会話に残って毎ターン再送されるため、同じ会話で注入済みの教訓は再注入しない。

あわせて remember-nudge.sh がバックグラウンド判定した結果(pending)を回収して通知する。
選定の精度は inject-lessons-eval.py（正解付きの実入力）で測る。定数を変えたら回すこと。
"""
import json
import math
import mmap
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

MAX_SECTIONS = 3
MAX_BYTES = 4000  # ヘッダを含む注入文全体の上限。1件目もこれを超えるなら入れない
# BM25 の定数。見出しの一致は本文の一致より強い手掛かりなので重みを上げる
BM25_K1 = 1.2
BM25_B = 0.75
HEADING_WEIGHT = 2.0
# 漢字列は元の語のまま数え、2-gram に分けない。分けた語を別々に足すと「最適化」1語が
# 3回数えられ、珍しい語1つで閾値を超えた。元の語が無いときだけ 2-gram で救う案も評価で
# 効果が出なかった（命中・再現率が同じ）ので入れていない
# 1位がこれに届かなければ注入しない。「1セクションにしか出ない語」の IDF に対する倍率で持つ。
# 固定値にすると教訓が増えるたびに IDF が上がり、同じ一致でも閾値の意味が変わるため。
# 値は inject-lessons-eval.py で決めた（311件で 6.0 相当）。上げると誤注入は減るが見落としが増える
MIN_SCORE_FACTOR = 1.125
SCORE_RATIO = 0.85  # 1位のスコアに対するこの比率未満は足切り
# 相槌や略語の2文字英字は、教訓の本文に偶然出る（"ok" が negative check の本文に当たる等）
STOP_WORDS = frozenset({"ok", "ng", "pc"})
# スコアリングは O(語数 × セクション数)。ログやコードを貼り付けた長大プロンプトで
# 語が1000超になると数百msかかるため上限を設ける。文字数の多い語ほど具体的で
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

BODY_HEADER = "【関連しそうな学習済みルール】"
INDEX_HEADER = "【学習済みルール索引】"

# 注入するのはルール本体だけ。背景（経緯）は全教訓の約3割を占め、要るときは Read できる
SHOWN_LABELS = ("ルール", "適用", "対策", "対処")
LABEL_RE = re.compile(r"^\*\*([^*]+?)[:：]?\*\*")

# 英数字列 / カタカナ2文字以上 / 漢字2文字以上。ひらがなは助詞ノイズのため対象外
TOKEN_RE = re.compile(r"[A-Za-z][A-Za-z0-9_.\-]+|[ァ-ヶー]{2,}|[一-鿿々]{2,}")
KANJI_RE = re.compile(r"^[一-鿿々]{2,}$")  # 英字だけ小文字化するための判定
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
    words = set()
    for match in TOKEN_RE.findall(text):
        if KANJI_RE.match(match):
            words.add(match)
        else:
            # 文末の "completed." の句点などを語に含めると一致しなくなる
            word = match.lower().rstrip(".-")
            if len(word) >= 2 and word not in STOP_WORDS:
                words.add(word)
    if len(words) > MAX_TOKENS:
        words = set(sorted(words, key=len, reverse=True)[:MAX_TOKENS])
    return words


def shown_text(body):
    """本文から SHOWN_LABELS の段落だけを残す。ラベルが1つも無い古い形式は本文全体を使う。"""
    kept, keep, labeled = [], False, False
    for line in body.splitlines():
        label = LABEL_RE.match(line)
        if label:
            labeled = True
            keep = label.group(1).strip() in SHOWN_LABELS
        if keep:
            kept.append(line)
    if not labeled:
        return body.strip()
    # ラベルはあるが表示対象が1つも無い形式は、空で注入しないよう本文全体を使う
    return "\n".join(kept).strip() or body.strip()


def load_sections():
    sections = []
    for path in sorted(LESSONS_DIR.glob("*.md")):
        text = path.read_text(encoding="utf-8", errors="replace")
        for chunk in re.split(r"(?m)^### ", text)[1:]:
            heading, _, body = chunk.partition("\n")
            shown = shown_text(body)
            sections.append({
                "file": path.name,
                "heading": heading.strip(),
                "shown": shown,
                "heading_key": heading.lower(),
                # 検索も注入する部分だけで行う。背景まで含めると経緯の文の語（「最適化」等）に
                # 当たって誤注入が増えた（inject-lessons-eval.py で比較）
                "body_key": shown.lower(),
                "score": 0.0,
            })
    return sections


def occurrence_counter(term):
    """text 中の term の出現回数を数える関数を返す。正規表現は語ごとに一度だけ作る。"""
    if not ASCII_RE.match(term):
        return lambda text: text.count(term)  # 漢字・カタカナは複合語の一部を拾うため部分一致のまま
    # 英字は code が CodeBuild に当たらないよう語の境目で切る。前に . - が付く位置
    # （cdk.context.json の context）は別の語の一部とみなす。後ろの .拡張子 は許す
    pattern = re.compile(rf"(?<![a-z0-9_.\-]){re.escape(term)}(?![a-z0-9_\-])")
    return lambda text: len(pattern.findall(text)) if term in text else 0


class Scorer:
    """BM25 で語ごとのスコアを出す。df と文書長は全セクションから一度だけ数える。"""

    def __init__(self, sections):
        self.sections = sections
        self.total = len(sections)
        avg_heading = sum(len(s["heading_key"]) for s in sections) / self.total
        avg_body = sum(len(s["body_key"]) for s in sections) / self.total
        self.norms = [(HEADING_WEIGHT / (1 - BM25_B + BM25_B * len(s["heading_key"]) / avg_heading),
                       1 / (1 - BM25_B + BM25_B * len(s["body_key"]) / avg_body)) for s in sections]
        # 直前の発言から拾う語の大半は教訓に出てこない。全体で一度だけ探して弾く
        self.corpus = "\n".join(s["heading_key"] + "\n" + s["body_key"] for s in sections)
        self.cache = {}

    def term_scores(self, term):
        """(セクションごとのスコア, 見出しに出たか) の配列の組。どこにも出ない語は None。"""
        if term in self.cache:
            return self.cache[term]
        if term not in self.corpus:
            self.cache[term] = None
            return None
        count = occurrence_counter(term)
        tfs, in_heading = [], []
        for s, (heading_norm, body_norm) in zip(self.sections, self.norms):
            heading_tf = count(s["heading_key"])
            tfs.append(heading_norm * heading_tf + body_norm * count(s["body_key"]))
            in_heading.append(heading_tf > 0)
        df = sum(1 for tf in tfs if tf > 0)
        if df == 0:
            result = None
        else:
            idf = math.log(1 + (self.total - df + 0.5) / (df + 0.5))
            result = ([idf * tf * (BM25_K1 + 1) / (tf + BM25_K1) if tf > 0 else 0.0 for tf in tfs], in_heading)
        self.cache[term] = result
        return result

    def add(self, weighted_words):
        for word, weight in weighted_words.items():
            result = self.term_scores(word)
            if result is None:
                continue
            for s, score, in_heading in zip(self.sections, *result):
                s["score"] += score * weight
                s["heading_hit"] = s.get("heading_hit", False) or in_heading


def display_dir():
    """注入文はモデルへ送られるため、ユーザー名を含む絶対パスを ~ に置き換えて出す。"""
    try:
        return "~/" + LESSONS_DIR.relative_to(Path.home()).as_posix()
    except ValueError:
        return LESSONS_DIR.as_posix()


def section_key(file_name, heading):
    return f"{file_name}#{heading}"


def render(picked):
    lines = [BODY_HEADER,
             "以下は過去の指摘から蓄積したルール。該当する作業ではこれに従う。"
             f"経緯（背景）が要るときは {display_dir()}/<ファイル> の同じ見出しを Read する。", ""]
    current = None
    for s in sorted(picked, key=lambda s: s["file"]):
        if s["file"] != current:
            current = s["file"]
            lines.append(f"## {current}")
        lines.append(f"### {s['heading']}\n{s['shown']}\n")
    return "\n".join(lines)


def relevant(sections):
    """閾値と足切りを通った教訓をスコア順に返す。注入済みかどうかはまだ見ない。"""
    # 本文にしか当たらない教訓は採らない。実入力の評価で、誤注入の大半が本文だけの一致
    # （「最適化」「スリープ」が経緯の文に1回出る等）、正解の大半が見出しの一致だった
    ranked = sorted((s for s in sections if s["score"] > 0 and s.get("heading_hit")),
                    key=lambda s: s["score"], reverse=True)
    total = len(sections)
    if not ranked or ranked[0]["score"] < MIN_SCORE_FACTOR * math.log(1 + (total - 0.5) / 1.5):
        return []
    cutoff = ranked[0]["score"] * SCORE_RATIO
    return [s for s in ranked if s["score"] >= cutoff]


def pick(candidates, already):
    picked = []
    for s in candidates:
        if len(picked) >= MAX_SECTIONS:
            break
        # 注入済みは枠の計算より前に外す。外した分は次点で埋める
        if section_key(s["file"], s["heading"]) in already:
            continue
        if len(render(picked + [s]).encode("utf-8")) > MAX_BYTES:
            continue
        picked.append(s)
    return picked


def render_index(sections):
    counts = {}
    for s in sections:
        counts[s["file"]] = counts.get(s["file"], 0) + 1
    entries = " ".join(f"{name}({n})" for name, n in sorted(counts.items()))
    return (
        f"{INDEX_HEADER}今回のプロンプトに強く関連する項目は検出されず。\n"
        f"関連しそうなら {display_dir()}/ 配下を Read すること: {entries}"
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


def line_bounds(data, pos):
    """pos を含む行の (先頭, 末尾) の位置。"""
    start = data.rfind(b"\n", 0, pos) + 1
    stop = data.find(b"\n", pos)
    return start, len(data) if stop < 0 else stop


def last_compact_offset(data):
    """最後の compact_boundary 行の直後の位置。無ければ 0（/clear は transcript ごと新しくなる）。"""
    end = len(data)
    while True:
        pos = data.rfind(b'"compact_boundary"', 0, end)
        if pos < 0:
            return 0
        start, stop = line_bounds(data, pos)
        try:
            entry = json.loads(data[start:stop])
            if isinstance(entry, dict) and entry.get("type") == "system" \
                    and entry.get("subtype") == "compact_boundary":
                return stop
        except ValueError:
            pass  # 会話本文に語として出ただけの行
        end = start


def injected_headings(text):
    """この hook の注入文から教訓の見出しを集める。ほかの hook の出力は空を返す。"""
    if BODY_HEADER not in text:
        return set()
    keys, current = set(), None
    for row in text.splitlines():
        if row.startswith("## "):
            current = row[3:].strip()
        elif row.startswith("### ") and current:
            keys.add(section_key(current, row[4:].strip()))
    return keys


def injected_in_session(transcript_path):
    """最後の圧縮以降にこの hook が注入した教訓の見出しと、索引を出したかを返す。

    圧縮より前の注入は要約に置き換わって Claude から見えないので、再注入してよい。
    末尾だけ読むと古い注入を見落とすため全体を対象にするが、mmap で該当行だけを取り出す
    （全体を read して行に割ると 50MB で約 30ms 余計にかかった）。
    """
    keys, index_shown = set(), False
    try:
        with open(transcript_path, "rb") as f, mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as data:
            pos = data.find(b"hook_additional_context", last_compact_offset(data))
            while pos >= 0:
                start, stop = line_bounds(data, pos)
                pos = data.find(b"hook_additional_context", stop)
                try:
                    attachment = json.loads(data[start:stop]).get("attachment")
                except (ValueError, AttributeError):
                    continue
                content = attachment.get("content") if isinstance(attachment, dict) else None
                for text in content if isinstance(content, list) else [content]:
                    if isinstance(text, str):
                        index_shown = index_shown or INDEX_HEADER in text
                        keys |= injected_headings(text)
    except (OSError, TypeError, ValueError):
        pass  # 空ファイルは mmap できない（ValueError）。注入済みなしとして扱う
    return keys, index_shown


def build_context(prompt, transcript_path=None):
    if not LESSONS_DIR.is_dir():
        return ""
    sections = load_sections()
    if not sections or not prompt.strip():
        return ""
    already, index_shown = injected_in_session(transcript_path) if transcript_path else (set(), False)
    scorer = Scorer(sections)
    prompt_words = {word: 1.0 for word in tokenize(prompt)}
    scorer.add(prompt_words)
    candidates = relevant(sections)
    if not candidates and transcript_path:
        # 常に足すと、直前の発言の語数が入力を圧倒して入力と無関係な教訓が1位になる
        # (実測: CDK の質問に codex の教訓が混入)。入力だけで決まらないときに限る。
        # 入力で当たった教訓が全部注入済みのときも、入力で決まっているのでここへ来ない
        for s in sections:
            s["score"], s["heading_hit"] = 0.0, False
        weighted = {word: TRANSCRIPT_WEIGHT
                    for word in tokenize(read_recent_assistant_text(transcript_path, prompt))}
        scorer.add({**weighted, **prompt_words})
        candidates = relevant(sections)
    picked = pick(candidates, already)
    if picked:
        return render(picked)
    if candidates or index_shown:
        return ""  # 関連する教訓はすべて会話に入っている／索引は既に出した
    return render_index(sections)


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
