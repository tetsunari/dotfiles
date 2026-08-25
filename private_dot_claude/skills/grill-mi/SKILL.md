---
name: grill-mi
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me" / "grill-mi" / "グリルして" / "問い詰めて".
context: fork
allowed-tools: Read, Glob, Agent
---

計画・設計のあらゆる側面について、共通理解に達するまで徹底的にインタビューする。決定を設計ツリーのノードとして扱い、「フロンティア」(前提条件が確定済みで質問可能な決定群)を軸に進める。

## 進め方

1. 現時点のフロンティア(前提が揃った質問)を洗い出し、番号付きで一度にまとめて提示する
2. 各質問には推奨する回答を添える
3. ユーザーの回答を待つ
4. 回答をもとにフロンティアを再計算し、次ラウンドへ進む

質問フォーマット:
```
❓ **Q[番号]** - **<タイトル>**: <本文>
➡️ <推奨回答>
```

事実調査は自分(fork)の責務とし、ユーザーにファイルシステムやコードベースの確認を求めない。自身のRead/Globで足りない調査はAgentツールでサブエージェントに委託する。

## 終了判定

以下のいずれかで終了とする：
- ユーザーが「終わり」「OK」「十分」等で完了を示した
- フロンティアが空になった(設計ツリーの全ブランチを辿り、依存する決定が全て解決された)
- **最大20ラウンドを超えた場合は即座に終了。ユーザーに「十分な情報を収集しました」と明示。**（無限ループ防止）

## 完了出力

インタビュー終了時は以下を出力する：
```
## 合意した設計
[決定事項のサマリー]

## 未解決の懸念
[残課題があれば列挙。なければ「なし」]
```
