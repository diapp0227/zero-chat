import '../core/app_icon.dart';

/// タブ1つ分の表示データ。フッタータブと PC の上部バーで共通
class TabNavItem {
  const TabNavItem({required this.label, required this.icon, this.badge});

  final String label;
  final AppIconName icon;
  final String? badge;
}
