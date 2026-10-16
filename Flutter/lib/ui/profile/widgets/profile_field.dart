import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_icon.dart';

/// プロフィール設定画面の入力項目1つ分。上に項目名、下に入力欄
class ProfileField extends StatelessWidget {
  const ProfileField({super.key, required this.label, required this.child});

  /// 項目名 (例: ユーザー名)
  final String label;

  /// 入力欄 (ProfileTextInput・ProfileSelectInput)
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.profileFieldLabel,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        child,
      ],
    );
  }
}

/// 文字を入力する欄。右下に文字数を出す
class ProfileTextInput extends StatelessWidget {
  const ProfileTextInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.maxLength,
    this.autofocus = false,
  });

  /// 入力した文字
  final TextEditingController controller;

  /// 何も入力していないときに出すヒント
  final String hintText;

  /// 最大文字数
  final int maxLength;

  /// 画面を開いたらすぐ入力できる状態にするか
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return _FieldFrame(
      // 文字数を枠の右下に置けるよう、枠いっぱいに広げる
      builder: (focusNode) => Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              maxLength: maxLength,
              style: const TextStyle(color: AppColors.inputText, fontSize: 13),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: AppColors.inputHint),
                border: InputBorder.none,
                isCollapsed: true,
                // 右側は文字数の表示と重ならないよう空ける
                contentPadding: const EdgeInsets.fromLTRB(14, 0, 52, 0),
                // 文字数は右下に自前で出すので、TextField 標準の表示は消す
                counterText: '',
              ),
            ),
          ),
          Positioned(
            right: 13,
            bottom: 15,
            child: Text(
              '${controller.text.length} / $maxLength',
              style: const TextStyle(color: AppColors.inputHint, fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }
}

/// 候補から1つを選ぶ欄。押すと候補の一覧が開く
class ProfileSelectInput<T> extends StatelessWidget {
  const ProfileSelectInput({
    super.key,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  /// 選ばれている候補
  final T value;

  /// 選べる候補の一覧
  final List<T> options;

  /// 候補の、画面に出す名前
  final String Function(T option) labelOf;

  /// 候補が選ばれたときの処理
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldFrame(
      builder: (focusNode) => DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          focusNode: focusNode,
          isExpanded: true,
          padding: const EdgeInsets.only(left: 14, right: 14),
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          focusColor: Colors.transparent,
          icon: const AppIcon(
            AppIconName.chevronDown,
            size: 16,
            color: AppColors.filterIcon,
          ),
          style: const TextStyle(color: AppColors.inputText, fontSize: 13),
          items: [
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(labelOf(option))),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

/// 入力欄の枠 (高さ 48・角丸・薄い背景)
///
/// 選択中は枠線の色を変え、外側に帯を出す
class _FieldFrame extends StatefulWidget {
  const _FieldFrame({required this.builder});

  /// 枠の中身を作る。渡された FocusNode を入力欄に付けると、選択中の見た目に切り替わる
  final Widget Function(FocusNode focusNode) builder;

  @override
  State<_FieldFrame> createState() => _FieldFrameState();
}

class _FieldFrameState extends State<_FieldFrame> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.profileFieldBackground,
        border: Border.all(
          color: focused ? AppColors.profileFieldFocusBorder : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (focused)
            const BoxShadow(
              color: AppColors.profileFieldFocusRing,
              spreadRadius: 3,
            ),
        ],
      ),
      child: widget.builder(_focusNode),
    );
  }
}
