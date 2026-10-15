# 投稿 API に Cognito の JWT 認証を付ける手順

投稿の取得・作成 API (`zero-chat-api`) を、Cognito でサインインした人だけが使えるようにする。
API Gateway (HTTP API) の **JWT オーソライザー**が、リクエストに付いたトークンを Lambda の前で確かめる。

```
Flutter アプリ (サインイン済み)
   │  GET /posts ・ POST /posts
   │  Authorization: Bearer <アクセストークン>
   ▼
API Gateway (HTTP API: zero-chat-api)
   │  JWT オーソライザー (zero-chat-cognito)
   │    ・署名が Cognito のものか
   │    ・発行元 (iss) がこのユーザープールか
   │    ・アプリケーションクライアント (client_id) が合っているか
   │    ・有効期限 (exp) が切れていないか
   │  → だめなら Lambda を呼ばずに 401 を返す
   ▼
Lambda (zero-chat-get-posts ・ zero-chat-create-post)   … 変更なし
```

関連するドキュメント:

- Cognito のユーザープールの作成手順 (この手順の前提): [cognito-auth-aws.md](cognito-auth-aws.md)
- 投稿取得 API の作成手順: [posts-api-aws.md](posts-api-aws.md)
- 投稿作成 API の作成手順: [create-post-api-aws.md](create-post-api-aws.md)
- アカウント ID・ユーザープール ID などの実際の値: [aws-resources.md](../private/aws-resources.md)

## 変更するリソース

| サービス | 名前 | 変更 |
|---|---|---|
| API Gateway | `zero-chat-api` (既存) | JWT オーソライザー `zero-chat-cognito` を作り、`GET /posts` と `POST /posts` に付ける。CORS で `authorization` ヘッダーを許可する |
| Lambda・DynamoDB | (既存) | 変更なし |

API Gateway は `ap-northeast-1` (東京)。ユーザープールは別のリージョンにあってもよい
(発行元の URL にユーザープールのリージョンを書く)。

---

## 0. 設計で決めたこと

| 項目 | 決めたこと | 理由 |
|---|---|---|
| 確かめる場所 | API Gateway の **JWT オーソライザー** | コードを書かずに設定だけで付けられ、Lambda も呼ばれないので無駄な実行と料金がかからない |
| 送るトークン | **アクセストークン** | API を呼ぶ権限を表すためのトークン。ID トークンは「誰か」を表すためのもの |
| トークンの付け方 | `Authorization: Bearer <トークン>` | HTTP の一般的な書き方。JWT オーソライザーは `Bearer ` を取り除いて読む |
| 対象のルート | `GET /posts` と `POST /posts` の**両方** | 社内向けの SNS なので、投稿を読むのもサインインした人だけにする |
| スコープ (権限の細かい区分) | 使わない | 今はサインインしているかどうかだけで十分 |

---

## 1. 作業の順番 (大事)

順番を間違えると、途中で Web 版やアプリから投稿が読めなくなる。

1. **CORS で `authorization` ヘッダーを許可する** (手順 2)
   — 先にトークンを送るアプリを出すと、ブラウザの事前確認 (プリフライト) で断られて Web 版が動かなくなるため
2. **トークンを送るアプリを出す** (手順 5)
   — Web 版は CloudFront に配置し直す。iOS・Android は新しいビルドを入れる
3. **JWT オーソライザーを作ってルートに付ける** (手順 3・4)
   — 付けた時点で、トークンを送らない古いアプリは 401 になる

---

## 2. CORS で authorization ヘッダーを許可する

**API Gateway → `zero-chat-api` → CORS → 設定 (編集)**

| 項目 | 値 |
|---|---|
| Access-Control-Allow-Headers | `content-type` に加えて **`authorization`** |

ほかの項目 (許可するオリジン・メソッド) はそのまま。
HTTP API は CORS の設定があればプリフライト (`OPTIONS`) に自動で答えるので、`OPTIONS` にはオーソライザーがかからない。

---

## 3. JWT オーソライザーを作る

**API Gateway → `zero-chat-api` → 認可 → 「オーソライザーを管理」タブ → 作成**

| 項目 | 値 |
|---|---|
| オーソライザーのタイプ | **JWT** |
| 名前 | `zero-chat-cognito` |
| ID ソース | `$request.header.Authorization` (初期値のまま) |
| 発行者 URL | `https://cognito-idp.<ユーザープールのリージョン>.amazonaws.com/<ユーザープールID>` |
| 対象者 | `<アプリケーションクライアントID>` (「対象者を追加」で 1 つ) |

