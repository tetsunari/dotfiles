export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
# export NVIM_HOME="/opt/nvim"
# export PAHT="$NVIM_NOME:$PATH"
export PATH="$PATH:/opt/nvim"
export CHEZMOI_HOME="$HOME/bin"
export PATH="$CHEZMOI_HOME:/chezmoi:$PATH"

# aws cli 補完
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit

# code コマンド
export PATH=$PATH:"$(wslpath $(/mnt/c/WINDOWS/system32/cmd.exe /c 'SET /P X=%USERPROFILE%<NUL' 2>/dev/null))/AppData/Local/Programs/Microsoft VS Code/bin"
# cursor コマンド
export PATH=$PATH:"$(wslpath $(/mnt/c/WINDOWS/system32/cmd.exe /c 'SET /P X=%USERPROFILE%<NUL' 2>/dev/null))/AppData/Local/Programs/cursor/resources/app/bin"
# kiro コマンド
export PATH=$PATH:"$(wslpath $(/mnt/c/WINDOWS/system32/cmd.exe /c 'SET /P X=%USERPROFILE%<NUL' 2>/dev/null))/AppData/Local/Programs/kiro/bin"
# curl path
export HOMEBREW_CURL_PATH="/usr/bin/curl"
