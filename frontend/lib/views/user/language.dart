import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../widgets/button.dart';
import '../../widgets/outlined_button.dart'; // 👈 Import mte3 el widget ejdid
import '../../widgets/paw_widget.dart';
import 'onboarding.dart';

class LanguageView extends StatefulWidget {
  const LanguageView({super.key});

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
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OnboardingView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 🐾 1. Paws de décoration
            buildPetPaw(
              context: context,
              size: 80,
              topPercent: 0.2,
              leftPercent: 0.80,
              color: AppColors.pinkpetsy,
            ),
            buildPetPaw(
              context: context,
              size: 70,
              topPercent: 0.05,
              leftPercent: 0.08,
              color: AppColors.vertpetsy,
            ),
            buildPetPaw(
              context: context,
              size: 30,
              topPercent: 0.09,
              leftPercent: 0.20,
              color: AppColors.vertpetsy,
            ),
            buildPetPaw(
              context: context,
              size: 60,
              topPercent: 0.30,
              leftPercent: 0.75,
              color: AppColors.pinkpetsy,
            ),
            buildPetPaw(
              context: context,
              size: 40,
              topPercent: 0.82,
              leftPercent: 0.9,
              color: AppColors.vertpetsy,
            ),
            buildPetPaw(
              context: context,
              size: 19,
              topPercent: 0.85,
              leftPercent: 0.87,
              color: AppColors.vertpetsy,
            ),

            // 📄 2. Contenu Principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // Logo Sittopia
                  Center(
                    child: SizedBox(
                      width: 242,
                      height: 57,
                      child: Image.asset(
                        'assets/images/ppetsy.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Titre
                  Text(
                    'choose_language_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pinkpetsy,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 110),

                  // 🌐 3. Les boutons de sélection de langue (CustomOutlinedButton)
                  Expanded(
                    child: Column(
                      children: [
                        CustomOutlinedButton(
                          text: '🇹🇳   Arabe',
                          isSelected: _selectedLanguageCode == 'ar',
                          width: screenSize.width * 0.85,  // 85% men 3ordh el ecran
                          height: screenSize.height * 0.1, // 7.5% men toul el ecran
                          fontFactor: 0.37, // 👈 Kobr el ktaba 35% men height el bouton!
                          onPressed: () => _selectLanguage('ar'),
                        ),
                        const SizedBox(height: 16),
                        CustomOutlinedButton(
                          text: '🇫🇷   Français',
                          isSelected: _selectedLanguageCode == 'fr',
                          width: screenSize.width * 0.85,
                          height: screenSize.height * 0.1,
                          fontFactor: 0.37,
                          onPressed: () => _selectLanguage('fr'),
                        ),
                        const SizedBox(height: 16),
                        CustomOutlinedButton(
                          text: '🇬🇧   English',
                          isSelected: _selectedLanguageCode == 'en',
                          width: screenSize.width * 0.85,
                          height: screenSize.height * 0.1,
                          fontFactor: 0.37,
                          onPressed: () => _selectLanguage('en'),
                        ),
                      ],
                    ),
                  ),

                  // 🔘 4. Bouton Next
                  CustomButton(
                    text: 'next_button'.tr(),
                    color: AppColors.vertpetsy,
                    widthFactor: 0.84,
                    heightFactor: 0.07,
                    fontFactor: 0.65,
                    onPressed: _onNextPressed,
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}