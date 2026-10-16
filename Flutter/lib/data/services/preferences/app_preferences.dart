import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/app_language.dart';
import 'in_memory_app_preferences.dart';

/// 端末に保存するアプリの設定の窓口
///
/// 保存する項目ごとに、読むためのゲッターと保存するメソッドを持つ。
/// 保存の仕組み (shared_preferences など) は実装クラスに閉じ込め、画面や ViewModel からは、このクラスだけを使う
abstract class AppPreferences {
  /// 選んだ表示の言語。まだ選んでいなければ null
  AppLanguage? get language;

  /// 表示の言語を [language] にして保存する
  Future<void> setLanguage(AppLanguage language);
}

/// アプリの設定の保存に使う AppPreferences
///
/// アプリの起動時 (main) に、端末に保存する SharedAppPreferences に差し替える。
/// 差し替えないとき (テストなど) は、メモリ上だけで持つ InMemoryAppPreferences
final appPreferencesProvider = Provider<AppPreferences>(
  (ref) => InMemoryAppPreferences(),
);
