# Lambda 関数の仕様: `zero-chat-get-posts`

タイムラインの投稿一覧を DynamoDB から取得して、新しい順に 10 件ずつ返す関数。
続きの 10 件は、レスポンスの `nextCursor` を次のリクエストの `cursor` に渡して読む。
投稿・返信をした人 (`author`) は、`zero-chat-profiles` の**最新のプロフィール**で上書きして返す。
API Gateway の `GET /posts` から呼ばれる。

## 関数の設定

| 項目 | 値 |
|---|---|
| 関数名 | `zero-chat-get-posts` |
| リージョン | `ap-northeast-1` (東京) |
| ランタイム | Python 3.13 |
| ハンドラ | `lambda_function.lambda_handler` |
| メモリ | 128 MB (初期値) |
| タイムアウト | 3 秒 (初期値) |
| 呼び出し元 | API Gateway HTTP API `zero-chat-api` のルート `GET /posts` |

### 環境変数

| キー | 値 | 説明 |
|---|---|---|
| `TABLE_NAME` | `zero-chat-posts` | 読み取る DynamoDB テーブルの名前 |
| `PROFILES_TABLE_NAME` | `zero-chat-profiles` | 投稿・返信をした人の最新のプロフィールを読むテーブルの名前 |

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
      "Action": "dynamodb:Query",
      "Resource": "arn:aws:dynamodb:ap-northeast-1:<アカウントID>:table/zero-chat-posts/index/*"
    },
    {
      "Effect": "Allow",
      "Action": "dynamodb:BatchGetItem",
      "Resource": "arn:aws:dynamodb:ap-northeast-1:<アカウントID>:table/zero-chat-profiles"
    }
  ]
}
```

投稿テーブルの GSI への Query と、プロフィールテーブルのまとめ読み (BatchGetItem) だけを許可している。
書き込みや投稿テーブル本体の読み取りはできない。

---

## API 仕様

### リクエスト

```
GET /posts
GET /posts?category=<種類>
GET /posts?cursor=<前回の nextCursor>
GET /posts?category=<種類>&cursor=<前回の nextCursor>
```

| クエリパラメータ | 必須 | 値 | 説明 |
|---|---|---|---|
| `category` | - | `announcement` / `dailyReport` / `selfStudy` | 指定するとその種類の投稿だけ、省略するとすべての投稿を返す |
| `cursor` | - | 前回のレスポンスの `nextCursor` | 指定すると、前回のページの続き (それより古い投稿) を返す。省略すると最新の 10 件。`category` は前回と同じ値にする |

### レスポンス (200 OK)

投稿を `postedAt` の**新しい順**に、**最大 10 件**返す。該当する投稿がなければ `posts` は空のリスト。
続きがあれば `nextCursor` に目印の文字列が入り、なければ `null`。

```json
{
  "posts": [
    {
      "id": 2,
      "author": { "id": 2, "name": "いぬ", "role": "エンジニア" },
      "category": "dailyReport",
      "text": "今日はチームでコードレビュー。\n小さな改善を積み重ねる時間が、プロダクトの強さにつながる。",
      "postedAt": "2026-10-14T09:00:00Z",
      "replies": [
        {
          "id": 3,
          "author": { "id": 5, "name": "くま", "role": "エンジニア" },
          "text": "意図まで共有するの、大切ですね！",
          "repliedAt": "2026-10-14T09:15:00Z"
        }
      ]
    }
  ],
  "nextCursor": "eyJpZCI6MiwiZmVlZCI6IkFMTCIsInBvc3RlZEF0IjoiMjAyNi0xMC0xNFQwOTowMDowMFoifQ"
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `posts` | 配列 | 投稿の一覧 (新しい順、最大 10 件) |
| `nextCursor` | 文字列 / `null` | 続きを読むための目印。次のリクエストの `cursor` にそのまま渡す。最後のページなら `null` |
| `posts[].id` | 整数 | 投稿の番号 |
| `posts[].author` | オブジェクト | 投稿した人 (`id` 整数 / `name` 文字列 / `role` 文字列 / `color1`・`color2` 文字列 `#RRGGBB`)。API で作った投稿は最新のプロフィールの値。`color1`・`color2` は、プロフィールから作った投稿だけにある |
| `posts[].category` | 文字列 | 投稿の種類 |
| `posts[].text` | 文字列 | 本文 |
| `posts[].postedAt` | 文字列 | 投稿日時 (UTC、ISO 8601) |
| `posts[].replies` | 配列 | 返信の一覧。なければ空の配列 |
| `posts[].replies[].id` | 整数 | 返信の番号 |
| `posts[].replies[].author` | オブジェクト | 返信した人 (形は `author` と同じ) |
| `posts[].replies[].text` | 文字列 | 本文 |
| `posts[].replies[].repliedAt` | 文字列 | 返信日時 (UTC、ISO 8601) |

- ヘッダーは `Content-Type: application/json; charset=utf-8`
- 日本語はエスケープせずそのまま返す (`ensure_ascii=False`)
- DynamoDB 内の検索用の属性 `feed` と、`author.userId` (Cognito の `sub`) は返さない

### エラー

| ステータス | 条件 | ボディ |
|---|---|---|
| 400 Bad Request | `category` が 3 種類のどれでもない | `{"message": "unknown category: <値>"}` |
| 400 Bad Request | `cursor` が読めない、または別の一覧 (違う `category`) の目印 | `{"message": "invalid cursor"}` |
| 500 Internal Server Error | DynamoDB の読み取りに失敗したなど、関数内で例外が起きた | `{"message": "Internal Server Error"}` (API Gateway が返す) |

500 のときの詳しい原因は、Lambda の「モニタリング → CloudWatch ログ」で確認する。

---

## 処理の流れ

1. `queryStringParameters` から `category` を取り出す
   (クエリパラメータがないと `queryStringParameters` 自体が来ないので、空の辞書として扱う)
2. 使うインデックスを決める
   - `category` なし → `feed-postedAt-index` を `feed = "ALL"` で Query
   - `category` が 3 種類のどれか → `category-postedAt-index` を `category = <値>` で Query
   - それ以外 → 400 を返して終わる
3. `cursor` があれば、目印を `ExclusiveStartKey` (この次から読む位置) に戻す。読めなければ 400
4. `ScanIndexForward=False` と `Limit=10` で Query する
   (ソートキー `postedAt` の降順 = 新しい順に並べ、`ExclusiveStartKey` の次から 10 件だけを読む)
5. 投稿・返信の `author.userId` を集め、`zero-chat-profiles` を `BatchGetItem` でまとめて読む
   (1 回に 100 人まで。読み切れなかったキー `UnprocessedKeys` が返ってきたら読み直す)
6. 各項目から、レスポンスに必要なフィールドだけを取り出す (`replies` がなければ空のリスト)。
   `author` は、プロフィールが見つかればその `name`・`role`・`color1`・`color2` で上書きし、`userId` を消す
7. Query の結果に `LastEvaluatedKey` (次に読み始める位置) があれば、それを `nextCursor` にする
8. JSON にして 200 で返す。DynamoDB の数値は Python の `Decimal` で返ってくるので、`int` に変換する

## コード

[Lambda/zero-chat-get-posts/lambda_function.py](../../Lambda/zero-chat-get-posts/lambda_function.py)

リポジトリのこのファイルを正とする。修正したら、Lambda コンソールの「コード」タブに貼り付けて「Deploy」する
(AWS 上のコードとずれないよう、両方を必ず一緒に更新する)。

- `boto3` は Lambda の Python ランタイムに最初から入っているので、追加のパッケージは不要
- `table` を関数の外で作っているのは、Lambda が同じ実行環境を使い回すときに接続を再利用するため
- `Limit` は「DynamoDB が読む件数」の上限。新しい順に並んだインデックスの先頭から 10 件だけを読むので、
  投稿が何件あっても、読み取り量 (料金) とレスポンスの大きさは 10 件分で済む。
  `FilterExpression` を使っていないので、条件に合う投稿が 10 件以上あれば必ず 10 件返る

## テストイベント

Lambda コンソールの「テスト」タブで使うイベント。

| イベント名 | 内容 | 期待する結果 |
|---|---|---|
| `all` | `{}` | 200、全投稿のうち新しい順に最大 10 件 |
| `dailyReport` | `{"queryStringParameters": {"category": "dailyReport"}}` | 200、日報だけを新しい順に最大 10 件 |
| `unknownCategory` | `{"queryStringParameters": {"category": "foo"}}` | 400 |

### 最新のプロフィールで表示する理由

投稿・返信を作るときにも名前・役職・カラーをコピーして保存しているが、それだけではプロフィールを変えても
過去の投稿・返信が昔のままになる。取得するときに最新のプロフィールで上書きすれば、
投稿テーブルを書き換えずに、いつも今のプロフィールで表示できる。

- 上書きできるのは `author.userId` がある投稿・返信だけ (作成 API が保存するようになった後に作ったもの)。
  それより前のものは、保存してある値のまま表示する
- プロフィールが見つからない人 (プロフィールを消したなど) も、保存してある値のまま表示する
- 1 回の取得で読むプロフィールは、表示する投稿・返信の人数分だけ (同じ人は 1 回)

### 続きの目印 (`cursor`) の仕組み

DynamoDB の Query は、`Limit` 件で読むのを止めたとき、「次に読み始める位置」(`LastEvaluatedKey`) を返す。
中身は、最後に読んだ投稿のテーブルのキーとインデックスのキー (例: `{"id": 2, "feed": "ALL", "postedAt": "..."}`)。
これを JSON にして、URL に入れられる Base64 (`-` と `_` を使う形、末尾の `=` なし) にしたものが `nextCursor`。

- 次のリクエストで `ExclusiveStartKey` に渡すと、その投稿の**次から**読むので、同じ時刻の投稿がページの境目にあっても
  抜けたり重なったりしない (日時で「これより古い」と指定する方式では、同じ時刻の投稿が抜ける)
- アプリは中身を気にせず、受け取った文字列をそのまま返すだけでよい
- ちょうど 10 件で終わったときも `nextCursor` が入る (DynamoDB は続きがあるかを読むまで知らないため)。
  その次のリクエストは 0 件・`nextCursor: null` になる
- 手で作った目印で DynamoDB がエラー (500) にならないよう、キーの組み合わせと、
  `feed` / `category` が今の一覧と同じかを確かめ、違えば 400 を返す
- 目印にはプロフィールの `userId` などは入らない (投稿の番号・種類・日時だけ)

## 制限と今後の課題

- 途中に新しい投稿が増えても、読み込み済みのページには出てこない。アプリは投稿・返信の後などに、先頭から読み直す
- `_to_json` は数値をすべて `int` にしている。小数を持つ属性を追加するときは変換を見直す
