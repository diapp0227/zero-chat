/// サインイン画面で選べる操作
enum AuthMode {
  signUp('サインアップ'),
  signIn('サインイン');

  const AuthMode(this.label);

  /// 切り替えボタンに表示する名前
  final String label;
}
