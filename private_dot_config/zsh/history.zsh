# コマンド履歴の管理
HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
# ヒストリに重複を表示しない
setopt hist_ignore_all_dups
# 重複するコマンドが保存された時、古い方を削除する
setopt hist_save_no_dups
# window間でヒストリを共有する
setopt share_history
# スペースから始まるコマンド行はヒストリに残さない
setopt hist_ignore_space
# ヒストリに保存する時に余計なスペースを削除する
setopt hist_reduce_blanks
# 日本語ファイル名を表示可能にする
setopt print_eight_bit

# declare -gA HSMW_HIGHLIGHT_STYLES
# HSMW_HIGHLIGHT_STYLES[path]="fg=white,bold"

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#9acd32"

