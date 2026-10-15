import 'package:flutter_test/flutter_test.dart';

import 'package:zero_chat/data/repositories/post/fake_post_repository.dart';
import 'package:zero_chat/domain/models/post_category.dart';

void main() {
  group('FakePostRepository', () {
    test('種類を指定しなければ、すべての投稿を新しい順に返す', () async {
      final posts = await FakePostRepository().fetchPosts();

      expect(posts, isNotEmpty);
      for (var i = 1; i < posts.length; i++) {
        expect(
          posts[i - 1].postedAt.isAfter(posts[i].postedAt) ||
              posts[i - 1].postedAt == posts[i].postedAt,
          isTrue,
        );
      }
    });

    test('種類を指定すると、その種類の投稿だけを返す', () async {
      final repository = FakePostRepository();
      final all = await repository.fetchPosts();

      for (final category in PostCategory.values) {
        final posts = await repository.fetchPosts(category: category);
        expect(posts.every((post) => post.category == category), isTrue);
        expect(
          posts.length,
          all.where((post) => post.category == category).length,
        );
      }
    });

    test('投稿・返信の番号はすべて一意', () async {
      final posts = await FakePostRepository().fetchPosts();
      final ids = [
        for (final post in posts) ...[
          post.id,
          for (final reply in post.replies) reply.id,
        ],
      ];

      expect(ids.toSet().length, ids.length);
    });

    test('作成した投稿は、一覧の先頭に出る', () async {
      final repository = FakePostRepository();

      final created = await repository.createPost(
        category: PostCategory.announcement,
        text: 'お知らせの本文',
        authorName: 'やまもと',
        authorRole: 'デザイナー',
      );
      final posts = await repository.fetchPosts();

      expect(posts.first.id, created.id);
      expect(created.text, 'お知らせの本文');
      expect(created.author.name, 'やまもと');
      expect(created.author.role, 'デザイナー');
    });

    test('作成した投稿は、その種類で絞り込んだ一覧にだけ出る', () async {
      final repository = FakePostRepository();

      final created = await repository.createPost(
        category: PostCategory.announcement,
        text: 'お知らせの本文',
        authorName: 'やまもと',
        authorRole: 'デザイナー',
      );

      final announcements = await repository.fetchPosts(
        category: PostCategory.announcement,
      );
      final dailyReports = await repository.fetchPosts(
        category: PostCategory.dailyReport,
      );
      expect(announcements.map((post) => post.id), contains(created.id));
      expect(dailyReports.map((post) => post.id), isNot(contains(created.id)));
    });

    test('作成した投稿にも、ほかと重ならない番号が付く', () async {
      final repository = FakePostRepository();

      for (var i = 0; i < 3; i++) {
        await repository.createPost(
          category: PostCategory.dailyReport,
          text: '日報 $i',
          authorName: 'やまもと',
          authorRole: 'エンジニア',
        );
      }
      final posts = await repository.fetchPosts();
      final ids = [
        for (final post in posts) ...[
          post.id,
          for (final reply in post.replies) reply.id,
        ],
      ];

      expect(ids.toSet().length, ids.length);
    });
  });
}
