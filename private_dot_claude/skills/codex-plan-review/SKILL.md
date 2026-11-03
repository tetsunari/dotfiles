---
name: codex-plan-review
description: |
  実装計画を Codex に批判レビューさせる時は必ずこのスキルを使う。
  「計画をレビュー」「計画の穴を探して」「codex にレビューさせて」「plan review」
  「herdr で計画をレビュー」と言われた時、および実装着手の直前に即座に起動。
  別モデルの独立した視点で計画の欠落を突かせ、指摘は人間がトリアージする。
context: inject
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Codex Plan Review

実装計画を **Codex（別モデル）** に叩かせ、Claude 自身では気づけない欠落を検出する。
`rules/trinity-development.md` の「批判レビュー」役の実行手順。

## 前提

- `codex` が認証済みであること（未認証なら `codex login status` で確認して報告する）
- レビュー対象の計画がファイルとして存在すること

## 大原則

**Codex の指摘を鵜呑みにしない。** 過剰防衛な指摘（起きない障害への対処要求、
スコープ外の一般論、YAGNI に反する拡張提案）が必ず混ざる。
**採否は人間がトリアージする。ここを自動化すると批判レビューの意味が消える。**

## 手順

### Step 1: 対象の確定

レビュー対象の計画ファイルを確定する。無ければ `task-planner` で先に作る。

### Step 2: Codex に投げる

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

```bash
codex exec -s read-only --skip-git-repo-check -C "<リポジトリルート>" \
  -o /tmp/codex-plan-review.txt \
  "以下の実装計画をレビューし、欠落・矛盾・リスクを指摘してください。
   指摘ごとに深刻度（blocking / non-blocking）を付けてください。
   $(cat <計画ファイル>)"
```

- **`-s read-only` を必ず付ける**（書き込ませない）
- 結果は `-o` でファイルに回収する。標準出力にはログが混ざる
- 標準出力に出る `rmcp transport` / `websocket` の ERROR 行は**非致命**なので無視してよい
- 標準出力の `session id:` を控える（次ラウンドで使う）

#### 経路B: Herdr ペインに常駐（上記の条件1・2を両方満たす場合のみ）

手順の詳細は `herdr` スキルに従う。要点のみ:

```bash
herdr pane split --current --direction right --cwd "$PWD" --no-focus
herdr agent start reviewer --kind codex --pane <returned-pane-id>
herdr agent prompt reviewer "<レビュー依頼文>" --wait --timeout 180000
herdr agent read reviewer --source recent-unwrapped --lines 200
```

- **計画本文をプロンプトに貼らず、計画ファイルのパスを渡して読ませる。**
  `agent prompt` の送信遅延はプロンプト長に比例して伸びる
- **起動直後の初回プロンプトは取りこぼすことがある**（実測: `agent prompt --wait` が
  成功を返したのに Codex の入力欄は空・Context 0% のまま）。送信後は必ず
  `agent read` で着弾を確認し、届いていなければ再送する
- 応答が読み切れない場合（alternate screen）は、Codex に Markdown ファイルへ
  書かせてパスだけ返させる。`herdr` スキルの読み取り節を参照
- Windows 版 claude から使う場合、`herdr` は Git Bash の shim
  （`~/.local/bin/herdr`）経由で WSL 側 CLI を叩く。`--cwd` の UNC パスは
  shim が WSL パスへ変換する。`HERDR_ENV` は `~/.zshenv` の `WSLENV` で伝搬させている
- レビュー終了後、**自分が作ったペインのみ**を閉じる

Step 3 以降のトリアージは経路によらず共通。

### Step 3: 指摘のトリアージ

Codex の指摘を**そのままユーザーに流さない**。以下の形式で整理して提示する。

```
## Codex の指摘（N件）

### 採用推奨（M件）
- [深刻度] 指摘内容 — なぜ妥当か

### 却下推奨（K件）
- 指摘内容 — なぜ却下するか（過剰防衛 / スコープ外 / 既に対処済み 等）
```

却下を推奨する場合は**必ず理由を書く**。「過剰だと思う」だけでは判断材料にならない。
判断が割れそうな指摘は、採否を決めずにユーザーへ委ねる。

### Step 4: 計画の修正

ユーザーが採用と判断した指摘のみを計画へ反映する。
**blocking の指摘を残したまま実装へ進まない。**

### Step 5: 再レビュー（必要な場合）

修正後に再度かけるときは、同じセッションを継続する。
経路Bなら `herdr agent prompt reviewer "<追加指示>" --wait` を再度送るだけでよい（session id 不要）。

```bash
codex exec -s read-only --skip-git-repo-check -C "<リポジトリルート>" \
  -o /tmp/codex-plan-review-r2.txt \
  resume <SESSION_ID> \
  "指摘を反映して計画を更新しました。残っている問題を指摘してください。
   $(cat <計画ファイル>)"
```

**`resume` は `-s` `-C` を受け付けない。** それらは `codex exec` 側（`resume` より前）に置く。
`--last` は他の codex セッションが割り込むとズレるため、**session id を明示指定**する。

## 終了条件

以下のいずれか。

- blocking の指摘がゼロになった
- 残る指摘をユーザーが「却下」と判断した
- **3ラウンドを超えた** — それ以上は収束しないので、残課題を明示して人間の判断に委ねる

## 機密

Codex は会社アカウントで学習オプトアウト済みのため、業務内容の送信は可
（`rules/trinity-development.md` の機密情報保護を参照）。
ただし API キー・パスワード・秘密鍵・接続情報は計画から除いてから送る。
