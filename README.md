# zero-chat

Flutter によるマルチプラットフォーム開発と AWS サーバーレス構築を学ぶため、自己学習で設計から公開まで行ったチャットアプリです。
1 つのコードで iOS / Android / Web / デスクトップに対応しています。

| iOS | Web |
|:---:|:---:|
| <img src="docs/public/images/zero-chat_iOS.png" alt="iOS 版のタイムライン画面" width="220"> | <img src="docs/public/images/zero-chat_Web.png" alt="Web 版のタイムライン画面" width="560"> |
| <video src="https://github.com/user-attachments/assets/e6c0c1d4-87dc-4f7f-bbfd-a6600542acb8" width="220" controls></video> | <video src="https://github.com/user-attachments/assets/f0ee8664-8444-4bd0-9956-9c47953e6b61" width="560" controls></video> |

## プロジェクト概要

### できること

- メールアドレスとパスワードでサインアップ (メールで届く 6 桁の確認コードで確認) ・サインインする。
  前回のサインインは、次にアプリを開いたときも残る
- 投稿の読み書きはサインインした人だけができる (API がトークンを確かめる)
- タイムラインで投稿を新しい順に表示する。下までスクロールすると、続きの 10 件を読み込む
- 投稿の種類で絞り込む (最新 / お知らせ / 日報 / 自己学習)
- 投稿に返信する。返信は投稿の下に開いたり閉じたりして表示する
- 投稿する (種類を選び、本文を 180 文字まで入力して送信する。送信後はタイムラインに反映される)
- プロフィール (ユーザー名・役職) をサインアップ時に入力し、プロフィール設定画面で変更する。アバターの色 (カラー1・カラー2) も一緒に保存する。
  サーバーにサインインした人ごとに保存され、投稿にはこの名前と役職が表示される
- 画面の幅に合わせてレイアウトを切り替える (スマホ: 下のタブバー / PC: 上部のバー)
- 表示の言語を日本語・英語から選ぶ (サインイン画面の「言語設定」・プロフィール設定画面)。
  選んだ言語は端末に保存し、初めて開いたときは端末の言語に合わせる


### 技術スタック

#### アプリ (Flutter)

| 領域 | 使っているもの |
|---|---|
| 言語・フレームワーク | Flutter / Dart |
| 状態管理・DI | Riverpod 3 (`flutter_riverpod`) |
| 画面遷移 | `go_router` |
| API との通信 | `http` (HTTPS) |
| 認証 (Cognito とのやり取り) | Amplify Flutter (`amplify_flutter`・`amplify_auth_cognito`) |
| アイコン・ロゴの表示 | `flutter_svg` |

#### サーバー (AWS)

| 領域 | 使っているサービス |
|---|---|
| 認証 | Amazon Cognito (ユーザープール) |
| API | Amazon API Gateway (HTTP API・JWT オーソライザー) |
| API の処理 | AWS Lambda (Python 3.13) |
| データベース | Amazon DynamoDB |
| Web 版の配信 | Amazon S3 + Amazon CloudFront |

### システム構成

```mermaid
flowchart LR
    subgraph Clients[アプリ]
        Mobile["iOS / Android<br/>デスクトップ"]
        Browser["Web 版<br/>(ブラウザ)"]
    end

    subgraph AWS
        CF[CloudFront] --> S3[(S3<br/>Web 版のファイル)]
        APIGW["API Gateway<br/>GET・POST /posts<br/>POST /posts/{id}/replies<br/>GET・PUT /profile"] --> Lambda[Lambda] --> DDB[(DynamoDB)]
        Cognito[Cognito<br/>ユーザープール]
        APIGW -.->|トークンを確認| Cognito
    end

    Browser -->|画面のファイルを取得| CF
    Browser -->|投稿の取得・作成| APIGW
    Mobile -->|投稿の取得・作成| APIGW
    Browser -->|サインイン| Cognito
    Mobile -->|サインイン| Cognito
```

アプリの内部は、Flutter 公式が推奨する MVVM + レイヤードアーキテクチャ (UI / Domain / Data) で作っている。
詳しくは [flutter-architecture.md](docs/public/flutter-architecture.md) を参照。

## ディレクトリ構成

