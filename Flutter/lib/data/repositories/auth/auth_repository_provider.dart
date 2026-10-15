import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'cognito_auth_repository.dart';
import 'fake_auth_repository.dart';

/// サインアップ・サインインに使う AuthRepository
///
/// Cognito の設定 ([cognitoUserPoolId]・[cognitoClientId]) が渡されていれば
/// CognitoAuthRepository、渡されていなければメモリ上だけで動く FakeAuthRepository。
/// テストでは overrides で別の実装に差し替える
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => isCognitoConfigured ? CognitoAuthRepository() : FakeAuthRepository(),
);
