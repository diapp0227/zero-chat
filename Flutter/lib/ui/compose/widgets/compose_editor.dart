import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/post_category.dart';
import '../../core/app_colors.dart';
import '../../core/avatar.dart';
import '../../core/sheet_header.dart';
import '../../profile/current_profile.dart';
import '../compose_view_model.dart';
import 'compose_parts.dart';

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
            colors: profile.avatarColors,
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
        if (submission.hasError)
          const ComposeNotice(
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
        ComposeToolbar(
          length: _controller.text.length,
          maxLength: ComposeEditor.maxLength,
          horizontalPadding: fullScreen ? 18 : 20,
        ),
      ],
    );
  }
}
