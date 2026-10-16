import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zero_chat/data/repositories/post/post_repository.dart';
import 'package:zero_chat/data/repositories/post/post_repository_provider.dart';
import 'package:zero_chat/data/repositories/profile/fake_profile_repository.dart';
import 'package:zero_chat/data/repositories/profile/profile_repository_provider.dart';
import 'package:zero_chat/domain/models/author.dart';
import 'package:zero_chat/domain/models/post.dart';
import 'package:zero_chat/domain/models/post_category.dart';
import 'package:zero_chat/domain/models/post_page.dart';
import 'package:zero_chat/domain/models/profile.dart';
import 'package:zero_chat/domain/models/reply.dart';
import 'package:zero_chat/ui/home/home_view_model.dart';
import 'package:zero_chat/ui/profile/current_profile.dart';
import 'package:zero_chat/ui/reply/reply_view_model.dart';

/// テスト用の PostRepository。createReply の呼び出しを記録し、[error] があれば投げる
class _TestPostRepository implements PostRepository {
  _TestPostRepository({this.error});

  /// createReply で投げるエラー (null なら成功する)
  final Object? error;

  /// createReply に渡された値の記録
  final createdReplies = <(int, String, String)>[];

  /// fetchPosts が呼ばれた回数 (タイムラインを読み込み直したかの確認用)
  int fetchCount = 0;

  @override
  Future<PostPage> fetchPosts({PostCategory? category, String? cursor}) async {
    fetchCount++;
    return const PostPage(posts: [], nextCursor: null);
  }

  @override
  Future<Post> createPost({
    required PostCategory category,
    required String text,
    required String authorName,
    required String authorRole,
  }) => throw UnimplementedError();

  @override
  Future<Reply> createReply({
    required int postId,
    required String text,
    required Profile author,
  }) async {
    createdReplies.add((postId, text, author.name));
    if (error != null) throw error!;
    return Reply(
      id: 1,
      author: Author(id: 0, name: author.name, role: author.role),
      text: text,
      repliedAt: DateTime(2026, 10, 16),
    );
  }
}

void main() {
  group('ReplyViewModel', () {
    Future<ProviderContainer> createContainer(
      _TestPostRepository repository,
    ) async {
      final container = ProviderContainer(
        overrides: [
          postRepositoryProvider.overrideWithValue(repository),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(currentProfileProvider.notifier)
          .save(const Profile(name: 'ああああ', role: 'デザイナー'));
      // 返信画面が開いている間と同じく、状態を見ている人がいる状態にする
      container.listen(replyViewModelProvider, (_, _) {});
      return container;
    }

    test('プロフィールの人として返信し、タイムラインを読み込み直して true を返す', () async {
      final repository = _TestPostRepository();
      final container = await createContainer(repository);
      container.listen(homeViewModelProvider, (_, _) {});
      await container.read(homeViewModelProvider.future);

      final succeeded = await container
          .read(replyViewModelProvider.notifier)
          .submit(postId: 2, text: '返信の本文');
      await container.read(homeViewModelProvider.future);

      expect(succeeded, isTrue);
      expect(repository.createdReplies.single, (2, '返信の本文', 'ああああ'));
      expect(repository.fetchCount, 2);
      expect(container.read(replyViewModelProvider), isA<AsyncData<void>>());
    });

    test('返信に失敗したら AsyncError の状態になり、false を返す', () async {
      final container = await createContainer(
        _TestPostRepository(error: Exception('offline')),
      );

      final succeeded = await container
          .read(replyViewModelProvider.notifier)
          .submit(postId: 2, text: '返信の本文');

      expect(succeeded, isFalse);
      expect(container.read(replyViewModelProvider).hasError, isTrue);
    });
  });
}
