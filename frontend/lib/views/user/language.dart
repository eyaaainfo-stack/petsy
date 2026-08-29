import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/button.dart';
import '../../widgets/outlined_button.dart'; // 👈 Import mte3 el widget ejdid
import '../../widgets/paw_widget.dart';
import 'onboarding.dart';

class LanguageView extends StatefulWidget {
  // 🔵 ZID: "true" ki el écran mawsoul mel Settings (settings_screen.dart)
  // - "Next" wa9tha ghir yرجّع (pop), mch ymchi l'OnboardingView (elli
  // mch mant9iya fi context "Settings", el user déjà logué w fel app).
  final bool fromSettings;

  const LanguageView({super.key, this.fromSettings = false});

  @override
  State<LanguageView> createState() => _LanguageViewState();
}

class _LanguageViewState extends State<LanguageView> {
  String _selectedLanguageCode = 'fr';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLanguageCode = context.locale.languageCode;
  }

  void _selectLanguage(String languageCode) async {
    setState(() {
      _selectedLanguageCode = languageCode;
    });
    // Live switch: el interface tetbadel fi el لحظة نفسها
    await context.setLocale(Locale(languageCode));
  }

  void _onNextPressed() {
    if (!mounted) return;
    if (widget.fromSettings) {
      // 🔵 Settings context - el langue tبdلت déjà LIVE (setLocale
      // fou9), ghir nرجّعو (pop) l'Settings.
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 🐾 1. Paws de décoration
            buildPetPaw(
              context: context,
              size: sizes.languagePawSize1,
              topPercent: 0.2,
              leftPercent: 0.80,
              color: AppColors.pinkpetsy,
            ),
            buildPetPaw(
              context: context,
              size: sizes.languagePawSize2,
              topPercent: 0.05,
              leftPercent: 0.08,
              color: AppColors.vertpetsy,
            ),
            buildPetPaw(
              context: context,
              size: sizes.languagePawSize3,
              topPercent: 0.09,
              leftPercent: 0.20,
              color: AppColors.vertpetsy,
            ),
            buildPetPaw(
              context: context,
              size: sizes.languagePawSize4,
              topPercent: 0.30,
              leftPercent: 0.75,
              color: AppColors.pinkpetsy,
            ),
            buildPetPaw(
              context: context,
              size: sizes.languagePawSize5,
              topPercent: 0.82,
              leftPercent: 0.9,
              color: AppColors.vertpetsy,
            ),
            buildPetPaw(
              context: context,
              size: sizes.languagePawSize6,
              topPercent: 0.85,
              leftPercent: 0.87,
              color: AppColors.vertpetsy,
            ),

            // 📄 2. Contenu Principal
            // 🔵 sa77e7t crash réel (RenderFlex overflow): el gaps
            // el fixes (SizedBox 80/40/110) + el Expanded kanou
            // ye7sbou b'écran "standard" - fi téléphone b'écran
            // asghar (height a9al), el contenu ma yenajjamch kaملou
            // fel espace disponible w l'app te-crash. Tawa:
            // LayoutBuilder + SingleChildScrollView + spaceBetween
            // (mch Expanded) - el contenu yeftereq b'el espace
            // disponible ken kbir bizzef (nafs look el 9dim), w
            // yscrolli (bla crash) ken l'écran ma yesta3ich.
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32, // -32: el vertical padding fou9
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // --- Block 1: Logo + Titre ---
                        Column(
                          children: [
                            SizedBox(height: sizes.languageBlockTopGap),
                            Center(
                              child: SizedBox(
                                width: sizes.languageLogoWidth,
                                height: sizes.languageLogoHeight,
                                child: Image.asset(
                                  'assets/images/ppetsy.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            SizedBox(height: sizes.languageLogoTitleGap),
                            Text(
                              'choose_language_title'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: sizes.languageTitleFontSize,
                                fontWeight: FontWeight.bold,
                                color: AppColors.pinkpetsy,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),

                        // --- Block 2: Boutons de sélection de langue ---
                        Column(
                          children: [
                            CustomOutlinedButton(
                              text: '🇹🇳   Arabe',
                              isSelected: _selectedLanguageCode == 'ar',
                              width: sizes.languageButtonWidth,
                              height: sizes.languageButtonHeight,
                              fontFactor: 0.37,
                              onPressed: () => _selectLanguage('ar'),
                            ),
                            SizedBox(height: sizes.languageButtonGap),
                            CustomOutlinedButton(
                              text: '🇫🇷   Français',
                              isSelected: _selectedLanguageCode == 'fr',
                              width: sizes.languageButtonWidth,
                              height: sizes.languageButtonHeight,
                              fontFactor: 0.37,
                              onPressed: () => _selectLanguage('fr'),
                            ),
                            SizedBox(height: sizes.languageButtonGap),
                            CustomOutlinedButton(
                              text: '🇬🇧   English',
                              isSelected: _selectedLanguageCode == 'en',
                              width: sizes.languageButtonWidth,
                              height: sizes.languageButtonHeight,
                              fontFactor: 0.37,
                              onPressed: () => _selectLanguage('en'),
                            ),
                          ],
                        ),

                        // --- Block 3: Bouton Next ---
                        Column(
                          children: [
                            CustomButton(
                              text: 'next_button'.tr(),
                              color: AppColors.vertpetsy,
                              widthFactor: 0.84,
                              heightFactor: 0.07,
                              fontFactor: 0.65,
                              onPressed: _onNextPressed,
                            ),
                            SizedBox(height: sizes.languageBottomGap),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}