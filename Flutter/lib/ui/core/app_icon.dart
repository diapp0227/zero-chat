import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// assets/icons/ の線画アイコン
enum AppIconName {
  home,
  search,
  bell,
  organization,
  mail;

  String get assetPath => 'assets/icons/$name.svg';
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
