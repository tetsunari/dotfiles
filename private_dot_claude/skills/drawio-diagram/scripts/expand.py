#!/usr/bin/env python3
"""draw.io で圧縮保存された .drawio を、全ページ非圧縮の XML に書き換える。標準ライブラリのみ。

使い方: python3 expand.py diagram.drawio [出力先.drawio]
出力先を省くと元のファイルを上書きする。圧縮されていないページはそのまま残す。
"""
import base64
import sys
import urllib.parse
import xml.etree.ElementTree as ET
import zlib


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    if len(sys.argv) not in (2, 3):
        print("usage: expand.py <in.drawio> [out.drawio]", file=sys.stderr)
        return 2
    src = sys.argv[1]
    dst = sys.argv[2] if len(sys.argv) == 3 else src

    tree = ET.parse(src)
    root = tree.getroot()
    expanded = 0
    for diagram in root.iter("diagram"):
        if diagram.find("mxGraphModel") is not None or not (diagram.text or "").strip():
            continue
        # draw.io の圧縮形式: URL エンコード → raw deflate → base64
        raw = zlib.decompress(base64.b64decode(diagram.text), -15).decode("utf-8")
        diagram.append(ET.fromstring(urllib.parse.unquote(raw)))
        diagram.text = None
        expanded += 1
    # 残すと draw.io で保存し直したときに再び圧縮されうる
    root.attrib.pop("compressed", None)

    ET.indent(tree)
    tree.write(dst, encoding="utf-8")
    print(f"expanded {expanded} page(s) -> {dst}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
