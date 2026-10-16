import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/preferences/app_preferences.dart';
import '../../domain/models/app_language.dart';

/// 画面の表示に使っている言語
///
/// 端末に保存した言語 (AppPreferences)、なければ端末の言語 (英語なら英語、それ以外は日本語)
final appLanguageProvider = NotifierProvider<AppLanguageState, AppLanguage>(
  AppLanguageState.new,
);

/// 表示の言語を覚えておき、select で切り替えて端末に保存する
class AppLanguageState extends Notifier<AppLanguage> {
  @override
  AppLanguage build() =>
      ref.read(appPreferencesProvider).language ?? _deviceLanguage();

  /// 表示の言語を [language] に切り替え、次に開いたときのために端末に保存する
  Future<void> select(AppLanguage language) async {
    state = language;
    await ref.read(appPreferencesProvider).setLanguage(language);
  }

  /// 端末の言語に近い言語。英語なら英語、それ以外は日本語
  AppLanguage _deviceLanguage() {
    final Locale locale = WidgetsBinding.instance.platformDispatcher.locale;
    return locale.languageCode == AppLanguage.en.code
        ? AppLanguage.en
        : AppLanguage.ja;
  }
}
