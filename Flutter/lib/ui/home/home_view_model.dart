import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/post/post_repository_provider.dart';
import '../../domain/models/post.dart';
import '../../domain/models/post_page.dart';
import '../../domain/models/reply.dart';
import '../core/avatar.dart';
import 'timeline_category.dart';
import 'timeline_post.dart';
import 'timeline_state.dart';

/// ホーム画面 (タイムライン) に表示する投稿の一覧と、続きの読み込みの状態
final homeViewModelProvider =
    AsyncNotifierProvider<HomeViewModel, TimelineState>(HomeViewModel.new);

/// ホーム画面の状態を持つ ViewModel
///
/// 選択中のカテゴリの投稿を PostRepository から 10 件ずつ取得し、
/// 投稿セルに渡す形 (TimelinePost) に変換する。
/// カテゴリが切り替わると、最新の 10 件から自動で取得し直す
class HomeViewModel extends AsyncNotifier<TimelineState> {
  // 続きのページを読むための目印 (null なら続きはない)
  String? _nextCursor;

  // build のたびに 1 増やす。続きの読み込み中にカテゴリが変わったら、その結果を捨てるために使う
  int _generation = 0;

  @override
  Future<TimelineState> build() async {
    final generation = ++_generation;
    final category = ref.watch(selectedTimelineCategoryProvider);
    final page = await ref
        .watch(postRepositoryProvider)
        .fetchPosts(category: category.postCategory);
    if (generation == _generation) _nextCursor = page.nextCursor;
    return TimelineState(
      posts: page.posts.map(_toTimelinePost).toList(),
      hasMore: page.nextCursor != null,
    );
  }

  /// 投稿を最新の 10 件から取得し直す (読み込みに失敗したときの再試行などで使う)
  void refresh() => ref.invalidateSelf();

  /// 続きの 10 件を読み込み、一覧の後ろに足す
  ///
  /// 続きがないとき・読み込み中のときは何もしない。
  /// 失敗したら [TimelineState.loadMoreFailed] を true にする (もう一度呼ぶと読み直す)
  Future<void> loadMore() async {
    final current = state.value;
    final cursor = _nextCursor;
    if (current == null || current.isLoadingMore || cursor == null) return;

    final generation = _generation;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );

    final PostPage page;
    try {
      page = await ref
          .read(postRepositoryProvider)
          .fetchPosts(
            category: ref.read(selectedTimelineCategoryProvider).postCategory,
            cursor: cursor,
          );
    } on Exception {
      if (generation != _generation) return;
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreFailed: true),
      );
      return;
    }

    // 読み込み中にカテゴリが変わった・読み直したときは、古い一覧の続きなので使わない
    if (generation != _generation) return;
    _nextCursor = page.nextCursor;
    state = AsyncData(
      TimelineState(
        posts: [...current.posts, ...page.posts.map(_toTimelinePost)],
        hasMore: page.nextCursor != null,
      ),
    );
  }

  TimelinePost _toTimelinePost(Post post) => TimelinePost(
    id: post.id,
    authorName: post.author.name,
    authorRole: post.author.role,
    avatarColors: post.author.avatarColors ?? avatarColorsFor(post.author.id),
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
    avatarColors: reply.author.avatarColors ?? avatarColorsFor(reply.author.id),
    repliedAt: reply.repliedAt,
    text: reply.text,
  );
}
