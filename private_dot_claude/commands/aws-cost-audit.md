---
description: AWS Cost Explorer でコスト分析し、工数対効果の高い改善箇所を優先度付きリストで提示する
---

# AWS コスト監査

AWS CLI (readonly) で Cost Explorer を調査し、コードベースも深掘りして改善提案を工数対効果でランク付けする。

## 使用可能なツール
- Bash（aws cli readonly コマンドのみ）
- Read, Grep, Glob（コードベース探索）
- TaskCreate, TaskUpdate, TaskList

## 実行フロー

### Phase 1: Cost Explorer 基礎データ収集

以下を並列で実行（全て readonly）:

```bash
# 直近30日 サービス別コスト（降順）
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[0].Groups[*].[Keys[0],Metrics.UnblendedCost.Amount]' \
  --output table

# リサイジング推奨（EC2/RDS）
aws ce get-rightsizing-recommendations \
  --service AMAZON_EC2 \
  --query 'RightsizingRecommendations[*].{ResourceId:CurrentInstance.ResourceId,Savings:RightsizingSavings.SavingsAmount,Action:RightsizingType}' \
  --output table 2>/dev/null || echo "EC2 rightsizing: データなし"

# Savings Plans 使用率
aws ce get-savings-plans-utilization \
  --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --query 'Total.Utilization' \
  --output json 2>/dev/null || echo "Savings Plans: 未契約"

# Reserved Instance 使用率
aws ce get-reservation-utilization \
  --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --query 'Total.UtilizationPercentage' \
  --output json 2>/dev/null || echo "RI: 未契約"

# コスト異常検知
aws ce get-anomalies \
  --date-interval StartDate=$(date -d '30 days ago' +%Y-%m-%d),EndDate=$(date +%Y-%m-%d) \
  --query 'Anomalies[*].{Service:AnomalyScore.CurrentScore,Impact:Impact.TotalImpact}' \
  --output table 2>/dev/null || echo "異常なし"
```

### Phase 2: 高コストサービスの深掘り調査

Phase 1 で上位5サービスを特定後、各サービスをリソース別に分解:

```bash
# 例: Lambda の詳細（上位サービスを代入）
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --filter '{"Dimensions":{"Key":"SERVICE","Values":["AWS Lambda"]}}' \
  --group-by Type=TAG,Key=Name \
  --output table 2>/dev/null

# Compute Optimizer 推奨（Lambda/EC2/ECS）
aws compute-optimizer get-lambda-function-recommendations \
  --query 'lambdaFunctionRecommendations[*].{Arn:functionArn,Finding:finding,Savings:utilizationMetrics}' \
  --output table 2>/dev/null || echo "Compute Optimizer: データ不足（14日以上のメトリクスが必要）"

aws compute-optimizer get-ec2-instance-recommendations \
  --query 'instanceRecommendations[*].{Id:instanceId,Finding:finding}' \
  --output table 2>/dev/null || echo "EC2 Compute Optimizer: なし"

# S3 ストレージクラス分析
aws s3api list-buckets --query 'Buckets[*].Name' --output text 2>/dev/null | \
  tr '\t' '\n' | head -20

# CloudWatch のカスタムメトリクス数（コスト要因）
aws cloudwatch list-metrics --query 'length(Metrics)' --output text 2>/dev/null
```

### Phase 3: コードベース探索

高コストリソースが判明したら、ローカルコードベースを探索して設定ミスや最適化機会を特定:

```bash
# CDK/Terraform/SAM ファイル探索
fd -e ts -e py -e yaml -e json . --exclude node_modules --exclude .git 2>/dev/null | \
  grep -E "(cdk|terraform|cloudformation|sam)" | head -30

# Lambda メモリ設定（高すぎる設定を探す）
rg -l "memorySize|MemorySize|memory_size" --type-add 'infra:*.{ts,py,yaml,yml,json}' -t infra 2>/dev/null | head -20

# 不必要な provisioned concurrency
rg "provisionedConcurrency|ProvisionedConcurrencyConfig" 2>/dev/null | head -10

# NAT Gateway 依存（高額）
rg "natGateway|NatGateway|nat_gateway" 2>/dev/null | head -10

# マルチAZ設定（RDS/ElastiCache）
rg "multiAz|MultiAZ|multi_az" 2>/dev/null | head -10

# CloudWatch Logs 保持期間
rg "retention|retentionDays|logRetention" 2>/dev/null | head -20

# DynamoDB キャパシティモード
rg "billingMode|BillingMode|billing_mode|PAY_PER_REQUEST|PROVISIONED" 2>/dev/null | head -10
```

### Phase 4: 工数対効果マトリクスで優先度付け

調査結果を以下の基準でスコアリング:

| 指標 | 基準 |
|------|------|
| **削減効果** | 月額削減見込み額（USD） |
| **工数** | S=数時間 / M=1-2日 / L=1週間+ |
| **ROI** | 効果 ÷ 工数 でランク付け |
| **リスク** | 変更による影響範囲 |

### Phase 5: 出力形式

```
## AWS コスト監査レポート
調査期間: YYYY-MM-DD ～ YYYY-MM-DD
月間総コスト: $XXX.XX

---

## 改善提案（工数対効果順）

### [ROI: 高] 1. <改善タイトル>
- **削減見込み**: ~$XX/月
- **工数**: S（X時間）
- **発見箇所**: `path/to/file.ts:行番号` or AWS Console > サービス名
- **現状**: 現在の設定/状況
- **改善策**: 具体的な変更内容
- **リスク**: 低 / 中 / 高

### [ROI: 中] 2. <改善タイトル>
（同様の形式）

...

---

## サマリー
| 項目 | 現在 | 削減後見込み |
|------|------|------------|
| 月間コスト | $XXX | $XXX |
| 削減合計 | - | $XX (-XX%) |

```

## 注意事項

- **readonly 厳守**: `aws ce`, `aws s3api list-*`, `aws lambda list-*` 等の参照系のみ実行
- **書き込み禁止**: `aws lambda update-*`, `aws s3 put-*` 等は絶対に実行しない
- **コスト取得失敗時**: IAM権限不足の可能性をユーザーに伝える
- `aws ce` は `us-east-1` リージョンのみ有効なため `--region` 不要

## 実行開始メッセージ

「AWS コスト監査を開始します。AWS CLIは参照専用で実行します。所要時間: 約2-3分」
と最初に表示してから Phase 1 を開始すること。
