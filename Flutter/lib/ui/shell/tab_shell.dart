import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_icon.dart';
import '../core/breakpoints.dart';
import 'bottom_nav_bar.dart';
import 'desktop_top_bar.dart';
import 'tab_nav_item.dart';

/// タブの並び順は router.dart の branches と一致させる
const tabNavItems = [
  TabNavItem(label: 'ホーム', icon: AppIconName.home),
  TabNavItem(label: '見つける', icon: AppIconName.search),
  TabNavItem(label: '通知', icon: AppIconName.bell, badge: '3'),
  TabNavItem(label: '組織', icon: AppIconName.organization),
  TabNavItem(label: 'メッセージ', icon: AppIconName.mail),
];

/// タブ切り替えの外枠
///
/// compact / medium 幅では画面下部のフッタータブ、
/// expanded 幅では画面上部のバーでタブを切り替える
class TabShell extends StatelessWidget {
  const TabShell({super.key, required this.navigationShell});

  /// 選ばれているタブの画面と、タブを切り替える操作 (go_router から渡される)
  final StatefulNavigationShell navigationShell;

  void _onSelected(int index) {
    // 選択中のタブを再度タップしたらそのタブの最初の画面に戻す
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _onCompose() {
    // 投稿画面は「4. 投稿画面」で実装する
  }

  @override
  Widget build(BuildContext context) {
    final size = ScreenSize.fromWidth(MediaQuery.sizeOf(context).width);

    if (size == ScreenSize.expanded) {
      return Scaffold(
        body: Column(
          children: [
            DesktopTopBar(
              items: tabNavItems,
              selectedIndex: navigationShell.currentIndex,
              onSelected: _onSelected,
              onCompose: _onCompose,
            ),
            // 上部の余白 (ステータスバー分) は DesktopTopBar が使うので中身からは外す
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: navigationShell,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: BottomNavBar(
        items: tabNavItems,
        selectedIndex: navigationShell.currentIndex,
        onSelected: _onSelected,
      ),
    );
  }
}
