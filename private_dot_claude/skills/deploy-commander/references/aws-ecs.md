# AWS ECS

## デプロイ

```bash
# イメージビルド & プッシュ
docker build -t app:latest .
docker tag app:latest $ECR_REPO:latest
docker push $ECR_REPO:latest

# サービス更新
aws ecs update-service \
  --cluster production \
  --service app-service \
  --force-new-deployment

# デプロイ状況確認
aws ecs describe-services \
  --cluster production \
  --services app-service
```

## ロールバック

```bash
aws ecs update-service \
  --cluster production \
  --service app-service \
  --task-definition app:previous-version
```

判断基準は `SKILL.md` の「ロールバック判断基準」に従う。
