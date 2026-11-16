# スタイル文字列

draw.io の `style=` にそのまま入れる。

このファイルは awslabs/agent-plugins の aws-architecture-diagram スキルのスタイル文字列を元に、色と枠の描き方を変えたもの。

## 入れ子の枠

外から順に AWS Cloud、リージョン、VPC、アベイラビリティゾーン、サブネット。

AWS Cloud、リージョン、VPC、AZ は AWS 公式のアイコンパッケージ（2026年7月31日版）に合わせ、塗らない。サブネットだけは draw.io の既定の形で、枠線を引かずに塗る（パブリック `#F2F6E8`、プライベート `#E6F6F7`）。面の色でパブリックとプライベートを見分けられる。AZ の名前は左上に置く。中央に置くと、上から本流へ入る線が名前を貫く。

サブネットのアイコンは `group_security_group`（鍵）を使う。`group_public_subnet` や `group_private_subnet` は draw.io に無い名前で、アイコンが空白になる。

### AWS Cloud

```text
html=1;whiteSpace=wrap;fontSize=12;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_aws_cloud_alt;strokeColor=#000000;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#000000;container=1;collapsible=0;recursiveResize=0
```

### リージョン

```text
html=1;whiteSpace=wrap;fontSize=12;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_region;strokeColor=#00A4A6;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#000000;dashed=1;container=1;collapsible=0;recursiveResize=0
```

### VPC

```text
html=1;whiteSpace=wrap;fontSize=12;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_vpc2;strokeColor=#8C4FFF;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#000000;container=1;collapsible=0;recursiveResize=0
```

### アベイラビリティゾーン

```text
fillColor=none;strokeColor=#00A4A6;dashed=1;verticalAlign=top;align=left;spacingLeft=10;fontSize=12;fontColor=#000000;whiteSpace=wrap;html=1;container=1;collapsible=0;recursiveResize=0
```

### パブリックサブネット

```text
html=1;whiteSpace=wrap;fontSize=12;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_security_group;grStroke=0;strokeColor=#7AA116;fillColor=#F2F6E8;verticalAlign=top;align=left;spacingLeft=30;fontColor=#248814;container=1;collapsible=0;recursiveResize=0
```

### プライベートサブネット

```text
html=1;whiteSpace=wrap;fontSize=12;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_security_group;grStroke=0;strokeColor=#00A4A6;fillColor=#E6F6F7;verticalAlign=top;align=left;spacingLeft=30;fontColor=#147EBA;container=1;collapsible=0;recursiveResize=0
```

## サービスアイコン

### サービス単位のアイコン

`{CATEGORY_COLOR}` と `{shape_name}` を埋める。ラベルは `verticalLabelPosition=bottom` でアイコンの下に出る。

```text
fontColor=#16191F;fillColor={CATEGORY_COLOR};strokeColor=#ffffff;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.{shape_name}
```

### 独立したシェイプ

NAT Gateway や Internet Gateway のように、`resourceIcon` ではなく専用のシェイプを持つもの。

```text
fontColor=#16191F;fillColor={CATEGORY_COLOR};strokeColor=none;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;aspect=fixed;shape=mxgraph.aws4.{shape_name}
```

### カテゴリの色とアイコン名

`{CATEGORY_COLOR}` にはカテゴリの色、`{shape_name}` にはアイコン名を入れる。

色は AWS 公式のアイコンパッケージ（2026年7月31日版）に合わせてある。draw.io のパレットは ELB を Compute にも、API Gateway を Application Integration にも載せているが、その色は使わない。

