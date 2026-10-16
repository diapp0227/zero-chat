import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../core/app_icon.dart';

/// 入力欄の左に出す印
enum AuthFieldPrefix {
  /// メールのアイコン
  mail,

  /// 人のアイコン (ユーザー名)
  user,

  /// 黄緑の ＊ (パスワード)
  password,

  /// 黄緑の # (認証コード)
  code,
}

/// サインイン画面の文字を入力する項目1つ分。上に項目名、下に入力欄、必要なら一番下に補足
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.prefix,
    required this.hintText,
    this.helperText,
    this.maxLength,
    this.obscureText = false,
    this.autofocus = false,
    this.onSubmitted,
  });

  /// 項目名 (例: メールアドレス)
  final String label;

  /// 入力した文字
  final TextEditingController controller;

  /// 入力欄の左に出す印。認証コードのときは数字6桁だけ入力できるようにする
  final AuthFieldPrefix prefix;

  /// 何も入力していないときに出すヒント
  final String hintText;

  /// 入力欄の下に出す補足 (例: コードの有効期限は10分です)
  final String? helperText;

  /// 入力できる最大文字数 (null なら制限しない)
  final int? maxLength;

  /// 入力した文字を ● で隠すか (パスワード)
  final bool obscureText;

  /// 画面を開いたらすぐ入力できる状態にするか
  final bool autofocus;

  /// キーボードの決定キーが押されたときの処理
  final VoidCallback? onSubmitted;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 選択中の見た目 (枠線の色・外側の帯) を切り替える
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
    final isCode = widget.prefix == AuthFieldPrefix.code;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(widget.label),
        const SizedBox(height: 7),
        _InputFrame(
          focused: focused,
          child: Row(
            spacing: 10,
            children: [
              _Prefix(prefix: widget.prefix),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  obscureText: widget.obscureText,
                  keyboardType: switch (widget.prefix) {
                    AuthFieldPrefix.mail => TextInputType.emailAddress,
                    AuthFieldPrefix.user => TextInputType.name,
                    AuthFieldPrefix.password => TextInputType.visiblePassword,
                    AuthFieldPrefix.code => TextInputType.number,
                  },
                  autofillHints: switch (widget.prefix) {
                    AuthFieldPrefix.mail => const [AutofillHints.email],
                    AuthFieldPrefix.user => const [AutofillHints.name],
                    AuthFieldPrefix.password => const [AutofillHints.password],
                    AuthFieldPrefix.code => const [AutofillHints.oneTimeCode],
                  },
                  inputFormatters: [
                    if (isCode) ...[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    if (widget.maxLength case final maxLength?)
                      LengthLimitingTextInputFormatter(maxLength),
                  ],
                  onSubmitted: (_) => widget.onSubmitted?.call(),
                  style: isCode
                      ? const TextStyle(
                          color: AppColors.inputText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4.8,
                        )
                      : const TextStyle(
                          color: AppColors.inputText,
                          fontSize: 12,
                        ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(color: AppColors.inputHint),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.helperText case final helperText?) ...[
          const SizedBox(height: 5),
          Text(
            helperText,
            style: const TextStyle(color: AppColors.authHelpText, fontSize: 8),
          ),
        ],
      ],
    );
  }
}

/// 入力欄の左の印 (幅 19)
class _Prefix extends StatelessWidget {
  const _Prefix({required this.prefix});

  /// 出す印の種類
  final AuthFieldPrefix prefix;

  @override
  Widget build(BuildContext context) {
    return switch (prefix) {
      AuthFieldPrefix.mail => const AppIcon(
        AppIconName.mail,
        size: 19,
        color: AppColors.authFieldIcon,
      ),
      AuthFieldPrefix.user => const AppIcon(
        AppIconName.user,
        size: 19,
        color: AppColors.authFieldIcon,
      ),
      AuthFieldPrefix.password => const SizedBox(
        width: 19,
        child: Padding(
          // ＊ は文字の上寄りに描かれるので、少し下げて入力欄の中央に見せる
          padding: EdgeInsets.only(top: 6),
          child: Text(
            '＊',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.authFieldMark, fontSize: 18),
          ),
        ),
      ),
      AuthFieldPrefix.code => const SizedBox(
        width: 19,
        child: Text(
          '#',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.authFieldMark,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    };
  }
}

/// サインイン画面の候補から1つを選ぶ項目 (役職)。上に項目名、下に押すと候補が開く欄
class AuthSelectField extends StatefulWidget {
  const AuthSelectField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  /// 項目名 (例: 役職)
  final String label;

  /// 入力欄の左に出すアイコン
  final AppIconName icon;

  /// 選ばれている候補
  final String value;

  /// 選べる候補の一覧
  final List<String> options;

  /// 候補の、画面に出す名前
  final String Function(String option) labelOf;

  /// 候補が選ばれたときの処理
  final ValueChanged<String> onChanged;

  @override
  State<AuthSelectField> createState() => _AuthSelectFieldState();
}

class _AuthSelectFieldState extends State<AuthSelectField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 選択中の見た目 (枠線の色・外側の帯) を切り替える
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(widget.label),
        const SizedBox(height: 7),
        _InputFrame(
          focused: _focusNode.hasFocus,
          child: Row(
            spacing: 10,
            children: [
              AppIcon(widget.icon, size: 19, color: AppColors.authFieldIcon),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.value,
                    focusNode: _focusNode,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: Colors.white,
                    focusColor: Colors.transparent,
                    icon: const AppIcon(
                      AppIconName.chevronDown,
                      size: 16,
                      color: AppColors.authFieldIcon,
                    ),
                    style: const TextStyle(
                      color: AppColors.inputText,
                      fontSize: 12,
                    ),
                    items: [
                      for (final option in widget.options)
                        DropdownMenuItem(
                          value: option,
                          child: Text(widget.labelOf(option)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) widget.onChanged(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 入力欄の上の項目名
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  /// 項目名
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.authFieldLabel,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// 入力欄の枠 (高さ 47・角丸・薄い背景)
///
/// 選択中は白くして枠線の色を変え、外側に帯を出す
class _InputFrame extends StatelessWidget {
  const _InputFrame({required this.focused, required this.child});

  /// 選択中か
  final bool focused;

  /// 枠の中身
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 47,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: focused ? Colors.white : AppColors.profileFieldBackground,
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
      child: child,
    );
  }
}
