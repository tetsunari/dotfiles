---
name: d2-slides
description: Markdown 1枚からスライド（HTML）を作る時は必ずこのスキルを使う。
  「スライドにして」「スライド作って」「発表資料」「デッキ」「slides」と言われた時に即座に起動。
  図は D2 / Mermaid のフェンスで書き、ビルド時に描画して、オフラインで開ける1枚HTMLにする。
  スライドからのはみ出し・図の描画失敗・図の縮小しすぎを検査する。d2 の CLI は使わない。
---

# d2-slides

スライドは普通、壊れていても誰も気づかない。枠で半分切れた箇条書き、読めないほど縮んだ図。
このスキルは、デッキを**検査に落ちる状態**にする。

```bash
node <skill>/scripts/build-deck.mjs deck.md --shots
# ✓ built/index.html: 8 slides, 5 figure(s) — 目で見る: built/.shots/deck.png
```

- 描画は `~/.claude/skills/explainer/scripts/render.mjs`（一時 http サーバ + agent-browser + esm.sh）。ビルド時にネット接続が要る
- 出力 `built/index.html` はオフラインで開ける。←/→/Space/クリックで送る。URL の `#s3` で 3 枚目から開く。印刷すると 1 枚 1 ページ
- d2 の CLI・npm パッケージをインストールしない・提案しない
- **描画は WSL 側でのみ動作確認済み。** Windows 版 claude からは未検証（agent-browser が Git Bash の shim で、Node から直接起動できない可能性が高い）。Windows 側で頼まれたら、その旨を伝えて止まる

置き場所は `<プロジェクト>/.claude/explainer/slides/<topic>/deck.md`（git 管理外。登録手順は explainer の「置き場所」）。

## デッキの形式

````markdown
---
title: 図が間違っていても誰も教えてくれない
subtitle: D2 のスコープの罠
author: 名前
date: 2026-10-07
---

# 図が間違っていても誰も教えてくれない      ← 単独の `#` で始まるスライドはタイトルスライド（subtitle / author / date を添える）

---

## スコープ外の名前は新しい箱になる          ← `##` が通常のスライドの見出し

```d2 elk
direction: right
edge: { cdn; gateway }
cluster: { orders; inventory }
edge.gateway -> cluster.orders: 呼ぶ
```

---

## 直し方

- コンテナをまたぐ辺はルートでフルパス
- 内側からは `_.` で親を指す
````

- スライドの区切りは行頭の `---`（コードフェンスの中は区切らない）
- 図は ```` ```d2 ````（dagre）/ ```` ```d2 elk ```` / ```` ```mermaid ````。D2 の書き方は d2-diagram スキル（特にスコープの罠）
- スライドは 1280×720。本文 28px、見出し 40px。1 枚に言うことは 1 つ
- **D2 の既定の文字（箱のラベル約 14px）はスライドでは小さすぎる。** 図は高さに合わせて 0.6 倍前後まで縮むため、デッキの図には文字サイズを指定する
  ```d2
  **.style.font-size: 28              # 箱とコンテナ
  (** -> **)[*].style.font-size: 24   # 辺のラベル
  ```
  資料（explainer）と同じ `.d2` を使い回すときは、デッキ用にコピーしてから足す

## ループ

```
1. 書く       deck.md
2. ビルド     node <skill>/scripts/build-deck.mjs deck.md --shots
3. 直す       ✗ が出たら、出た順に直す
4. 目で見る   built/.shots/deck.png を Read で開く（全スライドを縦に並べた 1 枚）
5. 2 に戻る   ✗ が 0 で、目で見ても不自然でなくなるまで
```

build-deck が落とすもの（exit 1）：

| 検査 | 直し方 |
|---|---|
| 図の描画失敗（構文エラー・30 秒以内に終わらない） | ソースの構文を直す。タイムアウトならネット接続を確認 |
| スライド枠からはみ出した要素（見出し・段落・箇条書き・表・コード・図） | 内容を減らすか、スライドを分ける |
| 図の縮小率が 0.5 未満 | 図を分割する、`direction` を変える（横長 → 縦長など） |

機械の検査は、図の中の文字が元々小さい・線が箱の名前を横切る、といった読みやすさまでは見ない。**必ず目で見る。**

## 渡す

`built/index.html` のパス、スライド枚数、検査結果（✓ か、残った ✗）を渡す。
