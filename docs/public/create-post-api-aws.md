# 投稿作成 API を AWS (DynamoDB + Lambda + API Gateway) で作る手順

アプリの投稿画面から送られた投稿を保存する WebAPI を、投稿取得 API と同じサーバーレス構成で作る。
すでにある API とテーブルに、ルートと Lambda 関数を 1 組足す。

```
Flutter アプリ (投稿画面)
   │  POST /posts  {"category": "...", "text": "...", "author": {"name": "...", "role": "..."}}
   ▼
API Gateway (HTTP API: zero-chat-api)       … 既存の API にルートを 1 本足す
   ▼
Lambda (Python: zero-chat-create-post)      … 新しく作る
   │  UpdateItem (番号を 1 増やす) → PutItem (投稿を書き込む)
   ▼
DynamoDB (zero-chat-posts)                  … 既存のテーブルをそのまま使う
```

関連するドキュメント:

- 投稿取得 API の作成手順 (この手順の前提): [posts-api-aws.md](posts-api-aws.md)
- テーブルの項目・インデックスの定義: [posts-table.md](posts-table.md)
- Lambda 関数のリクエスト・レスポンスとコード: [create-post-lambda.md](create-post-lambda.md)
- アカウント ID・API の URL などの実際の値: [aws-resources.md](../private/aws-resources.md)

## 作成・変更したリソース

| サービス | 名前 | 補足 |
|---|---|---|
| DynamoDB テーブル | `zero-chat-posts` (既存) | 投稿の番号を数える項目 (`id: 0`) を追加 |
| Lambda 関数 | `zero-chat-create-post` (新規) | Python 3.13 |
| IAM ロール | Lambda 作成時に自動で作られたもの (新規) | DynamoDB の UpdateItem・PutItem を追加で許可 |
| API Gateway | `zero-chat-api` (既存) | ルート `POST /posts` を追加、CORS とスロットリングを設定 |

リージョンはすべて `ap-northeast-1` (東京)。
コンソール右上のリージョンが「東京」になっていることを確認してから作業する。

---

## 0. 設計で決めたこと

| 項目 | 決めたこと | 理由 |
|---|---|---|
| Lambda | 取得用とは**別の関数**にする | 取得用は読み取りの権限のままにでき、書き込みの権限は作成用だけに付けられる |
| 投稿の番号 (`id`) | テーブル内に番号を数える項目 (`id: 0`) を置き、投稿のたびに 1 増やす | `id` は数値のパーティションキーで、後から型を変えられない。同時に投稿されても番号が重ならない |
| 投稿日時 (`postedAt`) | **サーバー**で付ける | 端末の時計がずれていても、タイムラインの並び順が崩れない |
| 投稿した人 (`author`) | 名前と役職はアプリから受け取り、`author.id` は `0` に固定 | ログインの仕組みがまだないため。認証を入れたら、認証情報から決めるように変える |
| 入力チェック | サーバーでも行う (本文 1〜180 文字、名前 1〜30 文字、種類と役職は決まった値だけ) | アプリを通さずに直接 API を呼ばれても、おかしなデータを保存しないため |

> ⚠️ 認証がないので、URL を知っていれば誰でも投稿できる。
> 手順 3-3 でルートに送信回数の上限 (スロットリング) を付けて、いたずらによる大量の書き込みを抑える。

---

## 1. DynamoDB: 投稿の番号を数える項目を作る

**DynamoDB → テーブル → `zero-chat-posts` → 項目を探索 → 項目を作成 → JSON ビュー**
(「DynamoDB JSON を表示」はオフ)

```json
{ "id": 0, "lastPostId": 10 }
```

- `10` のところは、**今テーブルにある投稿の `id` の最大値**に置き換える。次の投稿はその次の番号になる
- 小さすぎる値を入れると、新しい投稿の番号が既存の投稿とぶつかり、作成が失敗する
  (Lambda は同じ番号の項目があると書き込まないので、既存の投稿が上書きされることはない)
