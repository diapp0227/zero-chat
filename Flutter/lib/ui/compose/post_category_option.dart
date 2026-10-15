import '../../domain/models/post_category.dart';
import '../core/app_icon.dart';

/// 投稿画面の「投稿の種類」の選択肢に出す、アイコンと説明
extension PostCategoryOption on PostCategory {
  /// 種類の名前の左に出すアイコン
  AppIconName get icon => switch (this) {
    PostCategory.announcement => AppIconName.bell,
    PostCategory.dailyReport => AppIconName.calendar,
    PostCategory.selfStudy => AppIconName.sparkles,
  };

  /// 種類の名前の下に出す説明
  String get description => switch (this) {
    PostCategory.announcement => 'チームや組織への連絡を共有',
    PostCategory.dailyReport => '今日の取り組みや気づきを記録',
    PostCategory.selfStudy => '学んだことや知識を共有',
  };
}
