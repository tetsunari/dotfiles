# export VOLTA_HOME="$HOME/.volta"
# export PATH="$VOLTA_HOME/bin:$PATH"
# export NVIM_HOME="/opt/nvim"
# export PAHT="$NVIM_NOME:$PATH"
export PATH="$PATH:/opt/nvim"
export CHEZMOI_HOME="$HOME/bin"
export PATH="$CHEZMOI_HOME:/chezmoi:$PATH"

# aws cli 補完
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit

# gcloud
export CLOUDSDK_PYTHON=python3

# code コマンド
export PATH=$PATH:"$(wslpath $(/mnt/c/WINDOWS/system32/cmd.exe /c 'SET /P X=%USERPROFILE%<NUL' 2>/dev/null))/AppData/Local/Programs/Microsoft VS Code/bin"
# cursor コマンド
export PATH=$PATH:"$(wslpath $(/mnt/c/WINDOWS/system32/cmd.exe /c 'SET /P X=%USERPROFILE%<NUL' 2>/dev/null))/AppData/Local/Programs/cursor/resources/app/bin"
# kiro コマンド
export PATH=$PATH:"$(wslpath $(/mnt/c/WINDOWS/system32/cmd.exe /c 'SET /P X=%USERPROFILE%<NUL' 2>/dev/null))/AppData/Local/Programs/kiro/bin"
# Linux Brew
export HOMEBREW_DEVELOP=1
## curl path
export HOMEBREW_CURL_PATH="/home/linuxbrew/.linuxbrew/bin/curl"

# fzfの設定
export FZF_DEFSULT_OPST="
  --reverse
  --style=full:rounded
  --height 45%
  --margin 0.5%
"

# zoxideの設定
export _ZO_FZF_OPTS="
  --reverse
  --style=full:rounded
  --height 75%
  --margin 0,5%
  --preview 'eza -l --icons --sort modified -r --color=always {2..}'
  --preview-window=down,50%,wrap
  --no-sort
  --exact
"

# manコマンドの設定
export MANPAGER=less
export LESS=-R

export LESS_TERMCAP_mb=$'\e[1;31m'   # 強調 赤
export LESS_TERMCAP_md=$'\e[1;34m'   # 太字 青
export LESS_TERMCAP_me=$'\e[0m'      # reset

export LESS_TERMCAP_so=$'\e[7m'      # 反転
export LESS_TERMCAP_se=$'\e[0m'

export LESS_TERMCAP_us=$'\e[4;32m'   # 下線 緑
export LESS_TERMCAP_ue=$'\e[0m'

# ターミナルタイトルを現在のコマンドに設定 + 作業ディレクトリを通知
precmd() {
  print -Pn "\e]0;%~\a"
  print -Pn "\e]7;file://${HOST}${PWD}\a"
}
preexec() { print -Pn "\e]0;$1\a" }
