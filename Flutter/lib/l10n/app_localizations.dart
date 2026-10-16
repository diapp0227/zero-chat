import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// シートの左上のボタン
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// 投稿画面の左上のボタン
  ///
  /// In ja, this message translates to:
  /// **'戻る'**
  String get back;

  /// 保存するボタン
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// 保存している間のボタンの文字
  ///
  /// In ja, this message translates to:
  /// **'保存中…'**
  String get saving;

  /// 読み込みに失敗したときのボタン
  ///
  /// In ja, this message translates to:
  /// **'再読み込み'**
  String get reload;

  /// タブの名前
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get tabHome;

  /// タブの名前
  ///
  /// In ja, this message translates to:
  /// **'見つける'**
  String get tabDiscover;

  /// タブの名前
  ///
  /// In ja, this message translates to:
  /// **'通知'**
  String get tabNotifications;

  /// タブの名前
  ///
  /// In ja, this message translates to:
  /// **'組織'**
  String get tabOrganization;

  /// タブの名前
  ///
  /// In ja, this message translates to:
  /// **'メッセージ'**
  String get tabMessages;

  /// まだ作っていない画面の中央の文字
  ///
  /// In ja, this message translates to:
  /// **'{title} (未実装)'**
  String placeholderNotImplemented(String title);

  /// スマホの右下の ＋ ボタンの説明
  ///
  /// In ja, this message translates to:
  /// **'新しい投稿'**
  String get newPost;

  /// PC の上部バーの投稿ボタン
  ///
  /// In ja, this message translates to:
  /// **'投稿する'**
  String get composeButton;

  /// アバターのボタンの読み上げ
  ///
  /// In ja, this message translates to:
  /// **'プロフィールメニュー'**
  String get profileMenu;

  /// プロフィールメニューの項目
  ///
  /// In ja, this message translates to:
  /// **'プロフィール設定'**
  String get menuProfileSettings;

  /// プロフィールメニューの項目
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get menuLogout;

  /// タイムラインの「すべての投稿」のタブ
  ///
  /// In ja, this message translates to:
  /// **'最新'**
  String get timelineLatest;

  /// 投稿の種類
  ///
  /// In ja, this message translates to:
  /// **'お知らせ'**
  String get categoryAnnouncement;

  /// 投稿の種類
  ///
  /// In ja, this message translates to:
  /// **'日報'**
  String get categoryDailyReport;

  /// 投稿の種類
  ///
  /// In ja, this message translates to:
  /// **'自己学習'**
  String get categorySelfStudy;

  /// 投稿の種類の説明
  ///
  /// In ja, this message translates to:
  /// **'チームや組織への連絡を共有'**
  String get categoryAnnouncementDescription;

  /// 投稿の種類の説明
  ///
  /// In ja, this message translates to:
  /// **'今日の取り組みや気づきを記録'**
  String get categoryDailyReportDescription;

  /// 投稿の種類の説明
  ///
  /// In ja, this message translates to:
  /// **'学んだことや知識を共有'**
  String get categorySelfStudyDescription;

  /// 投稿が 0 件のとき
  ///
  /// In ja, this message translates to:
  /// **'投稿はまだありません'**
  String get timelineEmpty;

  /// 最初の読み込みに失敗したとき
  ///
  /// In ja, this message translates to:
  /// **'投稿を読み込めませんでした'**
  String get timelineLoadFailed;

  /// 続きの読み込みに失敗したとき
  ///
  /// In ja, this message translates to:
  /// **'読み込めませんでした'**
  String get timelineLoadMoreFailed;

  /// フィルターボタンの説明
  ///
  /// In ja, this message translates to:
  /// **'投稿をフィルター'**
  String get filterPosts;

  /// 投稿を保存するボタンの読み上げ
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get postSave;

  /// 保存済みの投稿のボタンの読み上げ
  ///
  /// In ja, this message translates to:
  /// **'保存を解除'**
  String get postUnsave;

  /// 投稿の右上の … ボタンの読み上げ
  ///
  /// In ja, this message translates to:
  /// **'その他のメニュー'**
  String get postMoreMenu;

  /// 長い本文の続きを開くボタン
  ///
  /// In ja, this message translates to:
  /// **'もっと見る'**
  String get postShowMore;

  /// 投稿の下の返信ボタン
  ///
  /// In ja, this message translates to:
  /// **'返信する'**
  String get postReply;

  /// 返信の一覧を開閉するボタン
  ///
  /// In ja, this message translates to:
  /// **'{count}件の返信'**
  String postReplyCount(int count);

  /// 1 分未満の経過時間
  ///
  /// In ja, this message translates to:
  /// **'たった今'**
  String get elapsedJustNow;

  /// 1 時間未満の経過時間
  ///
  /// In ja, this message translates to:
  /// **'{minutes}分'**
  String elapsedMinutes(int minutes);

  /// 24 時間未満の経過時間
  ///
  /// In ja, this message translates to:
  /// **'{hours}時間'**
  String elapsedHours(int hours);

  /// 前日
  ///
  /// In ja, this message translates to:
  /// **'昨日'**
  String get elapsedYesterday;

  /// 7 日未満の経過日数
  ///
  /// In ja, this message translates to:
  /// **'{days}日'**
  String elapsedDays(int days);

  /// 今年の日付。monthName は月の短い名前 (例: Oct)
  ///
  /// In ja, this message translates to:
  /// **'{month}月{day}日'**
  String elapsedMonthDay(int month, int day, String monthName);

  /// 去年以前の日付
  ///
  /// In ja, this message translates to:
  /// **'{year}年{month}月{day}日'**
  String elapsedYearMonthDay(int year, int month, int day, String monthName);

  /// 投稿画面の外側の読み上げ
  ///
  /// In ja, this message translates to:
  /// **'投稿画面を閉じる'**
  String get composeBarrier;

  /// 投稿の種類を選ぶ画面の見出し
  ///
  /// In ja, this message translates to:
  /// **'投稿の種類'**
  String get composeCategoryTitle;

  /// 投稿の種類を選ぶ画面の質問
  ///
  /// In ja, this message translates to:
  /// **'何を共有しますか？'**
  String get composeCategoryHeading;

  /// 投稿の種類を選ぶ画面の説明
  ///
  /// In ja, this message translates to:
  /// **'投稿に合うタイトルを選んでください'**
  String get composeCategoryDescription;

  /// 本文の入力欄のヒント
  ///
  /// In ja, this message translates to:
  /// **'{category}の内容を入力...'**
  String composeHint(String category);

  /// 投稿画面の右上のボタン
  ///
  /// In ja, this message translates to:
  /// **'投稿する'**
  String get composeSubmit;

  /// 投稿している間のボタンの文字
  ///
  /// In ja, this message translates to:
  /// **'投稿中…'**
  String get composeSending;

  /// 投稿に失敗したとき
  ///
  /// In ja, this message translates to:
  /// **'投稿できませんでした。時間をおいて、もう一度お試しください'**
  String get composeFailed;

  /// 返信画面の外側の読み上げ
  ///
  /// In ja, this message translates to:
  /// **'返信画面を閉じる'**
  String get replyBarrier;

  /// 返信画面の見出し
  ///
  /// In ja, this message translates to:
  /// **'返信する'**
  String get replyTitle;

  /// 返信画面の右上のボタン
  ///
  /// In ja, this message translates to:
  /// **'返信する'**
  String get replySubmit;

  /// 返信している間のボタンの文字
  ///
  /// In ja, this message translates to:
  /// **'返信中…'**
  String get replySending;

  /// 返信の入力欄のヒント
  ///
  /// In ja, this message translates to:
  /// **'返信内容を入力...'**
  String get replyHint;

  /// 返信に失敗したとき
  ///
  /// In ja, this message translates to:
  /// **'返信できませんでした。時間をおいて、もう一度お試しください'**
  String get replyFailed;

  /// 返信先の投稿者。name は太字で表示する
  ///
  /// In ja, this message translates to:
  /// **'{name}さんの投稿に返信'**
  String replyingTo(String name);

  /// プロフィール設定の外側の読み上げ
  ///
  /// In ja, this message translates to:
  /// **'プロフィール設定を閉じる'**
  String get profileBarrier;

  /// プロフィール設定の見出し
  ///
  /// In ja, this message translates to:
  /// **'プロフィール設定'**
  String get profileTitle;

  /// プロフィール設定の上部の見出し
  ///
  /// In ja, this message translates to:
  /// **'プロフィール情報'**
  String get profileIntroTitle;

  /// プロフィール設定の上部の説明
  ///
  /// In ja, this message translates to:
  /// **'タイムラインに表示される情報とカラーです'**
  String get profileIntroDescription;

  /// ユーザー名の項目名
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名'**
  String get userName;

  /// プロフィール設定のユーザー名のヒント
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名を入力'**
  String get userNameHint;

  /// 役職の項目名
  ///
  /// In ja, this message translates to:
  /// **'役職'**
  String get role;

  /// アバターのカラーの項目名
  ///
  /// In ja, this message translates to:
  /// **'カラー'**
  String get color;

  /// カラーの候補の読み上げ
  ///
  /// In ja, this message translates to:
  /// **'カラー{number}'**
  String colorOption(int number);

  /// プロフィール設定の言語の項目名
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get language;

  /// 保存に失敗したとき
  ///
  /// In ja, this message translates to:
  /// **'保存できませんでした。時間をおいて、もう一度お試しください'**
  String get profileSaveFailed;

  /// 役職
  ///
  /// In ja, this message translates to:
  /// **'エンジニア'**
  String get roleEngineer;

  /// 役職
  ///
  /// In ja, this message translates to:
  /// **'デザイナー'**
  String get roleDesigner;

  /// 役職
  ///
  /// In ja, this message translates to:
  /// **'プロダクトマネージャー'**
  String get roleProductManager;

  /// 役職
  ///
  /// In ja, this message translates to:
  /// **'セールス'**
  String get roleSales;

  /// 役職
  ///
  /// In ja, this message translates to:
  /// **'コーポレート'**
  String get roleCorporate;

  /// サインアップ・サインインの切り替え
  ///
  /// In ja, this message translates to:
  /// **'サインアップ'**
  String get authSignUp;

  /// サインアップ・サインインの切り替え
  ///
  /// In ja, this message translates to:
  /// **'サインイン'**
  String get authSignIn;

  /// サインイン画面の言語の項目名
  ///
  /// In ja, this message translates to:
  /// **'言語設定'**
  String get authLanguageSetting;

  /// サインアップの見出し
  ///
  /// In ja, this message translates to:
  /// **'アカウントを作成'**
  String get authSignUpTitle;

  /// サインアップの説明
  ///
  /// In ja, this message translates to:
  /// **'必要な情報を入力して、Zeroをはじめましょう。'**
  String get authSignUpDescription;

  /// サインアップのボタン
  ///
  /// In ja, this message translates to:
  /// **'アカウントを作成'**
  String get authSignUpSubmit;

  /// サインインの見出し
  ///
  /// In ja, this message translates to:
  /// **'おかえりなさい'**
  String get authSignInTitle;

  /// サインインの説明
  ///
  /// In ja, this message translates to:
  /// **'登録済みのアカウントでサインインしてください。'**
  String get authSignInDescription;

  /// サインインのボタン
  ///
  /// In ja, this message translates to:
  /// **'サインイン'**
  String get authSignInSubmit;

  /// 認証コードの見出し
  ///
  /// In ja, this message translates to:
  /// **'認証コードを入力'**
  String get authVerifyTitle;

  /// 認証コードの説明
  ///
  /// In ja, this message translates to:
  /// **'{email} に送信した{digits}桁の認証コードを入力してください。'**
  String authVerifyDescription(String email, int digits);

  /// 認証コードのボタン
  ///
  /// In ja, this message translates to:
  /// **'認証してはじめる'**
  String get authVerifySubmit;

  /// 認証コードの項目名
  ///
  /// In ja, this message translates to:
  /// **'認証コード'**
  String get authCodeLabel;

  /// 認証コードの補足
  ///
  /// In ja, this message translates to:
  /// **'コードの有効期限は24時間です'**
  String get authCodeHelper;

  /// 認証コードの画面のリンク
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスを変更'**
  String get authChangeEmail;

  /// 認証コードの画面のリンク
  ///
  /// In ja, this message translates to:
  /// **'コードを再送'**
  String get authResendCode;

  /// コードを再送したときのお知らせ
  ///
  /// In ja, this message translates to:
  /// **'認証コードを再送しました'**
  String get authCodeResent;

  /// メールアドレスの項目名
  ///
  /// In ja, this message translates to:
  /// **'メールアドレス'**
  String get authEmail;

  /// パスワードの項目名
  ///
  /// In ja, this message translates to:
  /// **'パスワード'**
  String get authPassword;

  /// パスワードのヒント
  ///
  /// In ja, this message translates to:
  /// **'{count}文字以上で入力'**
  String authPasswordHint(int count);

  /// サインアップのユーザー名のヒント
  ///
  /// In ja, this message translates to:
  /// **'例：ああああ'**
  String get authUserNameHint;

  /// サインインのリンク
  ///
  /// In ja, this message translates to:
  /// **'パスワードを忘れた方'**
  String get authForgotPassword;

  /// 送信している間のボタンの文字
  ///
  /// In ja, this message translates to:
  /// **'送信中…'**
  String get authSending;

  /// サインイン画面の左の見出し (PC)
  ///
  /// In ja, this message translates to:
  /// **'共有から、\n仕事がつながる。'**
  String get brandHeadline;

  /// サインイン画面の左の説明 (PC)
  ///
  /// In ja, this message translates to:
  /// **'日々の気づきや学びを気軽に共有して、チームのコミュニケーションをひとつ先へ。'**
  String get brandBody;

  /// サインイン画面の左下のメモ (PC)
  ///
  /// In ja, this message translates to:
  /// **'小さな共有を、チームの力に。'**
  String get brandNoteTitle;

  /// サインイン画面の左下のメモ (PC)
  ///
  /// In ja, this message translates to:
  /// **'Zeroなら必要な情報が自然と集まります。'**
  String get brandNoteBody;

  /// 認証のエラー
  ///
  /// In ja, this message translates to:
  /// **'このメールアドレスはすでに登録されています。サインインしてください'**
  String get authErrorEmailAlreadyExists;

  /// 認証のエラー
  ///
  /// In ja, this message translates to:
  /// **'パスワードは{count}文字以上で入力してください'**
  String authErrorInvalidPassword(int count);

  /// 認証のエラー
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスまたはパスワードが正しくありません'**
  String get authErrorWrongCredentials;

  /// 認証のエラー
  ///
  /// In ja, this message translates to:
  /// **'認証コードが正しくありません'**
  String get authErrorCodeMismatch;

  /// 認証のエラー
  ///
  /// In ja, this message translates to:
  /// **'認証コードの有効期限が切れています。コードを再送してください'**
  String get authErrorCodeExpired;

  /// 認証のエラー
  ///
  /// In ja, this message translates to:
  /// **'認証コードを送信できませんでした。メールアドレスを確認してください'**
  String get authErrorCodeDeliveryFailed;

  /// 認証のエラー
  ///
  /// In ja, this message translates to:
  /// **'試行回数が多すぎます。時間をおいて、もう一度お試しください'**
  String get authErrorTooManyAttempts;

  /// 認証のエラー
  ///
  /// In ja, this message translates to:
  /// **'通信できませんでした。接続を確認して、もう一度お試しください'**
  String get authErrorNetwork;

  /// 認証のエラー
  ///
  /// In ja, this message translates to:
  /// **'うまくいきませんでした。時間をおいて、もう一度お試しください'**
  String get authErrorUnknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
