import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../core/avatar.dart';
import '../core/sheet.dart';
import '../core/sheet_header.dart';
import '../../domain/models/profile.dart';
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
/// 開いたときにサーバーから最新のプロフィールを読み込む。
/// 入力中の内容は「保存」を押してサーバーに保存できるまでプロフィールに反映しない
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

  /// 保存中か (「保存」ボタンを押せなくする)
  bool _saving = false;

  /// 保存に失敗したか (見出しの下にメッセージを出す)
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    // 今のプロフィールを入力欄の初期値にする
    final profile = ref.read(currentProfileProvider);
    _nameController = TextEditingController(text: profile.name)
      // アバターの頭文字・文字数・「保存」の押せる・押せないを入力に合わせて切り替える
      ..addListener(() => setState(() {}));
    _role = profile.role;
    _loadLatest();
  }

  /// サーバーから最新のプロフィールを読み込み、入力欄に入れる
  Future<void> _loadLatest() async {
    final before = ref.read(currentProfileProvider);
    await ref.read(currentProfileProvider.notifier).load();
    if (!mounted) return;
    // 読み込み中に入力を始めていたら、入力したほうを残す
    if (_nameController.text != before.name || _role != before.role) return;
    final latest = ref.read(currentProfileProvider);
    setState(() {
      _nameController.text = latest.name;
      _role = latest.role;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // カラーはまだこの画面で選べないので、今のカラーのまま保存する
    final current = ref.read(currentProfileProvider);
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await ref
          .read(currentProfileProvider.notifier)
          .save(
            Profile(
              name: _nameController.text.trim(),
              role: _role,
              color1: current.color1,
              color2: current.color2,
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } on Exception {
      // 画面は閉じずに、入力した内容のまま保存し直せるようにする
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text;
    final canSave = name.trim().isNotEmpty && !_saving;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          title: 'プロフィール設定',
          leadingLabel: 'キャンセル',
          onLeadingPressed: () => Navigator.of(context).pop(),
          trailing: SheetPrimaryButton(
            label: _saving ? '保存中…' : '保存',
            onPressed: canSave ? _save : null,
          ),
        ),
        if (_saveFailed) const _SaveErrorNotice(),
        Flexible(
          child: SingleChildScrollView(
            padding: widget.fullScreen
                ? const EdgeInsets.symmetric(horizontal: 20, vertical: 26)
                : const EdgeInsets.fromLTRB(28, 26, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileIntro(
                  name: name,
                  colors: ref.watch(currentProfileProvider).avatarColors,
                ),
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
  const _ProfileIntro({required this.name, required this.colors});

  /// 入力中のユーザー名 (アバターの頭文字に使う)
  final String name;

  /// アバターのグラデーション (プロフィールのカラー1・カラー2)
  final (Color, Color) colors;

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
          Avatar(name: name.trim(), colors: colors, size: AvatarSize.lg),
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

/// 見出しの下に出す、保存に失敗したときのメッセージ (投稿画面のエラーと同じ見た目)
class _SaveErrorNotice extends StatelessWidget {
  const _SaveErrorNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.composeErrorBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Semantics(
        liveRegion: true,
        child: const Text(
          '保存できませんでした。時間をおいて、もう一度お試しください',
          style: TextStyle(color: AppColors.composeErrorText, fontSize: 11),
        ),
      ),
    );
  }
}
