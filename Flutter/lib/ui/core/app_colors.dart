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

  /// 投稿画面・プロフィール設定画面：PC で画面の後ろに敷く半透明の黒
  static const sheetBarrier = Color(0x99191A16);

  /// 投稿画面・プロフィール設定画面：見出しの行の下の線、投稿画面のツールバーの上の線
  static const sheetDivider = Color(0xFFE5E4DC);

  /// 投稿画面・プロフィール設定画面：「キャンセル」「戻る」の文字
  static const sheetCancel = Color(0xFF77776F);

  /// 投稿画面・プロフィール設定画面：押せない「投稿する」「保存」ボタンの文字
  static const sheetPrimaryDisabled = Color(0xFFAAA99F);

  /// 入力欄のヒント・文字数 (プロフィール設定)、投稿の種類の右の ＞
  static const inputHint = Color(0xFFAAA99F);

  /// 投稿画面・プロフィール設定画面：見出しの下の説明文
  static const sheetSubtitle = Color(0xFF92928A);

  /// 入力欄に入力した文字
  static const inputText = Color(0xFF30312B);

  /// 投稿画面：文字数の表示
  static const composeCounter = Color(0xFF9B9B92);

  /// 投稿画面：ツールバーのアイコン (画像・気分・予約)
  static const composeTool = Color(0xFF718029);

  /// 投稿画面：ツールバーのアイコンにマウスを乗せたときの背景
  static const composeToolHover = Color(0xFFEFEFE3);

  /// 投稿の種類の選択肢：枠線
  static const categoryOptionBorder = Color(0xFFE1E0D8);

  /// 投稿の種類の選択肢：背景
  static const categoryOptionBackground = Color(0xFFFBFAF6);

  /// 投稿の種類の選択肢：マウスを乗せたときの枠線
  static const categoryOptionHoverBorder = Color(0xFFBCC69A);

  /// 投稿の種類の選択肢：マウスを乗せたときの背景
  static const categoryOptionHoverBackground = Color(0xFFF4F5E9);

  /// 投稿の種類の選択肢：種類の名前
  static const categoryOptionText = Color(0xFF34352E);

  /// 投稿の種類の選択肢：種類の説明
  static const categoryOptionDescription = Color(0xFF8D8D84);

  /// 投稿の種類の選択肢：左のアイコン
  static const categoryOptionIcon = Color(0xFF667725);

  /// 投稿の種類の選択肢：左のアイコンの背景
  static const categoryOptionIconBackground = Color(0xFFE9ECD8);

  /// プロフィール設定画面：「プロフィール情報」の下の線
  static const profileIntroDivider = Color(0xFFE9E8E1);

  /// プロフィール設定画面：入力欄の上の項目名 (ユーザー名・役職)
  static const profileFieldLabel = Color(0xFF55564F);

  /// プロフィール設定画面：入力欄の背景
  static const profileFieldBackground = Color(0xFFFBFAF6);

  /// プロフィール設定画面：選択中の入力欄の枠線
  static const profileFieldFocusBorder = Color(0xFF879750);

  /// プロフィール設定画面：選択中の入力欄の外側の帯
  static const profileFieldFocusRing = Color(0xFFE7E9D8);

  /// 投稿画面：送信に失敗したときのメッセージの背景
  static const composeErrorBackground = Color(0xFFF8ECE9);

  /// 投稿画面：送信に失敗したときのメッセージの文字
  static const composeErrorText = Color(0xFFA14D42);
}
