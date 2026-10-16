import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../../core/app_logo.dart';
import '../../core/l10n.dart';

/// 見出しの明朝体。端末に無い場合は下の候補から順に探す
const authSerifFontFamily = 'Georgia';

/// [authSerifFontFamily] が無い端末で使う明朝体の候補
const authSerifFontFallback = ['Yu Mincho', 'Hiragino Mincho ProN', 'serif'];

/// サインイン画面の左側 (PC のみ)。水色の面にロゴ・キャッチコピー・メモを並べる
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // デザインでは見出しの大きさが画面幅の 4% (34〜48px)
    final headlineSize = (MediaQuery.sizeOf(context).width * 0.04).clamp(
      34.0,
      48.0,
    );

    return ClipRect(
      child: ColoredBox(
        color: AppColors.headerBackground,
        child: Stack(
          children: [
            // 右上の飾りの円 (半分ほど面の外にはみ出す)
            Positioned(
              top: -100,
              right: -110,
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.authBrandRing),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.authBrandRingOuter,
                      spreadRadius: 90,
                    ),
                    BoxShadow(
                      color: AppColors.authBrandRingInner,
                      spreadRadius: 45,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppLogo(),
                  const Spacer(),
                  const Text(
                    'WORKPLACE SOCIAL',
                    style: TextStyle(
                      color: AppColors.authBrandEyebrow,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.brandHeadline,
                    style: TextStyle(
                      color: AppColors.authBrandText,
                      fontFamily: authSerifFontFamily,
                      fontFamilyFallback: authSerifFontFallback,
                      fontSize: headlineSize,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      letterSpacing: headlineSize * -0.04,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 330),
                    child: Text(
                      context.l10n.brandBody,
                      style: const TextStyle(
                        color: AppColors.authBrandBody,
                        fontSize: 12,
                        height: 1.9,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const _BrandNote(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 左下のメモ。上に白い線、左に紺色の四角に入ったキラキラのアイコン
class _BrandNote extends StatelessWidget {
  const _BrandNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.authBrandNoteBorder)),
      ),
      child: Row(
        spacing: 11,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.authBrandText,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const AppIcon(
              AppIconName.sparkles,
              size: 17,
              color: AppColors.logoMarkForeground,
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: context.l10n.brandNoteTitle,
                    style: const TextStyle(
                      color: AppColors.authBrandText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: '\n${context.l10n.brandNoteBody}'),
                ],
              ),
              style: TextStyle(
                color: AppColors.authBrandNoteText,
                fontSize: 9,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