```
zero-chat/
├── Flutter/                         # Flutter アプリ
│   ├── lib/
│   │   ├── main.dart                # 起動処理 (Amplify の準備・前回のサインインの確認・ProviderScope)
│   │   ├── app.dart                 # MaterialApp.router
│   │   ├── routing/                 # 画面遷移 (go_router)
│   │   ├── l10n/                    # 翻訳 (app_ja.arb・app_en.arb と、そこから作られる AppLocalizations)
│   │   ├── ui/                      # UI layer (画面ごと)
│   │   │   ├── core/                #   共通の Widget・テーマ・色
│   │   │   ├── shell/               #   タブバー・上部バーなど画面の外枠
│   │   │   ├── auth/                #   サインアップ・サインイン画面と ViewModel・サインイン状態
│   │   │   ├── home/                #   ホーム (タイムライン) 画面と ViewModel
│   │   │   ├── compose/             #   投稿画面と ViewModel
│   │   │   ├── profile/             #   プロフィール設定画面・ログイン中の人のプロフィール
│   │   │   └── placeholder/         #   未実装の画面の仮表示
│   │   ├── domain/
│   │   │   └── models/              # Domain layer (投稿・返信・投稿者などのモデル)
│   │   └── data/                    # Data layer
│   │       ├── repositories/post/   #   投稿の取得・作成 (サーバー版 / 仮データ版)
│   │       ├── repositories/auth/   #   サインアップ・サインイン (Cognito 版 / 仮の認証版)
│   │       ├── repositories/profile/ #  自分のプロフィールの取得・保存 (サーバー版 / 仮データ版)
│   │       ├── services/api/        #   サーバーとの通信
│   │       └── services/preferences/ #  端末に保存する設定 (表示の言語など) の管理
│   ├── test/                        # テスト (lib/ と同じ構成)
│   ├── assets/                      # アイコン・ロゴの SVG
│   ├── config/
│   │   └── api.example.json         # API の URL と Cognito の ID を書く設定ファイルのひな形
│   ├── android/ ios/ web/           # 各プラットフォーム固有の設定
│   └── macos/ windows/ linux/
├── Lambda/                          # AWS Lambda 関数のコード
│   ├── zero-chat-get-posts/         #   投稿取得 API (GET /posts)
│   ├── zero-chat-create-post/       #   投稿作成 API (POST /posts)
│   ├── zero-chat-create-reply/      #   返信作成 API (POST /posts/{id}/replies)
│   ├── zero-chat-get-profile/       #   プロフィール取得 API (GET /profile)
│   └── zero-chat-update-profile/    #   プロフィール更新 API (PUT /profile)
└── docs/public/                     # 設計方針・構築手順・仕様のドキュメント (下の「ドキュメント」を参照)
    ├── flutter-architecture.md      #   アプリの設計方針
    ├── aws-setup.md                 #   AWS のリソースを一から作る手順
    ├── table/                       #   DynamoDB のテーブル定義
    ├── lambda/                      #   Lambda 関数の仕様
    └── auth/                        #   認証 (Cognito・JWT オーソライザー) の設定
```

## ドキュメント

アプリの設計方針、AWS 側の構築手順と、各リソースの仕様は `docs/public/` にある。

### まず読むもの

| ドキュメント | 内容 |
|---|---|
| [flutter-architecture.md](docs/public/flutter-architecture.md) | **アプリの設計方針。** MVVM + レイヤードアーキテクチャ (UI / Domain / Data) の分け方と、各層の役割 |
| [aws-setup.md](docs/public/aws-setup.md) | **AWS のリソースを一から作る手順。** Cognito → DynamoDB → Lambda → API Gateway → アプリの設定 → Web 版の公開の順に進める。更新・削除のしかたと、うまくいかないときの確認先もここにある |

### 仕様 (何がどう設定されているか)

| ディレクトリ | ドキュメント | 内容 |
|---|---|---|
| `table/` | [posts-table.md](docs/public/table/posts-table.md) | 投稿のテーブル `zero-chat-posts` (投稿・返信・インデックス・投稿の番号を数える項目) |
| | [profiles-table.md](docs/public/table/profiles-table.md) | プロフィールのテーブル `zero-chat-profiles` (名前・役職・カラー) |
| `lambda/` | [get-posts.md](docs/public/lambda/get-posts.md) | `GET /posts` 投稿の一覧 (10 件ずつ・続きの目印 `cursor`・最新のプロフィールで表示) |
| | [create-post.md](docs/public/lambda/create-post.md) | `POST /posts` 投稿の作成 |
| | [create-reply.md](docs/public/lambda/create-reply.md) | `POST /posts/{id}/replies` 返信の作成 |
| | [profile.md](docs/public/lambda/profile.md) | `GET /profile`・`PUT /profile` 自分のプロフィールの取得・保存 |
| `auth/` | [cognito.md](docs/public/auth/cognito.md) | Cognito のユーザープールの設定と、アプリからのサインアップ・サインイン |
| | [jwt-authorizer.md](docs/public/auth/jwt-authorizer.md) | API のトークンの確認 (JWT オーソライザー)・CORS |

