# 投稿・返信を最新のプロフィールで表示する手順

プロフィール (名前・役職・カラー) を変えたら、過去の投稿・返信もその内容で表示されるようにする。
投稿テーブルは書き換えず、**取得するときに最新のプロフィールを読んで上書きする**。

```
投稿作成・返信作成 (POST /posts・POST /posts/{id}/replies)
   │  author に userId (トークンの sub) も保存する
   ▼
DynamoDB (zero-chat-posts)
   ▲
   │  Query (投稿 10 件) → BatchGetItem (表示する人のプロフィール)
投稿取得 (GET /posts)                        … author を最新のプロフィールで上書きして返す
```

関連するドキュメント:

- 投稿取得の Lambda の仕様: [get-posts-lambda.md](get-posts-lambda.md)
- 投稿作成・返信作成の Lambda の仕様: [create-post-lambda.md](create-post-lambda.md)・[create-reply-lambda.md](create-reply-lambda.md)
- テーブルの定義: [posts-table.md](posts-table.md)・[profiles-table.md](profiles-table.md)
- 返信 API の作成手順 (この手順の前提): [reply-api-aws.md](reply-api-aws.md)

## 変更するリソース

| サービス | 名前 | 変更 |
|---|---|---|
| Lambda 関数 | `zero-chat-create-post` | コードを差し替え (`author.userId` を保存する) |
| Lambda 関数 | `zero-chat-create-reply` | コードを差し替え (`author.userId` を保存する) |
| Lambda 関数 | `zero-chat-get-posts` | コードを差し替え、環境変数と権限を追加 |
| DynamoDB・API Gateway | (既存) | 変更なし |

リージョンはすべて `ap-northeast-1` (東京)。アプリの変更は不要 (レスポンスの形は今と同じ)。

---

## 0. 設計で決めたこと

| 項目 | 決めたこと | 理由 |
|---|---|---|
| 最新にする方法 | 取得するときにプロフィールを読んで上書きする | プロフィールを変えたときに、投稿・返信を探して書き換える処理がいらない。書き換えの途中で失敗して新旧が混ざる心配もない |
| 誰の投稿・返信か | `author.userId` に Cognito の `sub` を保存する | プロフィールのテーブルのキーと同じ値なので、そのまま読める |
| プロフィールの読み方 | 表示する人をまとめて `BatchGetItem` で 1 回 (100 人ごと) | 投稿・返信ごとに 1 回ずつ読むより速く、料金も同じ |
| `sub` の扱い | レスポンスに含めない | ユーザーを見分ける値なので、アプリには渡さずサーバーの中だけで使う |
| 古い投稿・返信 | `userId` がないので、保存してある値のまま表示する | 誰のものかわからないため。必要なら DynamoDB で `author.userId` を手で足せば最新になる |

---

## 1. Lambda: 投稿作成・返信作成のコードを差し替える

**Lambda → `zero-chat-create-post`** と **`zero-chat-create-reply`** で、「コード」タブの `lambda_function.py` を次の内容に置き換えて「Deploy」する。
環境変数・権限の変更はいらない。

- [Lambda/zero-chat-create-post/lambda_function.py](../../Lambda/zero-chat-create-post/lambda_function.py)
- [Lambda/zero-chat-create-reply/lambda_function.py](../../Lambda/zero-chat-create-reply/lambda_function.py)

この後に作った投稿・返信から、DynamoDB の `author` に `userId` が入る。

---

## 2. Lambda: 投稿取得の関数を直す

**Lambda → `zero-chat-get-posts`**

1. **設定 → 環境変数** に追加 (**コードより先に**行う)

   | キー | 値 |
   |---|---|
   | `PROFILES_TABLE_NAME` | `zero-chat-profiles` |

2. **設定 → アクセス権限 → ロール名** で、既存のインラインポリシーを
   [get-posts-lambda.md](get-posts-lambda.md) の「実行ロールの権限」の JSON に置き換える
   (`zero-chat-profiles` の `dynamodb:BatchGetItem` を追加)
3. 「コード」タブの `lambda_function.py` を [lambda_function.py](../../Lambda/zero-chat-get-posts/lambda_function.py) に置き換えて「Deploy」

- 環境変数を足す前にコードを Deploy すると、`PROFILES_TABLE_NAME` がなくて**タイムラインが 500 で読めなくなる**。
  環境変数の値のつづり (`zero-chat-profiles`) も、テーブル名と 1 文字も違わないか確かめる
- 権限を足し忘れると、`userId` のある投稿・返信が 1 件でもあれば、プロフィールを読めずに 500 になる
  (ログに `AccessDeniedException`)

---

## 3. 動作を確認する

1. アプリで投稿か返信を 1 件作る (`author.userId` が保存される)
2. プロフィール設定で、名前かカラーを変えて保存する
3. タイムラインを読み込み直し、1 の投稿・返信が新しい名前・カラーで表示されれば完成

DynamoDB の `zero-chat-posts` では、1 の項目の `author` に `userId` が入り、名前・カラーは作ったときのままになっている
(表示だけが最新になる)。

## 公開範囲と今後の課題

- `userId` を保存する前に作った投稿・返信は、プロフィールを変えても表示が変わらない
- タイムラインを読むたびにプロフィールも読むので、読み取りの料金は少し増える (表示する人数分)
