import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../../../domain/models/app_language.dart';
import '../../core/l10n.dart';

/// サインアップ・サインインの切り替えの下の「言語設定」。左に項目名、右に押すと候補が開く言語
class AuthLanguageSelect extends StatelessWidget {
  const AuthLanguageSelect({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// 選ばれている言語
  final AppLanguage value;

  /// 言語が選ばれたときの処理
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: AppColors.profileFieldBackground,
        border: Border.all(color: AppColors.authLanguageBorder),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 14,
        children: [
          Text(
            context.l10n.authLanguageSetting,
            style: const TextStyle(
              color: AppColors.authLanguageLabel,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 92),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AppLanguage>(
                value: value,
                isDense: true,
                isExpanded: false,
                alignment: AlignmentDirectional.centerEnd,
                borderRadius: BorderRadius.circular(12),
                dropdownColor: Colors.white,
                focusColor: Colors.transparent,
                icon: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: AppIcon(
                    AppIconName.chevronDown,
                    size: 14,
                    color: AppColors.authLanguageValue,
                  ),
                ),
                style: const TextStyle(
                  color: AppColors.authLanguageValue,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  for (final language in AppLanguage.values)
                    DropdownMenuItem(
                      value: language,
                      child: Text(languageName(language)),
                    ),
                ],
                onChanged: (language) {
                  if (language != null) onChanged(language);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
