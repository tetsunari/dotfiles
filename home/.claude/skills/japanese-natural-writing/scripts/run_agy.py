#!/usr/bin/env python3
"""agy (Gemini) に編集・修復プロンプトと job を渡し、候補 JSON を検証して書き出す。

usage: run_agy.py {editor|repair} JOB_JSON OUT_JSON
成功時のみ OUT_JSON を書き、exit 0。失敗理由は stderr、exit 1。
生の NDJSON は OUT_JSON と同じ場所に <OUT>.ndjson で保存する。
"""
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

MODEL = "gemini-3.8-flash-high"
SKILL_DIR = Path(__file__).resolve().parent.parent
ALLOWED_STEP_TYPES = {"user_input", "agent_response"}


def fail(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def build_input(prompt: str, job: dict) -> str:
    payload = json.dumps({"instructions": prompt, "job": job}, ensure_ascii=False)
    message = {"role": "user", "content": [{"type": "text", "text": payload}]}
    return json.dumps({"event": "user", "message": message}, ensure_ascii=False) + "\n"


def run_agy(stream_input: str) -> subprocess.CompletedProcess:
    agy = shutil.which("agy")
    if not agy:
        fail("agy が見つからない（WSL 側で実行しているか確認）")
    # 原稿以外のファイルを置かない一時ディレクトリで実行する
    with tempfile.TemporaryDirectory() as isolated:
        return subprocess.run(
            [agy, "--print=", "--model", MODEL, "--effort", "high", "--sandbox",
             "--disable-slash-commands", "--input-format", "stream-json",
             "--output-format", "stream-json", "--print-timeout", "120s"],
            input=stream_input, text=True, capture_output=True, timeout=150, cwd=isolated,
        )


def parse_events(stdout: str) -> tuple[dict, dict]:
    init, results = None, []
    for n, line in enumerate(stdout.splitlines(), 1):
        if not line.strip():
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            fail(f"NDJSON {n} 行目が JSON でない")
        kind = event.get("event")
        if kind == "init":
            init = event.get("init", {})
        elif kind == "result":
            results.append(event.get("result", {}))
        elif kind == "step_update":
            step_type = event.get("step_update", {}).get("step_type")
            if step_type not in ALLOWED_STEP_TYPES:
                fail(f"想定外のステップ（ツール利用の疑い）: {step_type}")
    if init is None:
        fail("init イベントが無い")
    if len(results) != 1:
        fail(f"result イベントが {len(results)} 件（1件であるべき）")
    return init, results[0]


def parse_response(text: str) -> dict:
    # 応答全体が ```json 〜 ``` の1個のフェンスで包まれている場合だけ剥がす（2026-10-01 に実測）
    fenced = re.fullmatch(r"```(?:json)?\n(.*)\n```\s*", text, re.S)
    try:
        return json.loads(fenced.group(1) if fenced else text)
    except json.JSONDecodeError:
        fail("result.response が JSON でない（波括弧からの推測はしない）")


def validate_blocks(job: dict, candidate: dict) -> None:
    expected = job["blocks"]
    blocks = candidate.get("blocks") if isinstance(candidate, dict) else None
    if not isinstance(blocks, list):
        fail("候補に blocks 配列が無い")
    got_ids = [b.get("id") for b in blocks if isinstance(b, dict)]
    want_ids = [b["id"] for b in expected]
    if got_ids != want_ids:
        fail(f"ID の欠落・重複・順序違い: 期待 {want_ids} / 実際 {got_ids}")
    for src, b in zip(expected, blocks):
        text = b.get("text")
        if not isinstance(text, str):
            fail(f"{b['id']}: text が文字列でない")
        if src.get("original", "").strip() and not text.strip():
            fail(f"{b['id']}: 空でない原文に空の候補")


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    if len(sys.argv) != 4 or sys.argv[1] not in ("editor", "repair"):
        fail(__doc__)
    mode, job_path, out_path = sys.argv[1], Path(sys.argv[2]), Path(sys.argv[3])

    prompt = (SKILL_DIR / "prompts" / f"gemini-{mode}.md").read_text(encoding="utf-8")
    job = json.loads(job_path.read_text(encoding="utf-8"))

    try:
        proc = run_agy(build_input(prompt, job))
    except subprocess.TimeoutExpired:
        fail("タイムアウト（150秒）")
    out_path.with_suffix(".ndjson").write_text(proc.stdout, encoding="utf-8")
    if proc.returncode != 0:
        fail(f"agy exit {proc.returncode}: {proc.stderr.strip()[:500]}")

    init, result = parse_events(proc.stdout)
    if init.get("model") != MODEL:
        fail(f"モデル不一致: {init.get('model')}")
    if result.get("status") != "SUCCESS":
        fail(f"status={result.get('status')} error={result.get('error')}")
    candidate = parse_response(result.get("response", ""))
    validate_blocks(job, candidate)

    out_path.write_text(json.dumps(candidate, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"OK model={init.get('model')} blocks={len(candidate['blocks'])} out={out_path}")


if __name__ == "__main__":
    main()
