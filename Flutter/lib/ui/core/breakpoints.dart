/// 画面幅によるレイアウトの出し分け基準
///
/// プラットフォーム (Platform.isIOS など) ではなく幅で判定する
enum ScreenSize {
  compact,
  medium,
  expanded;

  static ScreenSize fromWidth(double width) {
    if (width < 600) return ScreenSize.compact;
    if (width < 840) return ScreenSize.medium;
    return ScreenSize.expanded;
  }
}
