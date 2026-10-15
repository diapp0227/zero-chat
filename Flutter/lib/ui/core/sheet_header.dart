import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 投稿画面・プロフィール設定画面 (showSheet で開く画面) の上部。
/// 左にボタン、中央に見出し、右にボタン (なければ空き)
///
/// 見出しが左右のボタンの幅に関係なく中央に来るよう、左右を同じ幅で分ける
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    required this.leadingLabel,
    required this.onLeadingPressed,
    this.trailing,
  });

  /// 中央の見出し
  final String title;

  /// 左のボタンの文字 (キャンセル・戻る)
  final String leadingLabel;

  /// 左のボタンが押されたときの処理
  final VoidCallback onLeadingPressed;

  /// 右に置くボタン (なければ何も置かない)
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 61),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.sheetDivider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TextOnlyButton(
                label: leadingLabel,
                onPressed: onLeadingPressed,
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}

/// 背景も枠もない、文字だけのボタン (キャンセル・戻る)
class _TextOnlyButton extends StatelessWidget {
  const _TextOnlyButton({required this.label, required this.onPressed});

  /// ボタンの文字
  final String label;

  /// 押されたときの処理
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
        minimumSize: WidgetStatePropertyAll(Size.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: WidgetStatePropertyAll(AppColors.sheetCancel),
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
        textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11)),
      ),
      child: Text(label),
    );
  }
}

/// 見出しの右に置く、太字の文字だけのボタン (投稿する・保存)
///
/// [onPressed] が null のときは押せない見た目 (薄い文字) になる
class SheetPrimaryButton extends StatelessWidget {
  const SheetPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  /// ボタンの文字
  final String label;

  /// 押されたときの処理 (null なら押せない)
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        // 左の「キャンセル」「戻る」と同じく、背景なしで端に揃える
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 8),
        ),
        minimumSize: const WidgetStatePropertyAll(Size.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColors.sheetPrimaryDisabled
              : AppColors.compose,
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
      child: Text(label),
    );
  }
}
