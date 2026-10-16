import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../auth_mode.dart';
import '../../core/l10n.dart';

/// 「サインアップ」「サインイン」を切り替えるボタン (グレーの帯の中に2つ並ぶ)
class AuthModeTabs extends StatelessWidget {
  const AuthModeTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// 選ばれている方
  final AuthMode selected;

  /// どちらかが押されたときの処理
  final ValueChanged<AuthMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.authSegmentBackground,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        spacing: 4,
        children: [
          for (final mode in AuthMode.values)
            Expanded(
              child: _AuthModeTab(
                label: mode.label(context.l10n),
                selected: mode == selected,
                onPressed: () => onSelected(mode),
              ),
            ),
        ],
      ),
    );
  }
}

/// 切り替えボタン1つ分。選ばれている方は白く浮かせる
class _AuthModeTab extends StatelessWidget {
  const _AuthModeTab({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  /// ボタンの文字
  final String label;

  /// 選ばれているか
  final bool selected;

  /// 押されたときの処理
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 39,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                if (selected)
                  const BoxShadow(
                    color: AppColors.authSegmentShadow,
                    offset: Offset(0, 3),
                    blurRadius: 10,
                  ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.inputText
                    : AppColors.authSegmentInactive,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
