import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// assets/icons/ の線画アイコン
///
/// 括弧内は SVG のファイル名 (拡張子なし)
enum AppIconName {
  home('home'),
  search('search'),
  bell('bell'),
  organization('organization'),
  user('user'),
  mail('mail'),
  plus('plus'),
  chevronDown('chevron_down'),
  chevronRight('chevron_right'),
  settings('settings'),
  history('history'),
  help('help'),
  logout('logout'),
  filter('filter'),
  bookmark('bookmark'),
  bookmarkFilled('bookmark_filled'),
  comment('comment'),
  more('more'),
  image('image'),
  smile('smile'),
  calendar('calendar'),
  sparkles('sparkles');

  const AppIconName(this.fileName);

  /// SVG のファイル名 (拡張子なし)
  final String fileName;

  String get assetPath => 'assets/icons/$fileName.svg';
}

/// assets/icons/ の SVG を、指定した大きさと色で表示する
class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.size = 21, this.color});

  /// 表示するアイコン
  final AppIconName name;

  /// 縦横の大きさ
  final double size;

  /// 未指定なら IconTheme の色を使う
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? IconTheme.of(context).color!;
    return SvgPicture.asset(
      name.assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }
}
