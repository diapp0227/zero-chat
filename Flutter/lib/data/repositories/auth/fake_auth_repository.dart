import 'auth_repository.dart';

/// メモリ上だけでアカウントを管理する AuthRepository
///
/// Cognito の設定が渡されていないとき (開発中・テスト) に使う。
/// 確認コードは常に [verificationCode]。アプリを閉じると登録したアカウントは消える
class FakeAuthRepository implements AuthRepository {
  /// [confirmedAccounts] (メールアドレス → パスワード) は、確認済みのアカウントとして最初から登録しておく
  FakeAuthRepository({Map<String, String> confirmedAccounts = const {}}) {
    for (final MapEntry(key: email, value: password)
        in confirmedAccounts.entries) {
      _accounts[email] = _FakeAccount(password)..confirmed = true;
    }
  }

  /// 受け付ける確認コード
  static const verificationCode = '123456';

  // メールアドレスごとのアカウント
  final _accounts = <String, _FakeAccount>{};

  bool _signedIn = false;

  @override
  Future<bool> isSignedIn() async => _signedIn;

  @override
  Future<void> signUp({required String email, required String password}) async {
    if (_accounts.containsKey(email)) {
      throw const AuthFailure(AuthFailureReason.emailAlreadyExists);
    }
    _accounts[email] = _FakeAccount(password);
  }

  @override
  Future<void> confirmSignUp({
    required String email,
    required String code,
  }) async {
    final account = _accounts[email];
    if (account == null || code != verificationCode) {
      throw const AuthFailure(AuthFailureReason.codeMismatch);
    }
    account.confirmed = true;
  }

  @override
  Future<void> resendSignUpCode({required String email}) async {
    if (!_accounts.containsKey(email)) {
      throw const AuthFailure(AuthFailureReason.unknown);
    }
  }

  @override
  Future<SignInOutcome> signIn({
    required String email,
    required String password,
  }) async {
    final account = _accounts[email];
    if (account == null || account.password != password) {
      throw const AuthFailure(AuthFailureReason.wrongCredentials);
    }
    if (!account.confirmed) return SignInOutcome.confirmationRequired;
    _signedIn = true;
    return SignInOutcome.signedIn;
  }

  @override
  Future<void> signOut() async => _signedIn = false;

  /// 仮の実装はトークンを発行しないので、常に null (API にトークンを付けない)
  @override
  Future<String?> accessToken() async => null;
}

/// 仮のアカウント1件分
class _FakeAccount {
  _FakeAccount(this.password);

  /// 登録したパスワード
  final String password;

  /// 確認コードで確認済みか
  bool confirmed = false;
}
