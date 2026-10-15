import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../core/app_icon.dart';

/// 入力欄の左に出す印
enum AuthFieldPrefix {
  /// メールのアイコン
  mail,

  /// 黄緑の ＊ (パスワード)
  password,

  /// 黄緑の # (認証コード)
  code,
}

/// サインイン画面の入力項目1つ分。上に項目名、下に入力欄、必要なら一番下に補足
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.prefix,
    required this.hintText,
    this.helperText,
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
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.authFieldLabel,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 47,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: focused ? Colors.white : AppColors.profileFieldBackground,
            border: Border.all(
              color: focused
                  ? AppColors.profileFieldFocusBorder
                  : AppColors.border,
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
                    AuthFieldPrefix.password => TextInputType.visiblePassword,
                    AuthFieldPrefix.code => TextInputType.number,
                  },
                  autofillHints: switch (widget.prefix) {
                    AuthFieldPrefix.mail => const [AutofillHints.email],
                    AuthFieldPrefix.password => const [AutofillHints.password],
                    AuthFieldPrefix.code => const [AutofillHints.oneTimeCode],
                  },
                  inputFormatters: isCode
                      ? [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ]
                      : null,
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
