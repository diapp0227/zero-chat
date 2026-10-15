import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zero_chat/data/repositories/post/post_repository.dart';
import 'package:zero_chat/data/repositories/post/post_repository_provider.dart';
import 'package:zero_chat/domain/models/author.dart';
import 'package:zero_chat/domain/models/post.dart';
import 'package:zero_chat/domain/models/post_category.dart';
import 'package:zero_chat/ui/compose/compose_view_model.dart';
import 'package:zero_chat/ui/home/home_view_model.dart';
import 'package:zero_chat/ui/profile/current_profile.dart';

/// テスト用の PostRepository。createPost の呼び出しを記録し、[error] があれば投げる
class _TestPostRepository implements PostRepository {
  _TestPostRepository({this.error});

  /// createPost で投げるエラー (null なら成功する)
  final Object? error;

  /// createPost に渡された値の記録
  final createdPosts = <Map<String, Object>>[];

  /// fetchPosts が呼ばれた回数 (タイムラインを読み込み直したかの確認用)
  int fetchCount = 0;

  @override
  Future<List<Post>> fetchPosts({PostCategory? category}) async {
    fetchCount++;
    return [];
  }

  @override
  Future<Post> createPost({
    required PostCategory category,
    required String text,
    required String authorName,
    required String authorRole,
  }) async {
    createdPosts.add({
      'category': category,
      'text': text,
      'authorName': authorName,
      'authorRole': authorRole,
    });
    if (error != null) throw error!;
    return Post(
      id: 1,
      author: Author(id: 0, name: authorName, role: authorRole),
      category: category,
      text: text,
      postedAt: DateTime(2026, 10, 15),
    );
  }
}

void main() {
  /// [repository] を使い、プロフィールを保存済みにした ProviderContainer
  ProviderContainer createContainer(_TestPostRepository repository) {
    final container = ProviderContainer(
      overrides: [postRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container
        .read(currentProfileProvider.notifier)
        .save(const Profile(name: 'やまもと', role: 'デザイナー'));
    // 投稿画面が開いている間と同じく、状態を見ている人がいる状態にする
    container.listen(composeViewModelProvider, (_, _) {});
    return container;
  }

  group('ComposeViewModel', () {
    test('最初は送信前 (AsyncData) の状態', () {
      final container = createContainer(_TestPostRepository());

      expect(container.read(composeViewModelProvider), isA<AsyncData<void>>());
    });

    test('プロフィールの名前と役職を付けて投稿を作成し、true を返す', () async {
      final repository = _TestPostRepository();
      final container = createContainer(repository);

      final succeeded = await container
          .read(composeViewModelProvider.notifier)
          .submit(category: PostCategory.dailyReport, text: '日報の本文');

      expect(succeeded, isTrue);
      expect(repository.createdPosts.single, {
        'category': PostCategory.dailyReport,
        'text': '日報の本文',
        'authorName': 'やまもと',
        'authorRole': 'デザイナー',
      });
      expect(container.read(composeViewModelProvider), isA<AsyncData<void>>());
    });

    test('送信中は AsyncLoading の状態になる', () async {
      final container = createContainer(_TestPostRepository());

      final future = container
          .read(composeViewModelProvider.notifier)
          .submit(category: PostCategory.dailyReport, text: '日報の本文');

      expect(container.read(composeViewModelProvider).isLoading, isTrue);
      await future;
    });

    test('作成に成功したら、タイムラインを読み込み直す', () async {
      final repository = _TestPostRepository();
      final container = createContainer(repository);
      container.listen(homeViewModelProvider, (_, _) {});
      await container.read(homeViewModelProvider.future);
      final fetchCountBefore = repository.fetchCount;

      await container
          .read(composeViewModelProvider.notifier)
          .submit(category: PostCategory.dailyReport, text: '日報の本文');
      await container.read(homeViewModelProvider.future);

      expect(repository.fetchCount, fetchCountBefore + 1);
    });

    test('作成に失敗したら AsyncError の状態になり、false を返す', () async {
      final repository = _TestPostRepository(error: Exception('通信エラー'));
      final container = createContainer(repository);
      container.listen(homeViewModelProvider, (_, _) {});
      await container.read(homeViewModelProvider.future);
      final fetchCountBefore = repository.fetchCount;

      final succeeded = await container
          .read(composeViewModelProvider.notifier)
          .submit(category: PostCategory.dailyReport, text: '日報の本文');
      await container.read(homeViewModelProvider.future);

      expect(succeeded, isFalse);
      expect(container.read(composeViewModelProvider).hasError, isTrue);
      // 失敗したときはタイムラインを読み込み直さない
      expect(repository.fetchCount, fetchCountBefore);
    });
  });
}
