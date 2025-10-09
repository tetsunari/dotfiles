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
