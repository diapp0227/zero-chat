import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/post_category.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../../core/avatar.dart';
import '../../core/sheet_header.dart';
import '../../profile/current_profile.dart';

/// 投稿画面の2ステップ目。選んだ種類の投稿の本文を入力する
class ComposeEditor extends ConsumerStatefulWidget {
  const ComposeEditor({
    super.key,
    required this.category,
    required this.fullScreen,
    required this.onBack,
  });

  /// 1ステップ目で選んだ投稿の種類 (見出しと入力欄のヒントに使う)
  final PostCategory category;

  /// 画面いっぱいに表示しているか (スマホ・タブレット)。
  /// true なら入力欄を伸ばして、ツールバーを画面の下端に置く
  final bool fullScreen;

  /// 「戻る」が押されたときの処理
  final VoidCallback onBack;

  /// 本文の最大文字数
  static const maxLength = 180;

  @override
  ConsumerState<ComposeEditor> createState() => _ComposeEditorState();
}

class _ComposeEditorState extends ConsumerState<ComposeEditor> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 文字数の表示と「投稿する」の押せる・押せないを入力に合わせて切り替える
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit() {
    // 投稿の送信は次の段階で実装する
  }

  @override
  Widget build(BuildContext context) {
    final fullScreen = widget.fullScreen;
    final canSubmit = _controller.text.trim().isNotEmpty;
    final profile = ref.watch(currentProfileProvider);

    final content = Padding(
      padding: fullScreen
          ? const EdgeInsets.symmetric(horizontal: 18, vertical: 20)
          : const EdgeInsets.all(22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 13,
        children: [
          Avatar(
            name: profile.name,
            colors: currentUserAvatarColors,
            size: AvatarSize.lg,
          ),
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: fullScreen ? 190 : 170),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLength: ComposeEditor.maxLength,
                maxLines: null,
                expands: fullScreen,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  color: AppColors.inputText,
                  fontSize: fullScreen ? 16 : 15,
                  height: 1.7,
                ),
                decoration: InputDecoration(
                  hintText: '${widget.category.label}の内容を入力...',
                  hintStyle: const TextStyle(color: AppColors.inputHint),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 7),
                  // 文字数は下のツールバーに出すので、TextField 標準の表示は消す
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          title: widget.category.label,
          leadingLabel: '戻る',
          onLeadingPressed: widget.onBack,
          trailing: SheetPrimaryButton(
            label: '投稿する',
            onPressed: canSubmit ? _onSubmit : null,
          ),
        ),
        if (fullScreen)
          Expanded(child: content)
        else
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 210),
            child: content,
          ),
        _ComposeToolbar(
          length: _controller.text.length,
          horizontalPadding: fullScreen ? 18 : 20,
        ),
      ],
    );
  }
}

/// 入力欄の下のツールバー。左に画像・気分・予約のボタン、右に文字数
class _ComposeToolbar extends StatelessWidget {
  const _ComposeToolbar({
    required this.length,
    required this.horizontalPadding,
  });

  /// 入力した本文の文字数
  final int length;

  /// 左右の余白
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 13,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.sheetDivider)),
      ),
      child: Row(
        children: [
          // 各ボタンの機能は次の段階で実装する
          const Row(
            spacing: 5,
            children: [
              _ToolButton(icon: AppIconName.image, tooltip: '画像を追加'),
              _ToolButton(icon: AppIconName.smile, tooltip: '気分を追加'),
              _ToolButton(icon: AppIconName.calendar, tooltip: '予約投稿'),
            ],
          ),
          const Spacer(),
          Text(
            '$length / ${ComposeEditor.maxLength}',
            style: const TextStyle(
              color: AppColors.composeCounter,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

/// ツールバーのアイコンだけのボタン1つ分
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.tooltip});

  /// 表示するアイコン
  final AppIconName icon;

  /// マウスを乗せたとき・読み上げで伝えるボタンの名前
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      tooltip: tooltip,
      icon: AppIcon(icon, color: AppColors.composeTool),
      style: ButtonStyle(
        fixedSize: const WidgetStatePropertyAll(Size.square(34)),
        minimumSize: const WidgetStatePropertyAll(Size.zero),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? AppColors.composeToolHover
              : Colors.transparent,
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}
