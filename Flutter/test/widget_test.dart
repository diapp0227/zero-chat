import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zero_chat/app.dart';
import 'package:zero_chat/ui/home/widgets/feed_header.dart';
import 'package:zero_chat/ui/shell/bottom_nav_bar.dart';
import 'package:zero_chat/ui/shell/desktop_top_bar.dart';

void main() {
  void setScreenSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('ホーム画面が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('タイムライン (未実装)'), findsOneWidget);
  });

  testWidgets('フッタータブで画面を切り替えられる', (WidgetTester tester) async {
    setScreenSize(tester, const Size(390, 844));

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    for (final label in ['ホーム', '見つける', '通知', '組織', 'メッセージ']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.text('通知'));
    await tester.pumpAndSettle();
    expect(find.text('通知 (未実装)'), findsOneWidget);

    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    expect(find.text('タイムライン (未実装)'), findsOneWidget);
  });

  testWidgets('スマホ幅ではホームに水色のヘッダーを表示する', (WidgetTester tester) async {
    setScreenSize(tester, const Size(390, 844));

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.byType(FeedHeader), findsOneWidget);
    expect(find.byType(DesktopTopBar), findsNothing);
    expect(find.text('Zero'), findsOneWidget);
  });

  testWidgets('expanded 幅では上部バーでタブを切り替える', (WidgetTester tester) async {
    setScreenSize(tester, const Size(1200, 800));

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.byType(DesktopTopBar), findsOneWidget);
    expect(find.byType(BottomNavBar), findsNothing);
    expect(find.byType(FeedHeader), findsNothing);
    expect(find.text('投稿する'), findsOneWidget);

    await tester.tap(find.text('通知'));
    await tester.pumpAndSettle();
    expect(find.text('通知 (未実装)'), findsOneWidget);
  });

  testWidgets('プロフィールメニューを開ける', (WidgetTester tester) async {
    setScreenSize(tester, const Size(390, 844));

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('ログアウト'), findsNothing);

    await tester.tap(find.bySemanticsLabel('プロフィールメニュー'));
    await tester.pumpAndSettle();

    expect(find.text('ログアウト'), findsOneWidget);
  });
}
