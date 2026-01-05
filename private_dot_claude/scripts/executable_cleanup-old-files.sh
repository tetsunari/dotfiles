#!/bin/bash
# Claude Codeプロジェクトの定期クリーンアップ

DAYS_DEBUG=90      # debugログは90日以上前を削除
DAYS_TODO=90       # Todoは90日以上前を削除
DAYS_SNAPSHOT=30   # スナップショットは30日以上前を削除

echo "🧹 古いファイルをクリーンアップ中..."
echo ""

# debugログ
echo "📁 debugログをクリーンアップ中..."
DEBUG_COUNT=$(find ~/.claude/debug/ -name "*.txt" -mtime +$DAYS_DEBUG | wc -l)
find ~/.claude/debug/ -name "*.txt" -mtime +$DAYS_DEBUG -delete
echo "✓ debugログクリーンアップ完了（$DEBUG_COUNT ファイル削除）"

# Todo履歴
echo "📁 Todo履歴をクリーンアップ中..."
TODO_COUNT=$(find ~/.claude/todos/ -name "*.json" -mtime +$DAYS_TODO | wc -l)
find ~/.claude/todos/ -name "*.json" -mtime +$DAYS_TODO -delete
echo "✓ Todo履歴クリーンアップ完了（$TODO_COUNT ファイル削除）"

# シェルスナップショット
echo "📁 シェルスナップショットをクリーンアップ中..."
SNAPSHOT_COUNT=$(find ~/.claude/shell-snapshots/ -name "*.sh" -mtime +$DAYS_SNAPSHOT | wc -l)
find ~/.claude/shell-snapshots/ -name "*.sh" -mtime +$DAYS_SNAPSHOT -delete
echo "✓ シェルスナップショットクリーンアップ完了（$SNAPSHOT_COUNT ファイル削除）"

echo ""
echo "🎉 クリーンアップ完了！"
