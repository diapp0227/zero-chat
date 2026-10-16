# Lambda 関数の仕様: `zero-chat-get-profile`・`zero-chat-update-profile`

サインインしている人の、自分のプロフィールを読み書きする関数。
API Gateway の `GET /profile`・`PUT /profile` から呼ばれる。

| 関数名 | ルート | DynamoDB の操作 | 呼ぶ画面 |
|---|---|---|---|
| `zero-chat-get-profile` | `GET /profile` | `GetItem` | タイムライン (ホーム) を開いたとき・プロフィール設定画面を開いたとき |
| `zero-chat-update-profile` | `PUT /profile` | `PutItem` | サインアップの完了時・プロフィール設定画面で「保存」したとき |

## 関数の設定 (2 つ共通)

| 項目 | 値 |
|---|---|
| リージョン | `ap-northeast-1` (東京) |
| ランタイム | Python 3.13 |
| ハンドラ | `lambda_function.lambda_handler` |
| メモリ・タイムアウト | 128 MB・3 秒 (初期値) |
| 環境変数 | `TABLE_NAME` = `zero-chat-profiles` |

### 実行ロールの権限

自動で付く `AWSLambdaBasicExecutionRole` 相当 (CloudWatch Logs) に加えて、インラインポリシーを 1 つ付ける。

`zero-chat-get-profile`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "dynamodb:GetItem",
      "Resource": "arn:aws:dynamodb:ap-northeast-1:<アカウントID>:table/zero-chat-profiles"
    }
  ]
}
```

`zero-chat-update-profile`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "dynamodb:PutItem",
      "Resource": "arn:aws:dynamodb:ap-northeast-1:<アカウントID>:table/zero-chat-profiles"
    }
  ]
}
```

---

## 誰のプロフィールかの決め方

どちらの API も、URL やボディでユーザーを指定しない。
JWT オーソライザーが確かめたアクセストークンの中身が、Lambda の
`event.requestContext.authorizer.jwt.claims` に届くので、その `sub` (ユーザーの番号) を `userId` に使う。

- アプリが他人の番号を送って、他人のプロフィールを読み書きすることはできない
- `claims` に `sub` がないとき (ルートにオーソライザーを付け忘れたときなど) は 401 を返し、DynamoDB には触らない

---

## `GET /profile`

### リクエスト

```
GET /profile
Authorization: Bearer <アクセストークン>
```

### レスポンス (200 OK)

```json
{
  "profile": {
    "name": "ああああ",
    "role": "デザイナー",
    "color1": "#E8BD79",
    "color2": "#B87947",
    "updatedAt": "2026-10-16T09:00:00Z"
  }
}
```

### エラー

| ステータス | 条件 | ボディの例 |
|---|---|---|
| 401 Unauthorized | トークンがない・正しくない (API Gateway が返す)、または `sub` が取れない | `{"message": "Unauthorized"}` |
| 404 Not Found | まだプロフィールを保存していない | `{"message": "profile not found"}` |
| 500 Internal Server Error | DynamoDB の読み取りに失敗したなど | `{"message": "Internal Server Error"}` (API Gateway が返す) |

アプリは 404 を「プロフィールがまだない」として扱い、エラーにはしない。

---

## `PUT /profile`

### リクエスト

```
PUT /profile
Authorization: Bearer <アクセストークン>
Content-Type: application/json
```

```json
{ "name": "ああああ", "role": "デザイナー", "color1": "#E8BD79", "color2": "#B87947" }
```

| フィールド | 型 | 必須 | 条件 |
|---|---|---|---|
| `name` | 文字列 | ○ | 前後の空白を除いて 1 文字以上、**30 文字以下** |
| `role` | 文字列 | ○ | `エンジニア` / `デザイナー` / `プロダクトマネージャー` / `セールス` / `コーポレート` のどれか |
| `color1` | 文字列 | ○ | カラー1。`#` と 16 進数 6 桁 (例: `#E8BD79`)。小文字で送っても大文字にして保存する |
| `color2` | 文字列 | ○ | カラー2。形は `color1` と同じ |

- 初めてなら作成し、すでにあれば丸ごと置き換える。同じ内容を何度送っても結果は同じ (`PUT` にした理由)
- `updatedAt` はサーバーが付ける

### レスポンス (200 OK)

保存したプロフィールを、`GET /profile` と同じ形で返す。

### エラー

| ステータス | 条件 | ボディの例 |
|---|---|---|
| 400 Bad Request | ボディが JSON として読めない | `{"message": "body must be valid JSON"}` |
| 400 Bad Request | ボディが JSON のオブジェクトでない | `{"message": "body must be a JSON object"}` |
| 400 Bad Request | `name` がない・空・空白だけ | `{"message": "name is required"}` |
| 400 Bad Request | `name` が 30 文字より長い | `{"message": "name must be at most 30 characters"}` |
| 400 Bad Request | `role` が決まった役職のどれでもない | `{"message": "unknown role: <値>"}` |
| 400 Bad Request | `color1` / `color2` がない、または `#RRGGBB` の形でない | `{"message": "color1 must be a color like #E8BD79"}` |
| 401 Unauthorized | トークンがない・正しくない、または `sub` が取れない | `{"message": "Unauthorized"}` |
| 500 Internal Server Error | DynamoDB の書き込みに失敗したなど | `{"message": "Internal Server Error"}` (API Gateway が返す) |

---

## コード

- [Lambda/zero-chat-get-profile/lambda_function.py](../../Lambda/zero-chat-get-profile/lambda_function.py)
- [Lambda/zero-chat-update-profile/lambda_function.py](../../Lambda/zero-chat-update-profile/lambda_function.py)

リポジトリのファイルを正とする。修正したら、Lambda コンソールの「コード」タブに貼り付けて「Deploy」する。

- 役職の一覧 (`ROLES`) は、アプリの `profileRoles` と投稿作成の Lambda に合わせている。増やすときは全部を一緒に変える

## テストイベント

Lambda コンソールの「テスト」タブでは JWT オーソライザーを通らないので、`requestContext` にトークンの中身を自分で書く。

`zero-chat-update-profile` (イベント名 `update`):

```json
{
  "requestContext": { "authorizer": { "jwt": { "claims": { "sub": "test-user" } } } },
  "body": "{\"name\": \"テスト\", \"role\": \"エンジニア\", \"color1\": \"#E8BD79\", \"color2\": \"#B87947\"}"
}
```

`zero-chat-get-profile` (イベント名 `get`):

```json
{
  "requestContext": { "authorizer": { "jwt": { "claims": { "sub": "test-user" } } } }
}
```

| 関数 | イベント | 期待する結果 |
|---|---|---|
| update | `update` | 200、`updatedAt` が付いたプロフィール |
| update | `body` の `name` を `""` に | 400、`name is required` |
| update | `body` の `role` を `社長` に | 400、`unknown role: 社長` |
| update | `body` の `color1` を `red` に | 400、`color1 must be a color like #E8BD79` |
| update / get | `requestContext` を消す | 401 |
| get | `get` (`update` の後) | 200、`update` で保存した内容 |
| get | `sub` を `nobody` に | 404 |

テストで作った `test-user` の項目は、DynamoDB から削除しておく。
