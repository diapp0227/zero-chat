import 'author.dart';

/// 投稿への返信1件
class Reply {
  const Reply({
    required this.id,
    required this.author,
    required this.text,
    required this.repliedAt,
  });

  /// 返信を見分けるための一意な番号
  final int id;

  /// 返信をした人
  final Author author;

  /// 返信の本文
  final String text;

  /// 返信日時
  final DateTime repliedAt;
}
