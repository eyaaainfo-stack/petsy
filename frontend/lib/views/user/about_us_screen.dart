import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/back_button.dart';
import '../../widgets/paw_widget.dart';

// ============================================================================
// AboutUsScreen (kifma tlab: "kol chy nhebbou kima fi teswira eli
// baatthelk - just logo w card rose fih lktiba heki")
// ============================================================================
// 🔵 Wsulha mel sidebar (owner w sitter, item "About us"). 🔴 FIX:
// design mbsat (nafs el mockup el eli 3tanih): title + logo "PETSY" +
// card rose WA7DA fiha el ktiba (bla icons, bla image, bla signature
// mnfassla) - na77ina el 3 "value cards" (icons) w el hero image
// w el closing/signature (kanou zeydin 3la el mockup).
// ============================================================================
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color bodyTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textDark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            buildPetPaw(context: context, size: sizes.screenWidth * 0.14, topPercent: 0.02, leftPercent: 0.86, color: AppColors.pinkpetsy.withOpacity(0.15)),
            buildPetPaw(context: context, size: sizes.screenWidth * 0.11, topPercent: 0.92, leftPercent: 0.04, color: AppColors.vertpetsy.withOpacity(0.15)),

            ListView(
              padding: EdgeInsets.symmetric(horizontal: sizes.aboutUsHorizontalPadding),
              children: [
                SizedBox(height: sizes.aboutUsTopGap),
                Center(
                  child: Text(
                    'about_us_title'.tr(),
                    style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.aboutUsTitleFontSize),
                  ),
                ),

                SizedBox(height: sizes.aboutUsSectionGap),

                // ------------------------------------------------------
                // Logo "ppetsy.jpg" - kifma fi teswira. 🔵 ZID: el user
                // yzid el fichier f assets/images/ppetsy.jpg (nafs
                // folder ppetsy.png el mawjouda, chraht fel pubspec.yaml).
                // ------------------------------------------------------
                Center(
                  child: Image.asset(
                    'assets/images/ppetsy.jpg',
                    width: sizes.screenWidth * 0.5,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Text(
                      'PETSY',
                      style: TextStyle(
                        color: AppColors.vertpetsy,
                        fontWeight: FontWeight.w900,
                        fontSize: sizes.aboutUsLogoFontSize,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: sizes.aboutUsSectionGap),

                // ------------------------------------------------------
                // Card rose WA7DA fiha el ktiba el kaملa (intro + 2
                // paragraphes) - kifma fi teswira, bla icons/titres.
                // ------------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(sizes.aboutUsCardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.pinkpetsy.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(sizes.aboutUsHeroRadius * 1.6),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'about_us_intro'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: sizes.aboutUsIntroFontSize, color: bodyTextColor, height: 1.5),
                      ),
                      SizedBox(height: sizes.aboutUsCardGap),
                      Text(
                        'about_us_card1_body'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: sizes.aboutUsIntroFontSize, color: bodyTextColor, height: 1.5),
                      ),
                      SizedBox(height: sizes.aboutUsCardGap),
                      Text(
                        'about_us_card2_body'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: sizes.aboutUsIntroFontSize, color: bodyTextColor, height: 1.5),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: sizes.aboutUsSectionGap * 1.5),
              ],
            ),

            const CustomBackButton(),
          ],
        ),
      ),
    );
  }
}