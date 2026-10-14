import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../core/app_logo.dart';
import '../../core/profile_menu_button.dart';

/// スマホ (compact / medium 幅) のタイムライン上部の水色ヘッダー
///
/// 中央にロゴ、右上にプロフィールメニュー。
/// タイムラインのタブ (TimelineCategoryTabs) はこの下に置く
class TimelineHeader extends StatelessWidget {
  const TimelineHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    // 水色の背景でもステータスバーの文字が読めるよう黒にする
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        height: 61 + topInset,
        padding: EdgeInsets.only(top: 15 + topInset),
        color: AppColors.headerBackground,
        child: const Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: AppLogo(markSize: 29, fontSize: 20),
            ),
            Positioned(top: 0, right: 18, child: ProfileMenuButton()),
          ],
        ),
      ),
    );
  }
}
