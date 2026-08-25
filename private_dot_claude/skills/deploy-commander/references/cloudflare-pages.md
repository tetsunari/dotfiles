# Cloudflare Pages

## デプロイ

```bash
# デプロイ
wrangler pages deploy dist --project-name my-project

# プレビュー
wrangler pages deploy dist --project-name my-project --branch preview

# 環境変数設定
wrangler pages secret put SECRET_NAME
```

## ロールバック

Cloudflare Pages はデプロイ単位で即時ロールバック可能。Cloudflare ダッシュボードまたは以下で過去のデプロイを再度 production に割り当てる。

```bash
wrangler pages deployment list --project-name my-project
wrangler pages deployment tail --project-name my-project
```

判断基準は `SKILL.md` の「ロールバック判断基準」に従う。
