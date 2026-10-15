import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/auth/auth_screen.dart';
import '../ui/auth/auth_session.dart';
import '../ui/home/home_screen.dart';
import '../ui/placeholder/placeholder_screen.dart';
import '../ui/shell/tab_shell.dart';

/// ルート定義。ログイン状態などを見てリダイレクトする場合は ref から参照する
final routerProvider = Provider<GoRouter>((ref) {
  // サインイン状態が変わったら redirect をやり直す。
  // ref.watch にすると GoRouter が作り直されて表示中の画面が消えるので、ValueNotifier で知らせる
  final signedIn = ValueNotifier(ref.read(authSessionProvider));
  ref.listen(authSessionProvider, (_, next) => signedIn.value = next);
  ref.onDispose(signedIn.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: signedIn,
    // サインインしていなければサインイン画面へ、サインイン済みならサインイン画面からホームへ
    redirect: (context, state) {
      final onAuth = state.matchedLocation == '/auth';
      if (!signedIn.value) return onAuth ? null : '/auth';
      return onAuth ? '/' : null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      // branches の順番は tab_shell.dart の tabNavItems と一致させる
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TabShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) =>
                    const PlaceholderScreen(title: '見つける'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) =>
                    const PlaceholderScreen(title: '通知'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/organization',
                builder: (context, state) =>
                    const PlaceholderScreen(title: '組織'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'メッセージ'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
