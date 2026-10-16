import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zero_chat/data/services/preferences/app_preferences.dart';
import 'package:zero_chat/data/services/preferences/in_memory_app_preferences.dart';
import 'package:zero_chat/domain/models/app_language.dart';
import 'package:zero_chat/ui/core/app_language_state.dart';

void main() {
  group('AppLanguageState', () {
    ProviderContainer createContainer(AppPreferences preferences) {
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('保存した言語があれば、その言語で始まる', () {
      final container = createContainer(
        InMemoryAppPreferences(language: AppLanguage.en),
      );

      expect(container.read(appLanguageProvider), AppLanguage.en);
    });

    test('保存した言語がなければ、端末の言語 (テストでは日本語) で始まる', () {
      final container = createContainer(InMemoryAppPreferences());

      expect(container.read(appLanguageProvider), AppLanguage.ja);
    });

    test('select で切り替えると、端末に保存する', () async {
      final preferences = InMemoryAppPreferences();
      final container = createContainer(preferences);

      await container.read(appLanguageProvider.notifier).select(AppLanguage.en);

      expect(container.read(appLanguageProvider), AppLanguage.en);
      expect(preferences.language, AppLanguage.en);
    });
  });

  test('AppLanguage.fromCode は、対応していない言語コードなら null', () {
    expect(AppLanguage.fromCode('en'), AppLanguage.en);
    expect(AppLanguage.fromCode('fr'), isNull);
    expect(AppLanguage.fromCode(null), isNull);
  });
}
