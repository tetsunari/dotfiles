# AWS CDK

> **役割分担**: CDK コードの変更・`cdk synth` 検証・Logical ID ドリフト対応は `cdk-infrastructure` スキルの担当。
> `deploy-commander` はデプロイ実行とロールバックのみを担当する。

## デプロイ

デプロイ実行前に、必ず `cdk-infrastructure` スキルで `cdk diff` による差分確認・ユーザー承認を経ていること。

```bash
# 差分確認（cdk-infrastructure スキル管轄）
cdk diff

# デプロイ
cdk deploy <StackName> --require-approval never
```

## ロールバック

CDK にはネイティブなロールバックコマンドがない。CloudFormation スタックの性質上、以下のいずれかで対応する。

```bash
# 直前のデプロイが失敗した場合、CloudFormation は自動ロールバックする
aws cloudformation describe-stack-events --stack-name <StackName>

# 正常デプロイ後に問題が発覚した場合は、前バージョンのコードに戻して再デプロイする
git revert <commit>
cdk deploy <StackName>
```

判断基準は `SKILL.md` の「ロールバック判断基準」に従う。
