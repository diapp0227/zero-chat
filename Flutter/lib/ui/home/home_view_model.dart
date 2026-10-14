import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/post/post_repository_provider.dart';
import '../../domain/models/post.dart';
import '../../domain/models/reply.dart';
import '../core/avatar.dart';
import 'timeline_category.dart';
import 'timeline_post.dart';

/// ホーム画面 (タイムライン) に表示する投稿の一覧
final homeViewModelProvider =
    AsyncNotifierProvider<HomeViewModel, List<TimelinePost>>(HomeViewModel.new);

/// ホーム画面の状態を持つ ViewModel
///
/// 選択中のカテゴリの投稿を PostRepository から取得し、
/// 投稿セルに渡す形 (TimelinePost) に変換する。
/// カテゴリが切り替わると、自動で取得し直す
class HomeViewModel extends AsyncNotifier<List<TimelinePost>> {
  @override
  Future<List<TimelinePost>> build() async {
    final category = ref.watch(selectedTimelineCategoryProvider);
    final posts = await ref
        .watch(postRepositoryProvider)
        .fetchPosts(category: category.postCategory);
    return posts.map(_toTimelinePost).toList();
  }

  /// 投稿を取得し直す (読み込みに失敗したときの再試行などで使う)
  void refresh() => ref.invalidateSelf();

  TimelinePost _toTimelinePost(Post post) => TimelinePost(
    id: post.id,
    authorName: post.author.name,
    authorRole: post.author.role,
    avatarColors: avatarColorsFor(post.author.id),
    postedAt: post.postedAt,
    // 投稿の種類を、本文の上のタイトルとして表示する
    title: post.category.label,
    text: post.text,
    replies: post.replies.map(_toTimelineReply).toList(),
  );

  TimelineReply _toTimelineReply(Reply reply) => TimelineReply(
    id: reply.id,
    authorName: reply.author.name,
    authorRole: reply.author.role,
    avatarColors: avatarColorsFor(reply.author.id),
    repliedAt: reply.repliedAt,
    text: reply.text,
  );
}
