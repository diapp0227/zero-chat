import 'package:flutter/painting.dart';

/// 投稿セルに表示する内容
///
/// 画面に出すための形にしたデータ。
/// 「投稿の情報注入」で、取得した投稿データからこの形に変換して渡す
class TimelinePost {
  const TimelinePost({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.avatarColors,
    required this.postedAt,
    required this.title,
    required this.text,
    this.image,
    this.replies = const [],
  });

  /// 投稿を見分けるための一意な番号 (画面には出さない)
  final int id;

  /// 投稿者の名前 (アバターの頭文字にも使う)
  final String authorName;

  /// 名前の下に出す肩書き (例: エンジニア)
  final String authorRole;

  /// アバターのグラデーションの開始色と終了色
  final (Color, Color) avatarColors;

  /// 投稿日時 (画面には「12分」「昨日」などの経過時間に変換して出す)
  final DateTime postedAt;

  /// 本文の上に太字で出すタイトル (例: 日報)
  final String title;

  /// 本文
  final String text;

  /// 本文の下に出す画像 (なければ null)
  final TimelinePostImage? image;

  /// 返信の一覧 (なければ空)
  final List<TimelineReply> replies;
}

/// 投稿に付いた画像
class TimelinePostImage {
  const TimelinePostImage({required this.url, required this.alt, this.label});

  /// 画像の URL
  final String url;

  /// 画像の説明 (画面読み上げ用)
  final String alt;

  /// 画像の左下に重ねる文字 (例: TOKYO, 18:42。なければ null)
  final String? label;
}

/// 投稿への返信1件
class TimelineReply {
  const TimelineReply({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.avatarColors,
    required this.repliedAt,
    required this.text,
  });

  /// 返信を見分けるための一意な番号 (画面には出さない)
  final int id;

  /// 返信者の名前 (アバターの頭文字にも使う)
  final String authorName;

  /// 名前の下に出す肩書き (例: エンジニア)
  final String authorRole;

  /// アバターのグラデーションの開始色と終了色
  final (Color, Color) avatarColors;

  /// 返信日時 (画面には「45分」などの経過時間に変換して出す)
  final DateTime repliedAt;

  /// 返信の本文
  final String text;
}
