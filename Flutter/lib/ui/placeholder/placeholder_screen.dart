import 'package:flutter/material.dart';

/// 未実装タブの仮画面
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  /// 画面の名前 (上部のバーと画面中央に表示する)
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title (未実装)')),
    );
  }
}
