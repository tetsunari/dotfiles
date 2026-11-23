#!/usr/bin/env python3
"""UserPromptSubmit hook: プロンプトに対応するスキルの起動指示を注入する。

スキルの発火をモデルの気分に委ねると、description が長大な少数のスキルに
注意が吸われて新しいスキルが呼ばれない。キーワードで機械的に判定し、
「このスキルを Skill ツールで起動せよ」と明示的に指示する。

発火表は skill-router.json に外出ししてあるので、スキル追加時はそちらだけ更新する。
inject-lessons.py とは独立して動く(片方が壊れてももう片方は生きる)。
"""
import json
import os
import re
import sys
import traceback
from datetime import datetime
from pathlib import Path

ROUTES_FILE = Path(os.environ.get("SKILL_ROUTER_FILE") or Path(__file__).resolve().parent / "skill-router.json")
SKILLS_DIR = Path(os.environ.get("SKILL_ROUTER_SKILLS_DIR") or Path.home() / ".claude/skills")
SETTINGS_FILE = Path(os.environ.get("SKILL_ROUTER_SETTINGS") or Path.home() / ".claude/settings.json")
STATE_DIR = Path(os.environ.get("INJECT_STATE_DIR") or Path.home() / ".claude/state")
LOG_FILE = STATE_DIR / "inject-skill-router.log"

MAX_SKILLS = 3  # 4つ以上並ぶと指示として弱くなるため、マッチ数の上位で打ち切る
# 相槌(「y」「はい」「OK」)を弾くだけの補助フィルタ。主判定はパターン側が担うため、
# ここを厳しくすると「grillして」のような短い正当な指示まで落ちる
MIN_PROMPT_CHARS = 4


def log_error(exc):
    """hook は失敗しても黙って exit するため、原因追跡用にログだけは残す。"""
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        with LOG_FILE.open("a", encoding="utf-8") as f:
            f.write(f"--- {datetime.now().isoformat()} {type(exc).__name__}: {exc}\n")
            f.write(traceback.format_exc())
    except OSError:
        pass


def disabled_skills():
    """settings.json で off にされたスキルは呼べないので発火対象から外す。"""
    try:
        overrides = json.loads(SETTINGS_FILE.read_text(encoding="utf-8")).get("skillOverrides", {})
    except (OSError, json.JSONDecodeError, ValueError, AttributeError):
        return set()
    return {name for name, state in overrides.items() if state == "off"}


def load_routes():
    try:
        routes = json.loads(ROUTES_FILE.read_text(encoding="utf-8")).get("routes", [])
    except (OSError, json.JSONDecodeError, ValueError, AttributeError) as exc:
        log_error(exc)
        return []

    off = disabled_skills()
    usable = []
    for route in routes:
        name = route.get("skill")
        # 実在しない/無効なスキルの起動を指示すると、モデルが存在しない名前を呼んで失敗する
        if not name or name in off or not (SKILLS_DIR / name / "SKILL.md").is_file():
            continue
        compiled = []
        for pattern in route.get("patterns", []):
            try:
                compiled.append(re.compile(pattern, re.IGNORECASE))
            except re.error as exc:
                log_error(exc)  # 壊れた1パターンで表全体を落とさない
        if compiled:
            usable.append({"skill": name, "reason": route.get("reason", ""), "patterns": compiled})
    return usable


def match(routes, prompt):
    hits = []
    for route in routes:
        count = sum(1 for pattern in route["patterns"] if pattern.search(prompt))
        if count:
            hits.append((count, route))
    # マッチしたパターン数が多いほど確信度が高いとみなす。同数なら表の記載順を保つ
    hits.sort(key=lambda h: h[0], reverse=True)
    return [route for _, route in hits[:MAX_SKILLS]]


def render(picked):
    lines = [
        "【スキル発火指示】",
        "このプロンプトは以下のスキルの対象と判定された。"
        "作業に着手する前に、Skill ツールで起動して内容に従うこと。",
        "無関係だと判断した場合のみ省略してよいが、そのときは省略した理由を一言述べること。",
        "",
    ]
    for route in picked:
        reason = f" — {route['reason']}" if route["reason"] else ""
        lines.append(f"- `{route['skill']}`{reason}")
    return "\n".join(lines)


def build_context(prompt):
    if len(prompt.strip()) < MIN_PROMPT_CHARS:
        return ""
    routes = load_routes()
    if not routes:
        return ""
    picked = match(routes, prompt)
    return render(picked) if picked else ""


def main():
    try:
        prompt = json.load(sys.stdin).get("prompt", "")
    except (json.JSONDecodeError, ValueError):
        return

    context = build_context(prompt)
    if not context:
        return

    json.dump({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": context,
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
