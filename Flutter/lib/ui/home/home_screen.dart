import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../core/breakpoints.dart';
import 'feed_tab.dart';
import 'widgets/feed_header.dart';
import 'widgets/feed_tabs.dart';

/// ホーム画面 (タイムライン)
///
/// PC (expanded 幅) では上部バーがヘッダーを兼ねるので FeedHeader は出さない
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// タイムラインの列の最大幅
  static const _feedMaxWidth = 640.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isExpanded = ScreenSize.fromWidth(width) == ScreenSize.expanded;
    final selectedTab = ref.watch(selectedFeedTabProvider);

    // スマホ・タブレットで列より画面が広いときは、列の左右に線を引く
    final showSideBorders = !isExpanded && width > _feedMaxWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _feedMaxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: showSideBorders
                  ? const Border.symmetric(
                      vertical: BorderSide(color: AppColors.border),
                    )
                  : null,
            ),
            child: Column(
              children: [
                if (!isExpanded) const FeedHeader(),
                FeedTabs(centered: !isExpanded),
                Expanded(
                  child: Center(
                    child: Text('${selectedTab.label}のタイムライン (未実装)'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
