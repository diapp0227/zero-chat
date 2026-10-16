import 'package:flutter/material.dart';

import '../../domain/models/post_category.dart';
import '../core/sheet.dart';
import 'widgets/compose_editor.dart';
import 'widgets/post_category_picker.dart';
import '../core/l10n.dart';

/// 投稿画面を開く
///
/// PC (expanded 幅) では背景をぼかした上に浮かぶカード、
/// スマホ・タブレットでは画面いっぱいの白い画面で表示する
Future<void> showComposeScreen(BuildContext context) {
  return showSheet(
    context,
    maxWidth: 560,
    barrierLabel: context.l10n.composeBarrier,
    builder: (context, fullScreen) => ComposeScreen(fullScreen: fullScreen),
  );
}

/// 投稿画面
///
/// 1. 投稿の種類を選ぶ (PostCategoryPicker)
/// 2. 本文を入力する (ComposeEditor)
/// の2ステップを、選んだ種類があるかどうかで切り替える
class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key, required this.fullScreen});

  /// 画面いっぱいに表示しているか (false なら PC 向けの浮かぶカード)
  final bool fullScreen;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  // 選んだ投稿の種類 (null なら種類を選ぶステップ)
  PostCategory? _category;

  @override
  Widget build(BuildContext context) {
    final category = _category;
    if (category == null) {
      return PostCategoryPicker(
        fullScreen: widget.fullScreen,
        onCancel: () => Navigator.of(context).pop(),
        onSelected: (category) => setState(() => _category = category),
      );
    }
    return ComposeEditor(
      category: category,
      fullScreen: widget.fullScreen,
      onBack: () => setState(() => _category = null),
    );
  }
}
