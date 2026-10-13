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
  mail('mail'),
  plus('plus'),
  chevronDown('chevron_down'),
  settings('settings'),
  history('history'),
  help('help'),
  logout('logout'),
  filter('filter'),
  bookmark('bookmark'),
  bookmarkFilled('bookmark_filled'),
  comment('comment'),
  more('more');

  const AppIconName(this.fileName);

  final String fileName;

  String get assetPath => 'assets/icons/$fileName.svg';
}

class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.size = 21, this.color});

  final AppIconName name;
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
