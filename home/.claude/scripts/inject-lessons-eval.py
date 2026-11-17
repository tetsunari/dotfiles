#!/usr/bin/env python3
"""inject-lessons.py の選定精度を、正解付きの評価セットで測る。

使い方: inject-lessons-eval.py [評価セット.jsonl]
評価セットの1行: {"prompt": str, "relevant": ["file.md|見出しの先頭", ...], "acceptable": [...]}
relevant が空の行は「教訓を1件も注入すべきでない」入力。acceptable は出ても誤りに数えない教訓。
行番号の偶数を調整用、奇数を確認用に分けて両方の数字を出す（閾値の当てはめすぎを見抜くため）。
"""
import importlib.util
import json
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_EVAL = SCRIPT_DIR / "inject-lessons-eval.jsonl"


def load_hook():
    # hook が同じディレクトリの lessons_cache を import する。-I で起動するとスクリプトの
    # ディレクトリが import 先に入らないため足す
    sys.path.insert(0, str(SCRIPT_DIR))
    spec = importlib.util.spec_from_file_location("inject_lessons", SCRIPT_DIR / "inject-lessons.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def matches(section, label):
    file_name, prefix = label.split("|", 1)
    return section[0] == file_name and section[1].startswith(prefix)


def evaluate(hook, rows):
    stats = {"pos": 0, "pos_hit": 0, "recall": 0.0, "neg": 0, "neg_fp": 0,
             "injected": 0, "correct": 0, "bytes": 0, "misses": [], "noise": []}
    for row in rows:
        context = hook.build_context(row["prompt"])
        # 注入文の解析は hook 側と同じものを使う（"file.md#見出し" を (file, 見出し) に戻す）
        sections = [tuple(key.split("#", 1)) for key in hook.injected_headings(context)]
        stats["bytes"] += len(context.encode("utf-8"))
        allowed = row["relevant"] + row.get("acceptable", [])
        wrong = [s for s in sections if not any(matches(s, label) for label in allowed)]
        stats["injected"] += len(sections)
        stats["correct"] += len(sections) - len(wrong)
        if wrong:
            stats["noise"].append((row["prompt"][:40], [f"{f}|{h[:30]}" for f, h in wrong]))
        if row["relevant"]:
            found = [label for label in row["relevant"] if any(matches(s, label) for s in sections)]
            stats["pos"] += 1
            stats["pos_hit"] += bool(found)
            stats["recall"] += len(found) / len(row["relevant"])
            if not found:
                stats["misses"].append(row["prompt"][:40])
        else:
            stats["neg"] += 1
            stats["neg_fp"] += bool(wrong)
    return stats


def summary(name, s, rows):
    precision = s["correct"] / s["injected"] if s["injected"] else 1.0
    return (f"{name}: 正例{s['pos']}問 命中率={s['pos_hit']}/{s['pos']} "
            f"再現率={s['recall'] / max(s['pos'], 1):.2f} | "
            f"負例{s['neg']}問 誤注入={s['neg_fp']}/{s['neg']} | "
            f"注入{s['injected']}件中 適合率={precision:.2f} | "
            f"平均{s['bytes'] / max(len(rows), 1):.0f}B/問")


def main():
    args = [a for a in sys.argv[1:] if a != "-v"]
    verbose = len(args) < len(sys.argv) - 1
    path = Path(args[0]) if args else DEFAULT_EVAL
    rows = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    hook = load_hook()
    for name, part in (("調整用", rows[0::2]), ("確認用", rows[1::2]), ("全体", rows)):
        s = evaluate(hook, part)
        print(summary(name, s, part))
        if verbose and name == "全体":
            for prompt in s["misses"]:
                print(f"  見落とし: {prompt}")
            for prompt, wrong in s["noise"]:
                print(f"  誤注入: {prompt} -> {wrong}")


if __name__ == "__main__":
    main()
