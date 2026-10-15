import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'breakpoints.dart';

/// 投稿画面・プロフィール設定画面のような、今の画面の上に開く画面を表示する
///
/// PC (expanded 幅) では背景をぼかした上に浮かぶカード (横幅は最大 [maxWidth])、
/// スマホ・タブレットでは画面いっぱいの白い画面で表示する。
/// [builder] には画面いっぱいかどうかが渡されるので、余白などの出し分けに使う
Future<void> showSheet(
  BuildContext context, {
  required double maxWidth,
  required String barrierLabel,
  required Widget Function(BuildContext context, bool fullScreen) builder,
}) {
  final size = ScreenSize.fromWidth(MediaQuery.sizeOf(context).width);

  if (size != ScreenSize.expanded) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(child: builder(context, true)),
        ),
      ),
    );
  }

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: AppColors.sheetBarrier,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _SheetCard(maxWidth: maxWidth, child: builder(context, false)),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.ease);
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 5 * animation.value,
          sigmaY: 5 * animation.value,
        ),
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween(begin: 0.985, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

/// PC で画面の上部寄りに浮かべる、角丸の白いカード
class _SheetCard extends StatelessWidget {
  const _SheetCard({required this.maxWidth, required this.child});

  /// カードの最大の横幅
  final double maxWidth;

  /// カードの中身
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          // 画面の高さの 11% だけ上を空けて浮かべる
          padding: EdgeInsets.fromLTRB(20, screenHeight * 0.11, 20, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Material(
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              shadowColor: const Color(0x30171812),
              elevation: 24,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
