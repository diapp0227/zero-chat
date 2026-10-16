/// アプリの表示に使う言語
enum AppLanguage {
  ja('ja'),
  en('en');

  const AppLanguage(this.code);

  /// 言語コード (端末への保存と、表示の言語 (Locale) の指定に使う)
  final String code;

  /// 言語コード [code] の言語。対応していない言語なら null
  static AppLanguage? fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }
}
