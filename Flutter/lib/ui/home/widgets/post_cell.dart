import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../../core/avatar.dart';
import '../../core/elapsed_time_label.dart';
import '../../reply/reply_screen.dart';
import '../timeline_post.dart';

/// タイムラインの投稿1件分
///
/// 投稿者・タイトル・本文 (5行を超えたら「もっと見る」)・画像・返信を表示する
class PostCell extends StatefulWidget {
  const PostCell({super.key, required this.post, this.showActions = false});

  /// 表示する投稿
  final TimelinePost post;

  /// 右上の保存・その他メニューのボタンを表示するか。仕様が決まるまでは非表示
  final bool showActions;

  @override
  State<PostCell> createState() => _PostCellState();
}

/// PostCell の状態 (保存したか・返信を開いているか) を持つ
class _PostCellState extends State<PostCell> {
  bool _saved = false;

  // 返信は最初から全部表示し、「N件の返信」を押すと閉じる
  bool _repliesOpen = true;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final replyCount = post.replies.length;
    // 返信が1件以上あれば「N件の返信」で開閉する
    final hasReplies = replyCount > 0;
    final showReplies = hasReplies && _repliesOpen;
    final isNarrow = MediaQuery.sizeOf(context).width <= 520;

    return Container(
      padding: isNarrow
          ? const EdgeInsets.fromLTRB(16, 20, 16, 13)
          : const EdgeInsets.fromLTRB(25, 22, 25, 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PostHeader(
            post: post,
            showActions: widget.showActions,
            saved: _saved,
            onToggleSaved: () => setState(() => _saved = !_saved),
          ),
          const SizedBox(height: 16),
          Text(
            post.title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.5,
              letterSpacing: 0.15,
            ),
          ),
          const SizedBox(height: 7),
          _CollapsibleText(text: post.text),
          const SizedBox(height: 16),
          if (post.image case final image?) ...[
            _PostImage(image: image, isNarrow: isNarrow),
            const SizedBox(height: 13),
          ],
          _ReplySummary(onTap: () => showReplyScreen(context, post)),
          if (hasReplies) ...[
            const SizedBox(height: 11),
            _RepliesToggle(
              replyCount: replyCount,
              open: _repliesOpen,
              onTap: () => setState(() => _repliesOpen = !_repliesOpen),
            ),
          ],
          if (showReplies) ...[
            const SizedBox(height: 13),
            _Replies(replies: post.replies),
          ],
        ],
      ),
    );
  }
}

/// 投稿の上部。アバター・名前・経過時間・肩書きと、保存・その他メニューのボタン
class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    required this.showActions,
    required this.saved,
    required this.onToggleSaved,
  });

  /// 表示する投稿
  final TimelinePost post;

  /// 保存・その他メニューのボタンを表示するか
  final bool showActions;

  /// 保存済みか (保存ボタンの見た目を切り替える)
  final bool saved;

  /// 保存ボタンが押されたときの処理
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        Avatar(
          name: post.authorName,
          colors: post.avatarColors,
          size: AvatarSize.lg,
        ),
        Expanded(
          child: _AuthorInfo(
            name: post.authorName,
            timeLabel: elapsedTimeLabel(post.postedAt),
            role: post.authorRole,
            nameSize: 13,
            timeSize: 10,
            gap: 6,
          ),
        ),
        if (showActions)
          Row(
            spacing: 2,
            children: [
              _PostActionButton(
                icon: saved ? AppIconName.bookmarkFilled : AppIconName.bookmark,
                iconSize: 19,
                label: saved ? '保存を解除' : '保存',
                color: saved ? AppColors.postSaved : AppColors.postAction,
                onPressed: onToggleSaved,
              ),
              _PostActionButton(
                icon: AppIconName.more,
                iconSize: 21,
                label: 'その他のメニュー',
                color: AppColors.postAction,
                // メニューの中身は未定のため、押しても何もしない
                onPressed: () {},
              ),
            ],
          ),
      ],
    );
  }
}

/// 「名前 · 時間」と、その下の肩書き。投稿と返信で共通
class _AuthorInfo extends StatelessWidget {
  const _AuthorInfo({
    required this.name,
    required this.timeLabel,
    required this.role,
    required this.nameSize,
    required this.timeSize,
    required this.gap,
  });

  /// 名前
  final String name;

  /// 名前の右に出す経過時間 (例: 12分)
  final String timeLabel;

  /// 名前の下に出す肩書き (例: エンジニア)
  final String role;

  /// 名前の文字の大きさ
  final double nameSize;

  /// 経過時間の文字の大きさ
  final double timeSize;

