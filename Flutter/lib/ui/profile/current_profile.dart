import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 選べる役職
const profileRoles = ['エンジニア', 'デザイナー', 'プロダクトマネージャー', 'セールス', 'コーポレート'];

/// ログイン中の人のアバターのグラデーション (開始色と終了色)
const currentUserAvatarColors = (Color(0xFFE8BD79), Color(0xFFB87947));

/// ログイン中の人のプロフィール (タイムラインに表示される名前と役職)
class Profile {
  const Profile({required this.name, required this.role});

  /// ユーザー名 (未設定なら空文字)
  final String name;

  /// 役職 (profileRoles のどれか)
  final String role;
}

/// ログイン中の人のプロフィール
///
/// サーバーに保存する仕組みができるまでは、アプリを閉じると消える
final currentProfileProvider = NotifierProvider<CurrentProfile, Profile>(
  CurrentProfile.new,
);

/// プロフィールを覚えておき、save で書き換える
class CurrentProfile extends Notifier<Profile> {
  @override
  Profile build() => Profile(name: '', role: profileRoles.first);

  void save(Profile profile) => state = profile;
}
