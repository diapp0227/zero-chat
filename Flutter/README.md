# zero_chat

Flutter 製のチャットアプリ (iOS / Android / Web / macOS / Windows / Linux)。

構成は [flutter-architecture.md](../flutter-architecture.md) を参照。

## サーバー (投稿取得 API) につないで起動する

API の URL は `config/api.json` に書き、ビルド時に渡す。
このファイルは公開しないよう git の管理対象外にしている。

1. `config/api.example.json` をコピーして `config/api.json` を作り、`<API ID>` を実際の値にする
   (URL の末尾に `/` は付けない)
2. `--dart-define-from-file` を付けて起動・ビルドする

```bash
flutter run --dart-define-from-file=config/api.json
```

付けずに起動すると、サーバーにはつながず仮のデータ (`FakePostRepository`) を表示する。

API の作り方と仕様は [posts-api-aws.md](../docs/public/posts-api-aws.md) /
[get-posts-lambda.md](../docs/public/get-posts-lambda.md) を参照。