  /// 名前と経過時間の間隔
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          spacing: gap,
          children: [
            Text(
              name,
              style: TextStyle(
                color: AppColors.text,
                fontSize: nameSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            Flexible(
              child: Text(
                '· $timeLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.postMeta, fontSize: timeSize),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          role,
          style: const TextStyle(color: AppColors.postRole, fontSize: 9),
        ),
      ],
    );
  }
}

/// 投稿の右上に並ぶアイコンだけのボタン (保存・その他メニュー)
class _PostActionButton extends StatelessWidget {
  const _PostActionButton({
    required this.icon,
    required this.iconSize,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  /// ボタンのアイコン
  final AppIconName icon;

  /// アイコンの大きさ
  final double iconSize;

  /// ボタンの名前 (画面読み上げ用。例: 保存)
  final String label;

  /// アイコンの色
  final Color color;

  /// ボタンが押されたときの処理
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          fixedSize: const WidgetStatePropertyAll(Size.square(32)),
          minimumSize: const WidgetStatePropertyAll(Size.square(32)),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
          iconColor: WidgetStatePropertyAll(color),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? AppColors.postActionHover
                : Colors.transparent,
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
        child: AppIcon(icon, size: iconSize),
      ),
    );
  }
}

/// 本文。5行を超えるときは「もっと見る」で全文を表示する
class _CollapsibleText extends StatefulWidget {
  const _CollapsibleText({required this.text});

  /// 本文
  final String text;

  @override
  State<_CollapsibleText> createState() => _CollapsibleTextState();
}

/// _CollapsibleText の状態 (全文を表示しているか) を持つ
class _CollapsibleTextState extends State<_CollapsibleText> {
  static const _maxLines = 5;
  static const _style = TextStyle(
    color: AppColors.text,
    fontSize: 13,
    height: 1.8,
    letterSpacing: 0.13,
  );

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (_expanded) return Text(widget.text, style: _style);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 5行に収まるかを、実際に文字を配置して確かめる
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: _style),
          maxLines: _maxLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: _style,
              maxLines: _maxLines,
              overflow: TextOverflow.ellipsis,
            ),
            if (overflows) ...[
              const SizedBox(height: 5),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expanded = true),
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    'もっと見る',
                    style: TextStyle(
                      color: AppColors.postLink,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 投稿の画像。角丸で、下を少し暗くして左下に文字を重ねる
class _PostImage extends StatelessWidget {
  const _PostImage({required this.image, required this.isNarrow});

  /// 表示する画像
  final TimelinePostImage image;

  /// スマホ幅 (520px 以下) か。画像の高さと角丸を切り替える
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // スマホでは画面幅の 82% (最大 340)、それ以外は 340
    final height = isNarrow ? math.min(screenWidth * 0.82, 340.0) : 340.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(isNarrow ? 15 : 18),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.postImagePlaceholder),
            Image.network(
              image.url,
              fit: BoxFit.cover,
              semanticLabel: image.alt,
              // 読み込めなかったときは、背景色だけを表示する
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
            // 下 40% を少し暗くして、左下の文字を読みやすくする
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: 0.4,
                widthFactor: 1,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x55000000)],
                    ),
                  ),
                ),
              ),
            ),
            if (image.label case final label?)
              Positioned(
                left: 17,
                bottom: 15,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 「返信する」のボタン。押すと返信画面を開く。返信の件数は「N件の返信」のほうに出す
class _ReplySummary extends StatelessWidget {
  const _ReplySummary({required this.onTap});

  /// 押されたときの処理
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: const MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 7,
              children: [
                AppIcon(
                  AppIconName.comment,
                  size: 18,
                  color: AppColors.replySummary,
                ),
                Text(
                  '返信する',
                  style: TextStyle(color: AppColors.replySummary, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 「N件の返信 ▲▼」のボタン。押すと返信の一覧を開閉する
class _RepliesToggle extends StatelessWidget {
  const _RepliesToggle({
    required this.replyCount,
    required this.open,
    required this.onTap,
  });

  /// 返信の件数 (「N件の返信」の N)
  final int replyCount;

  /// 返信を開いているか (▲ / ▼ の向きを切り替える)
  final bool open;

  /// 押されたときの処理
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        expanded: open,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Text(
                  '$replyCount件の返信',
                  style: const TextStyle(
                    color: AppColors.postLink,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // 開いているときは ▼ を上下反転させる
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const AppIcon(
                    AppIconName.chevronDown,
                    size: 15,
                    color: AppColors.postLink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 返信の一覧。上と左に線を引いて、投稿にぶら下がって見えるようにする
class _Replies extends StatelessWidget {
  const _Replies({required this.replies});

  /// 表示する返信の一覧
  final List<TimelineReply> replies;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 0, 2),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.repliesBorderTop),
          left: BorderSide(color: AppColors.repliesBorderLeft, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 13,
        children: [for (final reply in replies) _ReplyItem(reply: reply)],
      ),
    );
  }
}

/// 返信1件。小さいアバター・名前・経過時間・肩書き・本文
class _ReplyItem extends StatelessWidget {
  const _ReplyItem({required this.reply});

  /// 表示する返信
  final TimelineReply reply;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Avatar(
          name: reply.authorName,
          colors: reply.avatarColors,
          size: AvatarSize.sm,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AuthorInfo(
                name: reply.authorName,
                timeLabel: elapsedTimeLabel(reply.repliedAt),
                role: reply.authorRole,
                nameSize: 11,
                timeSize: 9,
                gap: 5,
              ),
              const SizedBox(height: 6),
              Text(
                reply.text,
                style: const TextStyle(
                  color: AppColors.replyText,
                  fontSize: 11,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
