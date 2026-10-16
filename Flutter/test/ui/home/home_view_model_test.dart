import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zero_chat/data/repositories/post/post_repository.dart';
import 'package:zero_chat/data/repositories/post/post_repository_provider.dart';
import 'package:zero_chat/domain/models/author.dart';
import 'package:zero_chat/domain/models/post.dart';
import 'package:zero_chat/domain/models/post_category.dart';
import 'package:zero_chat/domain/models/profile.dart';
import 'package:zero_chat/domain/models/reply.dart';
import 'package:zero_chat/ui/core/avatar.dart';
import 'package:zero_chat/ui/home/home_view_model.dart';
import 'package:zero_chat/ui/home/timeline_category.dart';

/// テスト用の PostRepository。受け取った種類を記録し、決まった投稿を返す
class _TestPostRepository implements PostRepository {
  _TestPostRepository(this.posts);

  /// 返す投稿
  final List<Post> posts;

  /// fetchPosts に渡された種類の記録
  final requestedCategories = <PostCategory?>[];

  @override
  Future<List<Post>> fetchPosts({PostCategory? category}) async {
    requestedCategories.add(category);
    return posts
        .where((post) => category == null || post.category == category)
        .toList();
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
  }) => throw UnimplementedError();
}

void main() {
  const author = Author(id: 2, name: 'テスト', role: 'デザイナー');
  final postedAt = DateTime(2026, 10, 14, 9);
  final posts = [
    Post(
      id: 10,
      author: author,
      category: PostCategory.dailyReport,
      text: '日報の本文',
      postedAt: postedAt,
      replies: [
        Reply(id: 11, author: author, text: '返信の本文', repliedAt: postedAt),
      ],
    ),
    Post(
      id: 20,
      author: author,
      category: PostCategory.announcement,
      text: 'お知らせの本文',
      postedAt: postedAt,
    ),
  ];

  ProviderContainer createContainer(_TestPostRepository repository) =>
      ProviderContainer.test(
        overrides: [postRepositoryProvider.overrideWithValue(repository)],
      );

  test('投稿を投稿セルに渡す形に変換する', () async {
    final container = createContainer(_TestPostRepository(posts));

    final result = await container.read(homeViewModelProvider.future);

    final post = result.first;
    expect(post.id, 10);
    expect(post.authorName, 'テスト');
    expect(post.authorRole, 'デザイナー');
    expect(post.avatarColors, avatarColorsFor(2));
    expect(post.postedAt, postedAt);
    // 投稿の種類がタイトルになる
    expect(post.title, '日報');
    expect(post.text, '日報の本文');
    expect(post.replies.single.id, 11);
    expect(post.replies.single.text, '返信の本文');
  });

  test('author にカラーがあれば、その色でアバターを描く', () async {
    const colors = (Color(0xFF80C9B2), Color(0xFF458B78));
    const colored = Author(
      id: 0,
      name: 'ああああ',
      role: 'エンジニア',
      avatarColors: colors,
    );
    final container = createContainer(
      _TestPostRepository([
        Post(
          id: 30,
          author: colored,
          category: PostCategory.selfStudy,
          text: '本文',
          postedAt: postedAt,
          replies: [
            Reply(id: 1, author: colored, text: '返信', repliedAt: postedAt),
          ],
        ),
      ]),
    );

    final post = (await container.read(homeViewModelProvider.future)).single;

    expect(post.avatarColors, colors);
    expect(post.replies.single.avatarColors, colors);
  });

  test('「最新」ではすべての投稿を取得する', () async {
    final repository = _TestPostRepository(posts);
    final container = createContainer(repository);

    final result = await container.read(homeViewModelProvider.future);

    expect(repository.requestedCategories, [null]);
    expect(result.map((post) => post.id), [10, 20]);
  });

  test('カテゴリを切り替えると、その種類の投稿を取得し直す', () async {
    final repository = _TestPostRepository(posts);
    final container = createContainer(repository);
    // 自動で破棄されないよう、テストの間は監視しておく
    container.listen(homeViewModelProvider, (_, _) {});
    await container.read(homeViewModelProvider.future);

    container
        .read(selectedTimelineCategoryProvider.notifier)
        .select(TimelineCategory.announcement);
    final result = await container.read(homeViewModelProvider.future);

    expect(repository.requestedCategories, [null, PostCategory.announcement]);
    expect(result.map((post) => post.id), [20]);
  });
}
