import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/back_button.dart';
import 'theme.dart';
import 'language.dart';

// ============================================================================
// SettingsScreen ("settings_screen.dart") - mchtarek bin owner w sitter
// ============================================================================
// 🔵 Wsulha mel sidebar (owner/sitter, item "Settings") - "Theme" ->
// theme.dart (jdid), "Language" -> language.dart (el EXISTING, mel
// onboarding - lakin "fromSettings: true" bch "Next" ma ymchich l
// OnboardingView, ghir yrajja3 (pop) l'Settings).
// ============================================================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sizes.fpHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: sizes.fpTopGap + sizes.fpBackButtonSize),
                  Text(
                    'settings_label'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.pinkpetsy, fontSize: sizes.fpTitleFontSize * 0.75),
                  ),
                  SizedBox(height: sizes.fpSectionGap * 1.5),

                  _settingsRow(
                    context: context,
                    sizes: sizes,
                    icon: Icons.palette_outlined,
                    label: 'theme_label'.tr(),
                    mutedTextColor: mutedTextColor,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ThemeScreen()));
                    },
                  ),
                  Divider(color: AppColors.pinkpetsy.withOpacity(0.15)),
                  _settingsRow(
                    context: context,
                    sizes: sizes,
                    icon: Icons.language_outlined,
                    label: 'language_label'.tr(),
                    mutedTextColor: mutedTextColor,
                    onTap: () {
                      // 🔵 "fromSettings: true" - bch "Next" (LanguageView)
                      // ghir yrajja3 (pop) l'Settings, mch ymchi
                      // l'OnboardingView (kifma el behavior el asli tel
                      // onboarding).
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LanguageView(fromSettings: true)));
                    },
                  ),
                  Divider(color: AppColors.pinkpetsy.withOpacity(0.15)),
                ],
              ),
            ),

            const CustomBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _settingsRow({
    required BuildContext context,
    required AppSizes sizes,
    required IconData icon,
    required String label,
    required Color mutedTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.018),
        child: Row(
          children: [
            Icon(icon, color: AppColors.pinkpetsy, size: sizes.screenWidth * 0.06),
            SizedBox(width: sizes.screenWidth * 0.04),
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: sizes.myProfileBodyFontSize))),
            Icon(Icons.chevron_right, color: mutedTextColor),
          ],
        ),
      ),
    );
  }
}