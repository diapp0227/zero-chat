import 'package:flutter_riverpod/flutter_riverpod.dart';

/// サインインしているか
///
/// サーバーでの認証 (Cognito など) ができるまでは、アプリを閉じると未サインインに戻る
final authSessionProvider = NotifierProvider<AuthSession, bool>(
  AuthSession.new,
);

/// サインイン状態を覚えておき、signIn / signOut で切り替える
class AuthSession extends Notifier<bool> {
  @override
  bool build() => false;

  void signIn() => state = true;

  void signOut() => state = false;
}
