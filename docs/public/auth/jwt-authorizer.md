# API の認証の設定: JWT オーソライザー `zero-chat-cognito`

API Gateway (`zero-chat-api`) のすべてのルートで、Cognito が発行したアクセストークンを確かめる。
サインインしていない人 (トークンがない・正しくない) のリクエストは、Lambda を呼ばずに 401 で断る。

```
Flutter アプリ
   │  Authorization: Bearer <アクセストークン>
   ▼
API Gateway (zero-chat-api)
   │  JWT オーソライザー zero-chat-cognito がトークンを確かめる (署名・有効期限・発行元・対象者)
   │  → だめなら 401 を返して終わり
   ▼
Lambda  … event.requestContext.authorizer.jwt.claims にトークンの中身 (sub など) が届く
```

- 作る手順: [aws-setup.md](../aws-setup.md) の「4. API Gateway を作る」
- トークンを発行するユーザープール: [cognito.md](cognito.md)
- ユーザープール ID などの実際の値: [aws-resources.md](../../private/aws-resources.md)

---

## 設計で決めたこと

| 項目 | 決めたこと | 理由 |
|---|---|---|
| 確かめる場所 | API Gateway の **JWT オーソライザー** | コードを書かずに設定だけで付けられ、Lambda も呼ばれないので無駄な実行と料金がかからない |
| 送るトークン | **アクセストークン** | API を呼ぶ権限を表すためのトークン。ID トークンは「誰か」を表すためのもの |
| トークンの付け方 | `Authorization: Bearer <トークン>` | HTTP の一般的な書き方。JWT オーソライザーは `Bearer ` を取り除いて読む |
| 対象のルート | **すべてのルート** | 社内向けの SNS なので、投稿を読むのもサインインした人だけにする |
| スコープ (権限の細かい区分) | 使わない | 今はサインインしているかどうかだけで十分 |
| 誰のリクエストか | Lambda がトークンの `sub` を使う | アプリから送られた名前や ID を信じないため (他人になりすませない) |

---

## 設定値

### オーソライザー

**API Gateway → `zero-chat-api` → 認可 → 「オーソライザーを管理」**

| 項目 | 値 |
|---|---|
| オーソライザーのタイプ | **JWT** |
| 名前 | `zero-chat-cognito` |
| ID ソース | `$request.header.Authorization` (初期値のまま) |
| 発行者 URL | `https://cognito-idp.<ユーザープールのリージョン>.amazonaws.com/<ユーザープールID>` |
| 対象者 | `<アプリケーションクライアントID>` (1 つ) |

- **発行者 URL** のリージョンは、ユーザープール ID の「`_`」より前と同じ (例: `ap-northeast-1_xxxxxxxxx` なら `ap-northeast-1`)
- 発行者 URL の末尾に `/` は付けない。1 文字でも違うと、正しいトークンでも 401 になる
- 対象者は、アプリの `config/api.json` の `COGNITO_CLIENT_ID` と同じ値
- アクセストークンには `aud` がなく `client_id` に入っているが、JWT オーソライザーはどちらでも対象者と照らし合わせる

### オーソライザーを付けるルート

| ルート | オーソライザー |
|---|---|
| `GET /posts` | `zero-chat-cognito` |
| `POST /posts` | `zero-chat-cognito` |
| `POST /posts/{id}/replies` | `zero-chat-cognito` |
| `GET /profile` | `zero-chat-cognito` |
| `PUT /profile` | `zero-chat-cognito` |

ルートを足したときは、**必ずオーソライザーも付ける**。付け忘れると誰でも呼べるルートになる
(プロフィール・返信・投稿作成の Lambda は、トークンの `sub` が取れないと 401 を返すので、データは読み書きされない)。

### CORS

**API Gateway → `zero-chat-api` → CORS**

| 項目 | 値 |
|---|---|
| Access-Control-Allow-Origin | Web 版の CloudFront の URL (`https://xxxx.cloudfront.net`)、開発用の `http://localhost:8080` |
| Access-Control-Allow-Methods | `GET`・`POST`・`PUT` |
| Access-Control-Allow-Headers | `content-type`・`authorization` |

- Web 版はトークンを `Authorization` ヘッダーで送るので、`authorization` を許可しないと、ブラウザの事前確認 (プリフライト) で断られる
- HTTP API は CORS の設定があればプリフライト (`OPTIONS`) に自動で答えるので、`OPTIONS` のルートは作らない。`OPTIONS` にはオーソライザーがかからない
- iOS・Android などのアプリは CORS の対象外

---

## アプリ側

アプリはサインイン中、すべての API のリクエストにアクセストークンを付ける。

| 層 | ファイル | 役割 |
|---|---|---|
| Data | `lib/data/services/api/api_service.dart` | `Authorization: Bearer <アクセストークン>` を付けて GET・POST・PUT する |
| Data | `lib/data/repositories/auth/cognito_auth_repository.dart` | `accessToken()` で、Amplify からアクセストークンを取り出す。有効期限 (1 時間) が切れていれば Amplify が自動で取り替える |
| Data | `lib/data/repositories/auth/fake_auth_repository.dart` | トークンを発行しないので、ヘッダーを付けない |

- Cognito の設定 (`COGNITO_USER_POOL_ID`・`COGNITO_CLIENT_ID`) を渡さずに、API の URL だけ渡して起動すると、
  トークンが付かないので API は 401 になる。API につなぐときは Cognito の設定も一緒に渡す

---

## 動作の確認

```bash
# トークンなし (401 と {"message":"Unauthorized"} が返る)
curl -i "<API の URL>/posts"

# トークンあり
curl -i "<API の URL>/posts" -H "Authorization: Bearer <アクセストークン>"
```

アクセストークンは、Web 版でサインインし、ブラウザの開発者ツール → ネットワーク → `posts` のリクエストの
`Authorization` ヘッダーからコピーする (トークンは 1 時間で切れる。**ほかの人に渡したり、どこかに貼ったりしない**)。

### うまくいかないとき

| 症状 | よくある原因 |
|---|---|
| アプリで 401 になる | 発行者 URL のリージョン・ユーザープール ID の間違い、末尾の `/`、対象者がアプリケーションクライアント ID と違う |
| Web 版だけ API が呼べない (ブラウザのコンソールに CORS のエラー) | CORS で `authorization` ヘッダー・メソッド (`PUT` など)・オリジンが許可されていない |
| ルートを足したら Lambda が 401 を返す | そのルートにオーソライザーを付け忘れている (Lambda にトークンの中身が届かない) |

---

## 公開範囲と今後の課題

- サインインしていれば誰でも、すべての投稿を読み書きできる (投稿ごとの権限はない)
- トークンが無効になったとき (ユーザーの削除など) は API が 401 を返す。
  今のアプリは「読み込めませんでした」と出すだけなので、401 ならサインイン画面に戻すようにする
