import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// すべてのテストの前に呼ばれる設定
///
/// テストの端末の言語は英語なので、日本語にしてから動かす
/// (画面の文言を日本語で確かめているテストが多いため。英語の表示は個別のテストで確かめる)
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
    ..localeTestValue = const Locale('ja')
    ..localesTestValue = const [Locale('ja')];
  await testMain();
}
