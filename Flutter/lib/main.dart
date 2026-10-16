import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/repositories/auth/cognito_auth_repository.dart';
import 'data/services/preferences/app_preferences.dart';
import 'data/services/preferences/shared_app_preferences.dart';
import 'ui/auth/auth_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cognito の設定が渡されていれば、Amplify (Cognito とやり取りするライブラリ) を準備する
  if (isCognitoConfigured) {
    await CognitoAuthRepository.configure();
  }

  // 端末に保存した設定 (表示の言語など) を読み込んでおく
  final preferences = await SharedAppPreferences.create();

  // 前回のサインインが端末に残っていれば、サインイン画面を飛ばしてホームを開く
  final container = ProviderContainer(
    overrides: [appPreferencesProvider.overrideWithValue(preferences)],
  );
  await container.read(authSessionProvider.notifier).restore();

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
