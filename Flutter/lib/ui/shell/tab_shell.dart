import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_icon.dart';
import '../core/breakpoints.dart';
import 'bottom_nav_bar.dart';

/// タブの並び順は router.dart の branches と一致させる
const tabNavItems = [
  BottomNavItem(label: 'ホーム', icon: AppIconName.home),
  BottomNavItem(label: '見つける', icon: AppIconName.search),
  BottomNavItem(label: '通知', icon: AppIconName.bell, badge: '3'),
  BottomNavItem(label: '組織', icon: AppIconName.organization),
  BottomNavItem(label: 'メッセージ', icon: AppIconName.mail),
];

/// タブ切り替えの外枠
///
/// compact / medium 幅ではフッタータブを表示する。
/// expanded 幅ではヘッダー側にナビゲーションを置く想定 (ヘッダー実装時に対応)
class TabShell extends StatelessWidget {
  const TabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onSelected(int index) {
    // 選択中のタブを再度タップしたらそのタブの最初の画面に戻す
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = ScreenSize.fromWidth(MediaQuery.sizeOf(context).width);
    final showBottomNav = size != ScreenSize.expanded;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: showBottomNav
          ? BottomNavBar(
              items: tabNavItems,
              selectedIndex: navigationShell.currentIndex,
              onSelected: _onSelected,
            )
          : null,
    );
  }
}
