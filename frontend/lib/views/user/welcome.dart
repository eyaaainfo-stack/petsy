import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/button.dart';
import '../../widgets/paw_widget.dart';
import '../../widgets/back_button.dart';
import '../../controllers/app_preferences.dart';
import 'account_type.dart';

// ============================================================================
// WelcomeView
// ============================================================================
// Hedhi el écran elli tji ba3d el 4 pages tel onboarding (kifha kif fel
// design elli b3aththa: "Welcome to PETSY" + soura tel 3 hayawanet + bouton
// "Get Started"). Écran STATIC (mafamech PageView/swipe houni, page wa7da
// w bess, mafamech fikra "current page" wala "dots").
// ============================================================================
class WelcomeView extends StatelessWidget {
  // StatelessWidget mch StatefulWidget: 3lech? 7it el écran hedha ma3andouch
  // "state" (7aja tetbeddel fi runtime, kif _currentPage fel onboarding).
  // Ki écran ma3andouch state, nesta3mlou StatelessWidget - a3sal w a5ff.
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // --------------------------------------------------------------
            // 🐾 Paws decoratives mbaathrin fel background (kifha kif design)
            // Kol wehda size/blasa mo5talfa, ki fel photo (top-right kbira,
            // yesarra sghira, etc). Kolhom mahsoubin b'% mel screenSize.
            // --------------------------------------------------------------
            buildPetPaw(
              context: context,
              size: sizes.welcomePawSize1,
              topPercent: 0.06,
              leftPercent: 0.68,
              color: AppColors.vertpetsy.withOpacity(0.6),
            ),
            buildPetPaw(
              context: context,
              size: sizes.welcomePawSize2,
              topPercent: 0.13,
              leftPercent: 0.08,
              color: AppColors.pinkpetsy.withOpacity(0.55),
            ),
            buildPetPaw(
              context: context,
              size: sizes.welcomePawSize3,
              topPercent: 0.26,
              leftPercent: 0.60,
              color: AppColors.vertpetsy.withOpacity(0.55),
            ),
            buildPetPaw(
              context: context,
              size: sizes.welcomePawSize4,
              topPercent: 0.50,
              leftPercent: 0.86,
              color: AppColors.pinkpetsy.withOpacity(0.55),
            ),
            buildPetPaw(
              context: context,
              size: sizes.welcomePawSize5,
              topPercent: 0.60,
              leftPercent: 0.42,
              color: AppColors.pinkpetsy.withOpacity(0.55),
            ),
            buildPetPaw(
              context: context,
              size: sizes.welcomePawSize6,
              topPercent: 0.72,
              leftPercent: 0.78,
              color: AppColors.vertpetsy.withOpacity(0.55),
            ),
            buildPetPaw(
              context: context,
              size: sizes.welcomePawSize7,
              topPercent: 0.80,
              leftPercent: 0.05,
              color: AppColors.vertpetsy.withOpacity(0.55),
            ),

            // 🔙 Back button -> yerja3 lel écran onboarding (lel akher
            // page elli kanet fiha, PageController ye7fadh el état)
            const CustomBackButton(),

            // --------------------------------------------------------------
            // Contenu principal: Column wa7da tji fiha kol 7aja mel fouq
            // lel te7t (image -> title -> soutitre -> bouton).
            // --------------------------------------------------------------
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sizes.welcomeHorizontalPadding),
              child: Column(
                children: [
                  // Espace fadhi fouq (7atta el image tji fel westt bel 3ard)
                  SizedBox(height: sizes.welcomeTopGap),

                  // ----------------------------------------------------------
                  // 🖼️ IMAGE — houni el blasa mte3 soura el 3 hayawanet.
                  // 👉 7ott el image fel: assets/images/welcome_pets.png
                  // (nafs mant9 el onboarding: badel ghir el fichier, el path
                  // fel code ma tbeddlouch)
                  // ----------------------------------------------------------
                  Image.asset(
                    'assets/images/welcome_pets.png',
                    width: sizes.welcomeImageWidth,
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: sizes.welcomeImageTitleGap),

                  // Title "Welcome to PETSY" - loun fixe pinkpetsy
                  Text(
                    'welcome_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: sizes.welcomeTitleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pinkpetsy,
                    ),
                  ),

                  SizedBox(height: sizes.welcomeTitleSubtitleGap),

                  // Soutitre "We are so happy to see you here" - loun
                  // vertpetsy (teal) bch ykoun kifha kif el design elli
                  // b3aththa (fel design el soutitre b'loun teal, mch grey)
                  Text(
                    'welcome_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: sizes.welcomeSubtitleFontSize,
                      color: AppColors.vertpetsy,
                      height: 1.4,
                    ),
                  ),

                  // ----------------------------------------------------------
                  // Spacer: widget "khali" ya5ou kol el espace elli fadhi
                  // elli baaha, w yzid bouton "Get Started" el te7t nih.
                  // Bdal ma nekteb SizedBox b'height fixe (elli ma yebkach
                  // sa7i7 fi kol hjm écran), Spacer automatique yet7addad
                  // 3la 7sab el espace elli fadhi.
                  // ----------------------------------------------------------
                  const Spacer(),

                  // ----------------------------------------------------------
                  // 🔘 Bouton "Get Started" -> ymchi lel écran "Choose your
                  // account type" (el 4 roles: Owner/Sitter/Admin/Courier)
                  // ----------------------------------------------------------
                  CustomButton(
                    text: 'get_started_button'.tr(),
                    color: AppColors.pinkpetsy,
                    widthFactor: 0.90,
                    heightFactor: 0.075,
                    fontFactor: 0.40,
                    onPressed: () async {
                      // 🔵 ZID: n7ottou el flag "el user 3adda el
                      // onboarding" - bch el app ma tarja3ch twarrih
                      // Language/slides mel jdid el marra el jaya elli
                      // yeftah biha el app (chrahtha fel splash_decider.dart).
                      await AppPreferences.setHasSeenOnboarding();
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AccountTypeView()),
                      );
                    },
                  ),

                  SizedBox(height: sizes.welcomeBottomGap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}