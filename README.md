# dotfiles
Dotfiles for Ubuntu on WSL and macOS.

# 🚀 Installation
Run the following command:
```bash
# curl
sh -c "$(curl -fsSL get.chezmoi.io)" -- init --apply tetsunari
```

# 🔡 Fonts
- UDEV Gothic 35NF: https://github.com/yuru7/udev-gothic?tab=readme-ov-file
- Firge35Nerd Console: https://github.com/yuru7/Firge

# WSL2 (Ubuntu)
## sudo
- https://qiita.com/buntafujikawa/items/0083b8aa1bd0e97748aa
  - 上記の記事を参考に、[Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux)経由のコマンドにsudo実行を可能にする
 
# Windows11
## ３本指ドラッグ
- ThreeFingerDrag: https://github.com/austinnixholm/ThreeFingerDrag?tab=readme-ov-file
  - アプリアイコンをクリックして設定を開きSpeedを`50`に設定
## キーマップ変更
- windowsをmac風に扱うために頑張る
### Auto Hot Key: 
- https://www.autohotkey.com/
  - wsl2 + weztermの設定など
  - https://github.com/tetsunari/dotfiles/tree/main/setup-ahk
### HHKB キーマップ変更ツール
- https://happyhackingkb.com/jp/download/
  - notionにまとめてる
## Obsidian
```systemd
[Unit]
Description=Mount Obsidian Vault from Windows
After=mnt-c.mount
Requires=mnt-c.mount

[Mount]
What=/mnt/c/Users/setup_user/Documents/Obsidian Vault
Where=/home/matsushita_te/vault
Type=none
Options=bind,rw,user

[Install]
WantedBy=multi-user.target
```
```bash
sudo systemctl daemon-reload
sudo systemctl enable home-matsushita_te-vault.mount
sudo systemctl start home-matsushita_te-vault.mount
```

