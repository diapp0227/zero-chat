import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../core/breakpoints.dart';
import 'home_view_model.dart';
import 'timeline_post.dart';
import 'widgets/post_cell.dart';
import 'widgets/timeline_category_tabs.dart';
import 'widgets/timeline_header.dart';

/// ホーム画面 (タイムライン)
///
/// PC (expanded 幅) では上部バーがヘッダーを兼ねるので TimelineHeader は出さない
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isExpanded = ScreenSize.fromWidth(width) == ScreenSize.expanded;
    // 選択中のカテゴリの投稿 (読み込み中・失敗の状態も含む)
    final posts = ref.watch(homeViewModelProvider);

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
                child: switch (posts) {
                  // 取得済み (カテゴリを切り替えて読み込み中も、前の投稿を出しておく)
                  AsyncValue(value: final posts?) =>
                    posts.isEmpty
                        ? const _TimelineMessage(message: '投稿はまだありません')
                        : _TimelineList(posts: posts),
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

/// 投稿の一覧
///
/// 一覧は画面の全幅に広げ、列の外側 (左右の余白) でもスクロールできるようにする
class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.posts});

  /// 表示する投稿の一覧
  final List<TimelinePost> posts;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // 下はフッタータブの裏に隠れないよう、その高さ分あける
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      itemCount: posts.length,
      itemBuilder: (context, index) => _TimelineColumn(
        child: PostCell(key: ValueKey(posts[index].id), post: posts[index]),
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
