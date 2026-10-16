import '../../../domain/models/app_language.dart';
import 'app_preferences.dart';

/// メモリ上だけで設定を持つ AppPreferences
///
/// テストで使う。アプリを閉じると消える
class InMemoryAppPreferences implements AppPreferences {
  /// [language] を渡すと、保存済みの言語として最初から持っておく
  InMemoryAppPreferences({AppLanguage? language}) : _language = language;

  AppLanguage? _language;

  @override
  AppLanguage? get language => _language;

  @override
  Future<void> setLanguage(AppLanguage language) async => _language = language;
}
