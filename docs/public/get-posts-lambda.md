# Lambda 関数の仕様: `zero-chat-get-posts`

タイムラインの投稿一覧を DynamoDB から取得して、新しい順に最大 10 件返す関数。
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
    }
  ]
}
```

テーブルの GSI への Query だけを許可している。書き込みやテーブル本体の読み取りはできない。

---

## API 仕様

### リクエスト

```
GET /posts
GET /posts?category=<種類>
```

| クエリパラメータ | 必須 | 値 | 説明 |
|---|---|---|---|
| `category` | - | `announcement` / `dailyReport` / `selfStudy` | 指定するとその種類の投稿だけ、省略するとすべての投稿を返す |

### レスポンス (200 OK)

投稿を `postedAt` の**新しい順**に、**最大 10 件**返す。該当する投稿がなければ `posts` は空のリスト。
11 件目より古い投稿は返さない。

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
  ]
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `posts` | 配列 | 投稿の一覧 (新しい順、最大 10 件) |
| `posts[].id` | 整数 | 投稿の番号 |
| `posts[].author` | オブジェクト | 投稿した人 (`id` 整数 / `name` 文字列 / `role` 文字列) |
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
- DynamoDB 内の検索用の属性 `feed` は返さない

### エラー

| ステータス | 条件 | ボディ |
|---|---|---|
| 400 Bad Request | `category` が 3 種類のどれでもない | `{"message": "unknown category: <値>"}` |
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
3. `ScanIndexForward=False` と `Limit=10` で Query する
   (ソートキー `postedAt` の降順 = 新しい順に並べ、先頭の 10 件だけを読む)
4. 各項目から、レスポンスに必要なフィールドだけを取り出す (`replies` がなければ空のリスト)
5. JSON にして 200 で返す。DynamoDB の数値は Python の `Decimal` で返ってくるので、`int` に変換する

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

## 制限と今後の課題

- **11 件目以降を取得できない**: 最新の 10 件より古い投稿を取る仕組み (ページング) はまだない。
  リクエストで「どこより古い投稿か」を指定できるようにする予定 (下のメモを参照)
- **認証なし**: URL を知っていれば誰でも呼べる
- `_to_json` は数値をすべて `int` にしている。小数を持つ属性を追加するときは変換を見直す

## メモ: 10 件より古い投稿の取得 (未実装)

検討中の案。実装するときに詳細を決める。

- リクエストで、前回受け取った**最後 (いちばん古い) の投稿の `postedAt`** を `before` として渡す
  - 例: `GET /posts?before=2026-10-14T09:00:00Z` / `GET /posts?category=dailyReport&before=...`
  - `before` なし = 今と同じ (最新の 10 件)
- Lambda では、Query のキー条件に `postedAt < before` を加える
  - 例: `Key("feed").eq("ALL") & Key("postedAt").lt(before)`
  - ソートキーの条件なので、`Limit=10` のまま「`before` より古い投稿を新しい順に 10 件」だけを読める
- アプリ側は、返ってきた件数が 10 件未満なら「これ以上古い投稿はない」と判断できる
  (ちょうど 10 件で終わっていた場合は、次のリクエストで 0 件が返る)
- `before` の形式チェック (ISO 8601 か) をして、おかしければ 400 を返す

### 未解決: 同じ時刻の投稿

`postedAt` が同じ投稿が 2 件以上あり、それがページの境目にまたがると、
`postedAt < before` では境目の時刻の残りの投稿が**取りこぼされる**
(`<=` にすると今度は**重複**する)。

対策の候補:

- インデックスのソートキーを `postedAt` と `id` をつないだ値 (例: `2026-10-14T09:00:00Z#00000002`) にし、
  `before` にもその値を渡す。同じ時刻でも `id` で順番が一意に決まる
- DynamoDB が返す `LastEvaluatedKey` (次に読み始める位置) を、そのまま次のリクエストに渡してもらう
  (日時ではなく、中身を意識しない文字列として扱う方式)
