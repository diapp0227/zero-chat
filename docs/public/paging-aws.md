# タイムラインのページング (続きの 10 件の読み込み) を AWS に反映する手順

タイムラインを下までスクロールしたら、続きの 10 件を読み込めるようにする。
投稿取得 API (`GET /posts`) が、続きを読むための目印 `nextCursor` を返し、アプリは次のリクエストの `cursor` にそれを渡す。

```
Flutter アプリ (タイムライン)
   │  GET /posts                      → 最新の 10 件 + nextCursor
   │  GET /posts?cursor=<nextCursor>  → 続きの 10 件 + nextCursor (最後なら null)
   ▼
API Gateway (zero-chat-api) → Lambda (zero-chat-get-posts) → DynamoDB (zero-chat-posts)
```

関連するドキュメント:

- 投稿取得の Lambda の仕様 (目印の仕組みも): [get-posts-lambda.md](get-posts-lambda.md)

## 変更するリソース

| サービス | 名前 | 変更 |
|---|---|---|
| Lambda 関数 | `zero-chat-get-posts` | コードを差し替える |
| DynamoDB・API Gateway・権限 | (既存) | 変更なし |

---

## 0. 設計で決めたこと

| 項目 | 決めたこと | 理由 |
|---|---|---|
| 続きの指定 | DynamoDB の `LastEvaluatedKey` を文字列にした目印 (`cursor`) | 同じ時刻の投稿がページの境目にあっても、抜けたり重なったりしない |
| 目印の形 | JSON を URL に入れられる Base64 にした文字列 | アプリは中身を気にせず、そのまま返すだけでよい |
| 1 ページの件数 | 10 件 (今と同じ) | 読み取り量 (料金) とレスポンスの大きさを今と同じに保つ |
| 終わりの判定 | `nextCursor` が `null` なら最後 | |
| 不正な目印 | 400 (`invalid cursor`) | 手で作った目印で DynamoDB がエラーになり、500 になるのを防ぐ |

---

## 1. Lambda: 投稿取得のコードを差し替える

**Lambda → `zero-chat-get-posts`** の「コード」タブの `lambda_function.py` を、
[lambda_function.py](../../Lambda/zero-chat-get-posts/lambda_function.py) に置き換えて「Deploy」する。

- 環境変数・権限・API Gateway の変更はいらない
- `cursor` を付けないリクエストは今と同じ (最新の 10 件) なので、今のアプリもそのまま動く。
  レスポンスに `nextCursor` が増えるだけ

---

## 2. 動作を確認する

```bash
# 最新の 10 件と nextCursor が返る
curl "<API の URL>/posts" -H "Authorization: Bearer <アクセストークン>"

# 続きの 10 件 (<nextCursor> は上のレスポンスの値)
curl "<API の URL>/posts?cursor=<nextCursor>" -H "Authorization: Bearer <アクセストークン>"

# 壊れた目印は 400
curl -i "<API の URL>/posts?cursor=broken" -H "Authorization: Bearer <アクセストークン>"
```

アプリでは、投稿が 11 件以上あるときに、タイムラインを下までスクロールすると続きが出る。

---

## 3. アプリ側

| 層 | ファイル | 役割 |
|---|---|---|
| UI | `lib/ui/home/home_screen.dart` | 一覧の下端の近くまでスクロールしたら続きを読み込む。読み込み中・失敗の表示を一覧の一番下に出す |
| UI | `lib/ui/home/home_view_model.dart` | 読み込んだ投稿と `nextCursor` を持ち、`loadMore` で続きを足す |
| Data | `lib/data/repositories/post/http_post_repository.dart` | `cursor` を付けて `GET /posts` を呼び、`nextCursor` を受け取る |
