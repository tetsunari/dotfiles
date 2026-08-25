---
name: cdk-infrastructure
description: |
  AWS CDK・CloudFormationのコード変更・デバッグ・リファクタリング時に必ずこのスキルを使う。
  CDKコードを編集する、デプロイエラーを調査する、コンストラクトを再構成する、
  スタック間参照を変更する時に即座に起動。
  Logical IDドリフト防止・cdk synth検証・overrideLogicalId管理を強制する。
context: fork
allowed-tools: Bash, Read
bash-restrictions: "cdk synth, cdk diff の読み取り専用コマンド。cdk deploy, cdk destroy は事前に必ず cdk diff で差分確認・ユーザー承認を経る。"
---

# CDK Infrastructure Skill

AWS CDK作業における品質ゲートと調査プロセスを強制するスキル。

## 必須チェック：Logical IDドリフト

CDKコンストラクトのパス・クラス・ネストを変更した場合は**必ず**以下を確認する：

```bash
# 変更前後でcdk synthの差分を取る
cdk synth > /tmp/after.json
diff /tmp/before.json /tmp/after.json | grep -E '"Type"|LogicalId'
```

**Logical IDが変わる操作（要注意）:**
- コンストラクトのネスト階層を変える
- クラス名・IDを変更する
- ファイル分割でコンストラクトを移動する
- Stackをまたいでリソースを移動する

**対処:** `overrideLogicalId()` で旧IDを明示的に維持する

## デバッグ調査プロセス

### Step 1: エラー種別の特定
CloudFormationエラーは種別によって調査順序が変わる：

| エラー種別 | 最初に確認すること |
|-----------|------------------|
| `UPDATE_ROLLBACK_FAILED` | 変更されたリソースのLogical ID |
| `REPLACEMENT` (意図せず) | コンストラクトパスの変更有無 |
| クロススタック参照エラー | SSMパラメータのパス（二重スラッシュ等） |
| IAM権限エラー | ARNのアカウントID・リージョンが正しいか |
| StateMachine名衝突 | 既存スタックに同名が残っていないか |

### Step 2: 実際の値を確認してから提案
推測で修正を提案しない。以下で実際の値を確認する：

```bash
# デプロイ済みスタックの現状確認
aws cloudformation describe-stack-resources --stack-name <STACK_NAME>

# SSMパラメータの実際の値確認
aws ssm get-parameter --name <PATH>

# 現在のcdk synth出力確認
cdk synth 2>&1 | head -50
```

### Step 3: 最小変更で修正
- 構造的なリファクタリングより `overrideLogicalId()` を優先する
- 複数のリソースを一度に変更しない
- 1リソースずつ変更してcdk synthで確認する

## コンストラクトリファクタリング手順

ファイル分割・クラス再構成を行う場合：

1. **変更前** に `cdk synth > /tmp/before.json` を実行・保存
2. リファクタリングを実施
3. **変更後** に `cdk synth > /tmp/after.json` を実行
4. `diff /tmp/before.json /tmp/after.json` でLogical ID変更を確認
5. 変更があれば `overrideLogicalId()` で旧IDを指定
6. 再度 `cdk synth` でエラーなし確認

## CDK特有のパターン

### StateMachine名の衝突防止
```typescript
// 明示的に名前を指定せずCDKに生成させる（衝突しにくい）
new StateMachine(this, 'MyStateMachine', {
  // stateMachineName: 'xxx' ← 指定しない
});
```

### SSM ARNのパス形式
```
// 正しい形式
arn:aws:ssm:ap-northeast-1:123456789:parameter/my/path

// よくある誤り（二重スラッシュ）
arn:aws:ssm:ap-northeast-1:123456789:parameter//my/path
```

### クロススタック参照のデッドロック回避
- 参照を先に削除してからリソースを削除する（2段階デプロイ）
- SSMパラメータ経由でのルーズカップリングを検討する
