import 'package:flutter_riverpod/flutter_riverpod.dart';

/// タイムラインの種類
enum TimelineCategory {
  latest('最新'),
  announcement('お知らせ'),
  dailyReport('日報'),
  selfStudy('自己学習');

  const TimelineCategory(this.label);

  /// タブに表示する名前 (例: 日報)
  final String label;
}

/// 選択中のタイムラインのカテゴリ
///
/// 「投稿の情報注入」でカテゴリに応じた投稿を読み込むときに参照する
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