| カテゴリ | `{CATEGORY_COLOR}` | サービスとアイコン名 |
|---|---|---|
| Compute | `#ED7100` | EC2 `ec2`、Lambda `lambda` |
| Containers | `#ED7100` | Fargate `fargate`、ECS `ecs`、EKS `eks`、ECR `ecr` |
| Database | `#C925D1` | Aurora `aurora`、RDS `rds`、DynamoDB `dynamodb`、ElastiCache `elasticache` |
| Networking | `#8C4FFF` | CloudFront `cloudfront`、ELB（ALB を含む）`elastic_load_balancing`、API Gateway `api_gateway`、Route 53 `route_53`、Transit Gateway `transit_gateway`、Direct Connect `direct_connect`、Site-to-Site VPN `site_to_site_vpn`、Global Accelerator `global_accelerator` |
| Analytics | `#8C4FFF` | Kinesis Data Streams `kinesis_data_streams`、Data Firehose `kinesis_data_firehose`、Glue `glue`、Athena `athena`、QuickSight `quicksight`、Redshift `redshift`、EMR `emr`、Lake Formation `lake_formation` |
| AI | `#01A88D` | Bedrock `bedrock`、Bedrock AgentCore `bedrock_agentcore` |
| IoT | `#7AA116` | IoT Core `iot_core` |
| App Integration | `#E7157B` | SQS `sqs`、SNS `sns`、EventBridge `eventbridge`、Step Functions `step_functions` |
| Storage | `#7AA116` | S3 `s3`、EFS `elastic_file_system` |
| Management | `#E7157B` | CloudWatch `cloudwatch_2`、CloudTrail `cloudtrail`、Systems Manager `systems_manager` |
| Security | `#DD344C` | WAF `waf`、ACM `certificate_manager_3`、Cognito `cognito`、IAM `identity_and_access_management`、KMS `key_management_service`、Secrets Manager `secrets_manager` |

### リソースアイコンと汎用アイコン

上の「独立したシェイプ」のスタイルに入れる。独立したサービスアイコンを持たない部品と、AWS の外のものだけを載せている。ALB や S3 のバケットのように、サービスアイコンを持つサービスのリソースアイコンは使わない。

| もの | `{CATEGORY_COLOR}` | `{shape_name}` |
|---|---|---|
| NAT Gateway | `#8C4FFF` | `nat_gateway` |
| Internet Gateway | `#8C4FFF` | `internet_gateway` |
| VPC エンドポイント | `#8C4FFF` | `endpoints` |
| Site-to-Site VPN の接続 | `#8C4FFF` | `vpn_connection` |
| カスタマーゲートウェイ | `#8C4FFF` | `customer_gateway` |
| Transit Gateway のアタッチメント | `#8C4FFF` | `transit_gateway_attachment` |
| 利用者（複数） | `#242F3E` | `users` |
| 利用者（1人） | `#242F3E` | `user` |
| インターネット | `#242F3E` | `internet` |
| 社内データセンター | `#242F3E` | `corporate_data_center` |
| クライアント PC | `#242F3E` | `client` |
| モバイル端末 | `#242F3E` | `mobile_client` |
| オンプレミスのサーバー | `#242F3E` | `traditional_server` |
| 工場 | `#7AA116` | `factory` |
| センサー | `#7AA116` | `sensor` |

インターネットは `internet` に決める。draw.io には絵が3種類あり、回ごとに変わると同じものに見えなくなる。

## 線

### 通常の流れ

```text
edgeStyle=orthogonalEdgeStyle;html=1;endArrow=block;endFill=1;strokeColor=#545B64;rounded=0;labelBackgroundColor=none;verticalAlign=bottom;align=left;spacingLeft=6;jumpStyle=arc;jumpSize=10
```

### 補助の流れ

ログ、メトリクス、レプリケーション、関連付けなど、リクエストの本流ではないもの。破線にし、色も本流と変えてある。

```text
edgeStyle=orthogonalEdgeStyle;html=1;endArrow=block;endFill=1;strokeColor=#E7157B;rounded=0;dashed=1;labelBackgroundColor=none;verticalAlign=bottom;align=left;spacingLeft=6;jumpStyle=arc;jumpSize=10
```

`align=center` への置き換えと接続点は SKILL.md の「線」の節に従う。
