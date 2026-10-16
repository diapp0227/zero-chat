import 'package:flutter_test/flutter_test.dart';

import 'package:zero_chat/data/repositories/post/http_post_repository.dart';
import 'package:zero_chat/data/services/api/api_service.dart';
import 'package:zero_chat/domain/models/post_category.dart';

/// テスト用の ApiService。リクエストを記録し、決まった JSON を返す
class _TestApiService implements ApiService {
  _TestApiService(this.response);

  /// getJson・postJson で返す JSON
  final Object? response;

  /// getJson に渡されたパス
  String? requestedPath;

  /// getJson に渡されたクエリパラメータ
  Map<String, String>? requestedQuery;

  @override
  Future<Object?> getJson(String path, {Map<String, String>? query}) async {
    requestedPath = path;
    requestedQuery = query;
    return response;
  }

  /// postJson に渡されたパス
  String? postedPath;

  /// postJson に渡された本文
  Object? postedBody;

  @override
  Future<Object?> postJson(String path, {required Object? body}) async {
    postedPath = path;
    postedBody = body;
    return response;
  }

  @override
  Future<Object?> putJson(String path, {required Object? body}) =>
      throw UnimplementedError();
}

void main() {
  group('HttpPostRepository', () {
    test('種類を指定しなければ、クエリなしで /posts を取得する', () async {
      final api = _TestApiService({'posts': <Object>[]});

      await HttpPostRepository(api).fetchPosts();

      expect(api.requestedPath, '/posts');
      expect(api.requestedQuery, isNull);
    });

    test('種類を指定すると、enum の名前を category に入れて取得する', () async {
      final api = _TestApiService({'posts': <Object>[]});

      await HttpPostRepository(
        api,
      ).fetchPosts(category: PostCategory.dailyReport);

      expect(api.requestedQuery, {'category': 'dailyReport'});
    });

    test('レスポンスの JSON を投稿に変換する', () async {
      final api = _TestApiService({
        'posts': [
          {
            'id': 2,
            'author': {'id': 2, 'name': 'いぬ', 'role': 'エンジニア'},
            'category': 'dailyReport',
            'text': '日報の本文',
            'postedAt': '2026-10-14T09:00:00Z',
            'replies': [
              {
                'id': 3,
                'author': {'id': 5, 'name': 'くま', 'role': 'デザイナー'},
                'text': '返信の本文',
                'repliedAt': '2026-10-14T09:15:00Z',
              },
            ],
          },
        ],
      });

      final posts = await HttpPostRepository(api).fetchPosts();

      final post = posts.single;
      expect(post.id, 2);
      expect(post.author.id, 2);
      expect(post.author.name, 'いぬ');
      expect(post.author.role, 'エンジニア');
      expect(post.category, PostCategory.dailyReport);
      expect(post.text, '日報の本文');
      // UTC の日時を、端末のタイムゾーンの日時にしている
      expect(post.postedAt, DateTime.utc(2026, 10, 14, 9).toLocal());
      expect(post.postedAt.isUtc, isFalse);

      final reply = post.replies.single;
      expect(reply.id, 3);
      expect(reply.author.name, 'くま');
      expect(reply.text, '返信の本文');
      expect(reply.repliedAt, DateTime.utc(2026, 10, 14, 9, 15).toLocal());
    });

    test('replies がなければ、返信は空', () async {
      final api = _TestApiService({
        'posts': [
          {
            'id': 1,
            'author': {'id': 1, 'name': 'ぱんだ', 'role': 'エンジニア'},
            'category': 'announcement',
            'text': 'お知らせの本文',
            'postedAt': '2026-10-14T09:00:00Z',
          },
        ],
      });

      final posts = await HttpPostRepository(api).fetchPosts();

      expect(posts.single.replies, isEmpty);
    });

    test('知らない種類が返ってきたらエラーになる', () async {
      final api = _TestApiService({
        'posts': [
          {
            'id': 1,
            'author': {'id': 1, 'name': 'ぱんだ', 'role': 'エンジニア'},
            'category': 'unknown',
            'text': '本文',
            'postedAt': '2026-10-14T09:00:00Z',
          },
        ],
      });

      expect(HttpPostRepository(api).fetchPosts(), throwsArgumentError);
    });

    test('投稿を作成するとき、種類・本文・名前・役職を /posts に POST する', () async {
      final api = _TestApiService({
        'post': {
          'id': 11,
          'author': {'id': 0, 'name': 'やまもと', 'role': 'デザイナー'},
          'category': 'selfStudy',
          'text': '自己学習の本文',
          'postedAt': '2026-10-15T09:00:00Z',
          'replies': <Object>[],
        },
      });

      await HttpPostRepository(api).createPost(
        category: PostCategory.selfStudy,
        text: '自己学習の本文',
        authorName: 'やまもと',
        authorRole: 'デザイナー',
      );

      expect(api.postedPath, '/posts');
      expect(api.postedBody, {
        'category': 'selfStudy',
        'text': '自己学習の本文',
        'author': {'name': 'やまもと', 'role': 'デザイナー'},
      });
    });

    test('作成した投稿として、サーバーが返した投稿を返す', () async {
      final api = _TestApiService({
        'post': {
          'id': 11,
          'author': {'id': 0, 'name': 'やまもと', 'role': 'デザイナー'},
          'category': 'selfStudy',
          'text': '自己学習の本文',
          'postedAt': '2026-10-15T09:00:00Z',
          'replies': <Object>[],
        },
      });

      final post = await HttpPostRepository(api).createPost(
        category: PostCategory.selfStudy,
        text: '自己学習の本文',
        authorName: 'やまもと',
        authorRole: 'デザイナー',
      );

      // 番号と投稿日時はサーバーが付けたもの
      expect(post.id, 11);
      expect(post.postedAt, DateTime.utc(2026, 10, 15, 9).toLocal());
      expect(post.author.name, 'やまもと');
      expect(post.category, PostCategory.selfStudy);
      expect(post.replies, isEmpty);
    });
  });
}
