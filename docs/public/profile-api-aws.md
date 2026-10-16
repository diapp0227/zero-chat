# プロフィール API を AWS (DynamoDB + Lambda + API Gateway) で作る手順

サインインした人のプロフィール (ユーザー名・役職・カラー1・カラー2) をサーバーに保存し、
Cognito のユーザーと結び付ける。新しいテーブルと Lambda 関数 2 つを作り、既存の API にルートを 2 本足す。

```
Flutter アプリ
   │  GET /profile                 … タイムラインを開いたとき・プロフィール設定画面を開いたとき
   │  PUT /profile {name, role, color1, color2}  … サインアップの完了時・プロフィール設定の「保存」
   │  Authorization: Bearer <アクセストークン>
   ▼
API Gateway (HTTP API: zero-chat-api)       … JWT オーソライザー zero-chat-cognito でトークンを確認
   ▼
Lambda (zero-chat-get-profile / zero-chat-update-profile)
   │  トークンの sub を userId にして GetItem / PutItem
   ▼
DynamoDB (zero-chat-profiles)
```

関連するドキュメント:

- テーブルの定義: [profiles-table.md](profiles-table.md)
- Lambda 関数のリクエスト・レスポンスとコード: [profile-lambda.md](profile-lambda.md)
- JWT オーソライザーの作り方 (この手順の前提): [api-jwt-auth-aws.md](api-jwt-auth-aws.md)
- アカウント ID・API の URL などの実際の値: [aws-resources.md](../private/aws-resources.md)

## 作成・変更するリソース

| サービス | 名前 | 補足 |
|---|---|---|
| DynamoDB テーブル | `zero-chat-profiles` (新規) | パーティションキー `userId` (文字列) |
| Lambda 関数 | `zero-chat-get-profile` (新規) | Python 3.13。GetItem だけ許可 |
| Lambda 関数 | `zero-chat-update-profile` (新規) | Python 3.13。PutItem だけ許可 |
| API Gateway | `zero-chat-api` (既存) | ルート `GET /profile`・`PUT /profile` を追加し、オーソライザー `zero-chat-cognito` を付ける。CORS に `PUT` を追加 |

リージョンはすべて `ap-northeast-1` (東京)。

---

## 0. 設計で決めたこと

| 項目 | 決めたこと | 理由 |
|---|---|---|
| テーブル | 投稿とは**別のテーブル** `zero-chat-profiles` | 投稿のテーブルはキーが数値の `id` で、インデックスもタイムライン用。1 人 1 項目のプロフィールとは読み方が違う |
| キー | Cognito の `sub` (`userId`) | ユーザーごとに一意で変わらない。メールアドレスは変更できるのでキーにしない |
| URL | `/profile` (ユーザーの番号を URL に入れない) | 自分のプロフィールしか扱わない。誰のものかはトークンの `sub` で決めるので、他人のものを読み書きできない |
| 更新のメソッド | `PUT` (丸ごと置き換え) | 項目が名前・役職・カラー 2 つだけなので、毎回すべて送るほうが簡単。何度送っても同じ結果になる |
| カラー | `color1`・`color2` を `#RRGGBB` の文字列で 1 人分の項目に持つ | Figma のプロフィール設定のカラー1・カラー2 と同じ形。コンソールで見ても色がわかる |
| Lambda | 取得用と更新用で**別の関数** | 投稿 API と同じく、読み取り用には書き込みの権限を付けずに済む |
| まだ保存していないとき | `GET` は 404 | アプリは「プロフィールなし」として扱い、エラーにしない |
| 入力チェック | サーバーでも行う (名前 1〜30 文字、役職は決まった値だけ、カラーは `#RRGGBB`) | アプリを通さずに API を呼ばれても、おかしなデータを保存しないため |

---

## 1. DynamoDB: テーブルを作る

**DynamoDB → テーブル → テーブルの作成**

| 項目 | 値 |
|---|---|
| テーブル名 | `zero-chat-profiles` |
| パーティションキー | `userId` (文字列) |
| ソートキー | なし |
| テーブル設定 | 設定をカスタマイズ → キャパシティモード **オンデマンド** |

インデックスは作らない。

---

## 2. Lambda 関数を作る (2 つ)

次の 2-1〜2-4 を、表の 2 つの関数それぞれで行う。

| 関数名 | コード | インラインポリシーの Action |
|---|---|---|
| `zero-chat-get-profile` | [lambda_function.py](../../Lambda/zero-chat-get-profile/lambda_function.py) | `dynamodb:GetItem` |
| `zero-chat-update-profile` | [lambda_function.py](../../Lambda/zero-chat-update-profile/lambda_function.py) | `dynamodb:PutItem` |

### 2-1. 関数を作成する

**Lambda → 関数 → 関数の作成 → 一から作成**

| 項目 | 値 |
|---|---|
| 関数名 | 上の表の関数名 |
| ランタイム | Python 3.13 |
| 実行ロール | 基本的な Lambda アクセス権限で新しいロールを作成 |

### 2-2. コードを貼り付けてデプロイする

「コード」タブの `lambda_function.py` を、上の表のファイルの内容に置き換えて「Deploy」を押す。

### 2-3. 環境変数を設定する

**設定 → 環境変数 → 編集**

| キー | 値 |
|---|---|
| `TABLE_NAME` | `zero-chat-profiles` |

### 2-4. DynamoDB の権限を付ける

