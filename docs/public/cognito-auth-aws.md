# サインアップ・サインインを Amazon Cognito で作る手順

アプリのサインアップ・サインイン画面から、Amazon Cognito のユーザープールにユーザーを登録・認証する。
ログイン画面はアプリ側にすでにあるので、Cognito のログイン画面 (マネージドログイン / Hosted UI) は使わず、
アプリから Cognito の API を直接呼ぶ。

```
Flutter アプリ (サインアップ・サインイン画面)
   │  ① SignUp            メールアドレス + パスワードを登録
   │  ② ConfirmSignUp     メールで届いた確認コードを送る
   │  ③ InitiateAuth (SRP) サインイン → トークン (JWT) を受け取る
   ▼
Cognito ユーザープール (zero-chat-users)
   │  確認コードのメールを送る
   ▼
ユーザーのメールボックス
```

関連するドキュメント:

- 投稿取得 API の作成手順: [posts-api-aws.md](posts-api-aws.md)
- 投稿作成 API の作成手順: [create-post-api-aws.md](create-post-api-aws.md)
- アカウント ID・ユーザープール ID などの実際の値: [aws-resources.md](../private/aws-resources.md)

## 作成するリソース

| サービス | 名前 | 補足 |
|---|---|---|
| Cognito ユーザープール | `zero-chat-users` | メールアドレスでサインイン、セルフサインアップあり |
| Cognito アプリケーションクライアント | `zero-chat-app` | シングルページアプリケーション (クライアントシークレットなし) |

リージョンは `ap-northeast-1` (東京)。
コンソール右上のリージョンが「東京」になっていることを確認してから作業する。

---

## 0. 設計で決めたこと

| 項目 | 決めたこと | 理由 |
|---|---|---|
| ログイン画面 | アプリの画面から Cognito の API を呼ぶ (マネージドログインは使わない) | デザインどおりの画面がすでにあり、Web・iOS・Android で同じ画面を使える |
| サインインに使う項目 | **メールアドレス** | 画面の入力項目がメールアドレスとパスワードだけのため |
| サインアップの確認 | メールで届く **6 桁の確認コード** | 画面の「認証コードを入力」の段階と対応する |
| パスワードの条件 | Cognito の初期設定のまま (**8 文字以上、大文字・小文字・数字・記号をそれぞれ含む**) | アプリの入力チェックと説明文もこれに合わせる |
| サインインの方式 | **SRP** (`ALLOW_USER_SRP_AUTH`) | パスワードそのものをネットワークに流さずに認証できる |
| クライアントシークレット | **なし** | アプリ (Web・スマホ) の中にシークレットを安全にしまう方法がないため |
| アプリの通信ライブラリ | `amplify_flutter` + `amplify_auth_cognito` | SRP の計算、トークンの保存と自動更新を任せられ、Web・iOS・Android で動く |
| メールの送信 | Cognito の既定の送信機能 | 開発中は十分。1 日に送れる通数に上限があるので、本番では Amazon SES に切り替える |

> 📝 確認コードの有効期限は **24 時間** (Cognito の仕様で変えられない)。
> 画面の「コードの有効期限は〜」の説明文もこれに合わせる。

---

## 1. ユーザープールを作る

**Amazon Cognito → ユーザープール → ユーザープールを作成**

「アプリケーションを定義」の画面で、次のように入力する。

| 項目 | 値 |
|---|---|
| アプリケーションタイプ | **シングルページアプリケーション (SPA)** |
| アプリケーションに名前を付ける | `zero-chat-app` |
| サインイン識別子のオプション | **メールアドレス** だけにチェック |
| 自己登録 | **自己登録を有効化** にチェック |
| サインアップのための必須属性 | `email` (サインイン識別子にメールアドレスを選ぶと自動で入る) |
| リターン URL | 空のまま (マネージドログインを使わないため) |

- サインイン識別子と必須属性は、**作成後に変更できない**。間違えたらユーザープールを作り直す
- 「ユーザーディレクトリを作成する」を押すと、ユーザープールとアプリケーションクライアントがまとめてできる
- できたユーザープールの名前は自動で付くので、**ユーザープール → 名前を変更** で `zero-chat-users` に変えておくと見分けやすい
  (名前の変更ができない場合はそのままでよい。アプリが使うのは名前ではなく ID)

