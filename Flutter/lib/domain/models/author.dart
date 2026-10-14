/// 投稿・返信をした人
class Author {
  const Author({required this.id, required this.name, required this.role});

  /// 人を見分けるための一意な番号 (1 以上)
  final int id;

  /// 名前
  final String name;

  /// 肩書き (例: エンジニア)
  final String role;
}
