import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zero_chat/app.dart';
import 'package:zero_chat/ui/home/feed_tab.dart';
import 'package:zero_chat/ui/home/home_screen.dart';
import 'package:zero_chat/ui/home/timeline_post.dart';
import 'package:zero_chat/ui/home/widgets/feed_header.dart';
import 'package:zero_chat/ui/home/widgets/feed_tabs.dart';
import 'package:zero_chat/ui/home/widgets/post_cell.dart';
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

    expect(find.byType(FeedTabs), findsOneWidget);
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
    expect(find.byType(FeedTabs), findsOneWidget);
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

  testWidgets('タイムラインのタブを切り替えられる', (WidgetTester tester) async {
    setScreenSize(tester, const Size(390, 844));

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.byType(FeedTabs), findsOneWidget);
    // フィルターボタンは仕様が決まるまで非表示
    expect(find.byTooltip('投稿をフィルター'), findsNothing);

    FeedTab selectedTab() => ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    ).read(selectedFeedTabProvider);

    expect(selectedTab(), FeedTab.latest);

    // 「日報」などは投稿のタイトルにもあるので、タブの帯の中から探す
    for (final tab in [
      FeedTab.announcement,
      FeedTab.dailyReport,
      FeedTab.selfStudy,
      FeedTab.latest,
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(FeedTabs),
          matching: find.text(tab.label),
        ),
      );
      await tester.pumpAndSettle();
      expect(selectedTab(), tab);
    }
  });

  testWidgets('expanded 幅でもタブを表示する', (WidgetTester tester) async {
    setScreenSize(tester, const Size(1200, 800));

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.byType(FeedTabs), findsOneWidget);
    for (final label in ['最新', 'お知らせ', '日報', '自己学習']) {
      expect(
        find.descendant(of: find.byType(FeedTabs), matching: find.text(label)),
        findsOneWidget,
      );
    }
  });

  group('投稿セル', () {
    testWidgets('保存・その他メニューのボタンは表示しない', (WidgetTester tester) async {
      setScreenSize(tester, const Size(390, 844));

      await tester.pumpWidget(const ProviderScope(child: App()));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('保存'), findsNothing);
      expect(find.bySemanticsLabel('その他のメニュー'), findsNothing);
    });

    testWidgets('ボタンを表示したときは保存状態を切り替えられる', (WidgetTester tester) async {
      final post = TimelinePost(
        id: 1,
        authorName: 'テスト',
        authorRole: 'エンジニア',
        avatarColors: (const Color(0xFF000000), const Color(0xFFFFFFFF)),
        postedAt: DateTime.now(),
        title: 'タイトル',
        text: '本文',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PostCell(post: post, showActions: true)),
        ),
      );

      await tester.tap(find.bySemanticsLabel('保存'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('保存を解除'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('保存を解除'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('保存'), findsOneWidget);
    });
  });
}
