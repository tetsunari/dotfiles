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

# Wayland環境変数
#export XDG_RUNTIME_DIR=/var/run/user/1000 foot
#export WAYLAND_DISPLAY=wayland-0
#export QT_QPA_PLATFORM=wayland
#export GDK_BACKEND=wayland
#export MOZ_ENABLE_WAYLAND=1

