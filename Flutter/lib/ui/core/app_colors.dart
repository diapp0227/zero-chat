import 'package:flutter/material.dart';

/// デザイン (Figma Make「タイムライン作成」) のカラートークン
abstract final class AppColors {
  /// 文字の基本色
  static const text = Color(0xFF272821);

  /// 薄い区切り線 (フッター上端・タブの帯・投稿の下・列の左右など)
  static const border = Color(0xFFDEDDD5);

  /// フッタータブ：選ばれていないタブのアイコンと文字
  static const navInactive = Color(0xFF8E8E85);

  /// フッタータブ：選ばれているタブのアイコンと文字
  static const navActive = Color(0xFF667725);

  /// フッタータブ：選ばれているタブの背景
  static const navActiveBackground = Color(0xFFEFF0E4);

  /// フッタータブの背景 (少し透ける白)
  static const navBackground = Color(0xF2FFFFFF);

  /// 通知の件数バッジの背景
  static const badge = Color(0xFFC85B4B);

  /// ヘッダー (PC の上部バー・スマホの水色ヘッダー) の背景
  static const headerBackground = Color(0xFF82CDD7);

  /// PC の上部バーの下の線
  static const headerBorder = Color(0xFF6EBBC6);

  /// PC の上部バー：タブにマウスを乗せたときの背景 (半透明の白)
  static const headerNavHover = Color(0x4FFFFFFF);

  /// ロゴの「Zero」の文字
  static const logoText = Color(0xFF24251F);

  /// ロゴのマークの背景
  static const logoMarkBackground = Color(0xFF24251F);

  /// ロゴのマークの線 (∅)
  static const logoMarkForeground = Color(0xFFD9EB79);

  /// 「投稿する」ボタンの背景
  static const compose = Color(0xFF263746);

  /// 「投稿する」ボタンにマウスを乗せたときの背景
  static const composeHover = Color(0xFF1C2B38);

  /// アバターの白い縁の外側の細い線
  static const avatarRing = Color(0xFFD9D8CF);

  /// アバターのグラデーション (開始色と終了色) の候補。人の番号で選ぶ
  static const avatarGradients = [
    (Color(0xFFF4A98C), Color(0xFFD56C65)),
    (Color(0xFF92A9D8), Color(0xFF536B9E)),
    (Color(0xFFE8BD79), Color(0xFFB87947)),
    (Color(0xFF8FBEA0), Color(0xFF527A61)),
    (Color(0xFF80C9B2), Color(0xFF458B78)),
    (Color(0xFFBF9AD8), Color(0xFF795B9A)),
    (Color(0xFF7BB5CF), Color(0xFF47758D)),
  ];

  /// プロフィールメニュー：項目の文字とアイコン、スマホのヘッダーの ▼
  static const menuText = Color(0xFF4F5049);

  /// プロフィールメニュー：マウスを乗せた・選んだ項目の文字とアイコン
  static const menuHoverText = Color(0xFF59681F);

  /// プロフィールメニュー：マウスを乗せた・選んだ項目の背景
  static const menuHoverBackground = Color(0xFFF1F2E8);

  /// プロフィールメニュー：ログアウトなど取り消しにくい操作の文字とアイコン
  static const menuDanger = Color(0xFFA14D42);

  /// タイムラインのタブ：選ばれていないタブの文字
  static const tabInactive = Color(0xFF999990);

  /// タイムラインのタブ：選ばれているタブの下線
  static const tabIndicator = Color(0xFF70822A);

  /// フィルターボタンのアイコン
  static const filterIcon = Color(0xFF77776F);

  /// フィルターボタンの枠線
  static const filterBorder = Color(0xFFE0DFD7);

  /// フィルターボタンの背景
  static const filterBackground = Color(0xFFFBFAF6);

  /// 投稿・返信：名前の右の経過時間
  static const postMeta = Color(0xFF96968D);

  /// 投稿・返信：名前の下の肩書き
  static const postRole = Color(0xFFA09F96);

  /// 投稿の右上のボタン (保存・その他メニュー) のアイコン
  static const postAction = Color(0xFF96968D);

  /// 投稿の右上のボタンにマウスを乗せたときの背景
  static const postActionHover = Color(0xFFEFEFE3);

  /// 保存済みの保存ボタンのアイコン
  static const postSaved = Color(0xFF70822A);

  /// 投稿の中の押せる文字 (もっと見る・N件の返信)
  static const postLink = Color(0xFF718029);

  /// 投稿の画像の読み込み中・読み込み失敗時の背景
  static const postImagePlaceholder = Color(0xFFE1DFD5);

  /// 「返信する」の吹き出しアイコンと文字
  static const replySummary = Color(0xFF87877F);

  /// 返信の本文
  static const replyText = Color(0xFF4F5049);

  /// 返信の一覧の上の線
  static const repliesBorderTop = Color(0xFFEBEAE3);

  /// 返信の一覧の左の線
  static const repliesBorderLeft = Color(0xFFE7E9D8);
}
