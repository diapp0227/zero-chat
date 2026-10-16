# 返信 API を作り、投稿の author にカラーを付ける手順

投稿への返信を保存する API を作る。あわせて、投稿作成 API も返信と同じく、
投稿した人 (名前・役職・カラー) をトークンの `sub` で読んだプロフィールから決めるように変える。

```
Flutter アプリ (返信画面)
   │  POST /posts/{id}/replies  {"text": "..."}
   │  Authorization: Bearer <アクセストークン>
   ▼
API Gateway (HTTP API: zero-chat-api)       … ルートを 1 本足し、オーソライザー zero-chat-cognito を付ける
   ▼
Lambda (zero-chat-create-reply)             … 新しく作る
   │  GetItem (プロフィール) → GetItem (投稿) → UpdateItem (replies に書き足す)
   ▼
DynamoDB (zero-chat-profiles / zero-chat-posts)  … 既存のテーブルをそのまま使う
```

関連するドキュメント:

- 返信作成の Lambda の仕様: [create-reply-lambda.md](create-reply-lambda.md)
- 投稿作成の Lambda の仕様 (今回変更): [create-post-lambda.md](create-post-lambda.md)
- テーブルの定義: [posts-table.md](posts-table.md)・[profiles-table.md](profiles-table.md)
- プロフィール API の作成手順 (この手順の前提): [profile-api-aws.md](profile-api-aws.md)

## 作成・変更するリソース

| サービス | 名前 | 補足 |
|---|---|---|
| Lambda 関数 | `zero-chat-create-reply` (新規) | Python 3.13 |
| Lambda 関数 | `zero-chat-create-post` (既存) | コードを差し替え、環境変数と権限を追加 |
| API Gateway | `zero-chat-api` (既存) | ルート `POST /posts/{id}/replies` を追加し、オーソライザーを付ける |
| DynamoDB | `zero-chat-posts`・`zero-chat-profiles` (既存) | 変更なし |

リージョンはすべて `ap-northeast-1` (東京)。

---

## 0. 設計で決めたこと

| 項目 | 決めたこと | 理由 |
|---|---|---|
| 保存場所 | 投稿の項目の `replies` (リスト) に書き足す | 今のテーブルの形のまま。返信は投稿と一緒に表示するだけなので、1 回の読み取りで取れるほうが簡単 |
| URL | `POST /posts/{id}/replies` | どの投稿への返信かを URL で表す |
| 返信した人・投稿した人 | アプリからは送らず、トークンの `sub` でプロフィールを読んで決める | 他人の名前で返信・投稿できないようにする。今日作ったプロフィールをそのまま使える |
| カラー | `author` に `color1`・`color2` をコピーして保存する | アバターを、その人が選んだ色で表示するため |
| 返信の番号 | 投稿の中で「今ある返信の番号の最大値 + 1」。保存の条件で、間に返信が入っていないかを確かめる | 番号を数える項目を増やさずに、重ならない番号を付けられる |

---

## 1. Lambda: 返信作成の関数を作る

**Lambda → 関数 → 関数の作成 → 一から作成**

| 項目 | 値 |
|---|---|
| 関数名 | `zero-chat-create-reply` |
| ランタイム | Python 3.13 |
| 実行ロール | 基本的な Lambda アクセス権限で新しいロールを作成 |

1. 「コード」タブの `lambda_function.py` を [lambda_function.py](../../Lambda/zero-chat-create-reply/lambda_function.py) に置き換えて「Deploy」
2. **設定 → 環境変数** に次の 2 つを追加

   | キー | 値 |
   |---|---|
   | `POSTS_TABLE_NAME` | `zero-chat-posts` |
   | `PROFILES_TABLE_NAME` | `zero-chat-profiles` |

3. **設定 → アクセス権限 → ロール名 → 許可を追加 → インラインポリシーを作成 → JSON** に、
   [create-reply-lambda.md](create-reply-lambda.md) の「実行ロールの権限」の JSON を貼る (`<アカウントID>` を置き換える)
