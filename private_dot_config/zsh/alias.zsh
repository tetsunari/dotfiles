alias ls='eza --group-directories-first --time-style=long-iso --git'
alias lg='lazygit'
alias vim='nvim'
alias vi='nvim'
alias wsl='/mnt/c/Windows/System32/wsl.exe'
alias notion="nohup $(wslpath $(/mnt/c/WINDOWS/system32/cmd.exe /c 'SET /P X=%USERPROFILE%<NUL' 2>/dev/null))/AppData/Local/Programs/Notion/Notion.exe > /dev/null 2>&1"
alias notkill='/mnt/c/Windows/System32/taskkill.exe /F /IM Notion.exe'

# Modern CLI Tools (Homebrew)
alias cat='bat'
alias ll='eza -l --group-directories-first --time-style=long-iso --git'
alias la='eza -a --group-directories-first'
alias tree='eza --tree'
alias find='fd'
alias cd='z'
alias cdi='zi'
alias diff='delta'

# WSL clipboard integration
alias pbcopy='clip.exe'
alias pbpaste='powershell.exe -command "Get-Clipboard"'
