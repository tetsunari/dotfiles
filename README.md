# dotfiles

Ubuntu on WSL2 および macOS 向けの設定ファイル集。[mise](https://mise.jdx.dev/) の `[dotfiles]` 設定と `mise bootstrap` を用いて配布・展開する。

- 対象読者: 新しい PC をセットアップする人、または既存 PC の設定を変更する人（どちらも持ち主本人）
- 目指す状態: 新しい PC で同一の環境を再現できること。また、設定の変更を GitHub にプッシュし、他の PC にも取り込めること
- 対象環境: Ubuntu 26.04 on WSL2、macOS。mise 2026.11.9 で確認
- 経緯: 管理ツールを chezmoi から mise に移行（#8、#14）

## 新しい PC に入れる

### WSL2 (Ubuntu)

sudo 権限を持つ一般ユーザーとして、Windows Terminal などのターミナルから実行する。

1. git と curl を入れる

   ```sh
   sudo apt-get update && sudo apt-get install -y git curl
   ```

2. mise を入れる

   ```sh
   curl -fsSL https://mise.run | sh
   export PATH="$HOME/.local/bin:$PATH"
   ```

3. リポジトリを `~/dotfiles` に取得し、本人だけが読める権限にする

   ```sh
   git clone https://github.com/tetsunari/dotfiles.git ~/dotfiles
   chmod 700 ~/dotfiles
   ```

4. mise にこのリポジトリの設定を許可する

   ```sh
   cd ~/dotfiles && mise trust
   ```

5. 初期設定を流す

   > [!CAUTION]
   > `--force-dotfiles` を指定すると、ホームディレクトリにある同名ファイル（`~/.bashrc` など）が上書きされる。残しておきたい既存ファイルがある場合は、事前にバックアップ（退避）する。

   ```sh
   mise bootstrap --yes --force-dotfiles
   ```

   - 処理中にパスワードの入力が2回求められる。1回目は apt 実行時の sudo 認証、2回目はログインシェルを zsh に変更する chsh の認証。
   - 出力をパイプ（`| tee` など）に渡さない。端末（TTY）ではないと判定され、sudo がパスワードを要求できずに停止してしまう。ログを記録したい場合は `script -qec "mise bootstrap --yes --force-dotfiles" bootstrap.log` を使用する。
   - WSL のみ: 終わったら、手順 2 で入れた mise を消す。bootstrap が Brewfile_wsl から brew 版の mise を入れるため、残すと mise が2つになる。以降の更新は `brew upgrade` で行う。

     ```sh
     rm ~/.local/bin/mise
     ```

6. Windows の PowerShell で WSL を再起動する（systemd と docker グループを効かせるため）

   ```powershell
   wsl --shutdown
   ```

7. SSH の鍵を GitHub に登録したあと、push できるように取得先を SSH に切り替える

   ```sh
   cd ~/dotfiles && git remote set-url origin git@github.com:tetsunari/dotfiles.git
   ```

### macOS

macOS 向けの手順は、まだ実機での動作確認を行っていない（#14）。

1. Xcode Command Line Tools を入れる

   ```sh
   xcode-select --install
   ```

2. Homebrew を入れる

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   eval "$(/opt/homebrew/bin/brew shellenv)"
   ```

3. WSL2 の手順 2〜5 と 7 を同じように実行する

## ふだんの使い方

### 変更を GitHub に上げる

1. `cd ~/dotfiles`
2. 下の表の場所を編集する
3. `git status` と `git diff` で変更を確かめる
4. 公開リポジトリなので、載せてはいけない値が無いか確かめる

   > [!CAUTION]
   > 社名、社内ホスト名、`/home/<ユーザー名>` などの絶対パス、各種トークン（認証情報）は push しない。

   鍵・トークンと、`/home/<ユーザー名>`・`/Users/<ユーザー名>` は、commit のときに gitleaks が見つけて止める（`.githooks/pre-commit`、独自ルールは `.gitleaks-paths.toml`）。`mise bootstrap` がこのフックを有効にする。社名・社内ホスト名は gitleaks では見つからないので、目で確かめる。

   ```sh
   git add -A && git diff --cached
   ```

5. コミットして push する

   ```sh
   git commit -m "変更の内容" && git push
   ```

| 編集したいもの | 編集する場所 | 反映 |
|---|---|---|
| copy で置いたファイル（`~/.claude/rules`・`~/.claude/mods` など） | ホーム側をそのまま編集し、`mise dot add --changed` でリポジトリへ戻す | 不要 |
| テンプレート（`.zshrc`・`alias.zsh`・`function.zsh`・mise の `config.toml`・lazygit の `config.yml`） | `~/dotfiles/home/` の下の `*.tera` | `mise dot apply` |
| `settings.json`（Claude Code・agy） | `~/dotfiles/home/` の下の `settings.json` | `mise dot apply` |
| 新しいファイル | `~/dotfiles/home/` の下の同じパスに置き、`git add` | `mise dot apply` |

ホーム側のファイルは symlink ではなく copy で置く（Claude Code は mod のファイルが symlink だと読まないため）。ホーム側で編集したファイルは、`mise dot add --changed` を実行するまでリポジトリに入らない。その前に `mise dot apply` すると、編集した分がリポジトリの内容で上書きされて消える。

テンプレートや `settings.json` は、ホームディレクトリ側で編集してもリポジトリには反映されない。`settings.json` はリポジトリにあるキーだけを書き込むので、PC だけの値はホーム側に残せる。

### ほかの PC の変更を取り込む

ホーム側で編集してまだリポジトリへ戻していないファイルは、`mise bootstrap` で上書きされて消える。先に戻してから取り込む。

```sh
cd ~/dotfiles && mise dot add --changed && git status
```

戻したファイルがあれば commit してから pull する。

```sh
cd ~/dotfiles && git pull && mise bootstrap --yes
```

### 注意

- `mise dot` は必ず `~/dotfiles` ディレクトリ内で実行する。他の場所で実行すると設定が読み込まれず、展開したファイルがすべて `orphaned`（孤立状態）と表示されてしまう。

> [!CAUTION]
> `~/dotfiles` 以外の場所で `mise dot apply --prune` を実行すると、展開したファイルがすべて削除されてしまう。

## 道具の入れ分け（brew と mise）

macOS と WSL で同じ分け方にする。brew を土台にし、版を固定したいものだけ mise に置く。

| 入れるもの | 使う道具 | 書く場所 |
|---|---|---|
| アプリ、ふだん使いの CLI、ライブラリ、常駐サービス | brew | WSL: `home/Brewfile_wsl`、macOS: 未定（#14） |
| 言語ランタイム、プロジェクトごとに版を固定したい道具、npm でしか入らない道具 | mise | `home/.config/mise/config.toml.tera` |

同じツールを両方に重複して記述しない。

## herdr を上げたとき

`~/.claude/hooks/herdr-agent-state.sh` は、herdr が生成したファイルをリポジトリに取り込んだもの。herdr を更新した際は状態を確かめる。

```sh
herdr integration status
```

`claude` が `current` でなければ、再インストールしてコミットする。herdr はホーム側のファイルを書き換えるので、`mise dot add --changed` でリポジトリへ戻す。なお、`settings.json` に追加された重複する hook は `mise dot apply` を実行すれば削除される。

```sh
herdr integration install claude
cd ~/dotfiles && mise dot add --changed && mise dot apply && git diff
```

## 手で入れるもの

### フォント

- UDEV Gothic 35NF: https://github.com/yuru7/udev-gothic
- Firge35Nerd Console: https://github.com/yuru7/Firge
- maplefont: https://github.com/subframe7536/maple-font
- IBM Plex Sans JP: https://fonts.google.com/specimen/IBM+Plex+Sans+JP

### WSL2: sudo で Homebrew のコマンドを使う

- https://qiita.com/buntafujikawa/items/0083b8aa1bd0e97748aa を参考に、[Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux) で入れたコマンドを sudo で実行できるようにする

### Windows 11

- 3本指ドラッグ: [ThreeFingerDrag](https://github.com/austinnixholm/ThreeFingerDrag)。アプリのアイコンから設定を開き、Speed を `50` にする
- キーマップ: [AutoHotkey](https://www.autohotkey.com/)。スクリプトは [setup-ahk](home/setup-ahk)
- HHKB のキーマップ: [キーマップ変更ツール](https://happyhackingkb.com/jp/download/)

### Obsidian の Vault を WSL にマウントする

`<Windows のユーザー名>` と `<WSL のユーザー名>` を実際のユーザー名に置き換え、`/etc/systemd/system/home-<WSL のユーザー名>-vault.mount` に配置する。

```systemd
[Unit]
Description=Mount Obsidian Vault from Windows
After=mnt-c.mount
Requires=mnt-c.mount

[Mount]
What=/mnt/c/Users/<Windows のユーザー名>/Documents/Obsidian Vault
Where=/home/<WSL のユーザー名>/vault
Type=none
Options=bind,rw,user

[Install]
WantedBy=multi-user.target
```

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now "home-$(id -un)-vault.mount"
```