Lambda の仕様には、リクエスト・レスポンス・エラー・環境変数・実行ロールの権限・テストイベントがある。

アカウント ID・API の URL・ユーザープール ID などの実際の値は、公開しないドキュメント
`docs/private/aws-resources.md` に書く (`.gitignore` 済みなので、リポジトリには入らない)。

## 動作環境

### 開発環境

| ツール | バージョン |
|---|---|
| Flutter | 3.35.1 (stable) |
| Dart | 3.9.0 |

Dart SDK の条件は `pubspec.yaml` で `^3.9.0` にしている。

### 対応プラットフォーム

| プラットフォーム | 最低バージョン | 動作確認 |
|---|---|---|
| iOS | 13.0 | ✅ iPhone 17 Pro シミュレーター |
| Android | 7.0 (API 24) | - |
| Web | Chrome などのモダンブラウザ | ✅ Chrome |
| macOS | 10.15 | - (※) |
| Windows / Linux | - | - |

最低バージョンは Flutter のプロジェクト作成時の初期値のまま。Amplify Flutter の条件 (iOS 13 以上・Android API 24 以上) も満たしている。

※ macOS アプリでは、Amplify がトークンを保存するためのキーチェーンの設定 (Keychain Sharing) をしていないため、サインインは動かない見込み。

## ビルド手順

### 1. 準備

[Flutter](https://docs.flutter.dev/get-started/install) をインストールし、リポジトリを取得して依存パッケージを入れる。
以降のコマンドはすべて `Flutter/` ディレクトリで実行する。

```bash
git clone https://github.com/diapp0227/zero-chat.git
cd zero-chat/Flutter
flutter pub get
```

### 2. 起動する

#### 仮のデータで起動する

サーバーがなくても、アプリに組み込んだ仮の投稿データと仮の認証で動かせる。
投稿した内容はアプリの中 (メモリ) にだけ保存され、アプリを閉じると消える。

- 起動すると、まずサインイン画面が出る。サインアップすると確認コードの入力に進むので、`123456` を入れる
- 仮の認証で作ったアカウントもアプリを閉じると消えるので、起動するたびにサインアップし直す

```bash
flutter run
```

#### サーバーにつないで起動する

API の URL と Cognito の ID は `config/api.json` に書き、ビルド時に渡す。
このファイルは公開しないよう git の管理対象外にしている。

1. `config/api.example.json` をコピーして `config/api.json` を作る
2. 次の 3 つを実際の値にする
   - `API_BASE_URL`: API の URL (`<API ID>` を置き換える。末尾に `/` は付けない)
   - `COGNITO_USER_POOL_ID`: Cognito のユーザープール ID
   - `COGNITO_CLIENT_ID`: Cognito のアプリケーションクライアント ID
3. `--dart-define-from-file` を付けて起動する

```bash
cp config/api.example.json config/api.json
flutter run --dart-define-from-file=config/api.json
```

Web 版をローカルで動かすときは、API の CORS 設定で許可しているポート (8080) に固定する。

```bash
flutter run -d chrome --web-port 8080 --dart-define-from-file=config/api.json
```

※ `--dart-define` の値はアプリに埋め込まれるため、秘密の情報は渡さない (API の URL と Cognito の ID は秘密の値ではない)。

※ API はサインインした人のトークンがないと 401 を返す。API の URL だけ渡して Cognito の ID を渡さないと、
仮の認証で動いてトークンが付かないため、投稿を読めない。

※ AWS 側の作り方は [aws-setup.md](docs/public/aws-setup.md) (一から作る手順) を参照。
テーブル・Lambda・認証の仕様は、上の「[ドキュメント](#ドキュメント)」から探せる。

### 3. テストする

```bash
flutter test
flutter analyze
```

テストは通信しないので、API や Cognito がなくても実行できる。

### 4. リリースビルド

サーバーにつなぐ場合は、どのプラットフォームでも `--dart-define-from-file=config/api.json` を付ける。

| プラットフォーム | コマンド | 出力先 |
|---|---|---|
| Web | `flutter build web --release --dart-define-from-file=config/api.json` | `build/web/` |
| iOS | `flutter build ios --release --dart-define-from-file=config/api.json` | `build/ios/` |
| Android | `flutter build apk --release --dart-define-from-file=config/api.json` | `build/app/outputs/flutter-apk/` |
| macOS | `flutter build macos --release --dart-define-from-file=config/api.json` | `build/macos/` |

Web 版を AWS (S3 + CloudFront) に公開する手順は [aws-setup.md](docs/public/aws-setup.md) の「6. Web 版を公開する」、
出し直す手順は「7. 更新するとき」を参照。