---

## 2. 設定を確認する

作成直後の設定がこの手順の想定どおりかを確認する。違っていたら「編集」で直す。

### 2-1. パスワードポリシー

**認証方法 → パスワードポリシー**

| 項目 | 値 |
|---|---|
| パスワードポリシーモード | Cognito のデフォルト |
| パスワードの最小文字数 | 8 |
| パスワードの要件 | 数字・特殊文字・大文字・小文字をそれぞれ 1 文字以上 |

アプリの入力チェックもこの条件に合わせている。ここを変えたら、アプリ側 (`lib/ui/auth/`) も合わせて変える。

### 2-2. サインアップ

**サインアップ**

| 項目 | 値 |
|---|---|
| 自己登録 | 有効 |
| Cognito が支援する検証と確認 | **E メールメッセージを送信、E メールアドレスを検証** |

これで、サインアップするとメールアドレスに 6 桁の確認コードが届き、
コードを送るまではそのユーザーはサインインできない (状態が「未確認」のまま)。

### 2-3. メール

**認証方法 → E メール**

| 項目 | 値 |
|---|---|
| E メールプロバイダー | Cognito で E メールを送信 (既定) |
| FROM アドレス | `no-reply@verificationemail.com` (既定) |

- 迷惑メールに振り分けられることがあるので、届かないときは迷惑メールフォルダも見る
- 1 日に送れる通数に上限がある。上限は [Cognito のクォータ](https://docs.aws.amazon.com/cognito/latest/developerguide/limits.html) で確認する

### 2-4. アプリケーションクライアント

**アプリケーション → アプリケーションクライアント → `zero-chat-app`**

| 項目 | 値 |
|---|---|
| クライアントシークレット | **なし** (表示されていないこと) |
| 認証フロー | `ALLOW_USER_SRP_AUTH` と `ALLOW_REFRESH_TOKEN_AUTH` が入っていること |
| ユーザー存在エラーの防止 | 有効 (既定) |

- `ALLOW_USER_PASSWORD_AUTH` (パスワードをそのまま送る方式) は**付けない**
- 「ユーザー存在エラーの防止」が有効だと、サインインに失敗したとき「そのメールアドレスは登録されていない」と
  「パスワードが違う」を区別せずに返す。登録済みのメールアドレスを調べられないようにするため
- ⚠️ この画面の設定を AWS CLI (`update-user-pool-client`) で変えるときは、**指定しなかった項目が初期値に戻る**。
  コンソールの「編集」を使うか、CLI なら今の設定をすべて読み出してから変更する

### 2-5. 機能プラン

**設定 → 機能プラン**

今回使う機能 (メールアドレスとパスワードでのサインアップ・サインイン、確認コード) は、
いちばん機能の少ない **Lite** プランで足りる。作成直後は Essentials になっていることがあるので、Lite に変える。
料金と無料利用枠は [Amazon Cognito の料金](https://aws.amazon.com/cognito/pricing/) で確認する。

---

## 3. ID を控える

アプリに渡す値は次の 2 つ。どちらも秘密の値ではない (アプリに埋め込まれて利用者の端末に届く) が、
アカウントの情報なので [aws-resources.md](../private/aws-resources.md) に書き、公開のドキュメントには書かない。

| 値 | 場所 | 形 |
|---|---|---|
| ユーザープール ID | ユーザープールの「概要」 | `ap-northeast-1_xxxxxxxxx` |
| アプリケーションクライアント ID | アプリケーションクライアントの一覧 | 英数字 26 文字前後 |

---

## 4. 動作を確認する (AWS CLI)

アプリにつなぐ前に、サインアップ → 確認 → サインインが通るかを確かめる。
`<クライアントID>` を自分の値に、メールアドレスを**自分が受信できるアドレス**に置き換える。

```bash
# ① サインアップ (確認コードがメールで届く)
aws cognito-idp sign-up \
  --region ap-northeast-1 \
  --client-id <クライアントID> \
  --username you@example.com \
  --password 'Passw0rd!' \
  --user-attributes Name=email,Value=you@example.com

# ② 届いたコードで確認する
aws cognito-idp confirm-sign-up \
  --region ap-northeast-1 \
  --client-id <クライアントID> \
  --username you@example.com \
  --confirmation-code 123456
```

- ① の結果が `"UserConfirmed": false` なら、確認コードの送信まで成功している
- ② のあと、**ユーザープール → ユーザー** でそのユーザーの「確認ステータス」が「確認済み」になっていれば完成
- パスワードの条件を満たさないと `InvalidPasswordException` になる
- サインイン (SRP) は計算が必要で CLI からは試しにくいので、アプリから確認する
- 確認が終わったテスト用のユーザーは、不要ならユーザー一覧から削除する

---

## 5. アプリから使う

### 5-1. 設定を渡す

ユーザープール ID とアプリケーションクライアント ID は、API の URL と同じく `config/api.json` に書き、
起動・ビルドのときに `--dart-define-from-file=config/api.json` で渡す。
ひな形は `config/api.example.json`。`config/api.json` は `.gitignore` 済みなので、リポジトリには入らない。

```json
{
  "API_BASE_URL": "https://<API ID>.execute-api.ap-northeast-1.amazonaws.com",
  "COGNITO_USER_POOL_ID": "ap-northeast-1_xxxxxxxxx",
  "COGNITO_CLIENT_ID": "<アプリケーションクライアントID>"
}
```

- **リージョンは設定しない**。ユーザープール ID の「`_`」より前 (例: `ap-northeast-1`) をリージョンとして使うので、
  東京以外のリージョンに作ったユーザープールでもそのまま動く
- Amplify の設定ファイル (`amplify_outputs.json`) や Amplify CLI は使わない。
  アプリの起動時に、上の 2 つの ID から同じ形の設定をコードで組み立てて渡す
- 2 つの ID のどちらかが渡されていなければ Cognito にはつながず、メモリ上だけで動く仮の実装を使う。
  このときの確認コードは常に `123456` で、登録したアカウントはアプリを閉じると消える

```bash
# Cognito につないで Web 版を動かす
cd Flutter
flutter run -d chrome --web-port 8090 --dart-define-from-file=config/api.json
```

### 5-2. 使うパッケージ

| パッケージ | 役割 |
|---|---|
| `amplify_flutter` | Amplify の本体。設定の読み込みと `Amplify.Auth` の入り口 |
| `amplify_auth_cognito` | Cognito のユーザープールとのやり取り。SRP の計算、トークンの端末への保存と自動更新 |

対応する OS のバージョン (iOS 13 以上・Android 7.0 (API 24) 以上) は、このアプリの設定ですでに満たしている。
macOS アプリとして動かす場合は、トークンを保存するためにキーチェーンの設定 (Keychain Sharing) の追加が必要 (未設定)。

### 5-3. ファイルの構成

| 層 | ファイル | 役割 |
|---|---|---|
| — | `lib/main.dart` | 起動時に Amplify を準備し、前回のサインインが端末に残っているかを確認する |
| UI | `lib/ui/auth/auth_screen.dart` | 入力を受け取り、ViewModel を呼ぶ。送信中は「送信中…」、失敗したらボタンの上にメッセージを出す |
| UI | `lib/ui/auth/auth_view_model.dart` | サインアップ・確認・サインイン・コードの再送を呼び、送信中・失敗の状態を持つ |
| UI | `lib/ui/auth/auth_failure_message.dart` | 失敗の理由を画面に出すメッセージにする |
| UI | `lib/ui/auth/auth_session.dart` | サインインしているかを保持する。router はこれを見て、サインイン画面とホームを切り替える |
| Data | `lib/data/repositories/auth/auth_repository.dart` | 認証の窓口 (抽象クラス) と、失敗の理由 (`AuthFailure`) |
| Data | `lib/data/repositories/auth/cognito_auth_repository.dart` | Amplify で Cognito を呼ぶ実装。Amplify の例外を `AuthFailure` に変換する |
| Data | `lib/data/repositories/auth/fake_auth_repository.dart` | メモリ上だけで動く仮の実装 (設定がないとき・テスト用) |
| Data | `lib/data/repositories/auth/auth_repository_provider.dart` | 設定があれば Cognito 用、なければ仮の実装を使う |

### 5-4. アプリでの流れ

| 画面の操作 | 呼ぶもの | 補足 |
|---|---|---|
| アプリを開く | `Amplify.Auth.fetchAuthSession` | 前回のサインインが残っていれば、サインイン画面を飛ばしてホームを開く |
| 「アカウントを作成」 | `Amplify.Auth.signUp` | 成功したら確認コードの入力へ進む |
| 「認証してはじめる」 | `Amplify.Auth.confirmSignUp` → `Amplify.Auth.signIn` | コードの確認だけではサインインしないので、続けて入力済みのパスワードでサインインする |
| 「コードを再送」 | `Amplify.Auth.resendSignUpCode` | 成功したら「認証コードを再送しました」と出す |
| 「サインイン」 | `Amplify.Auth.signIn` | 確認がまだのアカウントなら、`resendSignUpCode` で新しいコードを送ってから確認コードの入力へ進む (サインアップ時のコードは期限切れのことがあるため) |
| 「ログアウト」 | `Amplify.Auth.signOut` | 端末のサインインの情報を消す。消せなかったときも、画面はサインイン画面に戻す |

### 5-5. 失敗したときの表示

Cognito から返ってきた例外を理由ごとにまとめ、ボタンの上に次のメッセージを出す。

| Cognito の例外 | 画面のメッセージ |
|---|---|
| `UsernameExistsException` | このメールアドレスはすでに登録されています。サインインしてください |
| `InvalidPasswordException` | パスワードが条件を満たしていません |
| `NotAuthorizedException`・`UserNotFoundException` | メールアドレスまたはパスワードが正しくありません |
| `CodeMismatchException` | 認証コードが正しくありません |
| `ExpiredCodeException` | 認証コードの有効期限が切れています。コードを再送してください |
| `CodeDeliveryFailureException` | 認証コードを送信できませんでした。メールアドレスを確認してください |
| `LimitExceededException`・`TooManyRequestsException`・`TooManyFailedAttemptsException` | 試行回数が多すぎます。時間をおいて、もう一度お試しください |
| 通信できない | 通信できませんでした。接続を確認して、もう一度お試しください |
| それ以外 | うまくいきませんでした。時間をおいて、もう一度お試しください |

- 「ユーザー存在エラーの防止」が有効なので、登録されていないメールアドレスでサインインしても
  `NotAuthorizedException` になり、パスワード違いと同じメッセージになる
- パスワードの条件 (8 文字以上・大文字・小文字・数字・記号) はアプリでも確かめていて、
  満たすまで「アカウントを作成」は押せない。そのため `InvalidPasswordException` は、
  ユーザープール側のパスワードポリシーを変えたときなどにしか出ない

---

## 公開範囲と今後の課題

- **API はまだ保護されていない**。サインインしなくても API の URL を知っていれば投稿の取得・作成ができる。
  次の段階で HTTP API (`zero-chat-api`) に JWT オーソライザーを付け、
  発行元 `https://cognito-idp.ap-northeast-1.amazonaws.com/<ユーザープールID>`・対象 `<クライアントID>` のトークンだけを受け付けるようにする
- 投稿した人 (`author`) はまだアプリから送った名前と役職のまま。API を保護したら、トークンのユーザー (`sub`) から決めるようにする
- プロフィール (名前・役職) はまだアプリのメモリ上だけ。Cognito のユーザー属性か DynamoDB に保存する
- 「パスワードを忘れた方」(`resetPassword` / `confirmResetPassword`) は画面のデザインができてから作る
- 本番でユーザーが増えたら、メールの送信を Amazon SES に切り替える
- Web 版ではトークンがブラウザの保存領域に置かれる。XSS (ほかのスクリプトの埋め込み) を防ぐため、
  CloudFront で `Content-Security-Policy` などのセキュリティヘッダーを付けることを検討する
