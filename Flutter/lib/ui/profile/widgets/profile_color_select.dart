import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// アバターのカラーを、決まったグラデーションの組み合わせ ([AppColors.avatarGradients]) から選ぶ欄
///
/// 候補をアバターと同じ角丸四角で横に並べ、選ばれているものに枠を付ける。
/// 候補にない色 (以前に別の方法で保存した色など) のときは、どれにも枠を付けない
class ProfileColorSelect extends StatelessWidget {
  const ProfileColorSelect({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// 選ばれているグラデーション (カラー1・カラー2)
  final (Color, Color) value;

  /// 候補が選ばれたときの処理
  final ValueChanged<(Color, Color)> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = AppColors.avatarGradients;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < options.length; i++)
          _ColorOption(
            colors: options[i],
            label: 'カラー${i + 1}',
            selected: options[i] == value,
            onTap: () => onChanged(options[i]),
          ),
      ],
    );
  }
}

/// 候補1つ分。グラデーションの角丸四角と、選ばれているときの外側の枠
class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.colors,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// グラデーションの開始色と終了色
  final (Color, Color) colors;

  /// 画面読み上げ用の名前 (例: カラー1)
  final String label;

  /// 選ばれているか
  final bool selected;

  /// 押されたときの処理
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (start, end) = colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          // 枠の有無で大きさが変わらないよう、枠は常に描いて色だけ切り替える
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected
                    ? AppColors.profileFieldFocusBorder
                    : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                // アバター (Avatar) と同じ向きのグラデーション
                gradient: LinearGradient(
                  begin: const Alignment(-0.57, -0.82),
                  end: const Alignment(0.57, 0.82),
                  colors: [start, end],
                ),
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
