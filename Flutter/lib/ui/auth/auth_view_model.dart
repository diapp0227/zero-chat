import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth/auth_repository.dart';
import '../../data/repositories/auth/auth_repository_provider.dart';
import '../profile/current_profile.dart';
import 'auth_session.dart';

/// サインイン画面の送信の状態
///
/// 送信前・送信成功は AsyncData、送信中は AsyncLoading、失敗は AsyncError (中身は AuthFailure)。
/// サインイン画面を離れると破棄される
final authViewModelProvider =
    NotifierProvider.autoDispose<AuthViewModel, AsyncValue<void>>(
      AuthViewModel.new,
    );

/// サインイン画面の ViewModel
///
/// AuthRepository でサインアップ・確認・サインインを行い、
/// サインインできたら authSessionProvider をサインインしている状態にする
class AuthViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// アカウントを作る。成功したら (確認コードがメールで届くので) true を返す
  Future<bool> signUp({required String email, required String password}) {
    return _run(() async {
      await _repository.signUp(email: email, password: password);
      return true;
    });
  }

  /// 確認コード [code] でアカウントを確認し、続けてサインインする。サインインできたら true を返す
  ///
  /// [profile] (サインアップで入力したユーザー名・役職) を渡すと、サインインできたときにプロフィールにする
  Future<bool> confirmAndSignIn({
    required String email,
    required String password,
    required String code,
    Profile? profile,
  }) {
    return _run(() async {
      await _repository.confirmSignUp(email: email, code: code);
      return _signIn(email: email, password: password, profile: profile);
    });
  }

  /// サインインする
  ///
  /// 確認がまだ済んでいないアカウントなら、確認コードを送り直して
  /// [SignInOutcome.confirmationRequired] を返す。失敗したら null を返す
  Future<SignInOutcome?> signIn({
    required String email,
    required String password,
  }) async {
    SignInOutcome? outcome;
    await _run(() async {
      outcome = await _repository.signIn(email: email, password: password);
      if (outcome == SignInOutcome.confirmationRequired) {
        // サインアップのときのコードは期限切れのことがあるので、新しく送る
        await _repository.resendSignUpCode(email: email);
      } else {
        ref.read(authSessionProvider.notifier).signIn();
      }
      return true;
    });
    return outcome;
  }

  /// 確認コードを送り直す。成功したら true を返す
  Future<bool> resendCode({required String email}) {
    return _run(() async {
      await _repository.resendSignUpCode(email: email);
      return true;
    });
  }

  /// 表示中のエラーを消す (入力し直したときなど)
  void clearError() {
    if (state.hasError) state = const AsyncData(null);
  }

  Future<bool> _signIn({
    required String email,
    required String password,
    Profile? profile,
  }) async {
    final outcome = await _repository.signIn(email: email, password: password);
    if (outcome != SignInOutcome.signedIn) {
      throw const AuthFailure(AuthFailureReason.unknown);
    }
    // ホームに移る前にプロフィールを入れておき、最初からユーザー名・役職を表示する
    if (profile != null) {
      ref.read(currentProfileProvider.notifier).save(profile);
    }
    ref.read(authSessionProvider.notifier).signIn();
    return true;
  }

  /// [action] を送信中の状態で実行し、失敗したらエラーの状態にして false を返す
  Future<bool> _run(Future<bool> Function() action) async {
    // 送信中に画面が切り替わっても、送信が終わるまでは破棄しない
    final keepAliveLink = ref.keepAlive();
    state = const AsyncLoading();
    try {
      final result = await action();
      state = const AsyncData(null);
      return result;
    } on AuthFailure catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    } finally {
      keepAliveLink.close();
    }
  }
}
