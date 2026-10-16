import 'dart:ui';

/// サーバーの色 (#RRGGBB) を、不透明の色にする
Color colorFromHex(String hex) =>
    Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));

/// 色を、サーバーの形 (#RRGGBB、大文字) の文字列にする。透明度は送らない
String hexFromColor(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
