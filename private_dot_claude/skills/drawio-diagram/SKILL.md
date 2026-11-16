---
name: drawio-diagram
description: 図を draw.io の XML（.drawio）で描く・直す時は必ずこのスキルを使う。
  「draw.io で」「drawio」「構成図」「アーキテクチャ図」「システム構成図」「ネットワーク図」
  「AWS の図」「VPC の図」「.drawio を直して」と言われた時に即座に起動。
  Mermaid・PlantUML・D2・Python diagrams を指定された時は使わない。
---

# draw.io で図を描く

## この図が目指すもの

見た人が、何がどの境界の中にあり、何がどこへ流れるかを図だけで追えること。見栄えのための要素は足さない。タイトル、凡例、番号バッジ、図の横の説明パネルは置かない。情報は枠・アイコン・ラベル・線とそのラベルで伝える。

## 題材別の決まり

題材に合う reference を先に読み、SKILL.md の決まりと合わせて使う。題材の決まりが SKILL.md と食い違えば題材側を優先する。

| 題材 | 読むファイル |
|---|---|
| AWS の構成図（VPC・サブネット・AWS サービス） | `references/aws.md` と `references/aws-styles.md` |
| 既存の .drawio を直す | `references/edit.md` |
| 上記以外（汎用のシステム構成図など） | この SKILL.md のみ |

## 進め方

1. 構成を書き出す。登場する要素、置き場所（どの境界の中か）、つながりと流れの向き
2. 配置を決める。枠の入れ子と、各図形の座標・寸法を先に全部決める
3. XML を書く。枠 → 図形 → 線の順に、何回かに分けてファイルへ足す（1回で丸ごと書くと出力上限で落ちる）
4. `scripts/validate.py` で検査し、ERROR が 0 になるまで直す
5. 下の「最後に伝えること」を伝える

座標は自分で決める。自動配置（ELK、draw.io の `--layout` など）は使わない。入れ子や上下の位置に意味がある図なので、動かされると崩れる。

XML をスクリプトで生成してもよい。作業用のスクリプトは `/tmp` ではなく出力先の隣の `.drawio-work/` に置き、消さずに残す。

## 検証

描画して目で確かめる手段が無い前提で、機械で検査する。

```sh
python3 <このスキルのディレクトリ>/scripts/validate.py diagram.drawio
```

- 終了コード 1（ERROR あり）のまま渡さない。自分で書いたパースや id 重複の検査が通っても、このスクリプトを必ず通す
- WARN も直す。「はみ出し」は座標か枠の寸法、「ラベルを貫く」は `exitDy`/`entryDy`。既存の図を直すときに元からあった WARN は除く
- 検査は構造だけ。線がラベルに重なるか、アイコン名が正しいかは分からない。描画して確かめていないことを最後に伝える

## 依頼に無いもの

依頼どおりに動かすために必ず要るものは、書かれていなくても描き、足したことを伝える（AWS なら NAT Gateway や外向き ALB を置く VPC の Internet Gateway）。要るかどうかが設計の選び方で変わるものは足さず、描いていないことを伝える。

依頼に置き場所が書かれていない要素は、推測で枠に入れず、枠の外に置いたことを伝える。

## 配置

- 起点（利用者・クライアント）を上端か左端に置き、流れを上→下か左→右の一方向にそろえる
- 枠は外側の境界から順に入れ子にする。子の座標は親の左上からの相対座標
- 子は親の枠に収める。枠の内側の余白は 20〜30
- 同じ行の図形は中心の y を、同じ列は中心の x をそろえる
- 間隔はラベルと線のラベルが収まる最小限。広げすぎると載せたとき全体が縮む。目安は横 140、縦 160、線のラベルが入る区間だけ縦 210

## ラベル

- アイコンと人のラベルは図形の下（`verticalLabelPosition=bottom;verticalAlign=top`）、箱・円柱・キューのラベルは図形の中。線を避けるためにラベルを動かさず、線の側を直す
- 製品・サービス名は正式名称のまま、それ以外は会話の言語で書く。枠の名前も同じ言語にそろえる
- 2行目に短い補足を添えてよい（「Writer」「読み取り専用」など、図から読めない役割や制約だけ）
- 線にもラベルを付け、何が流れるかを書く（「HTTPS」「注文イベント」「ログ」）。ラベルは線の `value` に書き、別の文字として置かない
- 文字の背景は透明。線のスタイルに `labelBackgroundColor=none` を入れる
- 区切り文字は`・`を使用する

## 線

