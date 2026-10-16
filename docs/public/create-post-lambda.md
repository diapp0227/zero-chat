# Lambda 関数の仕様: `zero-chat-create-post`

アプリから送られた投稿を検証し、番号・投稿日時・投稿した人を付けて DynamoDB に保存する関数。
投稿した人 (`author`) は、トークンの `sub` で読んだプロフィール (`zero-chat-profiles`) から決める。
API Gateway の `POST /posts` から呼ばれる。

## 関数の設定

| 項目 | 値 |
|---|---|
| 関数名 | `zero-chat-create-post` |
| リージョン | `ap-northeast-1` (東京) |
| ランタイム | Python 3.13 |
| ハンドラ | `lambda_function.lambda_handler` |
| メモリ | 128 MB (初期値) |
| タイムアウト | 3 秒 (初期値) |
| 呼び出し元 | API Gateway HTTP API `zero-chat-api` のルート `POST /posts` |

### 環境変数

| キー | 値 | 説明 |
|---|---|---|
| `TABLE_NAME` | `zero-chat-posts` | 書き込む DynamoDB テーブルの名前 |
| `PROFILES_TABLE_NAME` | `zero-chat-profiles` | 投稿した人のプロフィールを読むテーブルの名前 |

### 実行ロールの権限

| ポリシー | 内容 |
|---|---|
| `AWSLambdaBasicExecutionRole` 相当 (自動で付く) | CloudWatch Logs へのログ出力 |
| インラインポリシー (手動で追加) | 下記 |

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["dynamodb:UpdateItem", "dynamodb:PutItem"],
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
| `dynamodb:UpdateItem` | 投稿の番号を数える項目 (`id: 0`) の `lastPostId` を 1 増やす |
| `dynamodb:PutItem` | 投稿を書き込む |
| `dynamodb:GetItem` (`zero-chat-profiles`) | 投稿した人のプロフィールを読む |

投稿の読み取り・削除はできない。

---

## API 仕様

### リクエスト

```
POST /posts
Content-Type: application/json
```

```json
{
  "category": "dailyReport",
  "text": "今日はチームでコードレビュー。"
}
```

| フィールド | 型 | 必須 | 条件 |
|---|---|---|---|
| `category` | 文字列 | ○ | `announcement` / `dailyReport` / `selfStudy` のどれか |
| `text` | 文字列 | ○ | 前後の空白を除いて 1 文字以上、**180 文字以下** |

- 本文の上限は、アプリの投稿画面の入力欄と同じ
- 番号 (`id`)・投稿日時 (`postedAt`)・投稿した人 (`author`) は送らない。サーバーが決める。
  以前の形の `author` を送っても使わない (他人の名前を名乗れないようにするため)

### レスポンス (201 Created)

保存した投稿を、`GET /posts` の投稿 1 件と同じ形で返す。

```json
{
  "post": {
    "id": 11,
    "author": { "id": 0, "name": "ああああ", "role": "エンジニア", "color1": "#E8BD79", "color2": "#B87947" },
    "category": "dailyReport",
    "text": "今日はチームでコードレビュー。",
    "postedAt": "2026-10-15T09:00:00Z",
    "replies": []
  }
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `post.id` | 整数 | サーバーが付けた投稿の番号 |
| `post.author.id` | 整数 | 投稿した人の番号。常に `0` |
| `post.author.name` | 文字列 | プロフィールのユーザー名 |
| `post.author.role` | 文字列 | プロフィールの役職 |
| `post.author.color1`・`color2` | 文字列 | プロフィールのカラー1・カラー2 (`#RRGGBB`) |
| `post.category` | 文字列 | リクエストの種類 |
| `post.text` | 文字列 | リクエストの本文 (前後の空白を除いたもの) |
| `post.postedAt` | 文字列 | サーバーが付けた投稿日時 (UTC、ISO 8601、秒まで) |
| `post.replies` | 配列 | 常に空の配列 |

- ヘッダーは `Content-Type: application/json; charset=utf-8`
- 日本語はエスケープせずそのまま返す (`ensure_ascii=False`)
- DynamoDB 内の検索用の属性 `feed` は返さない (保存はする)

### エラー

| ステータス | 条件 | ボディの例 |
|---|---|---|
| 400 Bad Request | ボディが JSON として読めない、またはボディがない | `{"message": "body must be valid JSON"}` |
| 400 Bad Request | ボディが JSON のオブジェクトでない (配列など) | `{"message": "body must be a JSON object"}` |
| 400 Bad Request | `category` が 3 種類のどれでもない | `{"message": "unknown category: <値>"}` |
| 400 Bad Request | `text` がない・空・空白だけ | `{"message": "text is required"}` |
| 400 Bad Request | `text` が 180 文字より長い | `{"message": "text must be at most 180 characters"}` |
| 400 Bad Request | 投稿した人のプロフィールがまだない | `{"message": "profile is required"}` |
| 401 Unauthorized | トークンがない・正しくない (API Gateway が返す)、または `sub` が取れない | `{"message": "Unauthorized"}` |
| 429 Too Many Requests | ルートのスロットリングの上限を超えた | `{"message": "Too Many Requests"}` (API Gateway が返す) |
| 500 Internal Server Error | 番号が既存の投稿とぶつかった、DynamoDB の書き込みに失敗したなど | `{"message": "Internal Server Error"}` (API Gateway が返す) |

