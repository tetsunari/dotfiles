---
name: task-planner
description: 新機能実装・リファクタリング・バグ修正・技術的負債解消など、実装計画を立てる時は必ずこのスキルを使う。曖昧な要望をファイル単位の具体的なToDoリストに分解。タスク間依存関係整理、既存コード調査、マークダウンチェックリスト形式で出力。
context: fork
allowed-tools: Read, Glob, Bash
---

# Task Planner: タスク細分化・実装計画策定

## Overview

曖昧な要望や大きな機能要件を、ファイル単位の具体的なToDoリストに分解。タスク間の依存関係を整理し、実行可能な実装計画を策定。

**Core principle:** 曖昧さを排除し、実行可能な粒度まで分解することで、確実な実装を実現する。

詳細テンプレートは **`references/templates.md`** を参照。

## When to Use

- 新機能の実装計画
- 大規模リファクタリングの計画
- バグ修正の調査・計画
- 技術的負債の解消計画
- プロジェクト見積もり

## Planning Process

### Phase 1: 要件の明確化

ゴール・スコープ・制約・優先度（Must Have / Should Have / Nice to Have）を確認。MVPの定義をユーザーと合意する。

### Phase 2: 既存コード調査

`references/templates.md` の調査コマンド集を参照。変更対象ファイル・依存関係・影響テストを特定する。

### Phase 3: タスク分解

**粒度**: 1タスク = 1ファイル or 1機能単位。完了判定が明確であること。

**サイズ基準**:
- S: 30分以内 / M: 1-2時間 / L: 半日 / XL: 1日以上（要分割）

**依存関係**:
- 前提タスクを明確化
- 並列実行可能なタスクを特定
- クリティカルパスを把握

### Phase 4: 依存関係マッピング

Mermaid形式でタスク依存関係を図示。クリティカルパスと並列実行可能タスクを明示する。`references/templates.md` の依存関係図テンプレートを使用。

### Phase 5: 実装計画出力

`references/templates.md` のフォーマットに従い、マークダウン形式で出力。

## TaskCreate/TaskUpdate Integration

TaskCreateツールで各タスクを登録し、TaskUpdateで依存関係（addBlockedBy）を設定。各タスクにはsubject、description、activeFormを指定する。

## Key Principles

- **Concrete over abstract** - 抽象的な計画より具体的なタスク
- **File-level granularity** - ファイル単位で分解
- **Clear dependencies** - 依存関係を明確に
- **Testable tasks** - 各タスクが検証可能
- **Incremental delivery** - 段階的にデリバリー

## Integration

- **kaizen** skill: 段階的改善の視点
- **subagent-drive-development** skill: タスク並列実行
