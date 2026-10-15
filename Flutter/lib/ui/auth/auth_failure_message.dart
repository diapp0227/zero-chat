import '../../data/repositories/auth/auth_repository.dart';

/// 認証に失敗した理由を、画面に出すメッセージにする
extension AuthFailureMessage on AuthFailureReason {
  /// サインイン画面のボタンの上に出すメッセージ
  String get message => switch (this) {
    AuthFailureReason.emailAlreadyExists => 'このメールアドレスはすでに登録されています。サインインしてください',
    AuthFailureReason.invalidPassword => 'パスワードが条件を満たしていません',
    AuthFailureReason.wrongCredentials => 'メールアドレスまたはパスワードが正しくありません',
    AuthFailureReason.codeMismatch => '認証コードが正しくありません',
    AuthFailureReason.codeExpired => '認証コードの有効期限が切れています。コードを再送してください',
    AuthFailureReason.codeDeliveryFailed => '認証コードを送信できませんでした。メールアドレスを確認してください',
    AuthFailureReason.tooManyAttempts => '試行回数が多すぎます。時間をおいて、もう一度お試しください',
    AuthFailureReason.network => '通信できませんでした。接続を確認して、もう一度お試しください',
    AuthFailureReason.unknown => 'うまくいきませんでした。時間をおいて、もう一度お試しください',
  };
}
