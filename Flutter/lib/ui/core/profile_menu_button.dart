import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session.dart';
import '../profile/current_profile.dart';
import '../profile/profile_settings_screen.dart';
import 'app_colors.dart';
import 'app_icon.dart';
import 'avatar.dart';

/// プロフィールメニューの項目
enum ProfileMenuAction {
  settings('プロフィール設定', AppIconName.settings),
  // history('利用履歴', AppIconName.history),
  // help('ヘルプ', AppIconName.help),
  logout('ログアウト', AppIconName.logout);

  const ProfileMenuAction(this.label, this.icon);

  /// メニューに表示する名前
  final String label;

  /// 名前の左に出すアイコン
  final AppIconName icon;
}

/// アバター + ▼ のボタン。押すとプロフィールメニューを開く
///
/// PC の上部バーとスマホのヘッダーで共通
class ProfileMenuButton extends ConsumerWidget {
  const ProfileMenuButton({
    super.key,
    this.foregroundColor = AppColors.menuText,
    this.menuGap = 12,
    this.onSelected,
  });

  /// ▼ アイコンの色
  final Color foregroundColor;

  /// ボタンの下端からメニューまでの間隔
  final double menuGap;

  /// 項目が押されたときの処理 (「プロフィール設定」の画面を開く・ログアウトはこのボタンが行う)
  final ValueChanged<ProfileMenuAction>? onSelected;

  static const _menuWidth = 180.0;

  // ボタンの幅 (アバター 28 + 間隔 4 + ▼ 15)。メニューの右端をボタンの右端に揃えるのに使う
  static const _buttonWidth = 47.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return MenuAnchor(
      alignmentOffset: Offset(_buttonWidth - _menuWidth, menuGap),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: const WidgetStatePropertyAll(Color(0x24263746)),
        elevation: const WidgetStatePropertyAll(12),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
      menuChildren: [
        for (final action in ProfileMenuAction.values)
          SizedBox(
            // メニュー幅 180 から左右の余白 6 ずつを引いた幅
            width: _menuWidth - 12,
            child: _ProfileMenuItem(
              action: action,
              onPressed: () {
                switch (action) {
                  case ProfileMenuAction.settings:
                    showProfileSettingsScreen(context);
                  case ProfileMenuAction.logout:
                    // サインイン画面への移動は router の redirect が行う
                    ref.read(authSessionProvider.notifier).signOut();
                }
                onSelected?.call(action);
              },
            ),
          ),
      ],
      builder: (context, controller, child) {
        return Semantics(
          button: true,
          expanded: controller.isOpen,
          label: 'プロフィールメニュー',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Avatar(
                    name: profile.name,
                    colors: currentUserAvatarColors,
                    size: AvatarSize.sm,
                  ),
                  const SizedBox(width: 4),
                  AppIcon(
                    AppIconName.chevronDown,
                    size: 15,
                    color: foregroundColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// プロフィールメニューの1項目
class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({required this.action, required this.onPressed});

  /// この項目の内容
  final ProfileMenuAction action;

  /// 押されたときの処理
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDanger = action == ProfileMenuAction.logout;

    Color foreground(Set<WidgetState> states) {
      if (isDanger) return AppColors.menuDanger;
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return AppColors.menuHoverText;
      }
      return AppColors.menuText;
    }

    return MenuItemButton(
      onPressed: onPressed,
      leadingIcon: AppIcon(action.icon, size: 19),
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 42)),
        // スマホでも最小 48px に広げず、デザインどおり 42px にする
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 11),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(foreground),
        iconColor: WidgetStateProperty.resolveWith(foreground),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)
              ? AppColors.menuHoverBackground
              : Colors.transparent,
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 11)),
      ),
      child: Text(action.label),
    );
  }
}