- `edgeStyle=orthogonalEdgeStyle;rounded=0` で直角に曲げ、角は丸めない
- 接続点を必ず指定する。`exitX`/`exitY`/`entryX`/`entryY` で辺の中央（上 `0.5,0`、下 `0.5,1`、左 `0,0.5`、右 `1,0.5`）から出し入れする。指定しないと出入り位置が描画のたびに変わり、ラベルを貫く
- ラベルが下にある図形では、下の辺がラベルに隠れるので、下から出す・下へ入れる線はラベルの下へずらす。`exitDy`（入る側は `entryDy`）を `10 + 14 × ラベルの行数`（1行 24、2行 38、3行 52）にし、`exitPerimeter=0`（`entryPerimeter=0`）を足す
- 1つの辺に2本つなぐなら 0.25 と 0.75、3本なら 0.25・0.5・0.75 に振り分ける。4本目からは、行き先の方向に近い左右の辺へ回す
- 流れに逆らって戻る線（下の図形から上の図形へ書き戻すなど）は、左右の辺から出し入れする
- 線どうしを同じ経路で重ねない。交差はかまわない
- 線の `parent` はレイヤー（新しく描く図では `1`）にする。両端が別々の枠の中にあっても同じ
- 本流は実線、ログ・メトリクス・レプリケーション・関連付けのような補助の流れは破線にして色も変える。凡例は置かない
- 矢印は呼び出し・データが流れる向き
- 線が重なる場合は「円弧」で線のジャンプをする
- なるべく直線（不用意に線に確度をつけない）で表示する

汎用の線のスタイル（AWS の図は `references/aws-styles.md` を使う）:

```text
本流: edgeStyle=orthogonalEdgeStyle;html=1;rounded=0;endArrow=block;endFill=1;strokeColor=#545B64;labelBackgroundColor=none;verticalAlign=bottom;align=left;spacingLeft=6
補助: edgeStyle=orthogonalEdgeStyle;html=1;rounded=0;endArrow=block;endFill=1;strokeColor=#E7157B;dashed=1;labelBackgroundColor=none;verticalAlign=bottom;align=left;spacingLeft=6
```

左右の辺どうしをつなぐ線（`exitX` と `entryX` がどちらも 0 か 1）は、`align=left;spacingLeft=6` を `align=center` に置き換える。

## 図形

- 題材に公式アイコン集があれば、それを使う（AWS は `references/aws-styles.md` の表）。確かめられないからといって四角で代用しない。表に無い名前を推測で使ったら、そのことを伝える
- アイコンの無い汎用の図では、種類ごとに形を固定する。サービス・プロセス `rounded=1;whiteSpace=wrap;html=1`、データストア `shape=cylinder3;whiteSpace=wrap;html=1;boundedLbl=1;size=10`、キュー `shape=process;whiteSpace=wrap;html=1`、人 `shape=umlActor;verticalLabelPosition=bottom;verticalAlign=top;html=1`
- 枠（境界）は塗らずに線だけ、ラベルは左上: `rounded=0;whiteSpace=wrap;html=1;fillColor=none;verticalAlign=top;align=left;spacingLeft=10;container=1;collapsible=0;recursiveResize=0`。社外・外部の枠は `dashed=1`

## XML の決まりごと

`.drawio` は非圧縮の XML。圧縮・base64 にしない。

```xml
<mxfile>
  <diagram id="page-1" name="Page-1">
    <mxGraphModel adaptiveColors="auto">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <mxCell id="api" value="API サーバー" style="..." vertex="1" parent="1">
          <mxGeometry x="200" y="80" width="120" height="60" as="geometry" />
        </mxCell>
        <mxCell id="edge-api-to-db" value="注文を書き込む" style="..." edge="1" parent="1" source="api" target="db">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

- 新しく描く図は `id="0"`（ルート）と `id="1"`（レイヤー）を必ず置き、他は `1` か入れ子の枠を `parent` にする。既存の図はルートとレイヤーの id が違っていてもそのまま使う
- 図形の寸法は `width` と `height`。`w`/`h` と書かない
- id は `api`、`db-writer`、`edge-api-to-db` のように中身の分かる名前にし、重複させない。`source`/`target` は実在の id
- 線は自己終了タグにせず `<mxGeometry relative="1" as="geometry" />` を子に持たせる（無いと描かれない）
- XML コメントは書かない（`--` が入ると読めなくなる）
- 属性値の `& < > "` は `&amp; &lt; &gt; &quot;`。ラベルの改行は `&#xa;`（`\n` は文字のまま出る）。スタイルに `html=1`
- `html=1` のラベルは HTML として読まれるので、`List<Item>` のように `<` `>` を文字として見せるには `List&amp;lt;Item&amp;gt;` と書く
- `host`、`modified`、`version` のような draw.io が付ける属性は捏造しない

## 出力

保存先の指定があればそこ、無ければリポジトリの既存の図の置き場、それも無ければ作業ディレクトリ。ファイル名は中身の分かるケバブケース（`order-system.drawio`）。

## 最後に伝えること

- ファイルの場所と描いた要素
- validate.py の結果と、描画して目で確かめていないこと
- 依頼に無いが足したもの、描かなかったもの、置き場所を決めずに枠の外へ出したもの
- まとめて省いた線
- 推測したアイコン名・リージョン
- 残した作業用のファイル
- 判断に迷ったところ