4. [create-reply-lambda.md](create-reply-lambda.md) の「テストイベント」で試す

---

## 2. Lambda: 投稿作成の関数を直す

**Lambda → `zero-chat-create-post`**

1. 「コード」タブの `lambda_function.py` を [lambda_function.py](../../Lambda/zero-chat-create-post/lambda_function.py) に置き換えて「Deploy」
2. **設定 → 環境変数** に追加

   | キー | 値 |
   |---|---|
   | `PROFILES_TABLE_NAME` | `zero-chat-profiles` |

3. **設定 → アクセス権限 → ロール名** で、既存のインラインポリシーに `zero-chat-profiles` の `GetItem` を足す
   ([create-post-lambda.md](create-post-lambda.md) の「実行ロールの権限」の JSON に置き換える)

- 環境変数を足す前に Deploy すると、`PROFILES_TABLE_NAME` がなくて投稿の作成が 500 になる。
  コードの差し替えと環境変数の追加は続けて行う
- 権限を足し忘れると、プロフィールを読めずに 500 になる (ログに `AccessDeniedException`)
- この変更の後は、プロフィールを保存していない人は投稿できない (400 `profile is required`)

---

## 3. API Gateway: ルートを足す

**API Gateway → `zero-chat-api` → ルート → 作成**

| 項目 | 値 |
|---|---|
| メソッド | `POST` |
| パス | `/posts/{id}/replies` |

1. 作ったルートに **統合をアタッチ → 統合を作成してアタッチ** で Lambda 関数 `zero-chat-create-reply` をつなぐ
2. **認可 → 「ルートにオーソライザーをアタッチする」** で `zero-chat-cognito` を付ける
3. (任意) **保護 → スロットリング** で、`POST /posts` と同じくレート `5`・バースト `10` 程度にする

- パスの `{id}` は、Lambda の `event.pathParameters.id` に文字列で届く
- CORS は `POST` を許可済み (投稿作成 API で設定) なので、変更はいらない

---

## 4. 動作を確認する

```bash
# 投稿 1 に返信する (201 と返信が返る)
curl -i -X POST "<API の URL>/posts/1/replies" \
  -H "Authorization: Bearer <アクセストークン>" \
  -H "Content-Type: application/json" \
  -d '{"text":"curl からのテスト返信"}'

# 返信が投稿の replies の最後に出る
curl "<API の URL>/posts" -H "Authorization: Bearer <アクセストークン>"

# 投稿を作ると、author にプロフィールの名前・役職・カラーが入る
curl -i -X POST "<API の URL>/posts" \
  -H "Authorization: Bearer <アクセストークン>" \
  -H "Content-Type: application/json" \
  -d '{"category":"dailyReport","text":"curl からのテスト投稿"}'
```

---

## 5. アプリ側

| 層 | ファイル | 役割 |
|---|---|---|
| UI | `lib/ui/home/widgets/post_cell.dart` | 「返信する」を押すと返信画面を開く |
| UI | `lib/ui/reply/reply_screen.dart` | 返信画面 (返信先の投稿・入力欄・文字数) |
| UI | `lib/ui/reply/reply_view_model.dart` | 返信を送り、成功したらタイムラインを読み込み直す |
| UI | `lib/ui/home/home_view_model.dart` | `author` にカラーがあればその色、なければ番号から決めた色でアバターを描く |
| Data | `lib/data/repositories/post/http_post_repository.dart` | `POST /posts/{id}/replies` を呼び、`author` のカラーを読む |

- **作業の順番**: アプリより先に、このページの手順 1〜3 を済ませる。
  先にアプリを出すと、返信の送信が API Gateway の 404 になり失敗する (画面にはメッセージが出る)
- 投稿作成の Lambda を直す前のアプリも、本文と種類を送っているのでそのまま投稿できる (送ってくる `author` は使わない)
