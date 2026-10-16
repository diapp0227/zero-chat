import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// 投稿画面・返信画面の見出しの下に出すお知らせ (送信に失敗したときなど)
class ComposeNotice extends StatelessWidget {
  const ComposeNotice({
    super.key,
    required this.message,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  /// お知らせの文
  final String message;

  /// 文の色
  final Color foregroundColor;

  /// 背景の色
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: TextStyle(color: foregroundColor, fontSize: 11),
      ),
    );
  }
}

/// 投稿画面・返信画面の入力欄の下のツールバー。右端に文字数
class ComposeToolbar extends StatelessWidget {
  const ComposeToolbar({
    super.key,
    required this.length,
    required this.maxLength,
    required this.horizontalPadding,
  });

  /// 入力した本文の文字数
  final int length;

  /// 本文の最大文字数
  final int maxLength;

  /// 左右の余白
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 13,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.sheetDivider)),
      ),
      // 画像・気分・予約のボタンは、機能を作るまで出さない。
      // ボタンがあったときと同じ高さ (34) を保ち、文字数は右端に置く
      child: Container(
        height: 34,
        alignment: Alignment.centerRight,
        child: Text(
          '$length / $maxLength',
          style: const TextStyle(color: AppColors.composeCounter, fontSize: 9),
        ),
      ),
    );
  }
}
