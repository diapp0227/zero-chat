import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zero_chat/app.dart';
import 'package:zero_chat/data/repositories/post/post_repository_provider.dart';
import 'package:zero_chat/data/repositories/post/fake_post_repository.dart';
import 'package:zero_chat/data/repositories/auth/auth_repository_provider.dart';
import 'package:zero_chat/data/repositories/auth/fake_auth_repository.dart';
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
import 'package:zero_chat/ui/profile/current_profile.dart';
import 'package:zero_chat/ui/reply/reply_screen.dart';
import 'package:zero_chat/ui/core/sheet_header.dart';
import 'package:zero_chat/data/repositories/profile/fake_profile_repository.dart';
import 'package:zero_chat/data/repositories/profile/profile_repository_provider.dart';
import 'package:zero_chat/domain/models/profile.dart';
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

  testWidgets('「返信する」から返信すると、投稿の下に返信が出る', (WidgetTester tester) async {
    setScreenSize(tester, const Size(390, 844));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWithBuild((ref, notifier) => true),
          // 返信にはユーザー名が要るので、プロフィールを保存済みにしておく
          profileRepositoryProvider.overrideWithValue(
            FakeProfileRepository(
              profile: const Profile(name: 'ああああ', role: 'エンジニア'),
            ),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('返信する').first);
    await tester.pumpAndSettle();
    expect(find.byType(ReplyScreen), findsOneWidget);
    expect(find.textContaining('さんの投稿に返信'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(ReplyScreen),
        matching: find.byType(TextField),
      ),
      'テストの返信',
    );
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(SheetPrimaryButton),
        matching: find.text('返信する'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ReplyScreen), findsNothing);
    expect(find.text('テストの返信'), findsOneWidget);
  });

  testWidgets('下までスクロールすると、続きの投稿を読み込む', (WidgetTester tester) async {
    setScreenSize(tester, const Size(390, 844));
    // 3 件ずつ返す仮データ (全部で 4 ページ以上になる)
    final repository = FakePostRepository(pageSize: 3);
    final all = (await FakePostRepository().fetchPosts()).posts;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWithBuild((ref, notifier) => true),
          postRepositoryProvider.overrideWithValue(repository),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    // 最初は 3 件目までしか読み込んでいない
    expect(find.byKey(ValueKey(all.last.id)), findsNothing);

    await tester.dragUntilVisible(
      find.byKey(ValueKey(all.last.id)),
      find.byType(ListView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    // 一番古い投稿まで出て、最後まで読んだので読み込み中の表示は消える
    expect(find.byKey(ValueKey(all.last.id)), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
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
      await tester.pump();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      // パスワードが空のうちは進まない
      expect(find.text('認証コードを入力'), findsNothing);

      // パスワードの条件はアプリでは確かめず、Cognito に任せる
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.pump();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      // ユーザー名が空のうちは進まない
      expect(find.text('認証コードを入力'), findsNothing);

      await tester.enterText(find.byType(TextField).at(2), 'ああああ');
      await tester.tap(find.text('エンジニア'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('デザイナー').last);
      await tester.pumpAndSettle();
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

      // サインアップで入力したユーザー名・役職がプロフィールになる
      final profile = ProviderScope.containerOf(
        tester.element(find.byType(App)),
      ).read(currentProfileProvider);
      expect(profile.name, 'ああああ');
      expect(profile.role, 'デザイナー');
    });

    testWidgets('サインインするとホームへ進み、ログアウトで戻る', (WidgetTester tester) async {
      setScreenSize(tester, const Size(1200, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(
                confirmedAccounts: {'a@example.com': 'Passw0rd!'},
              ),
            ),
          ],
          child: const App(),
        ),
      );
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
      // ユーザー名・役職はサインアップのときだけ
      expect(find.text('ユーザー名'), findsNothing);
      expect(find.text('役職'), findsNothing);
      // パスワード再設定の画面ができるまでは非表示
      expect(find.text('パスワードを忘れた方'), findsNothing);

      await tester.enterText(find.byType(TextField).at(0), 'a@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'wrong');
      await tester.pump();
      await tester.tap(find.byType(AuthSubmitButton));
      await tester.pumpAndSettle();
      // パスワードが違えば、エラーを出してサインイン画面のまま
      expect(find.text('メールアドレスまたはパスワードが正しくありません'), findsOneWidget);
      expect(find.byType(AuthScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(1), 'Passw0rd!');
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
}
