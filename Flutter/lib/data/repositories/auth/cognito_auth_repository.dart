import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import 'auth_repository.dart';

/// Cognito のユーザープール ID (例: ap-northeast-1_xxxxxxxxx)
///
/// ビルド時に `--dart-define-from-file=config/api.json` で渡す。
/// 渡さなければ空文字で、そのときは Cognito につながず FakeAuthRepository を使う
const cognitoUserPoolId = String.fromEnvironment('COGNITO_USER_POOL_ID');

/// Cognito のアプリケーションクライアント ID
const cognitoClientId = String.fromEnvironment('COGNITO_CLIENT_ID');

/// Cognito の設定が渡されているか
const isCognitoConfigured = cognitoUserPoolId != '' && cognitoClientId != '';

/// Amplify (Cognito とやり取りするライブラリ) で認証する AuthRepository
///
/// 使う前に一度だけ [configure] を呼ぶ
class CognitoAuthRepository implements AuthRepository {
  /// Amplify に Cognito の設定を渡す。アプリの起動時に一度だけ呼ぶ
  static Future<void> configure() async {
    await Amplify.addPlugin(AmplifyAuthCognito());
    // Amplify の設定ファイル (amplify_outputs.json) と同じ形の JSON を渡す
    await Amplify.configure(
      jsonEncode({
        'version': '1',
        'auth': {
          // ユーザープール ID の「_」より前がリージョン (例: ap-northeast-1)
          'aws_region': cognitoUserPoolId.split('_').first,
          'user_pool_id': cognitoUserPoolId,
          'user_pool_client_id': cognitoClientId,
          // メールアドレスでサインインし、確認コードはメールで受け取る
          'username_attributes': ['email'],
          'standard_required_attributes': ['email'],
          'user_verification_types': ['email'],
        },
      }),
    );
  }

  @override
  Future<bool> isSignedIn() => _guard(() async {
    final session = await Amplify.Auth.fetchAuthSession();
    return session.isSignedIn;
  });

  @override
  Future<void> signUp({required String email, required String password}) =>
      _guard(() async {
        await Amplify.Auth.signUp(
          username: email,
          password: password,
          options: SignUpOptions(
            userAttributes: {AuthUserAttributeKey.email: email},
          ),
        );
      });

  @override
  Future<void> confirmSignUp({required String email, required String code}) =>
      _guard(() async {
        await Amplify.Auth.confirmSignUp(
          username: email,
          confirmationCode: code,
        );
      });

  @override
  Future<void> resendSignUpCode({required String email}) => _guard(() async {
    await Amplify.Auth.resendSignUpCode(username: email);
  });

  @override
  Future<SignInOutcome> signIn({
    required String email,
    required String password,
  }) => _guard(() async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      return switch (result.nextStep.signInStep) {
        AuthSignInStep.done => SignInOutcome.signedIn,
        AuthSignInStep.confirmSignUp => SignInOutcome.confirmationRequired,
        // MFA など、このアプリでは使っていない手順を求められたとき
        final step => throw AuthFailure(AuthFailureReason.unknown, step),
      };
    } on UserNotConfirmedException {
      return SignInOutcome.confirmationRequired;
    }
  });

  @override
  Future<void> signOut() => _guard(() async {
    final result = await Amplify.Auth.signOut();
    // 端末のサインインの情報を消せなかったときだけ失敗にする
    // (サーバー側のトークンの無効化だけ失敗した場合は、端末からは消えている)
    if (result is CognitoFailedSignOut) {
      throw AuthFailure(AuthFailureReason.unknown, result.exception);
    }
  });

  @override
  Future<String?> accessToken() => _guard(() async {
    final session = await Amplify.Auth.fetchAuthSession();
    if (session is! CognitoAuthSession || !session.isSignedIn) return null;
    return session.userPoolTokensResult.valueOrNull?.accessToken.raw;
  });

  /// [action] を実行し、Amplify の例外を [AuthFailure] に変換する
  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on Exception catch (e) {
      throw AuthFailure(_reasonOf(e), e);
    }
  }

  static AuthFailureReason _reasonOf(Exception e) => switch (e) {
    UsernameExistsException() => AuthFailureReason.emailAlreadyExists,
    InvalidPasswordException() => AuthFailureReason.invalidPassword,
    // ユーザー存在エラーの防止が有効なので、登録されていないメールアドレスも
    // パスワード違いと同じ NotAuthorized になる
    NotAuthorizedServiceException() ||
    UserNotFoundException() => AuthFailureReason.wrongCredentials,
    CodeMismatchException() => AuthFailureReason.codeMismatch,
    ExpiredCodeException() => AuthFailureReason.codeExpired,
    CodeDeliveryFailureException() => AuthFailureReason.codeDeliveryFailed,
    LimitExceededException() ||
    TooManyRequestsException() ||
    TooManyFailedAttemptsException() => AuthFailureReason.tooManyAttempts,
    NetworkException() => AuthFailureReason.network,
    _ => AuthFailureReason.unknown,
  };
}
