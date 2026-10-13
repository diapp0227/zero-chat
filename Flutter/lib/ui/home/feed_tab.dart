import 'package:flutter_riverpod/flutter_riverpod.dart';

/// タイムラインの種類
enum FeedTab {
  latest('最新'),
  announcement('お知らせ'),
  dailyReport('日報'),
  selfStudy('自己学習');

  const FeedTab(this.label);

  final String label;
}

/// 選択中のタイムラインのタブ
///
/// 「投稿の情報注入」でタブに応じた投稿を読み込むときに参照する
final selectedFeedTabProvider = NotifierProvider<SelectedFeedTab, FeedTab>(
  SelectedFeedTab.new,
);

class SelectedFeedTab extends Notifier<FeedTab> {
  @override
  FeedTab build() => FeedTab.latest;

  void select(FeedTab tab) => state = tab;
}
