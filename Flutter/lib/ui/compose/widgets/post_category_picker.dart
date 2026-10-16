import 'package:flutter/material.dart';

import '../../../domain/models/post_category.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../post_category_option.dart';
import '../../core/sheet_header.dart';
import '../../core/l10n.dart';

/// 投稿画面の1ステップ目。投稿の種類 (お知らせ・日報・自己学習) を選ぶ
class PostCategoryPicker extends StatelessWidget {
  const PostCategoryPicker({
    super.key,
    required this.fullScreen,
    required this.onCancel,
    required this.onSelected,
  });

  /// 画面いっぱいに表示しているか (スマホ・タブレット)。余白を少し変える
  final bool fullScreen;

  /// 「キャンセル」が押されたときの処理
  final VoidCallback onCancel;

  /// 種類が選ばれたときの処理
  final ValueChanged<PostCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          title: context.l10n.composeCategoryTitle,
          leadingLabel: context.l10n.cancel,
          onLeadingPressed: onCancel,
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: fullScreen
                ? const EdgeInsets.symmetric(horizontal: 20, vertical: 34)
                : const EdgeInsets.fromLTRB(28, 28, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.composeCategoryHeading,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 19,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.composeCategoryDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.sheetSubtitle,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: fullScreen ? 26 : 22),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: fullScreen ? 12 : 10,
                  children: [
                    for (final category in PostCategory.values)
                      _CategoryOption(
                        category: category,
                        minHeight: fullScreen ? 76 : 72,
                        onPressed: () => onSelected(category),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 投稿の種類の選択肢1つ分。左にアイコン、中央に名前と説明、右に ＞
class _CategoryOption extends StatefulWidget {
  const _CategoryOption({
    required this.category,
    required this.minHeight,
    required this.onPressed,
  });

  /// この選択肢の投稿の種類
  final PostCategory category;

  /// 選択肢の最低の高さ
  final double minHeight;

  /// 押されたときの処理
  final VoidCallback onPressed;

  @override
  State<_CategoryOption> createState() => _CategoryOptionState();
}

class _CategoryOptionState extends State<_CategoryOption> {
  // マウスが乗っているか (枠線と背景の色を変え、少し浮かせる)
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Semantics(
          button: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(0, _hovered ? -1 : 0, 0),
            constraints: BoxConstraints(minHeight: widget.minHeight),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.categoryOptionHoverBackground
                  : AppColors.categoryOptionBackground,
              border: Border.all(
                color: _hovered
                    ? AppColors.categoryOptionHoverBorder
                    : AppColors.categoryOptionBorder,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              spacing: 14,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.categoryOptionIconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AppIcon(
                    category.icon,
                    size: 22,
                    color: AppColors.categoryOptionIcon,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        category.label(context.l10n),
                        style: const TextStyle(
                          color: AppColors.categoryOptionText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        category.description(context.l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.categoryOptionDescription,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const AppIcon(
                  AppIconName.chevronRight,
                  size: 18,
                  color: AppColors.inputHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
