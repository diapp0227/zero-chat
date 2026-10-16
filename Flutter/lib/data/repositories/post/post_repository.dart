import '../../../domain/models/post.dart';
import '../../../domain/models/post_category.dart';
import '../../../domain/models/post_page.dart';
import '../../../domain/models/profile.dart';
import '../../../domain/models/reply.dart';

/// 投稿を取得・作成し、返信する窓口
///
/// 画面からは、この抽象クラスだけを使う。
/// 取得元 (仮のデータ・サーバーなど) を変えるときは、実装クラスを差し替える
abstract class PostRepository {
  /// 投稿の一覧を新しい順に取得する
  ///
  /// [category] を指定するとその種類の投稿だけ、null ならすべての投稿を返す
  ///
  /// 1 回で新しい順に最大 10 件を返す。[cursor] に前回の [PostPage.nextCursor] を渡すと、その続きを返す
  Future<PostPage> fetchPosts({PostCategory? category, String? cursor});

  /// 投稿を作成し、作成された投稿を返す
  ///
  /// 投稿の番号と投稿日時は、作成する側 (サーバーなど) が決める。
  /// [authorName] と [authorRole] は投稿した人の名前と役職
  Future<Post> createPost({
    required PostCategory category,
    required String text,
    required String authorName,
    required String authorRole,
  });

  /// 番号 [postId] の投稿に、本文 [text] で返信し、作成された返信を返す
  ///
  /// 返信の番号と返信日時は、作成する側 (サーバーなど) が決める。
  /// [author] は返信する人のプロフィール。サーバー版はトークンからプロフィールを決めるので使わない
  Future<Reply> createReply({
    required int postId,
    required String text,
    required Profile author,
  });
}
