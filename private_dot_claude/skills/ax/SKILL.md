---
name: ax
description: Use when fetching a web page or extracting structured data (titles, links, table rows) from HTML and want to avoid dumping raw HTML into the context window, or when curl gives no useful signal on empty/404 responses. Covers the `ax` CLI (https://github.com/yusukebe/ax).
---

# ax

## Overview
`ax`は「fetch → discover → extract」をワンコマンドで行うCLI(https://github.com/yusukebe/ax)。curlで取得した生HTMLをそのままコンテキストに渡すとトークンを浪費し、マークアップ変更で正規表現パースが壊れる問題を解消する。単一バイナリ(Bun compile + linkedom)。

## When to Use
- Webページから特定要素(タイトル・リンク・表データ等)を抽出したい
- 空レスポンスや404を確実に検知したい(curlは無出力で気づきにくい)
- 生HTMLをコンテキストに入れずページ構造を把握したい
- 未インストールの場合: `curl -fsSL https://ax.yusuke.run/install | sh`(導入前にスクリプト内容を確認)

## Quick Reference

| 用途 | コマンド |
|---|---|
| 基本fetch(ステータス・リダイレクト・応答時間を報告) | `ax <URL>` |
| ページ構造の把握 | `ax <URL> --outline` |
| 特定テキストの位置特定 | `ax <URL> --locate 'text'` |
| 複数フィールド抽出 | `ax <URL> '.item' --row 'title=a, href=a@href'` |
| テーブル抽出 | `ax <URL> --table` |
| 条件フィルタ | `ax <URL> '.item' --where '...'` |
| Markdown変換+トークン上限 | `ax <URL> --md --budget 800` |
| JSON出力(デフォルトはTSV) | `ax <URL> --json` |

## Implementation

記事一覧のタイトルとリンクを抽出する例:
```bash
ax https://example-news.com/ '.article' --row 'title=h2, href=a@href' --budget 1000
```
空/404レスポンスでも完全なレポートが出力されるため、`ax`の出力(ステータス行)を確認するだけで異常検知できる。

## Common Mistakes
- 生HTMLをそのままcurlで取得してcontextに流し込む → `--outline`/`--row`で構造化してから読む
- 正規表現でHTMLパース → CSSセレクタベースの`--row`/`--table`/`--where`を使う
- レスポンス確認を目視HTML頼みにする → `ax`は常にstatus/URL/redirect/timingを報告するので、その行を確認する
