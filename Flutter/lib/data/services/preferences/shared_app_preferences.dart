import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/app_language.dart';
import 'app_preferences.dart';

/// shared_preferences で端末に設定を保存する AppPreferences
///
/// 起動時に [create] で保存済みの値を読み込んでおき、ゲッターはすぐに値を返す
class SharedAppPreferences implements AppPreferences {
  SharedAppPreferences._(this._preferences);

  /// 端末に保存した設定を読み込んで作る
  static Future<SharedAppPreferences> create() async {
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: _Keys.all,
      ),
    );
    return SharedAppPreferences._(preferences);
  }

  final SharedPreferencesWithCache _preferences;

  @override
  AppLanguage? get language =>
      AppLanguage.fromCode(_preferences.getString(_Keys.language));

  @override
  Future<void> setLanguage(AppLanguage language) =>
      _preferences.setString(_Keys.language, language.code);
}

/// 端末に保存するときのキー。項目を足すときは、ここと [all] に足す
abstract final class _Keys {
  /// 表示の言語の言語コード (例: ja)
  static const language = 'language';

  /// 読み書きするキーの一覧 (これ以外のキーは読まない)
  static const all = {language};
}
