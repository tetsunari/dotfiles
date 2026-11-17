---
name: explainer-book
description: 1本の速習資料に収まらない、章立ての学習資料（<topic>-book/01-quickstart.md, 02-….md …）を作る時は必ずこのスキルを使う。
  「学習資料」「チュートリアル」「ハンズオン」「本にまとめて」「章立てで」「01-quickstart から」と言われた時、
  および explainer の資料が読了20分を超える・演習が要る・概念に順序がある時に即座に起動。
  章ごとの学習目標と理解度チェックの対応、概念の導入順、読了時間、「出発点で落ち・答えで通る」演習を verify-book.mjs で検査する。
---

# explainer-book

`explainer` の本版。1 本の速習資料（20 分以内・例 1 つずつ）で足りないとき、章に分けて、**手を動かして身につける**資料にする。

ペルソナ・図・検証・置き場所・依存の方針は `explainer` をそのまま使う。**先に `~/.claude/skills/explainer/SKILL.md` を読むこと。**
このスキルが足すのは、本全体の設計と検査。
`verify-book.mjs` は explainer の `verify-doc.mjs` を呼ぶ。

## いつ本にするか

どれかに当てはまったら本にする。1 つも当てはまらなければ explainer の 1 本で書く。

- 読了が 20 分を超える
- 読み手が手を動かす演習が要る（読むだけでは「判定できる」ようにならない）
- 概念に順序がある（A を知らないと B が読めない）

## 構成

```
<プロジェクト>/.claude/explainer/<topic>-book/   （git 管理外。explainer の「置き場所」）
  README.md            目次：想定読者、章ごとの「読み終えたらできること」、章の依存図、再現方法
  book.json            章の順序・学習目標・導入する概念・演習（references/book-json.md）
  01-quickstart.md     最初の章は必ず quickstart：理論の前に、動く結果に着く
  02-….md              concept：1 章 1 つの判定を身につける
  03-….md              practice：演習が中心
  checks.json          本文の出力と演習の答えを再生成するコマンド（explainer と同じ形式）
  examples/            章で使うコード。演習の出発点と答えを別ファイルにする
  figures/             book-map.mmd（生成）と各章の図
```

## 手順

```
1. ペルソナ     explainer と同じ。「怪しいところ」から、本全体の問いを 1 つ決める
2. 目標を並べる  問いに答えるために読み手ができるべき判定を 3〜6 個。1 章に 1〜2 個
3. 概念の順序   各判定に要る概念を書き出し、どの章で導入するかを決める（book.json の introduces / requires）
4. 実物を先に   各章の例と演習を作り、走らせる。演習は「出発点で落ちる」「答えで通る」を両方確かめる
5. 章を書く     explainer の writing.md の型。章の冒頭に所要時間とゴール、末尾に理解度チェック
6. 検証         node <skill>/scripts/verify-book.mjs <book-dir> --write（初回・book.json を変えたとき）→ --shots で検査
7. 読ませる     first-reader で、少なくとも 01-quickstart と演習の章を、ペルソナ本人に読ませる
8. 渡す         dist/index.html と、各章の 1 行要約。未検証の点を明記
```

構成の表（章・目標・概念）は、書き始める前にユーザーに見せて確認を取る。直すのは名指しされた行だけ。

### 2. 学習目標

目標は「読み終えたら、何を判定できるか」で書く。「〜を理解する」は検査できないので書かない。

- 悪い例：「CTI を理解する」
- 良い例：「CTI が出たとき、条件が弱すぎるだけか、性質が本当に破れるかを TLC で判定できる」

各目標には、理解度チェックの問いを 1 つ以上付ける（問いの直前に `<!-- quiz: <目標id> -->`）。

### 3. 概念の順序

- ペルソナが既に知っている概念は `assumed` に書く。説明しない
- それ以外の概念は、ちょうど 1 つの章が `introduces` する。その章より前の章の本文に出てきたら検証が落ちる（リンクの文字列も本文に含まれる）
- 章が前提にする概念は `requires` に書く。依存図の矢印になる

### 4. 演習

演習の答えも実行して確かめる。答えが間違った演習は、間違いを教える。

| kind | 例 | 検査 |
|---|---|---|
| `write` | 条件・関数・設定を書かせる | `starter`：出発点のまま実行すると**落ちる** check。`answer`：答えで**通る** check |
| `check` | 道具を回して判定させる | `answer`：判定の根拠になる出力を再生成する check |

- **starter の check は異常終了するので、checks.json に `"exit": <終了コード>` を書く**（書かないと verify-doc が落とす）
- 答えは、演習と同じ節の `<details>` に入れる
- 演習の前に `<!-- exercise: <id> -->` を置く

### 5. 章を書く

explainer の文体に加えて：

- 冒頭の引用ブロックに、所要時間・ゴール（その章の目標）・前提（前の章）
- 末尾で次の章へリンクする（`→ [02 へ](02-….md)`）。HTML では `.html` へのリンクに書き換わる
- 前の章の結果を使うときは章番号で参照する（「1 章の 3 つの check」）。同じ説明を繰り返さない
- 手で推論した結果は、道具の出力に置き換える。推論は外れる
- README に `![章の依存](figures/book-map.mmd)` を置く（verify-book が生成する Mermaid）

### 6. 検証

```
node <skill>/scripts/verify-book.mjs <book-dir> --write   # 依存図（book-map.mmd / .facts.json）を作り直す
node <skill>/scripts/verify-book.mjs <book-dir> --shots   # 検査。スクショは dist/.shots/<ページ>/
```

| 検査 | 落ちる条件 |
|---|---|
| chapters | 章ファイルがない。`NN-` の番号が book.json の順と違う。1 章が quickstart でない |
| objectives | quiz が付いていない目標がある。quiz が他の章の目標を名指ししている |
| concepts | 概念を導入より前の章で使っている。`requires` が導入されていない。`introduces` と宣言したのに本文に出てこない |
| budget | 推定読了時間（500 字/分 + コード 15 行/分）が `minutes` を超える |
| exercises | 印がない。答えが `<details>` にない。check が checks.json にない。`write` 演習に starter がない |
| map | `figures/book-map.*` が book.json と一致しない。README に図がない |

そのあと README と全章を `verify-doc.mjs --pages` に渡し、出力の引用・図・ページ間リンク・各ページの描画を検査する。
`book verdict: VERIFIED` になるまで直す。VERIFIED の後、スクショを Read で開いて目で見る。

## やってはいけないこと

- **章を増やして薄める。** 目標がない章、理解度チェックが目標を問わない章は要らない
- **演習の答えを走らせない。**
- **前の章の説明を繰り返す。** 章番号で参照する
- **検証を通すために言い換える。** 概念の検査に落ちたら、定義を前の章に移すか章の順序を見直す。同義語に置き換えて逃げない

## ファイル

| パス | 内容 |
|---|---|
| `references/book-json.md` | book.json の全フィールド |
| `scripts/verify-book.mjs` | 本全体の検査 → explainer の verify-doc.mjs |
| `~/.claude/skills/explainer/scripts/build-html.mjs` | 複数ページを HTML に（`.md` リンクを `.html` に書き換え） |
