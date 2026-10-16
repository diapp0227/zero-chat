import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth/auth_repository.dart';
import '../../data/repositories/auth/auth_repository_provider.dart';
import '../profile/current_profile.dart';

/// サインインしているか
///
/// 起動時に [AuthSession.restore] で、前回のサインインが端末に残っているかを確認する
final authSessionProvider = NotifierProvider<AuthSession, bool>(
  AuthSession.new,
);

/// サインイン状態を覚えておき、サインイン・サインアウトで切り替える
class AuthSession extends Notifier<bool> {
  @override
  bool build() => false;

  /// 前回のサインインが端末に残っていれば、サインインしている状態にする
  ///
  /// 確認できなかったとき (通信できないなど) はサインインしていない状態のままにする
  Future<void> restore() async {
    try {
      state = await ref.read(authRepositoryProvider).isSignedIn();
    } on AuthFailure {
      state = false;
    }
  }

  /// サインインしている状態にする。AuthRepository でサインインできたあとに呼ぶ
  void signIn() => state = true;

  /// サインアウトする
  ///
  /// 端末のサインインの情報を消せなかったときも、画面はサインインしていない状態に戻す
  Future<void> signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on AuthFailure {
      // 次に起動したときにサインインが残っていることがあるが、もう一度ログアウトすれば消える
    } finally {
      state = false;
      // 次にサインインした人に、前の人のプロフィールが見えないようにする
      ref.invalidate(currentProfileProvider);
    }
  }
}
