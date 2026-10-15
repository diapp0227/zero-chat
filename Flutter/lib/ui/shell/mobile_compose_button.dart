import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_icon.dart';

/// スマホ・タブレット (compact / medium 幅) の右下に浮かぶ ＋ ボタン。押すと投稿画面を開く
///
/// PC では上部バーの「投稿する」ボタンが同じ役割
class MobileComposeButton extends StatelessWidget {
  const MobileComposeButton({super.key, required this.onPressed});

  /// 押されたときの処理
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x45263746),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: '新しい投稿',
        icon: const AppIcon(AppIconName.plus, size: 24, color: Colors.white),
        style: ButtonStyle(
          fixedSize: const WidgetStatePropertyAll(Size.square(50)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          backgroundColor: const WidgetStatePropertyAll(AppColors.compose),
        ),
      ),
    );
  }
}
