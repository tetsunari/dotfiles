---
name: d2-diagram
description: ソフトウェアの構成・モジュール依存・データの流れを D2 のテキストで描き、描かれたものを事実シートと照合する時は必ずこのスキルを使う。
  「D2 で」「d2 の図」「.d2 を直して」「構成をテキストで描いて」と言われた時、およびリポジトリに .d2 がある時に即座に起動。
  d2 の CLI は使わない（ブラウザ上の公式 WASM 版で描画）。draw.io を指定されたら drawio-diagram、Mermaid で済む図は Mermaid を使う。
---

# d2-diagram

D2 ファイルが図の本体で、絵はその描画にすぎない。
**D2 は、絵が間違っていても教えてくれない。** 構文が正しければ何でも描く。だから描いたものを読み戻して、事実シートと照合する。

- 描画：`~/.claude/skills/explainer/scripts/render.mjs`（一時 http サーバ + agent-browser + esm.sh の `@d2lang/d2`）。ビルド時にネット接続が要る
- エンジン：dagre（既定）と ELK。**TALA は使えない**
- d2 の CLI・npm パッケージをインストールしない・提案しない
- **描画は WSL 側でのみ動作確認済み。** Windows 版 claude からは未検証（agent-browser が Git Bash の shim で、Node から直接起動できない可能性が高い）。Windows 側で頼まれたら、その旨を伝えて止まる

## スコープの罠（一番大事）

D2 はスコープ外の名前をエラーにしない。**黙って新しい箱を作る。**

```d2
edge:    { cdn; gateway }
cluster: { orders; inventory }
gateway -> orders        # ← ルートに空の箱が 2 つ増える。本物の箱には矢印が付かない
```

コンテナをまたぐ辺は、**ルートでフルパス**か、**内側から `_.`** で書く。

```d2
edge.gateway -> cluster.orders          # ルート：両端をフルパス
cluster: {
  billing -> _.outside.stripe           # 内側から：`_` はこのコンテナの親（1 段だけ）
}
```

`_` はコンテナの内側でだけ使える。ルートで書くとコンパイルエラーになる。

## ループ

```
1. 事実シート   <name>.facts.json を、依頼文や道具の出力（import・設定・git diff --stat）から先に書く
2. ソース      <name>.d2 を書く
3. 検査        node <skill>/scripts/d2-check.mjs <name>.d2 --expect <name>.facts.json --shots /tmp/<name>
4. 目で見る    /tmp/<name>/desktop.png と mobile.png を Read で開く
5. 直す        ✗ が 0 になり、目で見ても不自然でなくなるまで 2〜4 を繰り返す
```

d2-check がシート無しでも落とすもの：描画の失敗（構文エラー）、**同じ名前の箱が 2 つ**（スコープの罠）。
どの辺もつながっていない箱は △ で知らせる（意図したものは `allowOrphans`）。

シート：

```json
{
  "boxes": ["gateway", "orders", "broker"],
  "deps": ["gateway->orders", "orders->broker"],
  "forbidden": ["orders->billing"],
  "containers": { "cluster": ["orders", "inventory"] },
  "exhaustive": true,
  "allowOrphans": ["legend"]
}
```

- `deps` は**向き付き**で照合する。逆向きなら「辺の向きが逆」で落ちる
- `exhaustive` で、シートに無い辺を描いたら落とす
- 名前は id の末尾 → ラベルの完全一致 → id かラベルの部分一致（1 つに絞れるときだけ）の順で探す。部分一致で当たったときは、どれに当たったかを出す。**その表示を読んでから**、シートと図のどちらを直すか決める。検査を通すために正しい箱のラベルを書き換えない

SVG が要るときは `--svg <out.svg>` で書き出す。

## 書き方の規則

- id は ASCII で安定した名前（`api`）。表示はコロンの後のラベル（`api: API サーバ`）
- コンテナをまたぐ辺はルートでフルパスか `_.`
- `direction` はルートに 1 つ。向きを変えたときの幅は描いて測る（縦に流しても、兄弟の箱が横一列に並んで幅が増えることがある）
- 辺は文として読めるように：`a -> b: 呼ぶ`。`--` は向きなし、`<->` は双方向
- エンジンはファイル先頭で選ぶ：`vars: { d2-config: { layout-engine: elk } }`（無ければ dagre）
  - ELK：一方向の長い流れ・入れ子。**箱ごとの `direction` を黙って無視する**
- **`grid-columns` は使わない。** ELK でも dagre でも、辺が箱を貫いて描かれた
- **d2-check は「線が箱を貫く」「ラベルが重なる」を検出できない。** CLEAN でも必ずスクショを目で見る
  - dagre：小さい図
- 座標は書かない

## 渡す

- 資料の中なら、`figures/<name>.d2` と `<name>.facts.json` を置き、本文から `![説明](figures/<name>.d2)` で参照する（explainer の verify-doc が照合し、build-html が描画する）
- 単体なら `<プロジェクト>/.claude/explainer/figures/` に置き（git 管理外。登録手順は explainer の「置き場所」）、`.d2` と `--svg` で書き出した SVG のパス、検査結果（CLEAN か）を渡す
