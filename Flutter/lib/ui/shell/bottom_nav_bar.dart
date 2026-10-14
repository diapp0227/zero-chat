import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_icon.dart';
import 'tab_nav_item.dart';

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

  /// 並べるタブの一覧
  final List<TabNavItem> items;

  /// 選ばれているタブの番号
  final int selectedIndex;

  /// タブが押されたときの処理 (押されたタブの番号を受け取る)
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

/// フッタータブのボタン1つ分。アイコンの下に名前
class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  /// このボタンのタブ
  final TabNavItem item;

  /// 選ばれているか (色と背景を切り替える)
  final bool selected;

  /// 押されたときの処理
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

/// アイコンと、その右上に重ねる件数バッジ
class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({required this.icon, required this.color, this.badge});

  /// 表示するアイコン
  final AppIconName icon;

  /// アイコンの色
  final Color color;

  /// 右上に出す件数 (なければ null)
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
