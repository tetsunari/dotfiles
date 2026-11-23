#!/usr/bin/python3
"""agy の PreToolUse hook。名前が *.env* のファイルを読む・書く・コマンドに渡すのを止める。

agy の permissions はパスの名指ししかできず、`*.env*` のような名前のパターンを書けないため hook で止める。
ファイルに書く中身（CodeContent など）は見ない。`process.env` を含むコードまで止めないため。
"""
import fnmatch
import json
import os
import re
import sys

PATTERN = "*.env*"
# パスを受け取る引数（AbsolutePath・TargetFile・DirectoryPath・SearchPath など）。中身（Content）は除く
PATH_KEY = re.compile(r"(path|file|dir)", re.IGNORECASE)
# コマンドを、引数・リダイレクト・代入（--env-file=.env）の区切りで分ける
COMMAND_SPLIT = re.compile(r"[\s;|&<>=()`]+")
# .en''v や .e\nv のように引用符・\ で名前を割る書き方を、取り除いてから見る
COMMAND_QUOTES = re.compile(r"['\"\\]")
# ワイルドカード（.en* や .e[n]v）が当たりうる名前。シェルの * は . で始まる名前に当たらないので、. 始まりの名前で試す
GLOB_SAMPLES = (".env", ".env.local")


def deny(reason):
    print(json.dumps({"decision": "deny", "reason": reason}, ensure_ascii=False))
    sys.exit(0)


def is_env_file(value):
    # .env.d/secret.json のようにフォルダ名が当たる場合も止めるため、パスの区切りごとに見る
    return any(fnmatch.fnmatch(part, PATTERN) for part in value.split(os.sep) if part)


def may_match_env_file(token):
    if is_env_file(token):
        return True
    name = os.path.basename(token)
    is_glob = name.startswith(".") and any(c in name for c in "*?[")
    return is_glob and any(fnmatch.fnmatch(sample, name) for sample in GLOB_SAMPLES)


def path_values(args):
    for key, value in args.items():
        if not PATH_KEY.search(key) or "content" in key.lower():
            continue
        for item in value if isinstance(value, list) else [value]:
            if isinstance(item, str):
                yield item


def main():
    try:
        call = json.load(sys.stdin)["toolCall"]
        args = call.get("args") or {}
        if isinstance(args, str):
            args = json.loads(args)
        if not isinstance(args, dict):
            raise TypeError(f"args が dict ではない: {type(args).__name__}")
    except (ValueError, KeyError, TypeError) as error:
        deny(f"deny-env-files: hook の入力を読めなかったため止めた（{error}）")

    for value in path_values(args):
        if is_env_file(value):
            deny(f"{PATTERN} のファイルは読み書きできない: {value}")

    command = args.get("CommandLine")
    if isinstance(command, str):
        for token in COMMAND_SPLIT.split(COMMAND_QUOTES.sub("", command)):
            if token and may_match_env_file(token):
                deny(f"{PATTERN} のファイルを渡すコマンドは実行できない: {token}")


if __name__ == "__main__":
    main()
