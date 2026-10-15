import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_icon.dart';

/// フォームの一番下の紺色のボタン (アカウントを作成・サインイン・認証してはじめる)
///
/// 入力が足りないとき (onPressed が null) は薄くして押せなくする
class AuthSubmitButton extends StatefulWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  /// ボタンの文字
  final String label;

  /// 押されたときの処理。null なら押せない
  final VoidCallback? onPressed;

  @override
  State<AuthSubmitButton> createState() => _AuthSubmitButtonState();
}

class _AuthSubmitButtonState extends State<AuthSubmitButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final hovered = enabled && _hovered;

    return Semantics(
      button: true,
      enabled: enabled,
      excludeSemantics: true,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: enabled ? 1 : 0.45,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              // マウスを乗せると 1px 浮かせる
              transform: Matrix4.translationValues(0, hovered ? -1 : 0, 0),
              decoration: BoxDecoration(
                color: hovered ? AppColors.composeHover : AppColors.compose,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  if (enabled)
                    const BoxShadow(
                      color: AppColors.authSubmitShadow,
                      offset: Offset(0, 8),
                      blurRadius: 20,
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const AppIcon(
                    AppIconName.chevronRight,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 黄緑の小さな文字だけのボタン (パスワードを忘れた方・コードを再送 など)
class AuthLinkButton extends StatelessWidget {
  const AuthLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  /// ボタンの文字
  final String label;

  /// 押されたときの処理
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.authLink,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
