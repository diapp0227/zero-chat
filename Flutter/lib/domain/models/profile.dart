import 'dart:ui';

/// サインインしている人のプロフィール (タイムラインに表示される名前・役職・アバターの色)
class Profile {
  const Profile({
    required this.name,
    required this.role,
    this.color1 = defaultColor1,
    this.color2 = defaultColor2,
  });

  /// カラー1 を選んでいないときの色
  static const defaultColor1 = Color(0xFFE8BD79);

  /// カラー2 を選んでいないときの色
  static const defaultColor2 = Color(0xFFB87947);

  /// ユーザー名 (未設定なら空文字)
  final String name;

  /// 役職 (profileRoles のどれか)
  final String role;

  /// カラー1 (アバターのグラデーションの開始色)
  final Color color1;

  /// カラー2 (アバターのグラデーションの終了色)
  final Color color2;

  /// アバターのグラデーション (開始色と終了色)
  (Color, Color) get avatarColors => (color1, color2);
}
