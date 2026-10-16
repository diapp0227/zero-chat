import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/profile/profile_repository.dart';
import '../../data/repositories/profile/profile_repository_provider.dart';
import '../../domain/models/profile.dart';

/// 選べる役職
const profileRoles = ['エンジニア', 'デザイナー', 'プロダクトマネージャー', 'セールス', 'コーポレート'];

/// ログイン中の人のプロフィール
///
/// サーバー (ProfileRepository) に保存したものを [CurrentProfile.load] で読み込む。
/// 読み込むまでと、まだ保存していないときは、ユーザー名が空のプロフィール
final currentProfileProvider = NotifierProvider<CurrentProfile, Profile>(
  CurrentProfile.new,
);

/// プロフィールを覚えておき、load で読み込み、save で保存する
class CurrentProfile extends Notifier<Profile> {
  @override
  Profile build() => Profile(name: '', role: profileRoles.first);

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  /// サーバーに保存したプロフィールを読み込む
  ///
  /// まだ保存していないとき・読み込めなかったときは、今のプロフィールのままにする
  /// (表示が古いままになるだけなので、エラーにはしない)
  Future<void> load() async {
    try {
      final profile = await _repository.fetchProfile();
      if (profile != null) state = profile;
    } on Exception {
      // 次に画面を開いたときに読み込み直す
    }
  }

  /// [profile] をサーバーに保存し、保存できたらプロフィールにする
  ///
  /// 保存できなかったときは例外を投げ、プロフィールは変えない
  Future<void> save(Profile profile) async {
    state = await _repository.updateProfile(profile);
  }

  /// サーバーに保存できなかった [profile] を、画面にだけ反映する
  ///
  /// サインアップの完了時に保存できなかったときに使う。アプリを閉じると消える
  void showUnsaved(Profile profile) => state = profile;
}
