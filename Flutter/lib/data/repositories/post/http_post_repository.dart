import '../../../domain/models/author.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/post_category.dart';
import '../../../domain/models/post_page.dart';
import '../../../domain/models/profile.dart';
import '../../../domain/models/reply.dart';
import '../../services/api/api_service.dart';
import '../../services/api/hex_color.dart';
import 'post_repository.dart';

/// サーバーの API で投稿を取得 (GET /posts)・作成 (POST /posts) し、
/// 返信 (POST /posts/{id}/replies) する PostRepository
///
/// 取得の API は新しい順に最大 10 件と、続きを読むための目印 (nextCursor) を返す。
/// レスポンスの形は docs/public/get-posts-lambda.md・create-post-lambda.md・create-reply-lambda.md を参照
class HttpPostRepository implements PostRepository {
  HttpPostRepository(this._apiService);

  final ApiService _apiService;

  @override
  Future<PostPage> fetchPosts({PostCategory? category, String? cursor}) async {
    final query = {
      // 種類は enum の名前 (例: dailyReport) で渡す
      'category': ?category?.name,
      'cursor': ?cursor,
    };
    final json =
        await _apiService.getJson('/posts', query: query.isEmpty ? null : query)
            as Map<String, dynamic>;
    final posts = json['posts'] as List<dynamic>;
    return PostPage(
      posts: posts
          .map((post) => _toPost(post as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  }

  @override
  Future<Post> createPost({
    required PostCategory category,
    required String text,
    required String authorName,
    required String authorRole,
  }) async {
    final json = await _apiService.postJson(
      '/posts',
      body: {
        // 種類は enum の名前 (例: dailyReport) で渡す
        'category': category.name,
        'text': text,
        // 投稿した人はサーバーがプロフィールから決める。
        // 以前の API (author を必須にしていた) でも投稿できるよう、送るだけ送る
        'author': {'name': authorName, 'role': authorRole},
      },
    );
    // サーバーが番号と投稿日時を付けた投稿が返ってくる
    return _toPost(
      (json as Map<String, dynamic>)['post'] as Map<String, dynamic>,
    );
  }

  @override
  Future<Reply> createReply({
    required int postId,
    required String text,
    required Profile author,
  }) async {
    // 返信した人はサーバーがトークンのプロフィールから決めるので、本文だけ送る
    final json = await _apiService.postJson(
      '/posts/$postId/replies',
      body: {'text': text},
    );
    return _toReply(
      (json as Map<String, dynamic>)['reply'] as Map<String, dynamic>,
    );
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
    // カラーは、プロフィールから作った投稿・返信にだけある
    avatarColors: switch ((json['color1'], json['color2'])) {
      (final String color1, final String color2) => (
        colorFromHex(color1),
        colorFromHex(color2),
      ),
      _ => null,
    },
  );

  /// サーバーの日時 (UTC) を、端末のタイムゾーンの日時にする
  ///
  /// 「昨日」などの日付の判定を端末の日付で行うため
  DateTime _toDateTime(String value) => DateTime.parse(value).toLocal();
}
