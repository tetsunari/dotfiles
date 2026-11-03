---
name: codex-pr-review
description: |
  コード差分・PR を Codex に批判レビューさせる時は必ずこのスキルを使う。
  「差分をレビュー」「PRをレビュー」「codex review」「pr review」
  「herdr で差分をレビュー」と言われた時、およびPR作成前・コミット前に即座に起動。
  別モデルの独立した視点でコードを叩かせ、指摘は人間がトリアージする。
context: inject
allowed-tools: Read, Bash, Grep, Glob
---

# Codex PR Review

コード差分を **Codex（別モデル）** にレビューさせる。
`code-reviewer` / `security-reviewer` agent とは**別視点**として使い、置き換えではない
（`rules/trinity-development.md` の「同一視点で3回より、違う視点で3種」）。

## 前提

`codex` が認証済みであること。未認証なら `codex login status` で確認して報告する。

## 手順

### Step 1: レビュー範囲の確定

`codex review` は範囲指定のオプションを持つ。対象に応じて選ぶ。

| 状況 | コマンド |
|---|---|
| 未コミットの変更（staged / unstaged / untracked） | `codex review --uncommitted` |
| ブランチ全体（PR相当） | `codex review --base <base-branch>` |
| 特定コミット | `codex review --commit <SHA>` |

レビュー観点を足したい場合は、プロンプトを引数で渡せる。

```bash
codex review --base main "このリポジトリの規約との整合性も見てください"
```

### Step 2: 実行と回収

**既定はワンショット（経路A）**（`rules/trinity-development.md` 規約9）。
経路Bは以下を**両方**満たす時のみ選ぶ。片方でも欠ければ経路A。

1. `HERDR_ENV=1`（下記で判定）
2. ユーザーが往復レビューを明示している。該当する語:
   「Herdr で」「ペインに常駐」「往復で詰めたい」「対話でレビュー」「reviewer を立てて」

```bash
test "${HERDR_ENV:-}" = 1 && echo "条件1 OK" || echo "経路A 確定"
```

条件1のみ満たし条件2が無い場合、経路Bを勝手に選ばない。往復が有効そうなら
経路Aを実行したうえで「Herdr 常駐に切り替えるか」をユーザーに尋ねる。

#### 経路A: ワンショット（既定）

リポジトリのルートで実行する。標準出力に出る `rmcp transport` / `websocket` の
ERROR 行は**非致命**なので、提示する際は除去してよい。

#### 経路B: Herdr ペインに常駐（上記の条件1・2を両方満たす場合のみ）

差分の疑問点を Codex と往復で詰めたい時に使う。手順の詳細は `herdr` スキルに従う。

```bash
herdr pane split --current --direction right --cwd "$PWD" --no-focus
herdr agent start reviewer --kind codex --pane <returned-pane-id>
herdr agent prompt reviewer "このリポジトリの <範囲> をレビューしてください" --wait --timeout 180000
herdr agent read reviewer --source recent-unwrapped --lines 200
```

- **差分本文をプロンプトに貼らない。** ペインの cwd がリポジトリルートなので、
  Codex 自身に `git diff` を実行させる
- 追加の問いは `herdr agent prompt reviewer "<追加指示>" --wait` を再送するだけでよい
- **起動直後の初回プロンプトは取りこぼすことがある**（実測: `--wait` が成功を返したのに
  Codex の入力欄は空のまま）。送信後は `agent read` で着弾を確認し、無ければ再送する
- Windows 版 claude から使う場合、`herdr` は Git Bash の shim
  （`~/.local/bin/herdr`）経由で WSL 側 CLI を叩く
- レビュー終了後、**自分が作ったペインのみ**を閉じる

### Step 3: 指摘のトリアージ

**Codex の指摘をそのままユーザーに流さない。** 以下の形式で整理する。

```
## Codex の指摘（N件）

### 採用推奨（M件）
- [ファイル:行] 指摘内容 — なぜ妥当か

### 却下推奨（K件）
- [ファイル:行] 指摘内容 — なぜ却下するか
```

却下の典型パターン:

- **過剰防衛** — 到達しない経路へのエラーハンドリング要求
- **スコープ外** — 今回の変更と無関係な既存コードへの指摘
- **YAGNI 違反** — 現時点で不要な拡張性の要求
- **規約との衝突** — このリポジトリの既存パターンに反する提案

ただし「到達しない」と判断する前に、**本当に到達しないか**を確認すること。
その分岐の前提条件が分岐自身の成功を不可能にしている場合、到達可能性に関わらず欠陥である。

### Step 4: 修正

ユーザーが採用と判断した指摘のみ反映する。修正は Claude が行う（Codex にはさせない）。

## 他のレビュー手段との使い分け

| 手段 | 視点 |
|---|---|
| `code-reviewer` agent | 規約・設計・並行性・ドメイン前提（Claude の視点） |
| `security-reviewer` agent | 脆弱性（OWASP） |
| **本スキル（Codex）** | **別モデルによる独立した視点** |
| `security-scan` / `full-scan` | 実行時・静的解析ツール |

## 機密

Codex は会社アカウントで学習オプトアウト済みのため業務コードの送信は可。
ただし `.env` や認証情報を含むファイルが差分に混ざっていないか、実行前に確認する。
