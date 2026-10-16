import 'timeline_post.dart';

/// タイムラインに表示している内容と、続きの読み込みの状態
class TimelineState {
  const TimelineState({
    required this.posts,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  /// 読み込んだ投稿 (新しい順。続きを読み込むと後ろに足していく)
  final List<TimelinePost> posts;

  /// まだ読み込んでいない、より古い投稿があるか
  final bool hasMore;

  /// 続きを読み込んでいる途中か
  final bool isLoadingMore;

  /// 続きの読み込みに失敗したか (一覧の一番下に「再読み込み」を出す)
  final bool loadMoreFailed;

  TimelineState copyWith({
    List<TimelinePost>? posts,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) {
    return TimelineState(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}
