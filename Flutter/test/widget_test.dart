import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zero_chat/app.dart';
import 'package:zero_chat/ui/auth/auth_screen.dart';
import 'package:zero_chat/ui/auth/auth_session.dart';
import 'package:zero_chat/ui/auth/widgets/auth_buttons.dart';
import 'package:zero_chat/ui/auth/widgets/auth_mode_tabs.dart';
import 'package:zero_chat/ui/core/profile_menu_button.dart';
import 'package:zero_chat/ui/home/timeline_category.dart';
import 'package:zero_chat/ui/home/home_screen.dart';
import 'package:zero_chat/ui/home/timeline_post.dart';
import 'package:zero_chat/ui/home/widgets/timeline_header.dart';
import 'package:zero_chat/ui/home/widgets/timeline_category_tabs.dart';
import 'package:zero_chat/ui/home/widgets/post_cell.dart';
import 'package:zero_chat/ui/shell/bottom_nav_bar.dart';
import 'package:zero_chat/ui/shell/desktop_top_bar.dart';

void main() {
  // サインイン済みの状態でアプリを開く
  final signedInApp = ProviderScope(
    overrides: [authSessionProvider.overrideWithBuild((ref, notifier) => true)],
    child: const App(),
  );

  void setScreenSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('ホーム画面が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(signedInApp);
    await tester.pumpAndSettle();

    expect(find.byType(TimelineCategoryTabs), findsOneWidget);
  });

  testWidgets('フッタータブで画面を切り替えられる', (WidgetTester tester) async {
    setScreenSize(tester, const Size(390, 844));

    await tester.pumpWidget(signedInApp);
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
    expect(find.byType(TimelineCategoryTabs), findsOneWidget);
  });

  testWidgets('スマホ幅ではホームに水色のヘッダーを表示する', (WidgetTester tester) async {
    setScreenSize(tester, const Size(390, 844));

    await tester.pumpWidget(signedInApp);
    await tester.pumpAndSettle();

    expect(find.byType(TimelineHeader), findsOneWidget);
    expect(find.byType(DesktopTopBar), findsNothing);
    expect(find.text('Zero'), findsOneWidget);
  });

  testWidgets('expanded 幅では上部バーでタブを切り替える', (WidgetTester tester) async {
    setScreenSize(tester, const Size(1200, 800));

    await tester.pumpWidget(signedInApp);
    await tester.pumpAndSettle();

    expect(find.byType(DesktopTopBar), findsOneWidget);
    expect(find.byType(BottomNavBar), findsNothing);
    expect(find.byType(TimelineHeader), findsNothing);
    expect(find.text('投稿する'), findsOneWidget);

    await tester.tap(find.text('通知'));
    await tester.pumpAndSettle();
    expect(find.text('通知 (未実装)'), findsOneWidget);
  });

  testWidgets('プロフィールメニューを開ける', (WidgetTester tester) async {
    setScreenSize(tester, const Size(390, 844));

    await tester.pumpWidget(signedInApp);
    await tester.pumpAndSettle();

    expect(find.text('ログアウト'), findsNothing);

    await tester.tap(find.bySemanticsLabel('プロフィールメニュー'));
    await tester.pumpAndSettle();

    expect(find.text('ログアウト'), findsOneWidget);
  });

  testWidgets('タイムラインのタブを切り替えられる', (WidgetTester tester) async {
    setScreenSize(tester, const Size(390, 844));

    await tester.pumpWidget(signedInApp);
    await tester.pumpAndSettle();

    expect(find.byType(TimelineCategoryTabs), findsOneWidget);
    // フィルターボタンは仕様が決まるまで非表示
    expect(find.byTooltip('投稿をフィルター'), findsNothing);

    TimelineCategory selectedCategory() => ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    ).read(selectedTimelineCategoryProvider);

    expect(selectedCategory(), TimelineCategory.latest);

    // 「日報」などは投稿のタイトルにもあるので、タブの帯の中から探す
    for (final category in [
      TimelineCategory.announcement,
      TimelineCategory.dailyReport,
      TimelineCategory.selfStudy,
      TimelineCategory.latest,
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(TimelineCategoryTabs),
          matching: find.text(category.label),
        ),
      );
      await tester.pumpAndSettle();
      expect(selectedCategory(), category);
    }
  });

  testWidgets('expanded 幅でもタブを表示する', (WidgetTester tester) async {
    setScreenSize(tester, const Size(1200, 800));

    await tester.pumpWidget(signedInApp);
    await tester.pumpAndSettle();

    expect(find.byType(TimelineCategoryTabs), findsOneWidget);
    for (final label in ['最新', 'お知らせ', '日報', '自己学習']) {
      expect(
        find.descendant(
          of: find.byType(TimelineCategoryTabs),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
  });

  group('投稿セル', () {
    testWidgets('保存・その他メニューのボタンは表示しない', (WidgetTester tester) async {
      setScreenSize(tester, const Size(390, 844));

      await tester.pumpWidget(signedInApp);
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

  group('サインイン画面', () {
    testWidgets('サインインしていなければサインイン画面を表示する', (WidgetTester tester) async {
      setScreenSize(tester, const Size(390, 844));

      await tester.pumpWidget(const ProviderScope(child: App()));
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(TimelineCategoryTabs), findsNothing);
      expect(find.text('サインアップ'), findsOneWidget);
    });

    testWidgets('サインアップすると認証コードを入力してホームへ進む', (WidgetTester tester) async {
      setScreenSize(tester, const Size(390, 844));

      await tester.pumpWidget(const ProviderScope(child: App()));
      await tester.pumpAndSettle();

      final submit = find.byType(AuthSubmitButton);
      await tester.enterText(find.byType(TextField).at(0), 'a@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.pump();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      // パスワードが条件 (大文字・数字・記号) を満たさないうちは進まない
      expect(find.text('認証コードを入力'), findsNothing);

      await tester.enterText(find.byType(TextField).at(1), 'Passw0rd!');
      await tester.pump();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('認証コードを入力'), findsOneWidget);
      expect(find.textContaining('a@example.com に送信した'), findsOneWidget);

      // 数字以外は入らず、6桁までしか入らない
      await tester.enterText(find.byType(TextField), '12ab345678');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '123456',
      );

      await tester.tap(find.byType(AuthSubmitButton));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsNothing);
      expect(find.byType(TimelineCategoryTabs), findsOneWidget);
    });

    testWidgets('サインインするとホームへ進み、ログアウトで戻る', (WidgetTester tester) async {
      setScreenSize(tester, const Size(1200, 800));

      await tester.pumpWidget(const ProviderScope(child: App()));
      await tester.pumpAndSettle();
      expect(find.text('WORKPLACE SOCIAL'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AuthModeTabs),
          matching: find.text('サインイン'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('おかえりなさい'), findsOneWidget);
      expect(find.text('パスワードを忘れた方'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'a@example.com');
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.pump();
      await tester.tap(find.byType(AuthSubmitButton));
      await tester.pumpAndSettle();
      expect(find.byType(DesktopTopBar), findsOneWidget);

      await tester.tap(find.byType(ProfileMenuButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ログアウト'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
    });
  });

  group('パスワードの条件', () {
    test('8文字以上で大文字・小文字・数字・記号を含めば通る', () {
      expect(AuthScreen.isValidPassword('Passw0rd!'), isTrue);
      expect(AuthScreen.isValidPassword('Ab1-cdef'), isTrue);
    });

    test('条件を1つでも満たさなければ通らない', () {
      expect(AuthScreen.isValidPassword('Pa0!'), isFalse); // 8文字未満
      expect(AuthScreen.isValidPassword('passw0rd!'), isFalse); // 大文字なし
      expect(AuthScreen.isValidPassword('PASSW0RD!'), isFalse); // 小文字なし
      expect(AuthScreen.isValidPassword('Password!'), isFalse); // 数字なし
      expect(AuthScreen.isValidPassword('Passw0rdd'), isFalse); // 記号なし
      expect(AuthScreen.isValidPassword('Passw0rdあ'), isFalse); // 日本語は記号に数えない
    });
  });
}
