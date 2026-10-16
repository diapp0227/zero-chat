import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/post_category.dart';
import '../core/l10n.dart';

/// タイムラインの種類 (タブで切り替える)
///
/// 「最新」はすべての投稿、それ以外は投稿の種類 [PostCategory] で絞り込む
enum TimelineCategory {
  latest(null),
  announcement(PostCategory.announcement),
  dailyReport(PostCategory.dailyReport),
  selfStudy(PostCategory.selfStudy);

  const TimelineCategory(this.postCategory);

  /// 表示する投稿の種類 (null ならすべての投稿)
  final PostCategory? postCategory;

  /// タブに表示する名前 (例: 最新、日報)
  String label(AppLocalizations l10n) =>
      postCategory?.label(l10n) ?? l10n.timelineLatest;
}

/// 選択中のタイムラインのカテゴリ
///
/// HomeViewModel が、選択中のカテゴリの投稿を読み込むときに参照する
final selectedTimelineCategoryProvider =
    NotifierProvider<SelectedTimelineCategory, TimelineCategory>(
      SelectedTimelineCategory.new,
    );

/// 選択中のカテゴリを覚えておき、select で切り替える
class SelectedTimelineCategory extends Notifier<TimelineCategory> {
  @override
  TimelineCategory build() => TimelineCategory.latest;

  void select(TimelineCategory category) => state = category;
}
