import '../../../domain/models/post.dart';
import '../../../domain/models/post_category.dart';

/// 投稿を取得する窓口
///
/// 画面からは、この抽象クラスだけを使う。
/// 取得元 (仮のデータ・サーバーなど) を変えるときは、実装クラスを差し替える
abstract class PostRepository {
  /// 投稿の一覧を新しい順に取得する
  ///
  /// [category] を指定するとその種類の投稿だけ、null ならすべての投稿を返す
  Future<List<Post>> fetchPosts({PostCategory? category});
}
