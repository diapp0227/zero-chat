import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_icon.dart';

class BottomNavItem {
  const BottomNavItem({required this.label, required this.icon, this.badge});

  final String label;
  final AppIconName icon;
  final String? badge;
}

/// 画面下部に固定するフッタータブ
///
/// 背後のコンテンツが透けるよう半透明 + ぼかし。Scaffold.extendBody と組み合わせて使う
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<BottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 62 + bottomInset,
          padding: EdgeInsets.only(top: 9, bottom: bottomInset),
          decoration: const BoxDecoration(
            color: AppColors.navBackground,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, item) in items.indexed)
                _BottomNavButton(
                  item: item,
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navActive : AppColors.navInactive;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.navActiveBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 52),
            child: SizedBox(
              height: 47,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _IconWithBadge(
                      icon: item.icon,
                      badge: item.badge,
                      color: color,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({required this.icon, required this.color, this.badge});

  final AppIconName icon;
  final Color color;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppIcon(icon, color: color),
        if (badge case final badge?)
          Positioned(
            top: -5,
            right: -8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 14),
              height: 14,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.badge,
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
