import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../timeline_category.dart';

/// タイムラインのタブ (最新 / お知らせ / 日報 / 自己学習) とフィルターボタンが並ぶ白い帯
///
/// スマホ (centered: true) はタブを中央に、PC はタブを左に寄せる。
/// タブが入りきらない狭い画面では、タブだけ横にスクロールできる
class TimelineCategoryTabs extends ConsumerWidget {
  const TimelineCategoryTabs({
    super.key,
    required this.centered,
    this.showFilterButton = false,
  });

  /// true ならタブを中央に (スマホ)、false なら左に寄せる (PC)
  final bool centered;

  /// フィルターボタンを表示するか。フィルターの仕様が決まるまでは非表示
  final bool showFilterButton;

  // 帯の左右の余白
  static const _sidePaddingCentered = 16.0;
  static const _sidePadding = 22.0;

  // フィルターボタンの幅 30 + タブとの間隔 8
  static const _filterWidth = 30.0 + 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTimelineCategoryProvider);

    final tabs = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: centered ? 24 : 25,
      children: [
        for (final category in TimelineCategory.values)
          _TimelineCategoryTabButton(
            category: category,
            selected: category == selected,
            onTap: () => ref
                .read(selectedTimelineCategoryProvider.notifier)
                .select(category),
          ),
      ],
    );

    final sidePadding = centered ? _sidePaddingCentered : _sidePadding;
    // タブの右側にあける幅。フィルターボタンを出すときはその分も空ける
    final rightSpace = sidePadding + (showFilterButton ? _filterWidth : 0);

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Stack(
        // 選択中の下線を帯の下の線に重ねるため、はみ出しを許可する
        clipBehavior: Clip.none,
        children: [
          Positioned(
            // 中央寄せのときは左右に同じ幅をあけ、フィルターボタンと重ならないようにする
            left: centered ? rightSpace : _sidePadding,
            right: rightSpace,
            // 選択中の下線を帯の下の線に重ねるため、1px 下にはみ出させる
            bottom: -1,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisAlignment: centered
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [tabs],
                  ),
                ),
              ),
            ),
          ),
          if (showFilterButton)
            Positioned(
              right: sidePadding,
              bottom: 7,
              child: const _FilterButton(),
            ),
        ],
      ),
    );
  }
}

/// タブ1つ分。文字と、選択中のときの緑の下線
class _TimelineCategoryTabButton extends StatelessWidget {
  const _TimelineCategoryTabButton({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  /// このタブのカテゴリ
  final TimelineCategory category;

  /// 選択中か (文字の色・太さと下線を切り替える)
  final bool selected;

  /// 押されたときの処理
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                // 帯の下端から 1px はみ出した位置が基準なので、下の余白は 13 + 1
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 14),
                child: Text(
                  category.label,
                  style: TextStyle(
                    color: selected ? AppColors.text : AppColors.tabInactive,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    height: 1.2,
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  left: 4,
                  right: 4,
                  bottom: 0,
                  child: Container(
                    height: 3,
                    decoration: const BoxDecoration(
                      color: AppColors.tabIndicator,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 投稿を絞り込むフィルターボタン (今は非表示)
class _FilterButton extends StatelessWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context) {
    bool isActive(Set<WidgetState> states) =>
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused);

    return Tooltip(
      message: '投稿をフィルター',
      child: TextButton(
        // フィルターの中身は未定のため、押しても何もしない
        onPressed: () {},
        style: ButtonStyle(
          fixedSize: const WidgetStatePropertyAll(Size.square(30)),
          minimumSize: const WidgetStatePropertyAll(Size.square(30)),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.filterBorder),
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (states) => isActive(states)
                ? AppColors.menuHoverText
                : AppColors.filterIcon,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => isActive(states)
                ? AppColors.menuHoverBackground
                : AppColors.filterBackground,
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
        child: const AppIcon(AppIconName.filter, size: 18),
      ),
    );
  }
}