**設定 → アクセス権限 → ロール名のリンク → 許可を追加 → インラインポリシーを作成 → JSON**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "<上の表の Action>",
      "Resource": "arn:aws:dynamodb:ap-northeast-1:<アカウントID>:table/zero-chat-profiles"
    }
  ]
}
```

- 取得用には `GetItem` だけ、更新用には `PutItem` だけを許可する (必要最小限の権限)
- テーブル本体への操作なので、`Resource` の末尾に `/index/*` は付けない

### 2-5. テストする

[profile-lambda.md](profile-lambda.md) の「テストイベント」で、`zero-chat-update-profile` → `zero-chat-get-profile` の順に試す。
コンソールのテストは JWT オーソライザーを通らないので、イベントの `requestContext` にユーザーの番号を自分で書く。
終わったら DynamoDB の `test-user` の項目を削除する。

---

## 3. API Gateway にルートを足す

### 3-1. ルートを作って Lambda をつなぐ

**API Gateway → `zero-chat-api` → ルート → 作成** を 2 回行い、それぞれに **統合をアタッチ → 統合を作成してアタッチ** で Lambda をつなぐ。

| メソッド | パス | 統合する Lambda 関数 |
|---|---|---|
| `GET` | `/profile` | `zero-chat-get-profile` |
| `PUT` | `/profile` | `zero-chat-update-profile` |

### 3-2. オーソライザーを付ける (必須)

**認可 → 「ルートにオーソライザーをアタッチする」タブ**

| ルート | オーソライザー |
|---|---|
| `GET /profile` | `zero-chat-cognito` |
| `PUT /profile` | `zero-chat-cognito` |

付け忘れると、Lambda にトークンの中身が届かず 401 になる (DynamoDB には触らない)。

### 3-3. CORS に PUT を足す (Web 版から呼ぶため)

**CORS → 設定 (編集)**

| 項目 | 値 |
|---|---|
| Access-Control-Allow-Methods | `GET`・`POST` に加えて **`PUT`** |

許可するオリジン・ヘッダー (`content-type`・`authorization`) はそのまま。
`PUT` を許可しないと、Web 版だけプロフィールを保存できなくなる (iOS・Android は CORS の対象外)。

### 3-4. 送信回数に上限を付ける (任意)

**保護 → スロットリング → ステージ `$default` → ルート `PUT /profile` を編集** で、
`POST /posts` と同じくレート `5`・バースト `10` 程度にしておく。

---

## 4. 動作を確認する

`<API の URL>` は **API → ステージ → `$default`** の「呼び出し URL」。
`<アクセストークン>` の取り出し方は [api-jwt-auth-aws.md](api-jwt-auth-aws.md) の「動作を確認する」を参照。

```bash
# まだ保存していなければ 404
curl -i "<API の URL>/profile" -H "Authorization: Bearer <アクセストークン>"

# 保存する (200 と保存したプロフィールが返る)
curl -i -X PUT "<API の URL>/profile" \
  -H "Authorization: Bearer <アクセストークン>" \
  -H "Content-Type: application/json" \
  -d '{"name":"テスト","role":"エンジニア","color1":"#E8BD79","color2":"#B87947"}'

# 保存した内容が返る
curl -i "<API の URL>/profile" -H "Authorization: Bearer <アクセストークン>"

# トークンなしは 401
curl -i "<API の URL>/profile"
```

DynamoDB の `zero-chat-profiles` に、`userId` がユーザープールのユーザーの `sub` と同じ項目ができていれば完成
(Cognito → ユーザープール → ユーザー の「ユーザー ID (sub)」と見比べる)。

---

## 5. アプリ側

アプリは投稿 API と同じベース URL (`config/api.json` の `API_BASE_URL`) とアクセストークンを使うので、設定の追加はない。

| 層 | ファイル | 役割 |
|---|---|---|
| UI | `lib/ui/profile/current_profile.dart` | `load` で取得、`save` で保存してから画面のプロフィールを書き換える。サインアウトで空に戻す |
| UI | `lib/ui/home/home_screen.dart` | タイムラインを開いたときに `load` する |
| UI | `lib/ui/profile/profile_settings_screen.dart` | 開いたときに `load`、「保存」で `save` する。失敗したらメッセージを出して画面を閉じない |
| UI | `lib/ui/auth/auth_view_model.dart` | サインアップの確認が済んでサインインしたら、入力したユーザー名・役職を `save` する |
| Data | `lib/data/repositories/profile/http_profile_repository.dart` | `GET /profile`・`PUT /profile` を呼び、`Profile` に変換する。404 は null にする |
| Data | `lib/data/services/api/api_service.dart` | `putJson` で JSON を PUT する |

- `config/api.json` を渡さずに起動したときは、`FakeProfileRepository` がメモリ上に保存する (アプリを閉じると消える)
- サインアップ時は、カラーに決まった色 (`#E8BD79`・`#B87947`) を入れて保存する。プロフィール設定の「保存」は、今のカラーをそのまま送る
- サインアップ時の保存に失敗しても、サインインは済んでいるのでホームへ進む。
  プロフィールは画面にだけ反映されるので、プロフィール設定画面から保存し直す
- **作業の順番**: アプリより先に、このページの手順 1〜3 を済ませる。
  先にアプリを出すと、`GET /profile` が 404 ではなく API Gateway の 404 (`{"message":"Not Found"}`) になり、
  プロフィールなしとして扱われる。保存は失敗する
