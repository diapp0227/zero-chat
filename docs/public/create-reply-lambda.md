# Lambda 関数の仕様: `zero-chat-create-reply`

投稿に返信を 1 件書き足す関数。API Gateway の `POST /posts/{id}/replies` から呼ばれる。
返信した人 (`author`) は、トークンの `sub` で読んだプロフィール (`zero-chat-profiles`) から決める。

## 関数の設定

| 項目 | 値 |
|---|---|
| 関数名 | `zero-chat-create-reply` |
| リージョン | `ap-northeast-1` (東京) |
| ランタイム | Python 3.13 |
| ハンドラ | `lambda_function.lambda_handler` |
| メモリ・タイムアウト | 128 MB・3 秒 (初期値) |
| 呼び出し元 | API Gateway HTTP API `zero-chat-api` のルート `POST /posts/{id}/replies` |

### 環境変数

| キー | 値 | 説明 |
|---|---|---|
| `POSTS_TABLE_NAME` | `zero-chat-posts` | 返信を書き足す投稿のテーブル |
| `PROFILES_TABLE_NAME` | `zero-chat-profiles` | 返信した人のプロフィールを読むテーブル |

### 実行ロールの権限

`AWSLambdaBasicExecutionRole` 相当 (自動で付く) に加えて、インラインポリシーを付ける。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["dynamodb:GetItem", "dynamodb:UpdateItem"],
      "Resource": "arn:aws:dynamodb:ap-northeast-1:<アカウントID>:table/zero-chat-posts"
    },
    {
      "Effect": "Allow",
      "Action": "dynamodb:GetItem",
      "Resource": "arn:aws:dynamodb:ap-northeast-1:<アカウントID>:table/zero-chat-profiles"
    }
  ]
}
```

| 操作 | 使いみち |
|---|---|
| `dynamodb:GetItem` (`zero-chat-posts`) | 返信先の投稿があるかと、今の返信の番号を読む |
| `dynamodb:UpdateItem` (`zero-chat-posts`) | 投稿の `replies` に返信を書き足す |
| `dynamodb:GetItem` (`zero-chat-profiles`) | 返信した人のプロフィールを読む |

---

## API 仕様

### リクエスト

```
POST /posts/{id}/replies
Authorization: Bearer <アクセストークン>
Content-Type: application/json
```

```json
{ "text": "意図まで共有するの、大切ですね！" }
```

| 項目 | 型 | 必須 | 条件 |
|---|---|---|---|
| `{id}` (URL) | 整数 | ○ | 返信先の投稿の番号 (1 以上) |
| `text` | 文字列 | ○ | 前後の空白を除いて 1 文字以上、**180 文字以下** |

- 返信の番号・返信日時・返信した人 (`author`) は送らない。サーバーが決める

### レスポンス (201 Created)

書き足した返信を、`GET /posts` の `replies` の 1 件と同じ形で返す。

```json
{
  "reply": {
    "id": 4,
    "author": { "id": 0, "name": "ああああ", "role": "エンジニア", "color1": "#E8BD79", "color2": "#B87947" },
    "text": "意図まで共有するの、大切ですね！",
    "repliedAt": "2026-10-16T09:15:00Z"
  }
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `reply.id` | 整数 | 返信の番号。**その投稿の中で**一意 (今ある返信の番号の最大値 + 1) |
| `reply.author` | オブジェクト | 返信した人。名前・役職・カラーはプロフィールのコピー。`id` は常に `0` |
| `reply.text` | 文字列 | 本文 (前後の空白を除いたもの) |
| `reply.repliedAt` | 文字列 | 返信日時 (UTC、ISO 8601、秒まで) |

### エラー

| ステータス | 条件 | ボディの例 |
|---|---|---|
| 400 Bad Request | ボディが JSON として読めない | `{"message": "body must be valid JSON"}` |
| 400 Bad Request | ボディが JSON のオブジェクトでない | `{"message": "body must be a JSON object"}` |
| 400 Bad Request | `text` がない・空・空白だけ | `{"message": "text is required"}` |
| 400 Bad Request | `text` が 180 文字より長い | `{"message": "text must be at most 180 characters"}` |
| 400 Bad Request | 返信した人のプロフィールがまだない | `{"message": "profile is required"}` |
| 401 Unauthorized | トークンがない・正しくない、または `sub` が取れない | `{"message": "Unauthorized"}` |
| 404 Not Found | `{id}` が数字でない・0 以下、またはその番号の投稿がない | `{"message": "post not found"}` |
| 500 Internal Server Error | 同時に返信が続いて 3 回とも保存がぶつかった、DynamoDB の操作に失敗したなど | `{"message": "Internal Server Error"}` (API Gateway が返す) |

---

## 処理の流れ

1. トークンの `sub` と、URL の投稿の番号を取り出す
2. `body` を JSON として読み、本文をチェックする
3. `sub` で `zero-chat-profiles` を読み、名前・役職・カラーを `author` にする
4. 投稿を `GetItem` で読む。`feed` がない項目 (番号を数える項目など) は投稿ではないので 404
5. 返信の番号を「今ある返信の番号の最大値 + 1」にする
6. `UpdateItem` の `list_append` で `replies` の最後に書き足す。
   条件として「読んだときと返信の数が同じ」(`size(replies) = :count`) を付ける
7. 条件に合わなかった (読んでから保存するまでに、ほかの人が返信した) ときは、4 からやり直す (最大 3 回)
8. 書き足した返信を 201 で返す

### 番号が重ならない理由

読んでから保存するまでの間に、ほかの人が返信すると、同じ番号を付けてしまうおそれがある。
保存の条件に「返信の数が読んだときと同じ」を付けているので、間に返信が入っていれば DynamoDB が保存を断る
(`ConditionalCheckFailedException`)。そのときは読み直して、新しい最大値 + 1 で保存し直す。

投稿の番号のように番号を数える項目を使わないのは、返信の番号は投稿の中で重ならなければ十分なため。

## コード

[Lambda/zero-chat-create-reply/lambda_function.py](../../Lambda/zero-chat-create-reply/lambda_function.py)

リポジトリのこのファイルを正とする。修正したら、Lambda コンソールの「コード」タブに貼り付けて「Deploy」する。

## テストイベント

コンソールのテストは JWT オーソライザーを通らないので、`requestContext` にユーザーの番号 (`sub`) を自分で書く。
URL の `{id}` は `pathParameters` に書く。

```json
{
  "requestContext": { "authorizer": { "jwt": { "claims": { "sub": "<プロフィールがあるユーザーの sub>" } } } },
  "pathParameters": { "id": "<返信先の投稿の id>" },
  "body": "{\"text\": \"Lambda からのテスト返信\"}"
}
```

| 変えるところ | 期待する結果 |
|---|---|
| (上のまま) | 201、番号と返信日時が付いた返信。DynamoDB の投稿の `replies` の最後に増える |
| `body` の `text` を `"   "` に | 400、`text is required` |
| `pathParameters` の `id` を `"999999"` に | 404、`post not found` |
| `sub` をプロフィールがない値に | 400、`profile is required` |
| `requestContext` を消す | 401 |

テストの返信はタイムラインに表示されるので、不要なら DynamoDB の投稿の `replies` から消す。

## 制限と今後の課題

- **編集・削除はできない**
- **返信の数の上限**: 返信は投稿の項目の中に持っているので、DynamoDB の 1 項目の上限 (400 KB) を超えると書き足せない。
  180 文字の返信なら 1,000 件程度までは収まる
- **プロフィールの変更**: 返信には、返信したときの名前・役職・カラーをコピーしている。あとでプロフィールを変えても、過去の返信の表示は変わらない
