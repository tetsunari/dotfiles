---
name: grill-mi
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me" / "grill-mi" / "グリルして" / "問い詰めて".
context: fork
allowed-tools: Read, Glob
---

計画・設計のあらゆる側面について、共通理解に達するまで徹底的にインタビューする。設計ツリーの各ブランチを一つずつ辿り、決定間の依存関係を順番に解決していく。各質問には推奨する回答も提示する。

質問は一度に一つずつ行う。

コードベースを探索することで答えられる質問は、インタビューの代わりにコードベースを探索する。

## 終了判定

以下のいずれかで終了とする：
- ユーザーが「終わり」「OK」「十分」等で完了を示した
- 設計ツリーの全ブランチを辿り、依存する決定が全て解決された
- **最大20質問を超えた場合は即座に終了。ユーザーに「十分な情報を収集しました」と明示。** （無限ループ防止）

## 完了出力

インタビュー終了時は以下を出力する：
```
## 合意した設計
[決定事項のサマリー]

## 未解決の懸念
[残課題があれば列挙。なければ「なし」]
```
