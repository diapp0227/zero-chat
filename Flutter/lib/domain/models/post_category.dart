/// 投稿の種類
enum PostCategory {
  announcement('お知らせ'),
  dailyReport('日報'),
  selfStudy('自己学習');

  const PostCategory(this.label);

  /// 種類の名前 (例: 日報)
  final String label;
}
