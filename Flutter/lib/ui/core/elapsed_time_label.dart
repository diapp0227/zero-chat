import 'l10n.dart';

/// 投稿日時などから、画面に出す経過時間の文字を作る
///
/// 表示の言語は [l10n] に合わせる (下の表は日本語の例。英語では just now・12m・3h・Yesterday・3d・Oct 13・Oct 13, 2025)
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
String elapsedTimeLabel(DateTime time, AppLocalizations l10n, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final elapsed = current.difference(time);

  if (elapsed.inMinutes < 1) return l10n.elapsedJustNow;
  if (elapsed.inHours < 1) return l10n.elapsedMinutes(elapsed.inMinutes);
  if (elapsed.inHours < 24) return l10n.elapsedHours(elapsed.inHours);

  // 24時間以上前は、時刻ではなく日付の差で数える
  final days = _dateOnly(current).difference(_dateOnly(time)).inDays;
  if (days <= 1) return l10n.elapsedYesterday;
  if (days < 7) return l10n.elapsedDays(days);
  // 月の短い名前 (例: Oct)。使うのは英語の表示だけ
  final monthName = _monthNames[time.month - 1];
  if (time.year == current.year) {
    return l10n.elapsedMonthDay(time.month, time.day, monthName);
  }
  return l10n.elapsedYearMonthDay(time.year, time.month, time.day, monthName);
}

/// 英語の月の短い名前 (1 月〜12 月)
const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// 時刻を切り捨てて、日付だけにする
DateTime _dateOnly(DateTime time) => DateTime(time.year, time.month, time.day);