- **発行者 URL** のリージョンは、API Gateway ではなく**ユーザープールのリージョン**。
  ユーザープール ID の「`_`」より前と同じ (例: `ap-southeast-2_xxxxxxxxx` なら `ap-southeast-2`)
- 発行者 URL の末尾に `/` は付けない。1 文字でも違うと、正しいトークンでも 401 になる
- 対象者は、アプリの `config/api.json` の `COGNITO_CLIENT_ID` と同じ値
- アクセストークンには `aud` がなく `client_id` に入っているが、JWT オーソライザーはどちらでも対象者と照らし合わせる

---

## 4. ルートにオーソライザーを付ける

**認可 → 「ルートにオーソライザーをアタッチする」タブ**

| ルート | オーソライザー |
|---|---|
| `GET /posts` | `zero-chat-cognito` |
| `POST /posts` | `zero-chat-cognito` |

ルートを選んで、オーソライザーに `zero-chat-cognito` を選び「オーソライザーをアタッチ」を押す。
`$default` ステージの自動デプロイがオンなので、付けた時点から有効になる。

---

## 5. アプリ側

アプリはサインイン中、すべての API のリクエストにアクセストークンを付ける。設定の追加はない。

| 層 | ファイル | 役割 |
|---|---|---|
| Data | `lib/data/services/api/api_service.dart` | `Authorization: Bearer <アクセストークン>` を付けて GET・POST する |
| Data | `lib/data/repositories/auth/cognito_auth_repository.dart` | `accessToken()` で、Amplify からアクセストークンを取り出す。有効期限 (1 時間) が切れていれば Amplify が自動で取り替える |
| Data | `lib/data/repositories/auth/fake_auth_repository.dart` | トークンを発行しないので、ヘッダーを付けない |

- Cognito の設定 (`COGNITO_USER_POOL_ID`・`COGNITO_CLIENT_ID`) を渡さずに、API の URL だけ渡して起動すると、
  トークンが付かないので API は 401 になる。API につなぐときは Cognito の設定も一緒に渡す
- Web 版は、ビルドし直して CloudFront に配置し直す ([deploy-web-aws.md](deploy-web-aws.md))

---

## 6. 動作を確認する

`<API の URL>` は **API → ステージ → `$default`** の「呼び出し URL」。

```bash
# トークンなし (401 と {"message":"Unauthorized"} が返る)
curl -i "<API の URL>/posts"
```

トークンありの確認は、アプリで行うのがかんたん。

1. アプリ (Web 版) でサインインし、タイムラインに投稿が表示されること
2. 投稿を作成でき、タイムラインに出ること
3. ブラウザの開発者ツール → ネットワーク → `posts` のリクエストに `Authorization: Bearer ...` が付いていること

curl でトークンありを試すときは、3. のヘッダーの値をコピーして使う
(トークンは 1 時間で切れる。**ほかの人に渡したり、どこかに貼ったりしない**)。

```bash
curl -i "<API の URL>/posts" -H "Authorization: Bearer <アクセストークン>"
```

### うまくいかないとき

| 症状 | よくある原因 |
|---|---|
| アプリで 401 になる | 発行者 URL のリージョン・ユーザープール ID の間違い、末尾の `/`、対象者がアプリケーションクライアント ID と違う |
| Web 版だけ投稿が読めない (ブラウザのコンソールに CORS のエラー) | 手順 2 の `authorization` の許可がない |
| 古いアプリで読めなくなった | オーソライザーを付ける前に、トークンを送るアプリを出していない (手順 1 の順番) |

---

## 公開範囲と今後の課題

- サインインしていれば誰でも、すべての投稿を読み書きできる (投稿ごとの権限はない)
- 投稿した人 (`author`) は、まだアプリから送った名前と役職のまま。
  Lambda には JWT オーソライザーが確かめたトークンの中身 (`event.requestContext.authorizer.jwt.claims`) が届くので、
  そこにあるユーザーの番号 (`sub`) から投稿した人を決めるようにする
- サインインしていても、トークンが無効になったとき (ユーザーの削除など) は API が 401 を返す。
  今のアプリは「読み込めませんでした」と出すだけなので、401 ならサインイン画面に戻すようにする
