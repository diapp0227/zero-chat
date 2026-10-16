import '../../data/repositories/auth/auth_repository.dart';
import '../core/l10n.dart';
import 'auth_screen.dart';

/// 認証に失敗した理由を、画面に出すメッセージにする
extension AuthFailureMessage on AuthFailureReason {
  /// サインイン画面のボタンの上に出すメッセージ
  String message(AppLocalizations l10n) => switch (this) {
    AuthFailureReason.emailAlreadyExists => l10n.authErrorEmailAlreadyExists,
    AuthFailureReason.invalidPassword => l10n.authErrorInvalidPassword(
      AuthScreen.minPasswordLength,
    ),
    AuthFailureReason.wrongCredentials => l10n.authErrorWrongCredentials,
    AuthFailureReason.codeMismatch => l10n.authErrorCodeMismatch,
    AuthFailureReason.codeExpired => l10n.authErrorCodeExpired,
    AuthFailureReason.codeDeliveryFailed => l10n.authErrorCodeDeliveryFailed,
    AuthFailureReason.tooManyAttempts => l10n.authErrorTooManyAttempts,
    AuthFailureReason.network => l10n.authErrorNetwork,
    AuthFailureReason.unknown => l10n.authErrorUnknown,
  };
}
