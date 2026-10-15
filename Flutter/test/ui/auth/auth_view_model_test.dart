import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_chat/data/repositories/auth/auth_repository.dart';
import 'package:zero_chat/data/repositories/auth/auth_repository_provider.dart';
import 'package:zero_chat/data/repositories/auth/fake_auth_repository.dart';
import 'package:zero_chat/ui/auth/auth_session.dart';
import 'package:zero_chat/ui/auth/auth_view_model.dart';

void main() {
  group('AuthViewModel', () {
    const email = 'a@example.com';
    const password = 'Passw0rd!';

    late FakeAuthRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      // autoDispose で途中で破棄されないよう、テストの間は監視しておく
      container.listen(authViewModelProvider, (_, _) {});
    });

    AuthViewModel viewModel() => container.read(authViewModelProvider.notifier);

    test('サインアップ → 確認コードで、サインインしている状態になる', () async {
      expect(
        await viewModel().signUp(email: email, password: password),
        isTrue,
      );
      expect(container.read(authSessionProvider), isFalse);

      final signedIn = await viewModel().confirmAndSignIn(
        email: email,
        password: password,
        code: FakeAuthRepository.verificationCode,
      );

      expect(signedIn, isTrue);
      expect(container.read(authSessionProvider), isTrue);
      expect(container.read(authViewModelProvider), isA<AsyncData<void>>());
    });

    test('確認がまだのアカウントでサインインすると confirmationRequired', () async {
      await repository.signUp(email: email, password: password);

      final outcome = await viewModel().signIn(
        email: email,
        password: password,
      );

      expect(outcome, SignInOutcome.confirmationRequired);
      expect(container.read(authSessionProvider), isFalse);
    });

    test('失敗したら AsyncError (中身は AuthFailure) になり、clearError で消える', () async {
      final outcome = await viewModel().signIn(
        email: email,
        password: password,
      );

      expect(outcome, isNull);
      final state = container.read(authViewModelProvider);
      expect(
        state.error,
        isA<AuthFailure>().having(
          (e) => e.reason,
          'reason',
          AuthFailureReason.wrongCredentials,
        ),
      );

      viewModel().clearError();
      expect(container.read(authViewModelProvider).hasError, isFalse);
    });

    test('ログアウトするとサインインしていない状態に戻る', () async {
      await repository.signUp(email: email, password: password);
      await viewModel().confirmAndSignIn(
        email: email,
        password: password,
        code: FakeAuthRepository.verificationCode,
      );

      await container.read(authSessionProvider.notifier).signOut();

      expect(container.read(authSessionProvider), isFalse);
      expect(await repository.isSignedIn(), isFalse);
    });
  });
}
