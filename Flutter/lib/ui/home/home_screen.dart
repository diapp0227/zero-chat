import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../core/breakpoints.dart';
import '../profile/current_profile.dart';
import 'home_view_model.dart';
import 'timeline_state.dart';
import 'widgets/post_cell.dart';
import 'widgets/timeline_category_tabs.dart';
import 'widgets/timeline_header.dart';

/// ホーム画面 (タイムライン)
///
/// PC (expanded 幅) では上部バーがヘッダーを兼ねるので TimelineHeader は出さない。
/// 開いたときに、自分のプロフィールをサーバーから読み込む
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // ヘッダーのアバターや投稿に使う名前・役職を最新にする
    ref.read(currentProfileProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isExpanded = ScreenSize.fromWidth(width) == ScreenSize.expanded;
    // 選択中のカテゴリの投稿 (読み込み中・失敗の状態も含む)
    final timeline = ref.watch(homeViewModelProvider);

    // スマホ・タブレットで列より画面が広いときは、列の左右に線を引く
    final showSideBorders = !isExpanded && width > _TimelineColumn.maxWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              if (!isExpanded) const _TimelineColumn(child: TimelineHeader()),
              _TimelineColumn(
                child: TimelineCategoryTabs(centered: !isExpanded),
              ),
              Expanded(
                child: switch (timeline) {
                  // 取得済み (カテゴリを切り替えて読み込み中も、前の投稿を出しておく)
                  AsyncValue(value: final timeline?) =>
                    timeline.posts.isEmpty
                        ? const _TimelineMessage(message: '投稿はまだありません')
                        : _TimelineList(
                            timeline: timeline,
                            onLoadMore: () => ref
                                .read(homeViewModelProvider.notifier)
                                .loadMore(),
                          ),
                  AsyncValue(error: _?) => _TimelineMessage(
                    message: '投稿を読み込めませんでした',
                    onRetry: () =>
                        ref.read(homeViewModelProvider.notifier).refresh(),
                  ),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ],
          ),
          if (showSideBorders)
            // 列の左右の線は、ヘッダーから一覧まで通して1本で引く
            const Positioned.fill(
              child: IgnorePointer(
                child: _TimelineColumn(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        vertical: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 投稿の一覧。一番下に、続きの読み込みの表示 (読み込み中・失敗) を置く
///
/// 一覧は画面の全幅に広げ、列の外側 (左右の余白) でもスクロールできるようにする
class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.timeline, required this.onLoadMore});

  /// 表示する投稿の一覧と、続きの読み込みの状態
  final TimelineState timeline;

  /// 続きを読み込む処理
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final posts = timeline.posts;
    return ListView.builder(
      // 下はフッタータブの裏に隠れないよう、その高さ分あける
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      itemCount: posts.length + 1,
      itemBuilder: (context, index) {
        if (index < posts.length) {
          return _TimelineColumn(
            child: PostCell(key: ValueKey(posts[index].id), post: posts[index]),
          );
        }
        return _TimelineFooter(timeline: timeline, onLoadMore: onLoadMore);
      },
    );
  }
}

/// 一覧の一番下。続きがあれば読み込み中の表示、失敗したら「再読み込み」を出す
///
/// ListView は画面の少し外 (下端の手前) の行から作るので、この行が作られたら
/// 一覧の下端の近くまでスクロールしたとみなして、続きを読み込む
class _TimelineFooter extends StatefulWidget {
  const _TimelineFooter({required this.timeline, required this.onLoadMore});

  /// 一覧と続きの読み込みの状態
  final TimelineState timeline;

  /// 続きを読み込む処理
  final VoidCallback onLoadMore;

  @override
  State<_TimelineFooter> createState() => _TimelineFooterState();
}

class _TimelineFooterState extends State<_TimelineFooter> {
  @override
  void initState() {
    super.initState();
    _loadMoreIfNeeded();
  }

  @override
  void didUpdateWidget(_TimelineFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 続きを足しても投稿が少なく、この行が画面に残っているときは、さらに続きを読む
    _loadMoreIfNeeded();
  }

  void _loadMoreIfNeeded() {
    final timeline = widget.timeline;
    if (!timeline.hasMore ||
        timeline.isLoadingMore ||
        timeline.loadMoreFailed) {
      return;
    }
    // 作っている途中に状態を変えないよう、描き終わってから読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLoadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeline = widget.timeline;
    if (!timeline.hasMore) return const SizedBox(height: 24);

    return _TimelineColumn(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: timeline.loadMoreFailed
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    const Text(
                      '読み込めませんでした',
                      style: TextStyle(color: AppColors.postMeta, fontSize: 12),
                    ),
                    TextButton(
                      onPressed: widget.onLoadMore,
                      child: const Text('再読み込み'),
                    ),
                  ],
                )
              : const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
        ),
      ),
    );
  }
}

/// 投稿がないときや読み込みに失敗したときに、一覧の代わりに出すメッセージ
class _TimelineMessage extends StatelessWidget {
  const _TimelineMessage({required this.message, this.onRetry});

  /// 表示するメッセージ
  final String message;

  /// 「再読み込み」ボタンが押されたときの処理 (null ならボタンを出さない)
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Text(
            message,
            style: const TextStyle(color: AppColors.postMeta, fontSize: 13),
          ),
          if (onRetry case final onRetry?)
            TextButton(onPressed: onRetry, child: const Text('再読み込み')),
        ],
      ),
    );
  }
}

/// 中身を最大 640px の列にして、画面の左右中央に置く
class _TimelineColumn extends StatelessWidget {
  const _TimelineColumn({required this.child});

  /// タイムラインの列の最大幅
  static const maxWidth = 640.0;

  /// 列に収める中身
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
