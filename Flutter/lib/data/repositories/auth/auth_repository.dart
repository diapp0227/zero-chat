/// サインアップ・サインイン・サインアウトを受け持つ窓口
///
/// 失敗したときは、理由を [AuthFailure] にして投げる
abstract class AuthRepository {
  /// 前回のサインインが端末に残っていて、そのまま使えるか
  Future<bool> isSignedIn();

  /// [email] と [password] でアカウントを作る。成功すると [email] に確認コードが届く
  Future<void> signUp({required String email, required String password});

  /// メールで届いた確認コード [code] で、[email] のアカウントを使える状態にする
  ///
  /// 確認だけではサインインしないので、続けて [signIn] を呼ぶ
  Future<void> confirmSignUp({required String email, required String code});

  /// [email] に確認コードを送り直す
  Future<void> resendSignUpCode({required String email});

  /// [email] と [password] でサインインする
  ///
  /// アカウントの確認がまだ済んでいなければ、サインインせずに
  /// [SignInOutcome.confirmationRequired] を返す
  Future<SignInOutcome> signIn({
    required String email,
    required String password,
  });

  /// サインアウトする (端末に残っているサインインの情報を消す)
  Future<void> signOut();
}

/// サインインの結果
enum SignInOutcome {
  /// サインインできた
  signedIn,

  /// アカウントの確認 (確認コードの入力) がまだ済んでいない
  confirmationRequired,
}

/// 認証に失敗した理由
enum AuthFailureReason {
  /// そのメールアドレスはすでに登録されている
  emailAlreadyExists,

  /// パスワードが条件を満たしていない
  invalidPassword,

  /// メールアドレスかパスワードが違う
  wrongCredentials,

  /// 確認コードが違う
  codeMismatch,

  /// 確認コードの有効期限が切れている
  codeExpired,

  /// 確認コードのメールを送れなかった
  codeDeliveryFailed,

  /// 短い時間に試しすぎた
  tooManyAttempts,

  /// 通信できなかった
  network,

  /// それ以外
  unknown,
}

/// 認証に失敗したときに投げる例外
class AuthFailure implements Exception {
  const AuthFailure(this.reason, [this.cause]);

  /// 失敗した理由
  final AuthFailureReason reason;

  /// 元になった例外 (調査用)
  final Object? cause;

  @override
  String toString() => 'AuthFailure(${reason.name}): $cause';
}
