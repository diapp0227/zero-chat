import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/post_category.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../../core/avatar.dart';
import '../../core/sheet_header.dart';
import '../../profile/current_profile.dart';
import '../../profile/profile_settings_screen.dart';
import '../compose_view_model.dart';

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

  Future<void> _onSubmit() async {
    final succeeded = await ref
        .read(composeViewModelProvider.notifier)
        .submit(category: widget.category, text: _controller.text.trim());
    // 成功したら投稿画面を閉じる (失敗したら画面に残してメッセージを出す)
    if (succeeded && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final fullScreen = widget.fullScreen;
    final profile = ref.watch(currentProfileProvider);
    final submission = ref.watch(composeViewModelProvider);
    final sending = submission.isLoading;
    // サーバーが名前を必須にしているので、ユーザー名が未設定なら投稿できない
    final hasName = profile.name.isNotEmpty;
    final canSubmit = _controller.text.trim().isNotEmpty && hasName && !sending;

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
                // 送信中は本文を変えられないようにする
                readOnly: sending,
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
            label: sending ? '投稿中…' : '投稿する',
            onPressed: canSubmit ? _onSubmit : null,
          ),
        ),
        if (!hasName)
          _ComposeNotice(
            message: '投稿するには、プロフィールのユーザー名を設定してください',
            foregroundColor: AppColors.composeNoticeText,
            backgroundColor: AppColors.composeNoticeBackground,
            actionLabel: '設定する',
            onAction: () => showProfileSettingsScreen(context),
          )
        else if (submission.hasError)
          const _ComposeNotice(
            message: '投稿できませんでした。時間をおいて、もう一度お試しください',
            foregroundColor: AppColors.composeErrorText,
            backgroundColor: AppColors.composeErrorBackground,
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

/// 見出しの下に出すお知らせ (ユーザー名が未設定・送信に失敗したとき)
///
/// [actionLabel] と [onAction] を渡すと、右端にボタンを出す
class _ComposeNotice extends StatelessWidget {
  const _ComposeNotice({
    required this.message,
    required this.foregroundColor,
    required this.backgroundColor,
    this.actionLabel,
    this.onAction,
  });

  /// お知らせの文
  final String message;

  /// 文とボタンの色
  final Color foregroundColor;

  /// 背景の色
  final Color backgroundColor;

  /// 右端のボタンの文字 (なければボタンを出さない)
  final String? actionLabel;

  /// 右端のボタンが押されたときの処理
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        spacing: 10,
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: foregroundColor, fontSize: 11),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                minimumSize: const WidgetStatePropertyAll(Size.zero),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: WidgetStatePropertyAll(foregroundColor),
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              child: Text(actionLabel),
            ),
        ],
      ),
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
