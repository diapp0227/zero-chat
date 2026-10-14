import '../core/app_icon.dart';

/// タブ1つ分の表示データ。フッタータブと PC の上部バーで共通
class TabNavItem {
  const TabNavItem({required this.label, required this.icon, this.badge});

  /// タブの名前 (例: ホーム)
  final String label;

  /// タブのアイコン
  final AppIconName icon;

  /// アイコンの右上に出す件数 (例: 3。なければ null)
  final String? badge;
}
