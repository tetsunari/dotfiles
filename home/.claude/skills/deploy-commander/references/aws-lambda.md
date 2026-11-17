# AWS Lambda (Serverless Framework)

## デプロイ

```bash
# ステージングデプロイ
serverless deploy --stage staging

# 本番デプロイ
serverless deploy --stage production

# 関数単位デプロイ
serverless deploy function -f functionName --stage production
```

## ロールバック

```bash
serverless rollback --timestamp <timestamp>
```

判断基準は `SKILL.md` の「ロールバック判断基準」に従う。
