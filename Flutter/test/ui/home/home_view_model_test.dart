import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zero_chat/data/repositories/post/post_repository.dart';
import 'package:zero_chat/data/repositories/post/post_repository_provider.dart';
import 'package:zero_chat/domain/models/author.dart';
import 'package:zero_chat/domain/models/post.dart';
import 'package:zero_chat/domain/models/post_category.dart';
import 'package:zero_chat/domain/models/post_page.dart';
import 'package:zero_chat/domain/models/profile.dart';
import 'package:zero_chat/domain/models/reply.dart';
import 'package:zero_chat/ui/core/avatar.dart';
import 'package:zero_chat/ui/home/home_view_model.dart';
import 'package:zero_chat/ui/home/timeline_category.dart';

/// テスト用の PostRepository。受け取った種類・目印を記録し、決まった投稿を 10 件ずつ返す
class _TestPostRepository implements PostRepository {
  _TestPostRepository(this.posts);

  /// 1 回で返す件数 (サーバーと同じ)
  static const pageSize = 10;

  /// 返す投稿
  final List<Post> posts;

  /// 続きの読み込み (cursor あり) で投げるエラー (null なら成功する)
  Object? loadMoreError;

  /// fetchPosts に渡された種類の記録
  final requestedCategories = <PostCategory?>[];

  /// fetchPosts に渡された目印の記録
  final requestedCursors = <String?>[];

  @override
  Future<PostPage> fetchPosts({PostCategory? category, String? cursor}) async {
    requestedCategories.add(category);
    requestedCursors.add(cursor);
    if (cursor != null && loadMoreError != null) throw loadMoreError!;
    final matched = posts
        .where((post) => category == null || post.category == category)
        .toList();
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, matched.length);
    return PostPage(
      posts: matched.sublist(start, end),
      nextCursor: end < matched.length ? '$end' : null,
    );
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

    final post = result.posts.first;
    expect(post.id, 10);
    expect(post.authorName, 'テスト');
    expect(post.authorRole, 'デザイナー');
    expect(post.avatarColors, avatarColorsFor(2));
    expect(post.postedAt, postedAt);
    // 投稿の種類がタイトルになる (名前は画面で表示の言語に合わせる)
    expect(post.category, PostCategory.dailyReport);
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

    final post = (await container.read(
      homeViewModelProvider.future,
    )).posts.single;

    expect(post.avatarColors, colors);
    expect(post.replies.single.avatarColors, colors);
  });

  test('「最新」ではすべての投稿を取得する', () async {
    final repository = _TestPostRepository(posts);
    final container = createContainer(repository);

    final result = await container.read(homeViewModelProvider.future);

    expect(repository.requestedCategories, [null]);
    expect(result.posts.map((post) => post.id), [10, 20]);
    // 2 件なので続きはない
    expect(result.hasMore, isFalse);
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
    expect(result.posts.map((post) => post.id), [20]);
  });

  group('続きの読み込み', () {
    // 新しい順に並んだ 25 件 (id 1〜25)
    final manyPosts = [
      for (var i = 1; i <= 25; i++)
        Post(
          id: i,
          author: author,
          category: PostCategory.dailyReport,
          text: '投稿 $i',
          postedAt: postedAt,
        ),
    ];

    Future<(ProviderContainer, _TestPostRepository)> load() async {
      final repository = _TestPostRepository(manyPosts);
      final container = createContainer(repository);
      container.listen(homeViewModelProvider, (_, _) {});
      await container.read(homeViewModelProvider.future);
      return (container, repository);
    }

    List<int> ids(ProviderContainer container) => container
        .read(homeViewModelProvider)
        .requireValue
        .posts
        .map((post) => post.id)
        .toList();

    test('最初は 10 件で、続きがある', () async {
      final (container, _) = await load();

      expect(ids(container), [for (var i = 1; i <= 10; i++) i]);
      expect(
        container.read(homeViewModelProvider).requireValue.hasMore,
        isTrue,
      );
    });

    test('loadMore で、前回の目印を渡して続きを後ろに足す', () async {
      final (container, repository) = await load();
      final viewModel = container.read(homeViewModelProvider.notifier);

      await viewModel.loadMore();
      expect(ids(container), [for (var i = 1; i <= 20; i++) i]);
      expect(repository.requestedCursors, [null, '10']);

      await viewModel.loadMore();
      expect(ids(container), [for (var i = 1; i <= 25; i++) i]);
      final timeline = container.read(homeViewModelProvider).requireValue;
      expect(timeline.hasMore, isFalse);

      // 最後まで読んだら、それ以上は取得しない
      await viewModel.loadMore();
      expect(repository.requestedCursors, [null, '10', '20']);
    });

    test('続きの読み込みに失敗したら loadMoreFailed になり、もう一度呼ぶと読み直す', () async {
      final (container, repository) = await load();
      final viewModel = container.read(homeViewModelProvider.notifier);

      repository.loadMoreError = Exception('offline');
      await viewModel.loadMore();
      var timeline = container.read(homeViewModelProvider).requireValue;
      expect(timeline.loadMoreFailed, isTrue);
      expect(timeline.isLoadingMore, isFalse);
      // 読み込み済みの投稿はそのまま
      expect(timeline.posts, hasLength(10));

      repository.loadMoreError = null;
      await viewModel.loadMore();
      timeline = container.read(homeViewModelProvider).requireValue;
      expect(timeline.loadMoreFailed, isFalse);
      expect(timeline.posts, hasLength(20));
    });

    test('読み直すと、最新の 10 件に戻る', () async {
      final (container, _) = await load();
      await container.read(homeViewModelProvider.notifier).loadMore();

      container.invalidate(homeViewModelProvider);
      await container.read(homeViewModelProvider.future);

      expect(ids(container), [for (var i = 1; i <= 10; i++) i]);
    });
  });
}
