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
  });
}
