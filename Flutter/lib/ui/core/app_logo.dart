import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_colors.dart';

/// 「Zero」のロゴ (マーク + 文字)
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.markSize = 34,
    this.fontSize = 23,
    this.showText = true,
  });

  /// マークの大きさ
  final double markSize;

  /// 「Zero」の文字の大きさ
  final double fontSize;

  /// false ならマークだけ表示する
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Zero',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LogoMark(size: markSize),
          if (showText) ...[
            const SizedBox(width: 9),
            Text(
              'Zero',
              style: TextStyle(
                color: AppColors.logoText,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ロゴのマーク。黒い角丸 (左下だけ小さい) の中に黄緑の ∅
class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  /// マークの大きさ (角丸と中の線画も、この大きさに合わせて変わる)
  final double size;

  @override
  Widget build(BuildContext context) {
    // デザインの比率: 34px のマークに対し角丸 11 (左下のみ 4)、中の線画 27px
    final scale = size / 34;
    final radius = Radius.circular(11 * scale);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.logoMarkBackground,
        borderRadius: BorderRadius.only(
          topLeft: radius,
          topRight: radius,
          bottomRight: radius,
          bottomLeft: Radius.circular(4 * scale),
        ),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: SvgPicture.asset(
        'assets/logo/logo_mark.svg',
        width: 27 * scale,
        height: 27 * scale,
        colorFilter: const ColorFilter.mode(
          AppColors.logoMarkForeground,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
