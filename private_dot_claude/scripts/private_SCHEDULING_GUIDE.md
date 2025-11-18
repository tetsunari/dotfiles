# 復習問題生成スクリプト - 定期実行設定ガイド

このドキュメントは、復習問題生成スクリプト（`run-quiz-generator.sh`）を月1回または週1回で自動実行する方法を説明します。

## 📋 目次

1. [Cron ジョブで定期実行（Linux/Mac）](#cron-ジョブで定期実行)
2. [Windows タスクスケジューラで定期実行](#windowsタスクスケジューラで定期実行)
3. [トラブルシューティング](#トラブルシューティング)
4. [実行結果の確認](#実行結果の確認)

---

## Cron ジョブで定期実行

Cron は Linux/Mac で定期的なタスク実行を管理するユーティリティです。

### 基本構文

```bash
# crontab を編集
crontab -e

# 形式: 分 時 日 月 曜日 コマンド
# 例：毎月第1日曜 00:00
0 0 * * 0 ~/.claude/scripts/run-quiz-generator.sh
```

### 設定パターン

#### 1️⃣ 毎月第1日曜 00:00（推奨: 月1回）

```crontab
# 毎月第1日曜の午前0時に実行
0 0 ? * SUN ~/.claude/scripts/run-quiz-generator.sh 2>&1 | mail -s "復習問題生成完了" your-email@example.com
```

**説明:**
- `0 0` - 午前 0 時 0 分
- `?` - 日を指定しない（曜日で指定）
- `*` - 毎月
- `SUN` - 日曜日
- `2>&1 | mail` - 実行結果をメール送信（オプション）

#### 2️⃣ 毎週日曜 09:00（推奨: 週1回）

```crontab
# 毎週日曜の午前9時に実行
0 9 * * SUN ~/.claude/scripts/run-quiz-generator.sh
```

#### 3️⃣ 毎週月曜 08:00（別案: 週1回）

```crontab
# 毎週月曜の午前8時に実行
0 8 * * MON ~/.claude/scripts/run-quiz-generator.sh
```

#### 4️⃣ 毎月1日 01:00（別案: 月1回）

```crontab
# 毎月1日の午前1時に実行
0 1 1 * * ~/.claude/scripts/run-quiz-generator.sh
```

#### 5️⃣ 毎月15日と1日 09:00（別案: 月2回）

```crontab
# 毎月1日と15日の午前9時に実行
0 9 1,15 * * ~/.claude/scripts/run-quiz-generator.sh
```

### 設定ステップ

#### ステップ 1: crontab を開く

```bash
crontab -e
```

エディタが開きます（デフォルト: nano）。vim を使いたい場合：

```bash
EDITOR=vim crontab -e
```

#### ステップ 2: 設定を追加

```crontab
# Claude Code 復習問題生成スクリプト
# 毎月第1日曜 00:00 に実行
0 0 ? * SUN ~/.claude/scripts/run-quiz-generator.sh
```

#### ステップ 3: 保存して終了

- **nano の場合:** `Ctrl+O` → Enter → `Ctrl+X`
- **vim の場合:** `:wq` → Enter

#### ステップ 4: 設定を確認

```bash
crontab -l
```

---

### 🔐 セキュリティ上の注意点

#### 環境変数の設定

Cron ジョブはユーザーシェルを実行しないため、フルパスを使用してください：

```crontab
# 推奨: フルパスを指定
0 0 ? * SUN /home/matsushita_te/.claude/scripts/run-quiz-generator.sh

# 非推奨: 相対パスや環境変数依存
0 0 ? * SUN run-quiz-generator.sh
```

#### PATH の設定

Cron ジョブで PATH を明示的に設定：

```crontab
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

0 0 ? * SUN ~/.claude/scripts/run-quiz-generator.sh
```

#### ログの設定

実行結果をログファイルに記録：

```crontab
# 標準出力と標準エラーを logs/quiz-generator.log に追記
0 0 ? * SUN ~/.claude/scripts/run-quiz-generator.sh >> ~/.claude/logs/quiz-generator.log 2>&1
```

---

## Windows タスクスケジューラで定期実行

Windows ユーザーの場合は、タスクスケジューラを使用します。

### 前提条件

- WSL 2（Windows Subsystem for Linux）がインストール済み
- スクリプトが WSL 環境で実行可能

### 設定手順

#### ステップ 1: タスクスケジューラを開く

```
Windows キー + R → "taskschd.msc" → Enter
```

または：

```
コントロールパネル → 管理ツール → タスクスケジューラ
```

#### ステップ 2: 基本タスクを作成

1. **右ペイン** → 「基本タスクの作成...」
2. **名前:** "復習問題生成" と入力
3. **説明:** "Claude Code の履歴から復習問題を生成" と入力

#### ステップ 3: トリガーを設定

**毎月第1日曜の場合:**

1. **トリガー:** 「新規...」
2. **開始日時:** 現在の日付
3. **繰り返す:** 毎月
4. **パターン:** 「毎月」を選択
5. **日付:** 「最初の」「日曜日」に設定
6. **時刻:** 00:00

#### ステップ 4: アクションを設定

1. **アクション:** 「新規...」
2. **プログラム/スクリプト:**
   ```
   wsl.exe
   ```
3. **引数を追加:**
   ```
   /home/matsushita_te/.claude/scripts/run-quiz-generator.sh
   ```
4. **開始位置（オプション）:**
   ```
   C:\Users\<YourUsername>
   ```

#### ステップ 5: 条件とオプションを設定

1. **条件タブ:**
   - ☑ コンピューターが AC 電源に接続されている場合のみ
   - ☑ コンピューターをスリープ解除してタスクを実行

2. **設定タブ:**
   - ☑ タスクが失敗した場合、以下の間隔で実行を再試行
   - 再試行間隔: 5 分

#### ステップ 6: 完了

「完了」をクリックして設定を保存

---

## トラブルシューティング

### 問題 1: Cron ジョブが実行されない

**確認項目:**

```bash
# crontab の設定を確認
crontab -l

# Cron デーモンが動作しているか確認
sudo service cron status

# ログファイルを確認（Linux）
sudo tail -f /var/log/syslog | grep CRON

# ログファイルを確認（Mac）
log stream --predicate 'process == "cron"' --level debug
```

**解決方法:**

1. **フルパスを使用しているか確認**
   ```bash
   # bad
   crontab -e
   0 0 ? * SUN run-quiz-generator.sh

   # good
   crontab -e
   0 0 ? * SUN ~/.claude/scripts/run-quiz-generator.sh
   ```

2. **スクリプトに実行権限があるか確認**
   ```bash
   ls -l ~/.claude/scripts/run-quiz-generator.sh
   # 出力: -rwxr-xr-x が表示されるか確認
   ```

3. **実行権限を付与**
   ```bash
   chmod +x ~/.claude/scripts/run-quiz-generator.sh
   ```

### 問題 2: スクリプトの実行に失敗している

**確認方法:**

```bash
# スクリプトを直接実行してエラーを確認
~/.claude/scripts/run-quiz-generator.sh

# ログファイルを確認
tail -100 ~/.claude/logs/quiz-generator.log
```

**よくあるエラー:**

| エラー | 原因 | 解決方法 |
|--------|------|---------|
| `Command not found` | コマンドが PATH に含まれていない | フルパスを指定する |
| `Permission denied` | 実行権限がない | `chmod +x` で権限付与 |
| `No such file or directory` | ファイルパスが間違っている | パスを確認 |

### 問題 3: 復習問題ファイルが生成されない

**確認方法:**

```bash
# 出力ディレクトリが存在するか確認
ls -la ~/output/

# ディレクトリが存在しない場合は作成
mkdir -p ~/output
```

**解決方法:**

```bash
# history.jsonl ファイルが存在するか確認
ls -la ~/.claude/history.jsonl

# ファイルサイズを確認（0 KB ではないか）
du -h ~/.claude/history.jsonl
```

---

## 実行結果の確認

### ログファイルの確認

```bash
# 最新のログを確認
tail -50 ~/.claude/logs/quiz-generator.log

# ログファイル全体を確認
cat ~/.claude/logs/quiz-generator.log

# リアルタイムでログを監視
tail -f ~/.claude/logs/quiz-generator.log
```

### 生成されたファイルの確認

```bash
# 復習問題ファイルを確認
ls -lh ~/output/quiz-*.md

# 最新のファイルを表示
ls -lhtr ~/output/quiz-*.md | tail -1

# ファイルの内容を表示
cat ~/output/quiz-2025-11-18.md
```

### Cron ログの確認（Mac/Linux）

```bash
# Mac: unified log から Cron 実行ログを確認
log stream --predicate 'process == "cron"' --level debug

# Linux: syslog から Cron 実行ログを確認
sudo grep CRON /var/log/syslog | tail -20
```

---

## メール通知の設定（オプション）

Cron ジョブ完了時にメール通知を受け取ります。

### 設定方法

```crontab
# 実行結果をメール送信
0 0 ? * SUN ~/.claude/scripts/run-quiz-generator.sh 2>&1 | mail -s "復習問題生成完了 $(date +\%Y-\%m-\%d)" your-email@example.com
```

### 前提条件

```bash
# メール送信ツール（mailutils）がインストール済み
sudo apt-get install mailutils

# または
brew install mailutils
```

---

## テスト実行

設定後、スクリプトが正常に動作するかテストしましょう。

```bash
# スクリプトを手動実行
~/.claude/scripts/run-quiz-generator.sh

# 出力を確認
echo $?  # 0 = 成功、0以外 = 失敗
```

---

## 推奨設定（まとめ）

### 月1回実行（推奨）

```crontab
# 毎月第1日曜 00:00
0 0 ? * SUN ~/.claude/scripts/run-quiz-generator.sh >> ~/.claude/logs/quiz-generator.log 2>&1
```

### 週1回実行

```crontab
# 毎週日曜 09:00
0 9 * * SUN ~/.claude/scripts/run-quiz-generator.sh >> ~/.claude/logs/quiz-generator.log 2>&1
```

---

## 追加リソース

- [Cron 公式ドキュメント](https://man7.org/linux/man-pages/man5/crontab.5.html)
- [Cron 式ジェネレーター](https://crontab.guru/)
- [Windows タスクスケジューラ ガイド](https://docs.microsoft.com/en-us/windows/desktop/TaskSchd/task-scheduler-start-page)

---

**最終更新:** 2025-11-18
