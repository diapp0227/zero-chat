# 投稿取得 API を AWS (DynamoDB + Lambda + API Gateway) で作る手順

タイムラインの投稿一覧を返す WebAPI を、AWS のサーバーレス構成で作る。

```
Flutter アプリ
   │  GET /posts?category=dailyReport
   ▼
API Gateway (HTTP API: zero-chat-api)
   ▼
Lambda (Python: zero-chat-get-posts)
   │  Query
   ▼
DynamoDB (zero-chat-posts)
```

関連するドキュメント:

- テーブルの項目・インデックスの定義: [posts-table.md](posts-table.md)
- Lambda 関数のリクエスト・レスポンスとコード: [get-posts-lambda.md](get-posts-lambda.md)
- 投稿作成 API (`POST /posts`) の作成手順: [create-post-api-aws.md](create-post-api-aws.md)
- アカウント ID・API の URL などの実際の値: [aws-resources.md](../private/aws-resources.md)

## 作成したリソース

| サービス | 名前 | 補足 |
|---|---|---|
| DynamoDB テーブル | `zero-chat-posts` | オンデマンド、GSI 2 つ |
| Lambda 関数 | `zero-chat-get-posts` | Python 3.13 |
| IAM ロール | Lambda 作成時に自動で作られたもの | DynamoDB の Query を追加で許可 |
| API Gateway | `zero-chat-api` | HTTP API、ルート `GET /posts` |

リージョンはすべて `ap-northeast-1` (東京)。
コンソール右上のリージョンが「東京」になっていることを確認してから作業する。

---

## 0. 前提

- AWS アカウントは**無料プラン**。料金は請求されず、クレジット (USD) を使い切るか期限が来ると無料プランが終わる
  - 終わるとアカウントが閉鎖され、90 日以内に有料プランへ切り替えないとリソースとデータが削除される
  - クレジットの残高と期限は、Billing and Cost Management コンソールのホームで確認できる
- 今回の 3 サービスはどれも毎月の無料利用枠があり、開発中のアクセス量ならクレジットはほぼ減らない

---

## 1. DynamoDB テーブルを作る

### 1-1. テーブルを作成する

**DynamoDB → テーブル → テーブルの作成**

| 項目 | 値 |
|---|---|
| テーブル名 | `zero-chat-posts` |
| パーティションキー | `id` (数値) |
| ソートキー | なし |
| テーブル設定 | 設定をカスタマイズ |
| キャパシティモード | **オンデマンド** |

それ以外は初期値のまま「テーブルの作成」。ステータスが「アクティブ」になるまで待つ。

#### オンデマンドにした理由

| | オンデマンド | プロビジョンド |
|---|---|---|
| 料金 | 読み書きした回数だけ | 「1 秒あたり何回まで」の枠を先に決め、その枠に時間単位で払う |
| アクセスがないとき | 読み書きの料金はかからない | 使っていなくても枠の分かかる |
| 急なアクセス増 | 自動で処理できる | 枠を超えるとエラー (スロットリング) |
| 事前の設定 | 不要 | テーブルと GSI **それぞれ**に枠を決める |

開発中はアクセス量が読めず、GSI も 2 つあって枠の管理が手間になるため、オンデマンドにした。
この規模なら料金はほぼかからない。アクセスの傾向が安定したら、プロビジョンドのほうが安いか見直せばよい
(モードは後から切り替えられる)。

### 1-2. GSI (グローバルセカンダリインデックス) を 2 つ作る

**テーブル `zero-chat-posts` → 「インデックス」タブ → インデックスの作成**

| インデックス名 | パーティションキー | ソートキー | 属性の射影 |
|---|---|---|---|
| `feed-postedAt-index` | `feed` (文字列) | `postedAt` (文字列) | すべて |
| `category-postedAt-index` | `category` (文字列) | `postedAt` (文字列) | すべて |

- キー名を入力すると、インデックス名は `<パーティションキー>-<ソートキー>-index` の形で自動で入る。
  **キー名を打ち間違えるとインデックス名もずれる**ので、作成前に上の表と完全に一致しているか確認する
  (大文字・小文字も区別される)
- インデックス名は後から変えられない。間違えたら正しい名前で作り直し、間違った方は削除する
- 射影は「すべて」にする。そうしないと `text` や `author` が Query の結果に含まれない
- 作成直後は「作成中」。「アクティブ」になるまで数分待つ

インデックスを 2 つ作る理由は [posts-table.md](posts-table.md) を参照。

### 1-3. テストデータを入れる

**「項目を探索」→ 項目を作成 → JSON ビュー** (「DynamoDB JSON を表示」はオフ) で入力する。

```json
{
  "id": 2,
  "feed": "ALL",
  "category": "dailyReport",
  "postedAt": "2026-10-14T09:00:00Z",
  "text": "今日はチームでコードレビュー。\n小さな改善を積み重ねる時間が、プロダクトの強さにつながる。",
  "author": { "id": 2, "name": "いぬ", "role": "エンジニア" },
  "replies": [
    {
      "id": 3,
      "author": { "id": 5, "name": "くま", "role": "エンジニア" },
      "text": "意図まで共有するの、大切ですね！",
      "repliedAt": "2026-10-14T09:15:00Z"
    }
  ]
}
```

