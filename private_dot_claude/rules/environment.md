---
description: "コマンドエイリアス設定：cat=bat, ls=eza, find=fd, grep=rg, cd=zoxide"
alwaysApply: true
---
# 環境設定

## コマンドエイリアス

このユーザー環境では以下のコマンドエイリアスが設定されています：

| エイリアス | 実際のコマンド | 説明 |
|-----------|--------------|------|
| `cat` | `bat` | syntax highlighting付きcat代替 |
| `ls` | `eza` | modern ls代替 |
| `find` | `fd` | 高速find代替 |
| `cd` | `z`（zoxide） | smart cd代替 |
| `grep` | `grep --colour=always` | **rg ではない**。GNU grep に色強制フラグを付けたもの |
| `diff` | `delta` | 色付き差分ビューア |
| `tree` | `eza --tree` | |
| `vi` / `vim` | `nvim` | |

### スクリプトで使うときは `command` を付ける

上記のエイリアスは**エラーを出さずに結果を変える**ため、出力を後段で処理する場合は
`command grep` / `command diff` / `command cat` のように素のコマンドを明示する。

実際に踏んだ壊れ方:

- **`diff`（→ delta）**: 色付き整形で出力するため `<` / `>` の行頭記号が付かない。
  `diff a b | grep '^<'` は差分があっても**常に空を返す**。差分の有無を判定するなら
  `command diff` を使うか、終了ステータス（差分ありで 1）を見る
- **`grep`（→ `--colour=always`）**: マッチ部分に ANSI エスケープが混入する。
  `VAR=$(grep ...)` や `grep -o ... | sort -u`、ハッシュ計算の入力にすると壊れる。
  `grep -c` のような数値のみの出力は影響を受けない
- **`cat`（→ bat）**: `-v` `-A` `-n` 等の GNU cat のフラグを受け付けず**エラーになる**。
  制御文字を確認する用途では `command cat -v`

### 注意事項
- 必要に応じてフルパスでの実行も可能
