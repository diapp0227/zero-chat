// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get cancel => 'キャンセル';

  @override
  String get back => '戻る';

  @override
  String get save => '保存';

  @override
  String get saving => '保存中…';

  @override
  String get reload => '再読み込み';

  @override
  String get tabHome => 'ホーム';

  @override
  String get tabDiscover => '見つける';

  @override
  String get tabNotifications => '通知';

  @override
  String get tabOrganization => '組織';

  @override
  String get tabMessages => 'メッセージ';

  @override
  String placeholderNotImplemented(String title) {
    return '$title (未実装)';
  }

  @override
  String get newPost => '新しい投稿';

  @override
  String get composeButton => '投稿する';

  @override
  String get profileMenu => 'プロフィールメニュー';

  @override
  String get menuProfileSettings => 'プロフィール設定';

  @override
  String get menuLogout => 'ログアウト';

  @override
  String get timelineLatest => '最新';

  @override
  String get categoryAnnouncement => 'お知らせ';

  @override
  String get categoryDailyReport => '日報';

  @override
  String get categorySelfStudy => '自己学習';

  @override
  String get categoryAnnouncementDescription => 'チームや組織への連絡を共有';

  @override
  String get categoryDailyReportDescription => '今日の取り組みや気づきを記録';

  @override
  String get categorySelfStudyDescription => '学んだことや知識を共有';

  @override
  String get timelineEmpty => '投稿はまだありません';

  @override
  String get timelineLoadFailed => '投稿を読み込めませんでした';

  @override
  String get timelineLoadMoreFailed => '読み込めませんでした';

  @override
  String get filterPosts => '投稿をフィルター';

  @override
  String get postSave => '保存';

  @override
  String get postUnsave => '保存を解除';

  @override
  String get postMoreMenu => 'その他のメニュー';

  @override
  String get postShowMore => 'もっと見る';

  @override
  String get postReply => '返信する';

  @override
  String postReplyCount(int count) {
    return '$count件の返信';
  }

  @override
  String get elapsedJustNow => 'たった今';

  @override
  String elapsedMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String elapsedHours(int hours) {
    return '$hours時間';
  }

  @override
  String get elapsedYesterday => '昨日';

  @override
  String elapsedDays(int days) {
    return '$days日';
  }

  @override
  String elapsedMonthDay(int month, int day, String monthName) {
    return '$month月$day日';
  }

  @override
  String elapsedYearMonthDay(int year, int month, int day, String monthName) {
    return '$year年$month月$day日';
  }

  @override
  String get composeBarrier => '投稿画面を閉じる';

  @override
  String get composeCategoryTitle => '投稿の種類';

  @override
  String get composeCategoryHeading => '何を共有しますか？';

  @override
  String get composeCategoryDescription => '投稿に合うタイトルを選んでください';

  @override
  String composeHint(String category) {
    return '$categoryの内容を入力...';
  }

  @override
  String get composeSubmit => '投稿する';

  @override
  String get composeSending => '投稿中…';

  @override
  String get composeFailed => '投稿できませんでした。時間をおいて、もう一度お試しください';

  @override
  String get replyBarrier => '返信画面を閉じる';

  @override
  String get replyTitle => '返信する';

  @override
  String get replySubmit => '返信する';

  @override
  String get replySending => '返信中…';

  @override
  String get replyHint => '返信内容を入力...';

  @override
  String get replyFailed => '返信できませんでした。時間をおいて、もう一度お試しください';

  @override
  String replyingTo(String name) {
    return '$nameさんの投稿に返信';
  }

  @override
  String get profileBarrier => 'プロフィール設定を閉じる';

  @override
  String get profileTitle => 'プロフィール設定';

  @override
  String get profileIntroTitle => 'プロフィール情報';

  @override
  String get profileIntroDescription => 'タイムラインに表示される情報とカラーです';

  @override
  String get userName => 'ユーザー名';

  @override
  String get userNameHint => 'ユーザー名を入力';

  @override
  String get role => '役職';

  @override
  String get color => 'カラー';

  @override
  String colorOption(int number) {
    return 'カラー$number';
  }

  @override
  String get language => '言語';

  @override
  String get profileSaveFailed => '保存できませんでした。時間をおいて、もう一度お試しください';

  @override
  String get roleEngineer => 'エンジニア';

  @override
  String get roleDesigner => 'デザイナー';

  @override
  String get roleProductManager => 'プロダクトマネージャー';

  @override
  String get roleSales => 'セールス';

  @override
  String get roleCorporate => 'コーポレート';

  @override
  String get authSignUp => 'サインアップ';

  @override
  String get authSignIn => 'サインイン';

  @override
  String get authLanguageSetting => '言語設定';

  @override
  String get authSignUpTitle => 'アカウントを作成';

  @override
  String get authSignUpDescription => '必要な情報を入力して、Zeroをはじめましょう。';

  @override
  String get authSignUpSubmit => 'アカウントを作成';

  @override
  String get authSignInTitle => 'おかえりなさい';

  @override
  String get authSignInDescription => '登録済みのアカウントでサインインしてください。';

  @override
  String get authSignInSubmit => 'サインイン';

  @override
  String get authVerifyTitle => '認証コードを入力';

  @override
  String authVerifyDescription(String email, int digits) {
    return '$email に送信した$digits桁の認証コードを入力してください。';
  }

  @override
  String get authVerifySubmit => '認証してはじめる';

  @override
  String get authCodeLabel => '認証コード';

  @override
  String get authCodeHelper => 'コードの有効期限は24時間です';

  @override
  String get authChangeEmail => 'メールアドレスを変更';

  @override
  String get authResendCode => 'コードを再送';

  @override
  String get authCodeResent => '認証コードを再送しました';

  @override
  String get authEmail => 'メールアドレス';

  @override
  String get authPassword => 'パスワード';

  @override
  String authPasswordHint(int count) {
    return '$count文字以上で入力';
  }

  @override
  String get authUserNameHint => '例：ああああ';

  @override
  String get authForgotPassword => 'パスワードを忘れた方';

  @override
  String get authSending => '送信中…';

  @override
  String get brandHeadline => '共有から、\n仕事がつながる。';

  @override
  String get brandBody => '日々の気づきや学びを気軽に共有して、チームのコミュニケーションをひとつ先へ。';

  @override
  String get brandNoteTitle => '小さな共有を、チームの力に。';

  @override
  String get brandNoteBody => 'Zeroなら必要な情報が自然と集まります。';

  @override
  String get authErrorEmailAlreadyExists => 'このメールアドレスはすでに登録されています。サインインしてください';

  @override
  String authErrorInvalidPassword(int count) {
    return 'パスワードは$count文字以上で入力してください';
  }

  @override
  String get authErrorWrongCredentials => 'メールアドレスまたはパスワードが正しくありません';

  @override
  String get authErrorCodeMismatch => '認証コードが正しくありません';

  @override
  String get authErrorCodeExpired => '認証コードの有効期限が切れています。コードを再送してください';

  @override
  String get authErrorCodeDeliveryFailed => '認証コードを送信できませんでした。メールアドレスを確認してください';

  @override
  String get authErrorTooManyAttempts => '試行回数が多すぎます。時間をおいて、もう一度お試しください';

  @override
  String get authErrorNetwork => '通信できませんでした。接続を確認して、もう一度お試しください';

  @override
  String get authErrorUnknown => 'うまくいきませんでした。時間をおいて、もう一度お試しください';
}