500 のときの詳しい原因は、Lambda の「モニタリング → CloudWatch ログ」で確認する。
番号がぶつかったときは、ログに `ConditionalCheckFailedException` が出る
(番号の項目の `lastPostId` が、既存の投稿の `id` の最大値より小さくなっている)。

---

## 処理の流れ

1. `body` を JSON として読む。HTTP API はボディを Base64 で送ってくることがあるので、
   `isBase64Encoded` が true なら先に戻す
2. 入力をチェックする。問題があれば、最初に見つかった問題を 400 で返して終わる
3. トークンの `sub` で `zero-chat-profiles` を読み、名前・役職・カラーを `author` にする。プロフィールがなければ 400
4. 番号の項目 (`id: 0`) の `lastPostId` を `ADD` で 1 増やし、増やした後の値を新しい投稿の番号にする
5. 投稿日時を、今の UTC の時刻から `YYYY-MM-DDTHH:MM:SSZ` の形で作る
6. 投稿を `PutItem` で保存する。`feed: "ALL"` も一緒に書き込み、タイムラインのインデックスに載せる
7. 保存した投稿 (`feed` を除く) を 201 で返す

### 番号が重ならない理由

`UpdateItem` の `ADD` は、DynamoDB の中で「今の値を読んで 1 足して書く」を 1 回の操作として行う。
2 人が同時に投稿しても、DynamoDB が順番に処理するので、それぞれ別の番号 (例: 11 と 12) を受け取る。
Lambda で「最大の番号を読んでから 1 足す」と書くと、同時に読んだ 2 人が同じ番号を使ってしまう。

さらに `PutItem` に `attribute_not_exists(id)` の条件を付けている。
万一同じ番号の投稿があっても上書きせず、エラーにする (既存の投稿を守るための保険)。

### 投稿日時をこの形にしている理由

テーブルのインデックスは `postedAt` を**文字列**として並べる。
桁数とタイムゾーン (`Z` = UTC) をそろえた文字列なら、文字列の順と日時の順が一致する
([posts-table.md](posts-table.md) の「`postedAt` を文字列にしている理由」を参照)。
既存の投稿と同じく秒までにそろえる。

## コード

[Lambda/zero-chat-create-post/lambda_function.py](../../Lambda/zero-chat-create-post/lambda_function.py)

リポジトリのこのファイルを正とする。修正したら、Lambda コンソールの「コード」タブに貼り付けて「Deploy」する
(AWS 上のコードとずれないよう、両方を必ず一緒に更新する)。

- 種類 (`CATEGORIES`) の一覧は、アプリの `PostCategory` に合わせている。増やすときは両方を一緒に変える
- `table` を関数の外で作っているのは、Lambda が同じ実行環境を使い回すときに接続を再利用するため

## テストイベント

Lambda コンソールの「テスト」タブで使うイベント。`body` は文字列にした JSON。
コンソールのテストは JWT オーソライザーを通らないので、`requestContext` にユーザーの番号 (`sub`) を自分で書く。
その `sub` のプロフィールが `zero-chat-profiles` にないと 400 (`profile is required`) になる。

| イベント名 | `body` の中身 | 期待する結果 |
|---|---|---|
| `create` | `{"category": "dailyReport", "text": "テスト投稿"}` | 201、番号・投稿日時・プロフィールの `author` が付いた投稿 |
| `emptyText` | `{"category": "dailyReport", "text": "   "}` | 400、`text is required` |
| `unknownCategory` | `{"category": "foo", "text": "テスト投稿"}` | 400、`unknown category: foo` |
| `invalidJson` | `{` | 400、`body must be valid JSON` |

`create` のイベントの書き方の例:

```json
{
  "requestContext": { "authorizer": { "jwt": { "claims": { "sub": "<プロフィールがあるユーザーの sub>" } } } },
  "body": "{\"category\": \"dailyReport\", \"text\": \"テスト投稿\"}"
}
```

`create` を実行すると実際に投稿が保存され、タイムラインに表示される。不要なら DynamoDB から項目を削除する。

## 制限と今後の課題

- **`author.id` は常に `0`**: 名前・役職・色はプロフィールから決めるが、人を見分ける番号はまだ使っていない
- **編集・削除はできない**
- **TODO**: 投稿の `id` を連番から UUID に変え、番号を数える項目をなくす。詳しくは [posts-table.md](posts-table.md) の「TODO: 投稿の `id` を UUID にする」
- **文字数の数え方の違い**: Python の `len` は Unicode のコードポイント数を数える。
  アプリの入力欄は見た目の 1 文字 (書記素) で数えるので、複数のコードポイントでできた絵文字などでは数がずれる。
  アプリで 180 文字以内でも、サーバーで 400 になることがある
