# Claude Code 設定ハーネス

- **言語**: Japanese
- **文字コード**: UTF-8

---

## rules/ 索引

| ファイル | 適用条件 | 内容 |
|---------|---------|------|
| `init.md` | 常時 | 出力トークン圧縮ルール |
| `trinity-development.md` | 常時 | 四位一体原則：ユーザー/Claude/Gemini(外部情報)/Codex(批判レビュー) の役割分担 |
| `ai-operations.md` | 常時 | AI運用10原則（確認ルール・自己改善ループ） |
| `agent-security.md` | 常時 | OWASP Agentic Top 10 + Least Agency 原則 |
| `core-principles.md` | 常時 | コア開発3原則（シンプル・根本原因・影響最小化） |
| `ponytail.md` | 常時 | 怠惰ラダー（実装前の探索順）・削ってはいけないもの |
| `security.md` | パッケージマニフェスト操作時 | パッケージインストール時のセキュリティチェック |
| `environment.md` | 常時 | コマンドエイリアス（bat/eza/fd/rg/zoxide） |
| `coding-style.md` | `*.ts,tsx,js,jsx,...` | 不変性・ファイル構成・エラーハンドリング |
| `patterns.md` | `*.ts,tsx,js,jsx` | API応答形式・Custom Hooks・Repository パターン |
| `wsl-operations.md` | **Windows側のみ** | Windows版 claude.exe から WSL を操作する際の知見。WSL側では出番が無いため**同期対象外**（WSL側に存在しないのが正常） |
| `verification-loop.md` | 常時 | 検証完了基準（動作証明なき完了禁止・確認手順） |
| `delegation.md` | 常時 | サブエージェント委譲基準・委譲マトリクス |

---

## セッション運用

コンテキストが 200k トークンを超えると読み込み単価が割増になり、かつ全履歴が毎ターン
再送されるため使用量がターン数の二乗で増える。長く続けるほど不利になる。

- 作業の区切りごとに `/clear` する。「まだ入るから」で続けない
- 200k 接近時、または作業フェーズが変わる時は `handoff` スキルで引き継ぎ文書を書き、
  新セッションで再開する（既存成果物は参照に留め、機密は伏せる）
- 現在の消費は `/context`、全体の使用量は `/usage` で確認する
- ツール出力の抑制は `rules/delegation.md` の「コンテキスト保護のための委譲」を参照

---

## agents/

エージェント定義は `~/.claude/agents/*.md`。一覧と用途は Claude Code が
「Available agent types」として自動注入するため、ここには重複して書かない。
委譲の判断基準は `rules/delegation.md` を参照。

---

## skills/ 索引（常時ロードから移設したもの）

| スキル | 起動条件 | 内容 |
|-------|---------|------|
| `ai-agent-principles` | AIエージェント/LLMアプリの設計・実装時 | Production AIエージェント8原則（旧 `rules/ai-agent-principles.md`） |

### herdr は両側に同期する（2026-09-09 に方針変更）

以前は「Windows 版 claude では `herdr` バイナリが無く `HERDR_ENV` も渡らない」ため
WSL 側のみに置いていたが、両方を解消したので**同期対象**に変更した。

| 対処 | 実体 |
|---|---|
| バイナリ | `C:\Users\setup_user\.local\bin\herdr`（Git Bash 用 shim）。引数を `wsl.exe -d Ubuntu -- /home/linuxbrew/.linuxbrew/bin/herdr` へ転送する。WSL 側でシェルを起動しないためクォートが崩れない。`--cwd` の UNC パスのみ WSL パスへ変換 |
| ペイン文脈 | `~/.zshenv`（WSL側）の `WSLENV` に `HERDR_ENV:HERDR_WORKSPACE_ID:HERDR_TAB_ID:HERDR_PANE_ID` を追加し、`win-claude` 起動時に引き継ぐ |

shim は WSL 側 CLI をそのまま呼ぶだけなので、スキル本文は無改造で両側に使える
（`agent-browser` のような二重保守は不要）。`~/.zshenv` の PATH 行が壊れると
shim も動かなくなる点は `rules/wsl-operations.md` と同じ。

`agent-browser` も同じ shim 方式で**同期対象に統一した**（2026-09-09）。
`C:\Users\setup_user\.local\bin\agent-browser` が
`wsl.exe -d Ubuntu -- /home/matsushita_te/.local/share/mise/shims/agent-browser` へ転送し、
引数中の Windows 形式パス（`//wsl.localhost/...` / `C:/...` / `/c/...`）を WSL パスへ変換する。
mise の shim は PATH 非依存で解決できるため `zsh -ic` は不要（起動が約1.4秒速い）。

**現在、両側で個別保守が必要なファイルは無い。**
