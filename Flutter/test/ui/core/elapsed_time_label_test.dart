import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:zero_chat/l10n/app_localizations.dart';
import 'package:zero_chat/ui/core/elapsed_time_label.dart';

void main() {
  // 現在日時を 2026年10月13日 15:00 に固定する
  final now = DateTime(2026, 10, 13, 15);

  final ja = lookupAppLocalizations(const Locale('ja'));
  final en = lookupAppLocalizations(const Locale('en'));

  String label(DateTime time) => elapsedTimeLabel(time, ja, now: now);

  group('elapsedTimeLabel', () {
    test('1分未満は「たった今」', () {
      expect(label(now), 'たった今');
      expect(label(now.subtract(const Duration(seconds: 59))), 'たった今');
    });

    test('未来の日時も「たった今」', () {
      expect(label(now.add(const Duration(minutes: 5))), 'たった今');
    });

    test('1時間未満は「N分」', () {
      expect(label(now.subtract(const Duration(minutes: 1))), '1分');
      expect(label(now.subtract(const Duration(minutes: 59))), '59分');
    });

    test('24時間未満は「N時間」', () {
      expect(label(now.subtract(const Duration(hours: 1))), '1時間');
      expect(
        label(now.subtract(const Duration(hours: 23, minutes: 59))),
        '23時間',
      );
    });

    test('24時間以上前で前日の日付なら「昨日」', () {
      // 10月12日 14:00
      expect(label(DateTime(2026, 10, 12, 14)), '昨日');
    });

    test('7日未満は日付の差で「N日」', () {
      // 10月11日 23:00 は 40 時間前だが、日付は 2 日前
      expect(label(DateTime(2026, 10, 11, 23)), '2日');
      expect(label(DateTime(2026, 10, 7, 10)), '6日');
    });

    test('7日以上前で今年なら「M月D日」', () {
      expect(label(DateTime(2026, 10, 6, 10)), '10月6日');
      expect(label(DateTime(2026, 1, 1)), '1月1日');
    });

    test('去年以前なら「YYYY年M月D日」', () {
      expect(label(DateTime(2025, 12, 31)), '2025年12月31日');
    });

    test('英語では短い形で、日付は月の名前で出す', () {
      String enLabel(DateTime time) => elapsedTimeLabel(time, en, now: now);

      expect(enLabel(now), 'just now');
      expect(enLabel(now.subtract(const Duration(minutes: 5))), '5m');
      expect(enLabel(now.subtract(const Duration(hours: 3))), '3h');
      expect(enLabel(DateTime(2026, 10, 12, 14)), 'Yesterday');
      expect(enLabel(DateTime(2026, 10, 11, 23)), '2d');
      expect(enLabel(DateTime(2026, 10, 6, 10)), 'Oct 6');
      expect(enLabel(DateTime(2025, 12, 31)), 'Dec 31, 2025');
    });
  });
}
