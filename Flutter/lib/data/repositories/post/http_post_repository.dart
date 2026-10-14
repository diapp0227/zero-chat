import '../../../domain/models/author.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/post_category.dart';
import '../../../domain/models/reply.dart';
import '../../services/api/api_service.dart';
import 'post_repository.dart';

/// サーバーの投稿取得 API (GET /posts) から投稿を取得する PostRepository
///
/// API は新しい順に最大 10 件を返す。
/// レスポンスの形は docs/public/get-posts-lambda.md を参照
class HttpPostRepository implements PostRepository {
  HttpPostRepository(this._apiService);

  final ApiService _apiService;

  @override
  Future<List<Post>> fetchPosts({PostCategory? category}) async {
    final json = await _apiService.getJson(
      '/posts',
      // 種類は enum の名前 (例: dailyReport) で渡す
      query: category == null ? null : {'category': category.name},
    );
    final posts = (json as Map<String, dynamic>)['posts'] as List<dynamic>;
    return posts.map((post) => _toPost(post as Map<String, dynamic>)).toList();
  }

  Post _toPost(Map<String, dynamic> json) => Post(
    id: json['id'] as int,
    author: _toAuthor(json['author'] as Map<String, dynamic>),
    category: PostCategory.values.byName(json['category'] as String),
    text: json['text'] as String,
    postedAt: _toDateTime(json['postedAt'] as String),
    replies: (json['replies'] as List<dynamic>? ?? [])
        .map((reply) => _toReply(reply as Map<String, dynamic>))
        .toList(),
  );

  Reply _toReply(Map<String, dynamic> json) => Reply(
    id: json['id'] as int,
    author: _toAuthor(json['author'] as Map<String, dynamic>),
    text: json['text'] as String,
    repliedAt: _toDateTime(json['repliedAt'] as String),
  );

  Author _toAuthor(Map<String, dynamic> json) => Author(
    id: json['id'] as int,
    name: json['name'] as String,
    role: json['role'] as String,
  );

  /// サーバーの日時 (UTC) を、端末のタイムゾーンの日時にする
  ///
  /// 「昨日」などの日付の判定を端末の日付で行うため
  DateTime _toDateTime(String value) => DateTime.parse(value).toLocal();
}
