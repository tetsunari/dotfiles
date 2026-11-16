# ponytail 導入記録

更新時はこのファイルの SHA を基準に `git diff <SHA>..HEAD -- skills/` で差分のみを再審査する。

## 取得元

| 項目 | 値 |
|---|---|
| リポジトリ | https://github.com/DietrichGebert/ponytail |
| 導入日 | 2026-09-14 |
| 上流バージョン | v4.9.0 |

## 配置ファイルと sha256

上流 `356918eb` の同名ファイルと一致することを確認済み。

| ファイル | 配置先 | sha256 |
|---|---|---|
| `ponytail-review/SKILL.md` | `skills/` | `40df33b58fc6ef889b93585733feb9566b76e9586efa7f376785c1e995197ac0` |
| `ponytail-audit/SKILL.md` | `skills/` | `5560b8e383dbe2ddfddc873a1e2bf2e586e23e0cd7d995537482b2315331f6d1` |
| `ponytail-debt/SKILL.md` | `skills/` | `c82bb352bab21e081e71b70430af451b91750760fa776a4a807c8cfa52d4c85f`（v5.2.0 `2961b52` に更新） |

### 2026-10-13 部分更新（v5.2.0 `2961b52`）

- `ponytail-debt` のみ上流版へ差し替え。`git grep --no-index --exclude-standard` で .gitignore 配下を除外、`/* */` コメントと新マーカー `shortcut:` に対応（旧 `ponytail:` も拾う）。審査: 非ASCII文字・HTMLコメントゼロ、実行コマンドは読み取りのみ
- `ponytail-review` / `ponytail-audit` は v4.9.0 のまま据え置き。v5（`01cbf81`）でバグ・セキュリティ・性能まで見る総合レビューに作り替えられ、`code-reviewer` と役割が重なるため
- `rules/ponytail.md` に v5 ラダーの要点4行（呼び出し元まで直し切る・エラー処理の引き継ぎ・エッジケース優先・独自部品優先）を追記。マーカーは `ponytail:` のまま（debt が両方拾うため）
- 次回の差分基準 SHA: debt は `2961b52`、review/audit は `356918eb`

配置先は Windows 側 `C:\Users\setup_user\.claude\` と WSL 側 `~/.claude/` の両方。

## ラダーは rules へ移した（スキル本体は不採用）

`skills/ponytail/SKILL.md`（上流 sha256 `1316a2f3f95741d2300b116fe0c2d81ce4a9568656ed0a62643f54aaf09957f2`）は**配置していない**。代わりに7段ラダーと安全カーブアウトを当環境向けに要約した `rules/ponytail.md` を常時ロードしている。

理由: 実測でスキルの自動発火が観測できなかった（`claude -p` で2試行、いずれも未発火。うち1回は `superpowers:brainstorming` が先に発火した）。SessionStart で常時注入される superpowers が、description 依存のスキルより構造的に優先されるため。常時ロードの rules に置けば発火を待たずに効く。

副次効果として常時ロードが差し引き 463B 減った（rules/ponytail.md +1,449、ai-operations.md の調停節縮小 -1,192、CLAUDE.md 索引 +105、スキル description -825）。

未検証: ラダーが実際に出力を変えるかは測れていない。同一プロンプトの A/B では差が出なかった（n=1、実装案を出す段階まで到達しなかったため判定不能）。正確に測るには上流の `benchmarks/agentic` 相当の対照実験が要る。

## 上流から意図的に除外したもの

| 除外物 | 理由 |
|---|---|
| `skills/ponytail-gain/` | 検証不能な自己申告のベンチ数値を "measured" として出力させる。上流内でも README は旧値（80-94%）を撤回済みなのに gain は旧値のまま残っており不整合 |
| `skills/ponytail-help/` | 当環境で無効な機能を案内する（`/ponytail-gain`、`PONYTAIL_DEFAULT_MODE`、`config.json`、プラグイン auto-update、`npm install -g` / `brew upgrade`）。誤設定と排除済み経路への誘導を招く |
| `hooks/` 一式 | Windows 側に `node` が無く解決できない。プラグイン化自体を見送ったため未導入 |
| `ponytail-mcp/`、各ホスト向けアダプタ | 当環境で不要 |

## 運用上の取り決め

- **プラグイン化しない。** SKILL.md の手動配置のみ。auto-update の経路は存在しない
- 更新は手動: `git clone` → 上記 SHA との差分を審査 → 再配置 → このファイルを更新
- 既存 rules との優先順位は `~/.claude/rules/ai-operations.md` の「ponytail スキルとの優先順位」節に記載
- `ponytail-review` / `ponytail-audit` の削除提案は採否を人間が判断する。安全性に関わるものは `code-reviewer` / `security-reviewer` に別途かける

## 審査記録

2026-09-14、`356918eb` 時点の6ファイルを security-reviewer で審査。不可視文字・HTMLコメント・base64/eval・外部送信・破壊的コマンド・指示上書き系はいずれも検出ゼロ。判定は「条件付きで配置可」。

同日、Codex（`codex exec -s read-only`、session `01a09dda-5692-7841-b522-2fa01957b6b3`）で導入判断と既存 rules 11本との整合をレビュー。既存規範との意味的衝突4点が追加検出され、`ai-operations.md` の調停節と本ファイルの作成、`ponytail-help` の除外で対処した。
