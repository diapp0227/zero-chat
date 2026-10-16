import 'post.dart';

/// 投稿の一覧の 1 ページ分 (新しい順に最大 10 件) と、続きを読むための目印
class PostPage {
  const PostPage({required this.posts, required this.nextCursor});

  /// このページの投稿 (新しい順)
  final List<Post> posts;

  /// 続きのページを読むための目印。次の fetchPosts の cursor にそのまま渡す。
  /// 最後のページなら null
  final String? nextCursor;
}
