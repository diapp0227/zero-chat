import 'package:flutter/material.dart';

import 'app_colors.dart';

enum AvatarSize {
  sm(dimension: 28, radius: 9, fontSize: 11),
  md(dimension: 38, radius: 12, fontSize: 14),
  lg(dimension: 44, radius: 14, fontSize: 16);

  const AvatarSize({
    required this.dimension,
    required this.radius,
    required this.fontSize,
  });

  final double dimension;
  final double radius;
  final double fontSize;
}

/// 名前の頭文字をグラデーション背景の角丸四角に表示するアイコン
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    required this.colors,
    this.size = AvatarSize.md,
  });

  final String name;

  /// グラデーションの開始色と終了色 (CSS の linear-gradient(145deg, ...) 相当)
  final (Color, Color) colors;
  final AvatarSize size;

  @override
  Widget build(BuildContext context) {
    final (start, end) = colors;
    return Container(
      width: size.dimension,
      height: size.dimension,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.57, -0.82),
          end: const Alignment(0.57, 0.82),
          colors: [start, end],
        ),
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(size.radius),
        boxShadow: const [
          BoxShadow(color: AppColors.avatarRing, spreadRadius: 1),
        ],
      ),
      child: Text(
        name.isEmpty ? '' : name.characters.first,
        style: TextStyle(
          color: Colors.white,
          fontSize: size.fontSize,
          fontFamily: 'Georgia',
          height: 1,
        ),
      ),
    );
  }
}
