# Web 版を AWS (S3 + CloudFront) に公開する手順

Flutter の Web ビルド (静的ファイル) を S3 に置き、CloudFront 経由で HTTPS 配信する。
S3 バケットは非公開のままにし、CloudFront からだけ読めるようにする (OAC)。

```
ブラウザ ──HTTPS──▶ CloudFront ──(OAC)──▶ S3 バケット (非公開)
```

## 作成済みのリソース

アカウント ID・バケット名・ディストリビューション ID などの実際の値は
[aws-resources.md](../private/aws-resources.md) にまとめている。

以下のコマンドは、[aws-resources.md](../private/aws-resources.md) にある `export` を実行して、
次のシェル変数を設定してある前提で書いている。

| 変数 | 中身 |
|---|---|
| `AWS_REGION` | バケットを置くリージョン |
| `BUCKET` | S3 バケット名 |
| `OAC_ID` | CloudFront OAC の ID |
| `DIST_ID` | CloudFront ディストリビューションの ID |
| `ACCOUNT_ID` | バケットを置く AWS アカウントの ID |
| `SITE_URL` | 公開 URL (`https://xxxx.cloudfront.net`) |
| `OAC_NAME` | OAC の名前 |
| `OAC_DESCRIPTION` | OAC の説明文 |
| `DIST_COMMENT` | ディストリビューションのメモ |
| `CALLER_REF_PREFIX` | ディストリビューション作成時の識別文字列の先頭部分 |
| `ORIGIN_ID` | ディストリビューション内でオリジン (S3) に付ける名前 |
| `POLICY_SID` | バケットポリシーのルールに付ける名前 |

---

## 0. 前提

- AWS CLI v2 がインストール済みであること
- `aws login` で、**バケットを置くアカウント** (`ACCOUNT_ID`) にログインしていること

```bash
aws login
aws sts get-caller-identity   # Account が ACCOUNT_ID と同じか確認
```

ブラウザで別のアカウントに入り直しても、CLI のログインは自動では切り替わらない。
アカウントを変えたいときは、ブラウザで目的のアカウントに入った状態で `aws login` をやり直す
(既存の設定を上書きするか聞かれたら `y`)。

## 1. S3 バケットを作る

今回はコンソールで作成した。バケット名の末尾 `-<アカウントID>-<リージョン>-an` は、
S3 の「アカウント専用の名前空間」のバケット名の形式で、コンソールが自動で付ける。

CLI で作る場合の例:

```bash
aws s3api create-bucket --bucket "$BUCKET" --region "$AWS_REGION" \
  --create-bucket-configuration LocationConstraint="$AWS_REGION"
```

## 2. バケットを非公開にする

コンソールのガイドに沿って作ると、静的ウェブサイトホスティング用の公開設定になることがある。
CloudFront 構成では不要なので、公開設定を外す。

```bash
# 「誰でも読める」バケットポリシーを削除
aws s3api delete-bucket-policy --bucket "$BUCKET"

# 静的ウェブサイトホスティングを無効化 (S3 の http:// の URL を使わない)
aws s3api delete-bucket-website --bucket "$BUCKET"

# パブリックアクセスを 4 つともブロック
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

## 3. CloudFront の OAC を作る

CloudFront が S3 を読むときに署名するための設定。

```bash
aws cloudfront create-origin-access-control --origin-access-control-config "{
  \"Name\": \"$OAC_NAME\",
  \"Description\": \"$OAC_DESCRIPTION\",
  \"SigningProtocol\": \"sigv4\",
  \"SigningBehavior\": \"always\",
  \"OriginAccessControlOriginType\": \"s3\"
}"
```

出力の `Id` が `OAC_ID`。

## 4. CloudFront のディストリビューションを作る

`dist.json` (`<...>` の部分はシェル変数の値に置き換える):

```json
{
  "CallerReference": "<CALLER_REF_PREFIX>-<任意の一意な文字列>",
  "Comment": "<DIST_COMMENT>",
  "Enabled": true,
  "DefaultRootObject": "index.html",
  "PriceClass": "PriceClass_200",
  "HttpVersion": "http2and3",
  "IsIPV6Enabled": true,
  "Origins": {
    "Quantity": 1,
    "Items": [{
      "Id": "<ORIGIN_ID>",
      "DomainName": "<BUCKET>.s3.<AWS_REGION>.amazonaws.com",
      "OriginAccessControlId": "<OAC_ID>",
      "S3OriginConfig": { "OriginAccessIdentity": "" }
    }]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "<ORIGIN_ID>",
    "ViewerProtocolPolicy": "redirect-to-https",
    "Compress": true,
    "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
    "AllowedMethods": {
      "Quantity": 2, "Items": ["GET", "HEAD"],
      "CachedMethods": { "Quantity": 2, "Items": ["GET", "HEAD"] }
    }
  }
}
```

| 設定 | 意味 |
|---|---|
| `DefaultRootObject` | `/` にアクセスされたら `index.html` を返す |
| `PriceClass_200` | 日本を含む地域のエッジから配信 (全地域より少し安い) |
| `redirect-to-https` | `http://` で来たら `https://` に転送 |
| `Compress` | `main.dart.js` などを圧縮して配信 |
| `CachePolicyId` | AWS 管理の推奨キャッシュポリシー `CachingOptimized` |
| `OriginAccessIdentity: ""` | 旧方式の OAI は使わない (OAC を使う) |

