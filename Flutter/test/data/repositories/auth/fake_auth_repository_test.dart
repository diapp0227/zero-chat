import 'package:flutter_test/flutter_test.dart';
import 'package:zero_chat/data/repositories/auth/auth_repository.dart';
import 'package:zero_chat/data/repositories/auth/fake_auth_repository.dart';

void main() {
  group('FakeAuthRepository', () {
    const email = 'a@example.com';
    const password = 'Passw0rd!';

    Matcher failsWith(AuthFailureReason reason) =>
        throwsA(isA<AuthFailure>().having((e) => e.reason, 'reason', reason));

    test('サインアップしただけでは確認が必要で、確認するとサインインできる', () async {
      final repository = FakeAuthRepository();
      await repository.signUp(email: email, password: password);

      expect(
        await repository.signIn(email: email, password: password),
        SignInOutcome.confirmationRequired,
      );
      expect(await repository.isSignedIn(), isFalse);

      await repository.confirmSignUp(
        email: email,
        code: FakeAuthRepository.verificationCode,
      );
      expect(
        await repository.signIn(email: email, password: password),
        SignInOutcome.signedIn,
      );
      expect(await repository.isSignedIn(), isTrue);

      await repository.signOut();
      expect(await repository.isSignedIn(), isFalse);
    });

    test('同じメールアドレスでは2回サインアップできない', () async {
      final repository = FakeAuthRepository();
      await repository.signUp(email: email, password: password);

      expect(
        repository.signUp(email: email, password: password),
        failsWith(AuthFailureReason.emailAlreadyExists),
      );
    });

    test('確認コードが違えば codeMismatch', () async {
      final repository = FakeAuthRepository();
      await repository.signUp(email: email, password: password);

      expect(
        repository.confirmSignUp(email: email, code: '000000'),
        failsWith(AuthFailureReason.codeMismatch),
      );
    });

    test('パスワード違い・未登録は wrongCredentials', () async {
      final repository = FakeAuthRepository(
        confirmedAccounts: {email: password},
      );

      expect(
        repository.signIn(email: email, password: 'wrong'),
        failsWith(AuthFailureReason.wrongCredentials),
      );
      expect(
        repository.signIn(email: 'b@example.com', password: password),
        failsWith(AuthFailureReason.wrongCredentials),
      );
    });
  });
}
