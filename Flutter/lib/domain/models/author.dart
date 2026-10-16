import 'dart:ui';

/// 投稿・返信をした人
class Author {
  const Author({
    required this.id,
    required this.name,
    required this.role,
    this.avatarColors,
  });

  /// 人を見分けるための番号 (サーバーの API で作った投稿・返信は 0)
  final int id;

  /// 名前
  final String name;

  /// 肩書き (例: エンジニア)
  final String role;

  /// アバターのグラデーション (プロフィールのカラー1・カラー2)
  ///
  /// プロフィールから作った投稿・返信にだけある。null なら [id] から色を決める
  final (Color, Color)? avatarColors;
}
