# DynamoDB テーブル定義: `zero-chat-posts`

タイムラインの投稿を保存するテーブル。返信は投稿の項目の中にリストで持つ。

## テーブル

| 項目 | 値 |
|---|---|
| テーブル名 | `zero-chat-posts` |
| リージョン | `ap-northeast-1` (東京) |
| パーティションキー | `id` (数値) |
| ソートキー | なし |
| キャパシティモード | オンデマンド |

## グローバルセカンダリインデックス (GSI)

| インデックス名 | パーティションキー | ソートキー | 射影 | 用途 |
|---|---|---|---|---|
| `feed-postedAt-index` | `feed` (文字列) | `postedAt` (文字列) | すべて | 全投稿を新しい順に取る |
| `category-postedAt-index` | `category` (文字列) | `postedAt` (文字列) | すべて | 1 つの種類の投稿を新しい順に取る |

## 項目 (投稿 1 件) の属性

| 属性 | 型 | 必須 | 説明 |
|---|---|---|---|
| `id` | 数値 (N) | ○ | 投稿を見分ける一意な番号。テーブルのパーティションキー |
| `feed` | 文字列 (S) | ○ | 常に `"ALL"`。`feed-postedAt-index` のキー |
| `category` | 文字列 (S) | ○ | 投稿の種類。`category-postedAt-index` のキー (値は下の表) |
| `postedAt` | 文字列 (S) | ○ | 投稿日時。UTC の ISO 8601 形式 (例: `2026-10-14T09:00:00Z`)。両インデックスのソートキー |
| `text` | 文字列 (S) | ○ | 本文 |
| `author` | マップ (M) | ○ | 投稿した人 (下の表) |
| `replies` | リスト (L) | - | 返信の一覧。表示する順に並べる。返信がなければ省略するか空のリスト |

`feed` / `category` / `postedAt` のどれかが欠けている、または文字列でない項目は、
インデックスに載らないため API の結果に出てこない。

### `category` の値

Flutter の `PostCategory` の enum 名をそのまま使う。

| 値 | 画面での名前 |
|---|---|
| `announcement` | お知らせ |
| `dailyReport` | 日報 |
| `selfStudy` | 自己学習 |

### `postedAt` を文字列にしている理由

ISO 8601 形式で、桁数とタイムゾーン (`Z` = UTC) を揃えた文字列は、
**文字列として並べた順と日時の順が一致する**。そのためソートキーにそのまま使える。
タイムゾーンや桁数が混ざると順番が崩れるので、必ず UTC の同じ形式で入れる。

### `author` (マップ)

| 属性 | 型 | 説明 |
|---|---|---|
| `id` | 数値 | 人を見分ける一意な番号 |
| `name` | 文字列 | 名前 |
| `role` | 文字列 | 役割 (例: エンジニア) |

### `replies` の要素 (マップ)

| 属性 | 型 | 説明 |
|---|---|---|
| `id` | 数値 | 返信を見分ける一意な番号 |
| `author` | マップ | 返信した人 (形は `author` と同じ) |
| `text` | 文字列 | 本文 |
| `repliedAt` | 文字列 | 返信日時。`postedAt` と同じ形式 |

返信を別のテーブルにせず投稿の中に持っているのは、今の画面では返信を投稿と一緒に表示するだけなので、
1 回の読み取りでまとめて取れるほうが簡単なため。
DynamoDB の 1 項目は最大 400 KB なので、返信が非常に多くなる場合は別の項目に分ける。

## 項目の例

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

## Flutter のモデルとの対応

| DynamoDB | Flutter (`lib/domain/models/`) |
|---|---|
| 項目 (投稿) | `Post` |
| `id` | `Post.id` |
| `author` | `Post.author` (`Author`) |
| `category` | `Post.category` (`PostCategory.values.byName(...)` で変換) |
| `text` | `Post.text` |
| `postedAt` | `Post.postedAt` (`DateTime.parse(...)` で変換) |
| `replies` | `Post.replies` (`List<Reply>`) |
| `replies[].repliedAt` | `Reply.repliedAt` |
| `feed` | なし (DynamoDB の検索用。API のレスポンスにも含めない) |
