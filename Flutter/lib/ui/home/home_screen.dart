import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../core/breakpoints.dart';
import 'sample_timeline_posts.dart';
import 'widgets/feed_header.dart';
import 'widgets/feed_tabs.dart';
import 'widgets/post_cell.dart';

/// ホーム画面 (タイムライン)
///
/// PC (expanded 幅) では上部バーがヘッダーを兼ねるので FeedHeader は出さない
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isExpanded = ScreenSize.fromWidth(width) == ScreenSize.expanded;
    // 投稿は仮のデータ。タブに応じた投稿の読み込みは「投稿の情報注入」で行う
    final posts = sampleTimelinePosts;

    // スマホ・タブレットで列より画面が広いときは、列の左右に線を引く
    final showSideBorders = !isExpanded && width > _FeedColumn.maxWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              if (!isExpanded) const _FeedColumn(child: FeedHeader()),
              _FeedColumn(child: FeedTabs(centered: !isExpanded)),
              Expanded(
                // 一覧は画面の全幅に広げ、列の外側 (左右の余白) でもスクロールできるようにする
                child: ListView.builder(
                  // 下はフッタータブの裏に隠れないよう、その高さ分あける
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) => _FeedColumn(
                    child: PostCell(
                      key: ValueKey(posts[index].id),
                      post: posts[index],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showSideBorders)
            // 列の左右の線は、ヘッダーから一覧まで通して1本で引く
            const Positioned.fill(
              child: IgnorePointer(
                child: _FeedColumn(
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

/// 中身を最大 640px の列にして、画面の左右中央に置く
class _FeedColumn extends StatelessWidget {
  const _FeedColumn({required this.child});

  /// タイムラインの列の最大幅
  static const maxWidth = 640.0;

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
