#!/usr/bin/env bash
# WSL 側 ~/.claude の知識層（CLAUDE.md・agents・skills・commands・rules）を
# Windows 版 claude の設定ディレクトリへ一方向でコピーする。~/.codex/AGENTS.md も Windows 版 codex へ送る。
# 既定は差分の表示だけ。--apply で反映し、--delete を足すと Windows 側にしかないファイルも消す。
# 上書き・削除したファイルは /tmp の退避先に残す。
# settings.json と scripts/ は対象外（hook が bash 依存で、両側で別物として持つため）。
set -euo pipefail

apply=false
delete=false
for arg in "$@"; do
  case "$arg" in
    --apply) apply=true ;;
    --delete) delete=true ;;
    *) echo "usage: $0 [--apply] [--delete]" >&2; exit 2 ;;
  esac
done

win_profile=$(cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r' || true)
if [ -z "$win_profile" ]; then
  echo "Windows のユーザーフォルダを取得できない" >&2
  exit 1
fi
src="$HOME/.claude/"
dst="$(wslpath "$win_profile")/.claude/"
if [ ! -d "$dst" ]; then
  echo "同期先が無い: $dst" >&2
  exit 1
fi

# リンク先の無い symlink があると rsync -L が途中で止まり、どこまで送ったか分からなくなるため、送る前に止める。
broken=$(cd "$src" && find CLAUDE.md agents skills commands rules -xtype l 2>/dev/null || true)
if [ -n "$broken" ]; then
  printf 'リンク先の無い symlink がある。片付けてから打ち直す:\n%s\n' "$broken" >&2
  exit 1
fi

# 更新日時はそろえない。中身が同じで日時だけ違うファイルが毎回差分に並ぶため。
# -L: mise dotfiles で ~/.claude の中身がリポジトリへの symlink になるため、リンク先の中身を送る。
opts=(-rL --checksum --itemize-changes)
$apply || opts+=(--dry-run)
if $delete; then opts+=(--delete); fi
if $apply; then
  backup_dir="/tmp/claude-sync-backup-$(date +%Y%m%d-%H%M%S)"
  opts+=(--backup "--backup-dir=$backup_dir")
fi

# 先に書いた exclude が優先される。wsl-operations.md は Windows 側専用なので、
# exclude しておくと --delete でも消されない。
rsync "${opts[@]}" \
  --exclude='/rules/wsl-operations.md' \
  --exclude='__pycache__/' \
  --exclude='.credentials*' --exclude='*.key' --exclude='*.pem' --exclude='.env*' \
  --include='/CLAUDE.md' \
  --include='/agents/***' --include='/skills/***' \
  --include='/commands/***' --include='/rules/***' \
  --exclude='*' \
  "$src" "$dst"

# Codex の共通指示も同じ扱いで送る（Windows 版 codex は %USERPROFILE%\.codex\AGENTS.md を読む）。
codex_dst="$(wslpath "$win_profile")/.codex/"
if [ -d "$codex_dst" ]; then
  rsync "${opts[@]}" "$HOME/.codex/AGENTS.md" "$codex_dst"
else
  echo "Windows 側に .codex が無いため AGENTS.md は送らない: $codex_dst" >&2
fi

if $apply; then
  echo "反映した。上書き・削除前のファイル: ${backup_dir}（変更が無ければ作られない）"
else
  echo "（dry-run）反映するには --apply、Windows 側にしかないファイルも消すなら --apply --delete"
fi
