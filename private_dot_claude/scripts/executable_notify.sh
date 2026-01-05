#!/bin/bash
# Claude Code notification script for wezterm
# Usage: notify.sh <title> <message>
#
# 参考: https://dev.classmethod.jp/articles/shuntaka-claude-code-terminal-life/
#       https://github.com/skanehira/dotfiles/tree/master/claude/hooks

TITLE="${1:-Claude Code}"
MESSAGE="${2:-通知}"

# OSC 777 - wezterm desktop notification
# Format: ESC ] 777 ; notify ; title ; body ST
printf '\033]777;notify;%s;%s\033\\' "$TITLE" "$MESSAGE"

# OSC 9 - iTerm2 compatible notification (fallback)
printf '\033]9;%s: %s\033\\' "$TITLE" "$MESSAGE"

# Bell sound for additional attention
printf '\a'

