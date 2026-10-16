import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../shell/tab_shell.dart';

/// 未実装タブの仮画面
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.tabIndex});

  /// 何番目のタブの画面か (tabNavItems の順番)。タブの名前を画面の名前にする
  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = tabNavItems(l10n)[tabIndex].label;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(l10n.placeholderNotImplemented(title))),
    );
  }
}