```bash
aws cloudfront create-distribution --distribution-config file://dist.json
```

出力の `Id` が `DIST_ID`、`DomainName` が公開 URL。配備完了まで数分かかる。

```bash
aws cloudfront wait distribution-deployed --id "$DIST_ID"
```

## 5. CloudFront からだけ読めるバケットポリシーを設定する

```bash
aws s3api put-bucket-policy --bucket "$BUCKET" --policy "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [{
    \"Sid\": \"$POLICY_SID\",
    \"Effect\": \"Allow\",
    \"Principal\": { \"Service\": \"cloudfront.amazonaws.com\" },
    \"Action\": \"s3:GetObject\",
    \"Resource\": \"arn:aws:s3:::$BUCKET/*\",
    \"Condition\": { \"StringEquals\": {
      \"AWS:SourceArn\": \"arn:aws:cloudfront::$ACCOUNT_ID:distribution/$DIST_ID\"
    } }
  }]
}"
```

`AWS:SourceArn` の条件で、**このディストリビューションからの読み取りだけ**を許可している。

## 6. ビルドしてアップロードする

```bash
cd Flutter
flutter build web --release --dart-define-from-file=config/api.json
aws s3 sync build/web "s3://$BUCKET" --delete --cache-control "no-cache"
```

- `--dart-define-from-file=config/api.json`: API の URL と Cognito の ID (ユーザープール ID・アプリケーションクライアント ID) をアプリに埋め込む。
  付け忘れると、Cognito の代わりに仮の認証で動き、API にトークンが付かないので投稿を読めない (401)。
  `config/api.json` の作り方は [cognito-auth-aws.md](cognito-auth-aws.md) の「5-1. 設定を渡す」を参照
- 埋め込む値はどれも秘密の値ではない (ブラウザに配信され、誰でも見られる)。秘密の値は `config/api.json` に書かない
- `--delete`: ビルドで消えたファイルを S3 からも消す
- `--cache-control "no-cache"`: Flutter の Web ビルドは `main.dart.js` などのファイル名にハッシュが付かない。
  長くキャッシュさせると、更新後も古いファイルが使われることがあるので、全ファイルを `no-cache` にしている。
  `no-cache` は「毎回サーバーに更新がないか確認する」という意味で、変更がなければ転送は発生しない (304)

## 7. 確認する

```bash
# CloudFront 経由で取れる (200)
curl -sS -o /dev/null -w "%{http_code}\n" "$SITE_URL/"

# S3 に直接はアクセスできない (403)
curl -sS -o /dev/null -w "%{http_code}\n" "https://$BUCKET.s3.$AWS_REGION.amazonaws.com/index.html"
```

---

## 更新するとき

```bash
cd Flutter
flutter build web --release --dart-define-from-file=config/api.json
aws s3 sync build/web "s3://$BUCKET" --delete --cache-control "no-cache"
aws cloudfront create-invalidation --distribution-id "$DIST_ID" --paths "/*"
```

最後の invalidation で、CloudFront のエッジに残っている古いキャッシュを消す。

- 前に一度でも開いたブラウザでは、Flutter のサービスワーカーが保存した古い版が表示されることがある。
  ページを 1〜2 回読み込み直すと新しい版に切り替わる (変わらなければスーパーリロード: Mac は `Cmd + Shift + R`)

## 削除するとき

1. ディストリビューションを無効化する (`Enabled` を `false` にして `update-distribution`)
2. 配備完了を待ってからディストリビューションを削除する
3. OAC を削除する (`aws cloudfront delete-origin-access-control`)
4. バケットを空にして削除する

```bash
aws s3 rm "s3://$BUCKET" --recursive
aws s3api delete-bucket --bucket "$BUCKET"
```

1 と 2 はコンソールで行うほうが簡単。

---

## 補足

### URL の形と S3 / CloudFront の設定

アプリは go_router の初期設定のまま `/#/notifications` のような `#` 付きの URL を使っている。
`#` 以降はサーバーに送られないので、どのページでも `index.html` が返り、再読み込みしても問題ない。

`usePathUrlStrategy()` で `#` なしの URL に変えた場合は、CloudFront で
「403 / 404 のときは `/index.html` を 200 で返す」カスタムエラーレスポンスを追加する必要がある。

### 最初に S3 バケットの作成に失敗した件

最初は別の AWS アカウント (ID は [aws-resources.md](../private/aws-resources.md)) の東京リージョンで
バケットを作ろうとしたが、組織の SCP (サービスコントロールポリシー) で
`s3:CreateBucket` が明示的に拒否された。

- SCP は組織の管理アカウント側の設定で、メンバーアカウントからは中身を見られない
- 中身を確認するには、管理アカウントのルートユーザーでコンソールにサインインし、
  AWS Organizations → ポリシー → サービスコントロールポリシーを見る
- 今回は SCP を変えず、バケットの作成が許可されていた別のアカウント (シドニー) を使った

### 公開範囲

CloudFront の URL を知っていれば、誰でもサインイン画面までは見られ、アカウントも作れる
(Cognito のセルフサインアップが有効なため)。投稿の読み書きはサインインした人だけ
([api-jwt-auth-aws.md](api-jwt-auth-aws.md))。
アプリの JavaScript には API の URL と Cognito の ID が入るが、どれも秘密の値ではない。
