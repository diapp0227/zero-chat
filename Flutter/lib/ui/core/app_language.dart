/// アプリの表示に使う言語
enum AppLanguage {
  ja('日本語'),
  en('英語');

  const AppLanguage(this.label);

  /// 言語設定の候補に表示する名前
  final String label;
}
