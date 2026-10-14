import 'author.dart';
import 'post_category.dart';
import 'reply.dart';

/// タイムラインの投稿1件
class Post {
  const Post({
    required this.id,
    required this.author,
    required this.category,
    required this.text,
    required this.postedAt,
    this.replies = const [],
  });

  /// 投稿を見分けるための一意な番号
  final int id;

  /// 投稿をした人
  final Author author;

  /// 投稿の種類 (お知らせ・日報・自己学習)
  final PostCategory category;

  /// 本文
  final String text;

  /// 投稿日時
  final DateTime postedAt;

  /// 返信の一覧 (表示する順。なければ空)
  final List<Reply> replies;
}
