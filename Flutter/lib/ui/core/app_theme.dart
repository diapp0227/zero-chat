import 'package:flutter/material.dart';

/// アプリのテーマ (色の基本設定)
abstract final class AppTheme {
  static const _seedColor = Colors.blue;

  /// ライトモードのテーマ
  static final light = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
  );

  /// ダークモードのテーマ
  static final dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
  );
}