- `feed` は全投稿で `"ALL"` にする
- `category` は `announcement` / `dailyReport` / `selfStudy` のどれか
- `postedAt` は UTC の ISO 8601 形式 (`...Z`) で揃える
- `feed` / `category` / `postedAt` が文字列で入っていない項目は、インデックスに載らず API の結果に出てこない

---

## 2. Lambda 関数を作る

### 2-1. 関数を作成する

**Lambda → 関数 → 関数の作成 → 一から作成**

| 項目 | 値 |
|---|---|
| 関数名 | `zero-chat-get-posts` |
| ランタイム | Python 3.13 |
| アーキテクチャ | 初期値のまま |
| 実行ロール | 基本的な Lambda アクセス権限で新しいロールを作成 |

### 2-2. コードを貼り付けてデプロイする

「コード」タブの `lambda_function.py` を、[lambda_function.py](../../Lambda/zero-chat-get-posts/lambda_function.py) の内容に置き換えて
「Deploy」を押す。

### 2-3. 環境変数を設定する

**設定 → 環境変数 → 編集**

| キー | 値 |
|---|---|
| `TABLE_NAME` | `zero-chat-posts` |

### 2-4. DynamoDB を読む権限を付ける

自動で作られた実行ロールには、CloudWatch Logs にログを書く権限しかない。
GSI への Query を追加で許可する。

**設定 → アクセス権限 → ロール名のリンク** (IAM が開く)
**→ 許可を追加 → インラインポリシーを作成 → JSON**

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

- `<アカウントID>` はハイフンなしの 12 桁の数字 (コンソール右上のアカウント名をクリックすると表示される)
- リージョン・テーブル名が実際のものと 1 文字でも違うと、テスト時に `AccessDeniedException` になる
- 許可しているのは**GSI への Query だけ**。書き込みやテーブル全体の読み取りはできない (必要最小限の権限)

### 2-5. テストする

**「テスト」タブ → 新しいイベント**

イベント名 `dailyReport`:

```json
{ "queryStringParameters": { "category": "dailyReport" } }
```

イベント名 `all` (種類を指定しない場合):

```json
{}
```

「テスト」を押して `"statusCode": 200` と `posts` が返れば成功。

---

## 3. API Gateway を作る

**API Gateway → API を作成 → HTTP API → 構築**

| 手順 | 設定 |
|---|---|
| 統合 | 「統合を追加」→ Lambda → `zero-chat-get-posts` |
| API 名 | `zero-chat-api` |
| ルート | メソッド `GET`、リソースパス `/posts`、統合ターゲット `zero-chat-get-posts` |
| ステージ | `$default` (自動デプロイ ON) |

最後に「作成」。

- REST API ではなく HTTP API にしたのは、料金が安く設定も少なく、今回の用途ならこれで足りるため
- API Gateway から Lambda を呼ぶ権限は、統合を作ったときに自動で付く
- 作成後、**API → ステージ → `$default`** に「呼び出し URL」が表示される

---

## 4. 動作を確認する

`<API ID>` は呼び出し URL の `https://` の直後にある英数字 (API 一覧の「ID」列でも確認できる)。

```bash
# 全件 (新しい順)
curl "https://<API ID>.execute-api.ap-northeast-1.amazonaws.com/posts"

# 種類で絞り込み
curl "https://<API ID>.execute-api.ap-northeast-1.amazonaws.com/posts?category=dailyReport"

# 存在しない種類 (400 になる)
curl -i "https://<API ID>.execute-api.ap-northeast-1.amazonaws.com/posts?category=foo"
```

`{"posts": [...]}` が新しい順に最大 10 件返り、`category` で絞り込めていれば完成。

---

## API を増やすとき

新しい機能ごとに、**同じ `zero-chat-api` にルートと Lambda を 1 組ずつ足す**。

```
zero-chat-api
├─ GET  /posts               → zero-chat-get-posts     (この手順)
├─ POST /posts               → zero-chat-create-post   (作成済み: create-post-api-aws.md)
└─ POST /posts/{id}/replies  → zero-chat-create-reply  (例: 返信する)
```

1. Lambda を作り、その処理に必要な権限だけをロールに付ける
   (例: 投稿の作成なら、テーブル本体 `table/zero-chat-posts` への `dynamodb:UpdateItem` と `dynamodb:PutItem`)
2. **API Gateway → `zero-chat-api` → ルート → 作成** でメソッドとパスを決める
3. 作ったルートを選び「統合をアタッチ」で 1 の Lambda をつなぐ
4. 自動デプロイなので、同じ URL ですぐ呼べる

同じ API にまとめると、アプリ側はベース URL を 1 つ持つだけで済み、認証やスロットリングもまとめて設定できる。
ルートや Lambda が増えてきたら、AWS SAM や CDK で構成をコードにしてリポジトリで管理することを検討する。

---

## 公開範囲と今後の課題

- **認証なしの公開 API**。URL を知っていれば誰でも投稿を読める。本番前に Cognito などで認証を付ける
- 大量アクセスに備えて、**API Gateway → ステージ → スロットリング**で 1 秒あたりのリクエスト数に上限を付ける
- 1 回のリクエストで返すのは最新の 10 件まで。それより古い投稿を取るページングは未対応
