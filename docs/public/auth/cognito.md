# Cognito の設定: ユーザープール `zero-chat-users`

アプリのサインアップ・サインイン画面から、Amazon Cognito のユーザープールにユーザーを登録・認証する。
ログイン画面はアプリ側にあるので、Cognito のログイン画面 (マネージドログイン / Hosted UI) は使わず、
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

- 作る手順: [aws-setup.md](../aws-setup.md) の「1. Cognito のユーザープールを作る」
- API がトークンを確かめる仕組み: [jwt-authorizer.md](jwt-authorizer.md)
- ユーザープール ID などの実際の値: [aws-resources.md](../../private/aws-resources.md)

## リソース

| サービス | 名前 | 補足 |
|---|---|---|
| Cognito ユーザープール | `zero-chat-users` | メールアドレスでサインイン、セルフサインアップあり |
| Cognito アプリケーションクライアント | `zero-chat-app` | シングルページアプリケーション (クライアントシークレットなし) |

リージョンは `ap-northeast-1` (東京)。ほかの AWS リソースと同じ。

---

## 設計で決めたこと

| 項目 | 決めたこと | 理由 |
|---|---|---|
| ログイン画面 | アプリの画面から Cognito の API を呼ぶ (マネージドログインは使わない) | デザインどおりの画面がすでにあり、Web・iOS・Android で同じ画面を使える |
| サインインに使う項目 | **メールアドレス** | 画面の入力項目がメールアドレスとパスワードだけのため |
| サインアップの確認 | メールで届く **6 桁の確認コード** | 画面の「認証コードを入力」の段階と対応する |
| パスワードの条件 | **8 文字以上だけ** (大文字・小文字・数字・記号は求めない) | 覚えやすさを優先する。アプリでは条件を確かめず、判定は Cognito に任せる |
| サインインの方式 | **SRP** (`ALLOW_USER_SRP_AUTH`) | パスワードそのものをネットワークに流さずに認証できる |
| クライアントシークレット | **なし** | アプリ (Web・スマホ) の中にシークレットを安全にしまう方法がないため |
| アプリの通信ライブラリ | `amplify_flutter` + `amplify_auth_cognito` | SRP の計算、トークンの保存と自動更新を任せられ、Web・iOS・Android で動く |
| メールの送信 | Cognito の既定の送信機能 | 開発中は十分。1 日に送れる通数に上限があるので、本番では Amazon SES に切り替える |
| 機能プラン | **Lite** | メールアドレスとパスワードでのサインアップ・サインイン、確認コードだけなら Lite で足りる |

> 📝 確認コードの有効期限は **24 時間** (Cognito の仕様で変えられない)。
> 画面の「コードの有効期限は〜」の説明文もこれに合わせる。

---

## 設定値

### ユーザープール

| 場所 (コンソール) | 項目 | 値 |
|---|---|---|
| サインイン | サインイン識別子 | **メールアドレス** だけ (作成後に変更できない) |
| サインアップ | 自己登録 | 有効 |
| サインアップ | 必須属性 | `email` (作成後に変更できない) |
| サインアップ | Cognito が支援する検証と確認 | **E メールメッセージを送信、E メールアドレスを検証** |
| 認証方法 → パスワードポリシー | モード | **カスタム** |
| 認証方法 → パスワードポリシー | 最小文字数 | 8 |
| 認証方法 → パスワードポリシー | パスワードの要件 | **すべてのチェックを外す** (数字・特殊文字・大文字・小文字を求めない) |
| 認証方法 → E メール | E メールプロバイダー | Cognito で E メールを送信 (既定。FROM は `no-reply@verificationemail.com`) |
| 設定 → 機能プラン | プラン | Lite |

