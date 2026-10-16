import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../compose/widgets/compose_parts.dart';
import '../core/app_colors.dart';
import '../core/avatar.dart';
import '../core/sheet.dart';
import '../core/sheet_header.dart';
import '../home/timeline_post.dart';
import '../profile/current_profile.dart';
import 'reply_view_model.dart';

/// [post] への返信画面を開く
///
/// 投稿画面と同じく、PC (expanded 幅) では背景をぼかした上に浮かぶカード、
/// スマホ・タブレットでは画面いっぱいの白い画面で表示する
Future<void> showReplyScreen(BuildContext context, TimelinePost post) {
  return showSheet(
    context,
    maxWidth: 560,
    barrierLabel: '返信画面を閉じる',
    builder: (context, fullScreen) =>
        ReplyScreen(post: post, fullScreen: fullScreen),
  );
}

/// 返信画面。返信先の投稿を示し、本文を入力して返信する
class ReplyScreen extends ConsumerStatefulWidget {
  const ReplyScreen({super.key, required this.post, required this.fullScreen});

  /// 返信先の投稿
  final TimelinePost post;

  /// 画面いっぱいに表示しているか (スマホ・タブレット)。
  /// true なら入力欄を伸ばして、ツールバーを画面の下端に置く
  final bool fullScreen;

  /// 本文の最大文字数
  static const maxLength = 180;

  @override
  ConsumerState<ReplyScreen> createState() => _ReplyScreenState();
}

class _ReplyScreenState extends ConsumerState<ReplyScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 文字数の表示と「返信する」の押せる・押せないを入力に合わせて切り替える
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final succeeded = await ref
        .read(replyViewModelProvider.notifier)
        .submit(postId: widget.post.id, text: _controller.text.trim());
    // 成功したら返信画面を閉じる (失敗したら画面に残してメッセージを出す)
    if (succeeded && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final fullScreen = widget.fullScreen;
    final profile = ref.watch(currentProfileProvider);
    final submission = ref.watch(replyViewModelProvider);
    final sending = submission.isLoading;
    // サーバーがプロフィールを必須にしているので、ユーザー名が未設定なら返信できない
    final hasName = profile.name.isNotEmpty;
    final canSubmit = _controller.text.trim().isNotEmpty && hasName && !sending;

    final content = Padding(
      padding: fullScreen
          ? const EdgeInsets.fromLTRB(18, 16, 18, 20)
          : const EdgeInsets.fromLTRB(22, 16, 22, 22),
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
              constraints: BoxConstraints(minHeight: fullScreen ? 190 : 130),
              child: TextField(
                controller: _controller,
                autofocus: true,
                // 送信中は本文を変えられないようにする
                readOnly: sending,
                maxLength: ReplyScreen.maxLength,
                maxLines: null,
                expands: fullScreen,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  color: AppColors.inputText,
                  fontSize: fullScreen ? 16 : 15,
                  height: 1.7,
                ),
                decoration: const InputDecoration(
                  hintText: '返信内容を入力...',
                  hintStyle: TextStyle(color: AppColors.inputHint),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 7),
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
          title: '返信する',
          leadingLabel: 'キャンセル',
          onLeadingPressed: () => Navigator.of(context).pop(),
          trailing: SheetPrimaryButton(
            label: sending ? '返信中…' : '返信する',
            onPressed: canSubmit ? _onSubmit : null,
          ),
        ),
        if (submission.hasError)
          const ComposeNotice(
            message: '返信できませんでした。時間をおいて、もう一度お試しください',
            foregroundColor: AppColors.composeErrorText,
            backgroundColor: AppColors.composeErrorBackground,
          ),
        _ReplyingTo(post: widget.post, fullScreen: fullScreen),
        if (fullScreen)
          Expanded(child: content)
        else
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 170),
            child: content,
          ),
        ComposeToolbar(
          length: _controller.text.length,
          maxLength: ReplyScreen.maxLength,
          horizontalPadding: fullScreen ? 18 : 20,
        ),
      ],
    );
  }
}

/// 「〇〇さんの投稿に返信」の帯。返信先の投稿者の小さいアバターと名前
class _ReplyingTo extends StatelessWidget {
  const _ReplyingTo({required this.post, required this.fullScreen});

  /// 返信先の投稿
  final TimelinePost post;

  /// 画面いっぱいに表示しているか (左右の余白を入力欄とそろえる)
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        fullScreen ? 18 : 22,
        18,
        fullScreen ? 18 : 22,
        0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.replyingToBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        spacing: 9,
        children: [
          Avatar(
            name: post.authorName,
            colors: post.avatarColors,
            size: AvatarSize.sm,
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: post.authorName,
                    style: const TextStyle(
                      color: AppColors.replyingToName,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: 'さんの投稿に返信'),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.replyingToText,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
