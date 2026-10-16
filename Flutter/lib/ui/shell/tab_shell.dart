import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../compose/compose_screen.dart';
import '../core/app_icon.dart';
import '../core/breakpoints.dart';
import 'bottom_nav_bar.dart';
import 'desktop_top_bar.dart';
import 'mobile_compose_button.dart';
import 'tab_nav_item.dart';
import '../core/l10n.dart';

/// タブの一覧 (名前は表示の言語 [l10n] に合わせる)
///
/// タブの並び順は router.dart の branches と一致させる
List<TabNavItem> tabNavItems(AppLocalizations l10n) => [
  TabNavItem(label: l10n.tabHome, icon: AppIconName.home),
  TabNavItem(label: l10n.tabDiscover, icon: AppIconName.search),
  TabNavItem(label: l10n.tabNotifications, icon: AppIconName.bell, badge: '3'),
  TabNavItem(label: l10n.tabOrganization, icon: AppIconName.organization),
  TabNavItem(label: l10n.tabMessages, icon: AppIconName.mail),
];

/// タブ切り替えの外枠
///
/// compact / medium 幅では画面下部のフッタータブ、
/// expanded 幅では画面上部のバーでタブを切り替える。
/// 投稿画面は、compact / medium 幅では右下の ＋ ボタン、expanded 幅では上部バーの「投稿する」から開く
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

  void _onCompose(BuildContext context) {
    showComposeScreen(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = ScreenSize.fromWidth(MediaQuery.sizeOf(context).width);

    if (size == ScreenSize.expanded) {
      return Scaffold(
        body: Column(
          children: [
            DesktopTopBar(
              items: tabNavItems(context.l10n),
              selectedIndex: navigationShell.currentIndex,
              onSelected: _onSelected,
              onCompose: () => _onCompose(context),
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
      floatingActionButton: MobileComposeButton(
        onPressed: () => _onCompose(context),
      ),
      bottomNavigationBar: BottomNavBar(
        items: tabNavItems(context.l10n),
        selectedIndex: navigationShell.currentIndex,
        onSelected: _onSelected,
      ),
    );
  }
}
