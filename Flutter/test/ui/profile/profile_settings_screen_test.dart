import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zero_chat/data/repositories/post/fake_post_repository.dart';
import 'package:zero_chat/data/repositories/post/post_repository_provider.dart';
import 'package:zero_chat/data/repositories/profile/fake_profile_repository.dart';
import 'package:zero_chat/data/repositories/profile/profile_repository_provider.dart';
import 'package:zero_chat/domain/models/post_category.dart';
import 'package:zero_chat/domain/models/post_page.dart';
import 'package:zero_chat/domain/models/profile.dart';
import 'package:zero_chat/ui/core/app_colors.dart';
import 'package:zero_chat/ui/core/avatar.dart';
import 'package:zero_chat/ui/home/home_view_model.dart';
import 'package:zero_chat/ui/profile/profile_settings_screen.dart';

/// fetchPosts が呼ばれた回数を数える PostRepository
class _CountingPostRepository extends FakePostRepository {
  /// fetchPosts が呼ばれた回数
  int fetchCount = 0;

  @override
  Future<PostPage> fetchPosts({PostCategory? category, String? cursor}) {
    fetchCount++;
    return super.fetchPosts(category: category, cursor: cursor);
  }
}

void main() {
  group('ProfileSettingsScreen', () {
    testWidgets('カラーを選ぶとアバターに反映し、保存するとサーバーに送る', (tester) async {
      final repository = FakeProfileRepository(
        profile: const Profile(name: 'ああああ', role: 'エンジニア'),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [profileRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => showProfileSettingsScreen(context),
                child: const Text('開く'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      // 最初は保存済みのカラー (決まった色) が選ばれている
      final colorOption = find.bySemanticsLabel('カラー3');
      expect(
        tester.getSemantics(colorOption).flagsCollection.isSelected,
        isTrue,
      );

      await tester.tap(find.bySemanticsLabel('カラー5'));
      await tester.pump();
      expect(
        tester.widget<Avatar>(find.byType(Avatar)).colors,
        AppColors.avatarGradients[4],
      );

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final saved = await repository.fetchProfile();
      expect(saved?.avatarColors, AppColors.avatarGradients[4]);
      // 名前と役職はそのまま
      expect(saved?.name, 'ああああ');
      expect(find.byType(ProfileSettingsScreen), findsNothing);
    });

    testWidgets('保存するとタイムラインを読み込み直す', (tester) async {
      final postRepository = _CountingPostRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(
                profile: const Profile(name: 'ああああ', role: 'エンジニア'),
              ),
            ),
            postRepositoryProvider.overrideWithValue(postRepository),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                // タイムラインが表示されている状態にする
                ref.watch(homeViewModelProvider);
                return TextButton(
                  onPressed: () => showProfileSettingsScreen(context),
                  child: const Text('開く'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(postRepository.fetchCount, 1);

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(postRepository.fetchCount, 2);
    });
  });
}
