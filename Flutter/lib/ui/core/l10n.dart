import 'package:flutter/widgets.dart';

import '../../domain/models/app_language.dart';
import '../../domain/models/post_category.dart';
import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

/// 画面の文言 (翻訳) を context から取り出す
extension AppLocalizationsContext on BuildContext {
  /// 今の表示の言語の文言
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// 投稿の種類の、画面に出す名前
extension PostCategoryLabel on PostCategory {
  /// 種類の名前 (例: 日報)
  String label(AppLocalizations l10n) => switch (this) {
    PostCategory.announcement => l10n.categoryAnnouncement,
    PostCategory.dailyReport => l10n.categoryDailyReport,
    PostCategory.selfStudy => l10n.categorySelfStudy,
  };
}

/// 役職 [role] の、画面に出す名前
///
/// 役職はサーバーに日本語の値 (profileRoles) で保存しているので、表示するときだけ翻訳する。
/// 知らない役職は、そのまま返す
String roleLabel(AppLocalizations l10n, String role) => switch (role) {
  'エンジニア' => l10n.roleEngineer,
  'デザイナー' => l10n.roleDesigner,
  'プロダクトマネージャー' => l10n.roleProductManager,
  'セールス' => l10n.roleSales,
  'コーポレート' => l10n.roleCorporate,
  _ => role,
};

/// 言語の名前。どの言語で表示していても見つけやすいよう、その言語自身の書き方で出す (例: English)
String languageName(AppLanguage language) => switch (language) {
  AppLanguage.ja => '日本語',
  AppLanguage.en => 'English',
};
