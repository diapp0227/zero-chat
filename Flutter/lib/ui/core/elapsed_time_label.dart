/// 投稿日時などから、画面に出す経過時間の文字を作る
///
/// | 経過時間                   | 表示          |
/// |----------------------------|---------------|
/// | 1分未満 (未来の日時も含む) | たった今      |
/// | 1時間未満                  | 12分          |
/// | 24時間未満                 | 3時間         |
/// | 前日                       | 昨日          |
/// | 7日未満                    | 3日           |
/// | それ以前 (今年)            | 10月13日      |
/// | それ以前 (去年以前)        | 2025年10月13日 |
///
/// [now] は現在日時。テストで日時を固定するときに指定する
String elapsedTimeLabel(DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final elapsed = current.difference(time);

  if (elapsed.inMinutes < 1) return 'たった今';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes}分';
  if (elapsed.inHours < 24) return '${elapsed.inHours}時間';

  // 24時間以上前は、時刻ではなく日付の差で数える
  final days = _dateOnly(current).difference(_dateOnly(time)).inDays;
  if (days <= 1) return '昨日';
  if (days < 7) return '$days日';
  if (time.year == current.year) return '${time.month}月${time.day}日';
  return '${time.year}年${time.month}月${time.day}日';
}

/// 時刻を切り捨てて、日付だけにする
DateTime _dateOnly(DateTime time) => DateTime(time.year, time.month, time.day);
