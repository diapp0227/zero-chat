import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_icon.dart';
import '../core/app_logo.dart';
import '../core/profile_menu_button.dart';
import 'tab_nav_item.dart';

/// PC (expanded 幅) で画面上部に固定する水色のバー
///
/// スマホのフッタータブの代わりに、ここでタブを切り替える
class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onCompose,
  });

  final List<TabNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    // 1050px 未満はロゴを詰め、文字を隠す
    final isNarrow = MediaQuery.sizeOf(context).width < 1050;

    return Container(
      height: 68 + topInset,
      padding: EdgeInsets.only(top: topInset),
      decoration: const BoxDecoration(
        color: AppColors.headerBackground,
        border: Border(bottom: BorderSide(color: AppColors.headerBorder)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isNarrow ? 910 : 1000),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isNarrow ? 14 : 20),
            child: Row(
              children: [
                SizedBox(
                  width: isNarrow ? 140 : 180,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppLogo(showText: !isNarrow),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 5,
                    children: [
                      for (final (i, item) in items.indexed)
                        _TopNavButton(
                          item: item,
                          selected: i == selectedIndex,
                          horizontalPadding: isNarrow ? 10 : 14,
                          onTap: () => onSelected(i),
                        ),
                    ],
                  ),
                ),
                Row(
                  spacing: 10,
                  children: [
                    _ComposeButton(onPressed: onCompose),
                    const ProfileMenuButton(
                      foregroundColor: Color(0xFF3F494D),
                      menuGap: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopNavButton extends StatelessWidget {
  const _TopNavButton({
    required this.item,
    required this.selected,
    required this.horizontalPadding,
    required this.onTap,
  });

  final TabNavItem item;
  final bool selected;
  final double horizontalPadding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: TextButton(
        onPressed: onTap,
        style: ButtonStyle(
          fixedSize: const WidgetStatePropertyAll(Size.fromHeight(42)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: horizontalPadding),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          foregroundColor: WidgetStatePropertyAll(
            selected ? AppColors.text : Colors.white,
          ),
          iconColor: WidgetStatePropertyAll(
            selected ? AppColors.text : Colors.white,
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (selected) return Colors.white;
            if (states.contains(WidgetState.hovered)) {
              return AppColors.headerNavHover;
            }
            return Colors.transparent;
          }),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            _IconWithBadge(icon: item.icon, badge: item.badge),
            Text(item.label),
          ],
        ),
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({required this.icon, this.badge});

  final AppIconName icon;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppIcon(icon),
        if (badge case final badge?)
          Positioned(
            top: -6,
            right: -7,
            child: Container(
              width: 15,
              height: 15,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.badge,
                border: Border.all(color: Colors.white, width: 2),
                shape: BoxShape.circle,
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ComposeButton extends StatelessWidget {
  const _ComposeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35263746),
            offset: Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          fixedSize: const WidgetStatePropertyAll(Size.fromHeight(40)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 17),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          iconColor: const WidgetStatePropertyAll(Colors.white),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? AppColors.composeHover
                : AppColors.compose,
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 7,
          children: [AppIcon(AppIconName.plus, size: 18), Text('投稿する')],
        ),
      ),
    );
  }
}
