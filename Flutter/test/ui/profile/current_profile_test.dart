import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zero_chat/data/repositories/profile/fake_profile_repository.dart';
import 'package:zero_chat/data/repositories/profile/profile_repository.dart';
import 'package:zero_chat/data/repositories/profile/profile_repository_provider.dart';
import 'package:zero_chat/domain/models/profile.dart';
import 'package:zero_chat/ui/profile/current_profile.dart';

/// 取得も保存も失敗する ProfileRepository
class _FailingProfileRepository implements ProfileRepository {
  @override
  Future<Profile?> fetchProfile() async => throw Exception('offline');

  @override
  Future<Profile> updateProfile(Profile profile) async =>
      throw Exception('offline');
}

void main() {
  group('CurrentProfile', () {
    const saved = Profile(
      name: 'ああああ',
      role: 'デザイナー',
      color1: Color(0xFF80C9B2),
      color2: Color(0xFF458B78),
    );

    ProviderContainer createContainer(ProfileRepository repository) {
      final container = ProviderContainer(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('load で保存済みのプロフィールを読み込む', () async {
      final container = createContainer(FakeProfileRepository(profile: saved));

      await container.read(currentProfileProvider.notifier).load();

      expect(container.read(currentProfileProvider).name, 'ああああ');
      expect(container.read(currentProfileProvider).avatarColors, (
        const Color(0xFF80C9B2),
        const Color(0xFF458B78),
      ));
    });

    test('まだ保存していなければ、ユーザー名が空のまま', () async {
      final container = createContainer(FakeProfileRepository());

      await container.read(currentProfileProvider.notifier).load();

      expect(container.read(currentProfileProvider).name, '');
      // カラーは決まった色
      expect(
        container.read(currentProfileProvider).color1,
        Profile.defaultColor1,
      );
    });

    test('読み込めなくてもエラーにせず、今のプロフィールのまま', () async {
      final container = createContainer(_FailingProfileRepository());
      container.read(currentProfileProvider.notifier).showUnsaved(saved);

      await container.read(currentProfileProvider.notifier).load();

      expect(container.read(currentProfileProvider).name, 'ああああ');
    });

    test('save で保存し、保存した内容をプロフィールにする', () async {
      final repository = FakeProfileRepository();
      final container = createContainer(repository);

      await container.read(currentProfileProvider.notifier).save(saved);

      expect(container.read(currentProfileProvider).role, 'デザイナー');
      expect((await repository.fetchProfile())?.name, 'ああああ');
    });

    test('保存できなければ例外を投げ、プロフィールは変えない', () async {
      final container = createContainer(_FailingProfileRepository());

      await expectLater(
        container.read(currentProfileProvider.notifier).save(saved),
        throwsException,
      );
      expect(container.read(currentProfileProvider).name, '');
    });
  });
}