- サインアップすると、メールアドレスに 6 桁の確認コードが届く。コードを送るまでは、そのユーザーはサインインできない (状態が「未確認」のまま)
- 確認のメールは迷惑メールに振り分けられることがある。1 日に送れる通数の上限は [Cognito のクォータ](https://docs.aws.amazon.com/cognito/latest/developerguide/limits.html) を参照
- パスワードの最小文字数を変えたら、入力欄のヒント (「8文字以上で入力」) とエラーのメッセージ (`lib/l10n/` の翻訳) も合わせて変える
- 料金と無料利用枠は [Amazon Cognito の料金](https://aws.amazon.com/cognito/pricing/) を参照

### アプリケーションクライアント `zero-chat-app`

| 項目 | 値 |
|---|---|
| アプリケーションタイプ | シングルページアプリケーション (SPA) |
| クライアントシークレット | **なし** |
| 認証フロー | `ALLOW_USER_SRP_AUTH` と `ALLOW_REFRESH_TOKEN_AUTH` |
| ユーザー存在エラーの防止 | 有効 (既定) |
| リターン URL | なし (マネージドログインを使わないため) |

- `ALLOW_USER_PASSWORD_AUTH` (パスワードをそのまま送る方式) は**付けない**
- 「ユーザー存在エラーの防止」が有効だと、サインインに失敗したとき「そのメールアドレスは登録されていない」と
  「パスワードが違う」を区別せずに返す。登録済みのメールアドレスを調べられないようにするため
- ⚠️ この設定を AWS CLI (`update-user-pool-client`) で変えるときは、**指定しなかった項目が初期値に戻る**。
  コンソールの「編集」を使うか、CLI なら今の設定をすべて読み出してから変更する

### アプリに渡す値

| 値 | 場所 | 形 |
|---|---|---|
| ユーザープール ID | ユーザープールの「概要」 | `ap-northeast-1_xxxxxxxxx` |
| アプリケーションクライアント ID | アプリケーションクライアントの一覧 | 英数字 26 文字前後 |

どちらも秘密の値ではない (アプリに埋め込まれて利用者の端末に届く) が、アカウントの情報なので
[aws-resources.md](../../private/aws-resources.md) に書き、公開のドキュメントには書かない。

---

## アプリから使う

### 設定を渡す

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
  どのリージョンに作ったユーザープールでもそのまま動く
- Amplify の設定ファイル (`amplify_outputs.json`) や Amplify CLI は使わない。
  アプリの起動時に、上の 2 つの ID から同じ形の設定をコードで組み立てて渡す
- 2 つの ID のどちらかが渡されていなければ Cognito にはつながず、メモリ上だけで動く仮の実装を使う。
  このときの確認コードは常に `123456` で、登録したアカウントはアプリを閉じると消える

```bash
# Cognito につないで Web 版を動かす
cd Flutter
flutter run -d chrome --web-port 8080 --dart-define-from-file=config/api.json
```

### 使うパッケージ

| パッケージ | 役割 |
|---|---|
| `amplify_flutter` | Amplify の本体。設定の読み込みと `Amplify.Auth` の入り口 |
| `amplify_auth_cognito` | Cognito のユーザープールとのやり取り。SRP の計算、トークンの端末への保存と自動更新 |

対応する OS のバージョン (iOS 13 以上・Android 7.0 (API 24) 以上) は、このアプリの設定ですでに満たしている。
macOS アプリとして動かす場合は、トークンを保存するためにキーチェーンの設定 (Keychain Sharing) の追加が必要 (未設定)。

### ファイルの構成

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

### アプリでの流れ

| 画面の操作 | 呼ぶもの | 補足 |
|---|---|---|
| アプリを開く | `Amplify.Auth.fetchAuthSession` | 前回のサインインが残っていれば、サインイン画面を飛ばしてホームを開く |
| 「アカウントを作成」 | `Amplify.Auth.signUp` | 成功したら確認コードの入力へ進む |
| 「認証してはじめる」 | `Amplify.Auth.confirmSignUp` → `Amplify.Auth.signIn` | コードの確認だけではサインインしないので、続けて入力済みのパスワードでサインインする |
| 「コードを再送」 | `Amplify.Auth.resendSignUpCode` | 成功したら「認証コードを再送しました」と出す |
| 「サインイン」 | `Amplify.Auth.signIn` | 確認がまだのアカウントなら、`resendSignUpCode` で新しいコードを送ってから確認コードの入力へ進む (サインアップ時のコードは期限切れのことがあるため) |
| 「ログアウト」 | `Amplify.Auth.signOut` | 端末のサインインの情報を消す。消せなかったときも、画面はサインイン画面に戻す |

### 失敗したときの表示

Cognito から返ってきた例外を理由ごとにまとめ、ボタンの上に次のメッセージを出す (日本語の場合。文言は `lib/l10n/` の翻訳ファイルにある)。

| Cognito の例外 | 画面のメッセージ |
|---|---|
| `UsernameExistsException` | このメールアドレスはすでに登録されています。サインインしてください |
| `InvalidPasswordException` | パスワードは8文字以上で入力してください |
| `NotAuthorizedException`・`UserNotFoundException` | メールアドレスまたはパスワードが正しくありません |
| `CodeMismatchException` | 認証コードが正しくありません |
| `ExpiredCodeException` | 認証コードの有効期限が切れています。コードを再送してください |
| `CodeDeliveryFailureException` | 認証コードを送信できませんでした。メールアドレスを確認してください |
| `LimitExceededException`・`TooManyRequestsException`・`TooManyFailedAttemptsException` | 試行回数が多すぎます。時間をおいて、もう一度お試しください |
| 通信できない | 通信できませんでした。接続を確認して、もう一度お試しください |
| それ以外 | うまくいきませんでした。時間をおいて、もう一度お試しください |

- 「ユーザー存在エラーの防止」が有効なので、登録されていないメールアドレスでサインインしても
  `NotAuthorizedException` になり、パスワード違いと同じメッセージになる
- パスワードの条件はアプリでは確かめず、空でなければ送る。8 文字未満なら Cognito が
  `InvalidPasswordException` を返すので、そのメッセージで 8 文字以上にするよう伝える

---

## 公開範囲と今後の課題

- CloudFront の URL を知っていれば、誰でもアカウントを作れる (セルフサインアップが有効なため)
- 「パスワードを忘れた方」(`resetPassword` / `confirmResetPassword`) は画面のデザインができてから作る
- 本番でユーザーが増えたら、メールの送信を Amazon SES に切り替える
- Web 版ではトークンがブラウザの保存領域に置かれる。XSS (ほかのスクリプトの埋め込み) を防ぐため、
  CloudFront で `Content-Security-Policy` などのセキュリティヘッダーを付けることを検討する
