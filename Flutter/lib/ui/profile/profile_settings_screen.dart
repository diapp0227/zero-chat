import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../core/avatar.dart';
import '../core/sheet.dart';
import '../core/sheet_header.dart';
import 'current_profile.dart';
import 'widgets/profile_field.dart';

/// プロフィール設定画面を開く
///
/// PC (expanded 幅) では背景をぼかした上に浮かぶカード、
/// スマホ・タブレットでは画面いっぱいの白い画面で表示する
Future<void> showProfileSettingsScreen(BuildContext context) {
  return showSheet(
    context,
    maxWidth: 520,
    barrierLabel: 'プロフィール設定を閉じる',
    builder: (context, fullScreen) =>
        ProfileSettingsScreen(fullScreen: fullScreen),
  );
}

/// プロフィール設定画面。ユーザー名と役職を入力して保存する
///
/// 入力中の内容は「保存」を押すまでプロフィールに反映しない
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key, required this.fullScreen});

  /// 画面いっぱいに表示しているか (スマホ・タブレット)。余白を少し変える
  final bool fullScreen;

  /// ユーザー名の最大文字数
  static const maxNameLength = 30;

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  late final TextEditingController _nameController;
  late String _role;

  @override
  void initState() {
    super.initState();
    // 今のプロフィールを入力欄の初期値にする
    final profile = ref.read(currentProfileProvider);
    _nameController = TextEditingController(text: profile.name)
      // アバターの頭文字・文字数・「保存」の押せる・押せないを入力に合わせて切り替える
      ..addListener(() => setState(() {}));
    _role = profile.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    ref
        .read(currentProfileProvider.notifier)
        .save(Profile(name: _nameController.text.trim(), role: _role));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text;
    final canSave = name.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          title: 'プロフィール設定',
          leadingLabel: 'キャンセル',
          onLeadingPressed: () => Navigator.of(context).pop(),
          trailing: SheetPrimaryButton(
            label: '保存',
            horizontalPadding: 17,
            onPressed: canSave ? _save : null,
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: widget.fullScreen
                ? const EdgeInsets.symmetric(horizontal: 20, vertical: 26)
                : const EdgeInsets.fromLTRB(28, 26, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileIntro(name: name),
                const SizedBox(height: 27),
                ProfileField(
                  label: 'ユーザー名',
                  child: ProfileTextInput(
                    controller: _nameController,
                    hintText: 'ユーザー名を入力',
                    maxLength: ProfileSettingsScreen.maxNameLength,
                    autofocus: true,
                  ),
                ),
                const SizedBox(height: 20),
                ProfileField(
                  label: '役職',
                  child: ProfileSelectInput(
                    value: _role,
                    options: profileRoles,
                    onChanged: (role) => setState(() => _role = role),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 入力欄の上の「プロフィール情報」。左にアバター、右に見出しと説明
class _ProfileIntro extends StatelessWidget {
  const _ProfileIntro({required this.name});

  /// 入力中のユーザー名 (アバターの頭文字に使う)
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 22),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.profileIntroDivider),
        ),
      ),
      child: Row(
        spacing: 13,
        children: [
          Avatar(
            name: name.trim(),
            colors: currentUserAvatarColors,
            size: AvatarSize.lg,
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                'プロフィール情報',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'タイムラインに表示される情報です',
                style: TextStyle(color: AppColors.sheetSubtitle, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
