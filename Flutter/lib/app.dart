import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'routing/router.dart';
import 'ui/core/app_language_state.dart';
import 'ui/core/app_theme.dart';

/// アプリ全体。テーマ・表示の言語・ルーティング (画面の切り替え) を設定する
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'zero_chat',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: ref.watch(routerProvider),
      // 表示の言語は、選んだ言語 (端末に保存) に合わせる
      locale: Locale(ref.watch(appLanguageProvider).code),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
