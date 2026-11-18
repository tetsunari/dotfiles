# Antigravity CLI実行契約

## 利用環境の確認

`agy` は WSL 側（brew の cask `antigravity-cli`。`/home/linuxbrew/.linuxbrew/bin/agy`）にのみ存在する。Windows 版 claude.exe（Git Bash）には無く、shim も無い。確認は `agy --version`・`agy models` で行い、`gemini-3.8-flash-high` が一覧にあることを確かめる（2026-09-24 に agy 1.2.9 で確認済み）。

指定値は `--model gemini-3.8-flash-high --effort high`。モデルや引数が利用できない場合はその旨を報告し、別モデル・別経路へ黙って切り替えない。

## 入力と実行

初回は[編集プロンプト](../prompts/gemini-editor.md)、レビュー後の修復は[修復プロンプト](../prompts/gemini-repair.md)を使う。二つを連結しない。初回jobには原則modeとblocksのみを入れ、Claudeが作った保持事項・構成案・レビュー基準は添えない。ユーザーが今回明示した条件は必要な範囲で添える。

呼出しは `scripts/run_agy.py` に一本化する。プロンプトと job を `{"instructions": "...", "job": {...}}` に符号化し、stream-json の NDJSON 1行として標準入力へ渡す。原文を CLI 引数やシェル文字列へ埋め込まない。

1. job を WSL の `/tmp/jnw/job.json` に Write ツールで書く（Windows 側からは `\\wsl.localhost\Ubuntu\tmp\jnw\job.json`）。形は [examples/job.json](../examples/job.json) を参照
2. 実行する

   ```bash
   # WSL 側セッション
   python3 ~/.claude/skills/japanese-natural-writing/scripts/run_agy.py editor /tmp/jnw/job.json /tmp/jnw/candidate.json
   # Windows 側セッション（Git Bash）
   MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- zsh -c 'python3 ~/.claude/skills/japanese-natural-writing/scripts/run_agy.py editor /tmp/jnw/job.json /tmp/jnw/candidate.json'
   ```

   修復時は第1引数を `repair` にし、job に `original`・`candidate`・`issues` を含める。
3. `OK ...` が出た場合のみ `candidate.json` を読む。`FAIL: ...` は理由を報告し、原文を保持する

スクリプトは原稿以外のファイルを置かない一時ディレクトリで `--sandbox --disable-slash-commands` を付けて実行する。`--dangerously-skip-permissions` は使わない。既存会話を継続する引数を使わない。CLI 固有の認証情報を直接読み出さない。

## 外部操作の境界

`--disable-slash-commands` と併用した `--mode plan` は無効になる警告が出るため、plan に依存しない。`--sandbox` も完全なツール無効化の保証ではない。プロンプトでもツール禁止を明記している。スクリプトは `step_update.step_type` が `user_input` / `agent_response` 以外（ツール利用の疑い）なら不採用にする。

## 応答の検証（スクリプトが行うこと）

- 終了コード・タイムアウト（150秒）
- `init.model == gemini-3.8-flash-high`
- `result` イベントが1件で `status == "SUCCESS"`（大文字）
- `result.response` を JSON として解析。ログ中の波括弧から推測しない
- 全IDが入力と同じ順序で一意に揃い、textが文字列で、空でない原文に空の候補が無いこと

生の NDJSON は `<出力>.ndjson` に残る。CLI 更新で形式が変わり FAIL した場合は、この NDJSON を確認してからスクリプトを直す。未知の値を一律に成功へ正規化しない。

壊れたJSON、欠落、拒否、想定外のツール利用、モデル不一致は採用しない。無制限の再試行や別経路への切替はしない。内容の修復はSKILL.mdに従い最大1回。
