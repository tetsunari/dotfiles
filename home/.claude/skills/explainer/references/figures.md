# 図：問い → 形 → 事実シート → 検査 → 目で見る

図は Mermaid か D2 のテキストで描く。座標は書かない。書くのは箱と辺（意味）で、配置は道具が決める。
描画はビルド時にブラウザ（agent-browser）で行う。D2 は公式 WASM 版で、エンジンは dagre（既定）と ELK。TALA は使えない。

## 描くか

描く：4 つ以上の要素とその関係がある / 時間の順序がある / 包含関係・前後の比較がある
描かない：答えが 1 文で済む / 1 つの関数の中身 / 値を 1 つ聞かれている

## 問いから形を選ぶ

| 読み手の問い | 形 |
|---|---|
| どういう状態があり、何で移るか | Mermaid `flowchart`（状態 = 箱、遷移 = 辺）または `stateDiagram-v2` |
| どういう順序でやり取りするか | Mermaid `sequenceDiagram` |
| どう分岐するか・戻る辺のある手順 | Mermaid `flowchart` |
| どういう構造か（モジュール・構成・入れ子） | D2（`figures/<name>.d2` + 事実シート） |
| A は B に含まれるか | D2 の入れ子のコンテナ |

1 つの問いに図は 1 枚。Mermaid で済むなら Mermaid、入れ子や構造が要るなら D2。
どちらでも無理な自由な図は、描かずに表か箇条書きにする。

## 事実シート（D2 の構造の図）

構造の図は、テストを先に書くのと同じく、**事実シートを図より先に**書く。
出どころは道具の出力（import・`package.json`・設定ファイル・`git diff --stat`）。手で書くなら出どころを本文に書く。

```json
{
  "boxes": ["gateway", "orders"],
  "deps": ["gateway->orders", "orders->inventory"],
  "forbidden": ["inventory->orders"],
  "containers": { "cluster": ["orders", "inventory"] },
  "exhaustive": true,
  "allowOrphans": ["legend"]
}
```

`figures/<name>.d2` の隣に `figures/<name>.facts.json` を置けば、verify-doc が `d2-check.mjs` で照合する。
**CLEAN が保証するのは箱と辺の照合だけ。** 線が箱を貫く・ラベルが重なるといった配置の崩れは検出しないので、CLEAN でも必ずスクショを目で見る（下の「目で見るループ」）。
単体では `node ~/.claude/skills/d2-diagram/scripts/d2-check.mjs figures/<name>.d2 --expect figures/<name>.facts.json --shots /tmp/<name>`。
書き方とシートの詳細は d2-diagram スキル。

## D2 の注意

- **スコープ外の名前は、黙って新しい箱になる。** コンテナをまたぐ辺はルートでフルパス（`edge.gateway -> cluster.orders`）か、内側から `_.`（1 段上）で書く
- id は ASCII、表示はラベル（`gw: API ゲートウェイ`）
- エンジンはファイルの先頭で選ぶ：`vars: { d2-config: { layout-engine: elk } }`。本文のフェンスなら ```` ```d2 elk ````
  - ELK：一方向の長い流れ・入れ子。**箱ごとの `direction` を黙って無視する**
  - **`grid-columns` は使わない。** ELK でも dagre でも、辺が箱を貫いて描かれた（d2-check では検出できない）
  - dagre：小さい図
- 図の幅は本文の幅（約 740px）に縮められる。**0.7 倍を下回ると verify-doc が落とす**（文字が約 11px 未満になる）。
  `direction` を変えたときに幅がどう変わるかは、描いて測るまで分からない（縦に流しても、兄弟の箱が横一列に並んで幅が増えることがある）。
  ラベルを短くし、言いたいことはコンテナ名や本文に寄せる
- ラベルは 2 行以内

## Mermaid の注意

- 事実シートの照合は無い。辺の数が多い図は D2 にして照合をかける
- ラベルはページの CSS の影響を受ける（foreignObject の中の HTML）。図の中の文字が切れていたら、ページ側の CSS が `p` などに効いていないか疑う
- スタジアム形 `([…])` より角丸 `(…)`。二重丸 `(((…)))` は大きくなりすぎる
- 動きは図にしない。手順は本文に番号を振って書く

## 目で見るループ

1 回 = 描画 → 機械の検査 → 目で見る → 直す。

1. `verify-doc.mjs <資料> --shots`（または `d2-check.mjs ... --shots <dir>`）
2. `dist/.shots/<ページ>/desktop.png`・`desktop-dark.png`・`mobile.png` を Read で開く（資料の図はライト・ダーク両方の配色で描かれ、閲覧側の設定で切り替わる。スライドはライトのみ）
3. 見るもの：文字の切れ・潰れ、線が箱の名前を横切る、入口が上（左）に来ていない、スマホで読めない
4. 直したら 1 に戻る。ELK と dagre で見比べて、良い方を選んだ理由をソースのコメントに残す

機械の検査（描画失敗・横のはみ出し・事実シート）が通っても、読みやすさは目で見ないと分からない。