- この項目は `feed` / `category` / `postedAt` を持たないので、どのインデックスにも載らず、タイムラインには出ない

項目の詳しい定義は [posts-table.md](posts-table.md) の「投稿の番号を数える項目」を参照。

---

## 2. Lambda 関数を作る

### 2-1. 関数を作成する

**Lambda → 関数 → 関数の作成 → 一から作成**

| 項目 | 値 |
|---|---|
| 関数名 | `zero-chat-create-post` |
| ランタイム | Python 3.13 |
| アーキテクチャ | 初期値のまま |
| 実行ロール | 基本的な Lambda アクセス権限で新しいロールを作成 |

### 2-2. コードを貼り付けてデプロイする

「コード」タブの `lambda_function.py` を、[lambda_function.py](../../Lambda/zero-chat-create-post/lambda_function.py) の内容に置き換えて
「Deploy」を押す。

### 2-3. 環境変数を設定する

**設定 → 環境変数 → 編集**

| キー | 値 |
|---|---|
| `TABLE_NAME` | `zero-chat-posts` |

### 2-4. DynamoDB に書き込む権限を付ける

自動で作られた実行ロールには、CloudWatch Logs にログを書く権限しかない。
番号の項目の更新と、投稿の書き込みを追加で許可する。

**設定 → アクセス権限 → ロール名のリンク** (IAM が開く)
**→ 許可を追加 → インラインポリシーを作成 → JSON**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["dynamodb:UpdateItem", "dynamodb:PutItem"],
      "Resource": "arn:aws:dynamodb:ap-northeast-1:<アカウントID>:table/zero-chat-posts"
    }
  ]
}
```

- 取得用の Lambda はインデックス (`.../index/*`) を指定したが、今回は**テーブル本体**を指定する
  (末尾に `/index/*` を付けない)。UpdateItem・PutItem はテーブル本体への操作のため
- `<アカウントID>` はハイフンなしの 12 桁の数字 (コンソール右上のアカウント名をクリックすると表示される)
- 許可しているのは**番号を増やす UpdateItem と、書き込む PutItem だけ**。削除や読み取りはできない (必要最小限の権限)

### 2-5. テストする

**「テスト」タブ → 新しいイベント** (イベント名 `create`)

```json
{
  "body": "{\"category\": \"dailyReport\", \"text\": \"Lambda からのテスト投稿\", \"author\": {\"name\": \"テスト\", \"role\": \"エンジニア\"}}"
}
```

- `body` は、API Gateway から届くときと同じく**文字列にした JSON** にする
- 「テスト」を押して `"statusCode": 201` と `post` が返れば成功
- DynamoDB の「項目を探索」で、投稿が 1 件増え、`id: 0` の項目の `lastPostId` が 1 増えていることも確認する
- テスト投稿はタイムラインに表示されるので、不要なら項目を削除する

ほかのテストイベント (入力が不正な場合など) は [create-post-lambda.md](create-post-lambda.md) を参照。

---

## 3. API Gateway にルートを足す

### 3-1. ルートを作る

**API Gateway → `zero-chat-api` → ルート → 作成**

| 項目 | 値 |
|---|---|
| メソッド | `POST` |
| パス | `/posts` |

### 3-2. Lambda をつなぐ

作った `POST /posts` を選ぶ → **統合をアタッチ → 統合を作成してアタッチ**

| 項目 | 値 |
|---|---|
| 統合タイプ | Lambda 関数 |
| Lambda 関数 | `zero-chat-create-post` |

- API Gateway から Lambda を呼ぶ権限は、統合を作ったときに自動で付く
- `$default` ステージの自動デプロイがオンなので、保存した時点で同じ URL から呼べるようになる

### 3-3. 送信回数に上限を付ける (スロットリング)

**保護 → スロットリング → ステージ `$default` → ルート `POST /posts` を編集**

| 項目 | 値の目安 | 意味 |
|---|---|---|
| レート制限 | `5` | 1 秒あたりに受け付けるリクエスト数 |
| バースト制限 | `10` | 一瞬に集中したときに受け付ける最大数 |

上限を超えたリクエストには、Lambda を呼ばずに API Gateway が `429 Too Many Requests` を返す。
認証がない間のいたずら対策と、料金が増えすぎないための保険。

### 3-4. CORS を設定する (Web 版から呼ぶため)

ブラウザで動く Web 版は、別のドメインの API を呼ぶときに CORS の許可が必要になる。
**CORS → 設定 (編集)** で、取得 API のときの設定に次を足す。

| 項目 | 値 |
|---|---|
| Access-Control-Allow-Origin | Web 版の CloudFront の URL、開発用の `http://localhost:8080` (取得 API で設定済み) |
| Access-Control-Allow-Methods | `GET`、**`POST`** (`POST` を追加) |
| Access-Control-Allow-Headers | **`content-type`** (追加) |

- JSON を POST するとき、ブラウザは本番のリクエストの前に「送ってよいか」の確認 (`OPTIONS` のプリフライト) を自動で送る。
  HTTP API は CORS の設定があれば `OPTIONS` に自動で答えるので、`OPTIONS` のルートを作る必要はない
- `content-type` を許可しないと、プリフライトで断られて Web 版からだけ投稿できなくなる
- iOS / Android などのアプリは CORS の対象外なので、この設定がなくても呼べる

---

## 4. 動作を確認する

`<API の URL>` は **API → ステージ → `$default`** の「呼び出し URL」(末尾の `/` は付けない)。

```bash
# 投稿を作成する (201 と作成した投稿が返る)
curl -i -X POST "<API の URL>/posts" \
  -H "Content-Type: application/json" \
  -d '{"category":"dailyReport","text":"curl からのテスト投稿","author":{"name":"テスト","role":"エンジニア"}}'

# 作成した投稿が先頭に出る
curl "<API の URL>/posts"

# 本文が空 (400 になる)
curl -i -X POST "<API の URL>/posts" \
  -H "Content-Type: application/json" \
  -d '{"category":"dailyReport","text":"","author":{"name":"テスト","role":"エンジニア"}}'
```

`HTTP/2 201` で作成した投稿が返り、`GET /posts` の先頭にその投稿が出れば完成。

---

## 5. アプリから呼ぶ

アプリ側は取得 API と同じベース URL (`config/api.json` の `API_BASE_URL`) を使うので、設定の追加はない。

| 層 | ファイル | 役割 |
|---|---|---|
| UI | `lib/ui/compose/compose_view_model.dart` | 「投稿する」で `createPost` を呼び、成功したらタイムラインを読み込み直す |
| Data | `lib/data/repositories/post/http_post_repository.dart` | `POST /posts` の本文を作り、返ってきた投稿を `Post` に変換する |
| Data | `lib/data/services/api/api_service.dart` | `postJson` で JSON を POST する (2xx 以外は `ApiException`) |

`config/api.json` を渡さずに起動したときは、仮データの `FakePostRepository` が投稿をメモリ上に保存する
(アプリを閉じると消える)。

---

## 公開範囲と今後の課題

- **認証なし**。URL を知っていれば誰でも投稿でき、名前と役職も自由に名乗れる。
  Cognito などで認証を付け、投稿した人を認証情報から決めるようにする
- 投稿した人の番号 (`author.id`) はすべて `0`。そのため、自分の投稿のアバターの色がヘッダーの色とそろわない
- 投稿の編集・削除はまだない
- **TODO**: 投稿の `id` を連番から UUID に変え、番号を数える項目をなくす。詳しくは [posts-table.md](posts-table.md) の「TODO: 投稿の `id` を UUID にする」
- 本文の文字数は、Python の文字数 (Unicode のコードポイント数) で数えている。
  絵文字の中には複数のコードポイントでできているものがあり、アプリの入力欄の数え方と少しずれることがある
