---
name: aws-naming
description: |
  AWS のリソースに名前を付ける・名前を見直す時は必ずこのスキルを使う。
  Terraform・CDK・CloudFormation・AWS CLI で VPC・サブネット・Lambda・IAM ロール・S3・RDS・ALB などを
  新しく作る時、「命名」「リソース名」「name_prefix」「Name タグ」と言われた時に即座に起動。
  {System}-{Category}-{Env}-{Usage}-{ResourceType} の形と、AWS 側の文字・長さの制約の扱いを決める。
allowed-tools: Read, Grep, Glob, WebFetch
---

# AWS リソースの命名規則

目的: 名前を見ただけでどのシステム・環境・用途のものか分かり、誤操作を防ぐ。検索・フィルタ・IAM の条件（リソース名の前方一致）で絞り込めるようにする。

## 形

```
{System}-{Category}-{Env}-{Usage}-{ResourceType}
```

- 要素の間はハイフン `-` でつなぐ
- 要素の中は英小文字・数字・アンダースコア `_` だけを使う

| 要素 | 決め方 |
|---|---|
| System | 案件のシステム名。案件の CLAUDE.md（または AGENTS.md）に書いてある値を使う。書いていなければ、名前を付ける前に利用者に聞く。推測で決めない |
| Category | 機能のまとまり（例: `web` Web サービスのインフラ一式、`access_analyze` アクセス集計、`managed` 管理者向け、`monitoring` 外形監視）。案件で決めた一覧から選び、むやみに増やさない。一覧に無いものが要るときは利用者に聞く |
| Env | `dev`・`stg`・`prd`。全環境から使うものは `all` |
| Usage | 用途。動詞や名詞を `_` でつなぐ（例: `export_access_log`、`user_infomation`） |
| ResourceType | CloudFormation のリソースタイプ名の最後の部分を英小文字にしたもの（`AWS::Lambda::Function` → `function`、`AWS::Cognito::UserPool` → `userpool`、`AWS::EC2::Subnet` → `subnet`）。一覧: https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-template-resource-type-ref.html |

## VPC・サブネット

Usage を `{AZ の短い形}_{pub|pvt}_{用途}` にする。AZ の短い形は、リージョンの `ap-northeast-` を `apne` に縮めたもの（`ap-northeast-1a` → `apne1a`）。

- `example-web-dev-apne1a_pvt_lambda-subnet`（ap-northeast-1a・プライベート・Lambda 用）
- `example-web-dev-apne1c_pub_alb-subnet`（ap-northeast-1c・パブリック・ALB 用）

## AWS 側の制約に当たるとき

規則より AWS の制約が優先する。作れない名前を書かない。

**アンダースコアが使えないリソース**では、Usage を1語で表す（`_` を `-` に置き換えたり、詰めたりしない）。
- 例: Web 基盤・本番のアクセスログを置く S3 バケット → `example-web-prd-accesslog-bucket`
- Category が `access_analyze` のように `_` を含むときも同じで、1語の別名が要る。案件で決めていなければ利用者に聞く

**名前の長さの上限に収まらないとき**は、Category を削る。
- 例: ALB（32 文字まで）→ `example-prd-api-alb`
- Category を削ると、同じ環境で同じ Usage のものが2つあったときに見分けられない。Usage を変えて見分ける

公式ドキュメントで確かめた制約（2026-11-23）:

| リソース | 使える文字 | 長さ | 出典 |
|---|---|---|---|
| S3 汎用バケット | 英小文字・数字・`.`・`-`。先頭と末尾は英数字 | 3〜63 | https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html |
| RDS DB インスタンス識別子 | 英数字・`-`。先頭は英字。末尾の `-` と `--` は不可 | 1〜63 | https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Limits.html |
| ALB・NLB | 英数字・`-`。先頭と末尾の `-` は不可。`internal-` で始めない | 最大 32 | https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_CreateLoadBalancer.html |

この表に無いリソースは、名前を決める前にそのサービスの公式ドキュメント（API リファレンスの Name パラメータの制約）を読んで、使える文字と長さを確かめる。確かめられなければ「未確認」と利用者に伝える。

## 例（System を `example` とした場合）

| 名前 | 意味 |
|---|---|
| `example-access_analyze-prd-export_access_log-function` | アクセス集計基盤・本番・アクセスログをエクスポート・Lambda 関数 |
| `example-access_analyze-prd-export_access_log_function-role` | 同じ Lambda 関数の IAM ロール |
| `example-web-dev-user_infomation-userpool` | Web 基盤・開発・ユーザー情報・Cognito ユーザープール |
| `example-web-stg-session_id-table` | Web 基盤・検証・セッション ID・DynamoDB テーブル |
| `example-web-prd-delete_s3_object-queue` | Web 基盤・本番・S3 オブジェクトを削除・SQS キュー |
| `example-monitoring-prd-health_check_web-function` | 外形監視基盤・本番・Web 基盤のヘルスチェック・Lambda 関数 |

## 既に動いているリソースに当てはめない

名前を変えると、多くのリソース（RDS・S3・ALB・IAM ロールなど）は Terraform・CloudFormation が作り直す。RDS や S3 は作り直しでデータが消える。既存の名前が規則と違っていても、勝手に直さず、違いを利用者に伝えるだけにする。規則は新しく作るリソースと新しい環境に使う。
