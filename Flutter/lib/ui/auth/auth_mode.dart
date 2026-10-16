import '../core/l10n.dart';

/// サインイン画面で選べる操作
enum AuthMode {
  signUp,
  signIn;

  /// 切り替えボタンに表示する名前
  String label(AppLocalizations l10n) => switch (this) {
    AuthMode.signUp => l10n.authSignUp,
    AuthMode.signIn => l10n.authSignIn,
  };
}
