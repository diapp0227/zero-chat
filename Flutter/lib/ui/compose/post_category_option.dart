import '../../domain/models/post_category.dart';
import '../core/app_icon.dart';
import '../core/l10n.dart';

/// 投稿画面の「投稿の種類」の選択肢に出す、アイコンと説明
extension PostCategoryOption on PostCategory {
  /// 種類の名前の左に出すアイコン
  AppIconName get icon => switch (this) {
    PostCategory.announcement => AppIconName.bell,
    PostCategory.dailyReport => AppIconName.calendar,
    PostCategory.selfStudy => AppIconName.sparkles,
  };

  /// 種類の名前の下に出す説明
  String description(AppLocalizations l10n) => switch (this) {
    PostCategory.announcement => l10n.categoryAnnouncementDescription,
    PostCategory.dailyReport => l10n.categoryDailyReportDescription,
    PostCategory.selfStudy => l10n.categorySelfStudyDescription,
  };
}
