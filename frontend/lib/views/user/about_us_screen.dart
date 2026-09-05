import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/back_button.dart';
import '../../widgets/paw_widget.dart';

// ============================================================================
// AboutUsScreen (kifma tlab: "interface about us mahleha w fiha klem
// touchant qui valorise l'effort w le projet w el afkar lkol eli bch
// tkoun tsahal ala el user")
// ============================================================================
// 🔵 Wsulha mel sidebar (owner w sitter, item "About us") - kanet
// "_notImplementedYet" (TODO) - tawa screen 7a9i9i, m3ammar b klem
// heartfelt (mch générique) 3ala el 9issa/el jouhd/el afkar wra el app.
// ============================================================================
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.75) ?? Colors.grey;
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
                // Hero image - kifma tlab: "genere une photo liha... tw
                // nhot esmha aboutus.png" - el user y7ott el fichier
                // f assets/images/aboutus.png (nafs blasa el images
                // l'okhrin, chraht fel pubspec.yaml).
                // ------------------------------------------------------
                ClipRRect(
                  borderRadius: BorderRadius.circular(sizes.aboutUsHeroRadius),
                  child: Image.asset(
                    'assets/images/aboutus.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: sizes.screenWidth * 0.5,
                      color: AppColors.pinkpetsy.withOpacity(0.08),
                      alignment: Alignment.center,
                      child: Icon(Icons.pets, size: sizes.screenWidth * 0.16, color: AppColors.pinkpetsy.withOpacity(0.4)),
                    ),
                  ),
                ),

                SizedBox(height: sizes.aboutUsSectionGap),

                // ------------------------------------------------------
                // Intro - el 9issa mella bdat kolchi.
                // ------------------------------------------------------
                Text(
                  'about_us_intro'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: sizes.aboutUsIntroFontSize, color: bodyTextColor, height: 1.5),
                ),

                SizedBox(height: sizes.aboutUsSectionGap * 1.2),

                // ------------------------------------------------------
                // 3 cards - el jouhd/el afkar/el communauté (kifma tlab:
                // "klem touchant qui valorise l'effort w le projet w
                // el afkar lkol eli bch tkoun tsahal ala el user").
                // ------------------------------------------------------
                _valueCard(
                  sizes: sizes,
                  icon: Icons.auto_awesome,
                  iconColor: AppColors.pinkpetsy,
                  titleKey: 'about_us_card1_title',
                  bodyKey: 'about_us_card1_body',
                  bodyTextColor: bodyTextColor,
                ),
                SizedBox(height: sizes.aboutUsCardGap),
                _valueCard(
                  sizes: sizes,
                  icon: Icons.favorite_rounded,
                  iconColor: AppColors.vertpetsy,
                  titleKey: 'about_us_card2_title',
                  bodyKey: 'about_us_card2_body',
                  bodyTextColor: bodyTextColor,
                ),
                SizedBox(height: sizes.aboutUsCardGap),
                _valueCard(
                  sizes: sizes,
                  icon: Icons.diversity_3_rounded,
                  iconColor: AppColors.pinkpetsy,
                  titleKey: 'about_us_card3_title',
                  bodyKey: 'about_us_card3_body',
                  bodyTextColor: bodyTextColor,
                ),

                SizedBox(height: sizes.aboutUsSectionGap * 1.4),

                // ------------------------------------------------------
                // Closing - merci, ta7t el 3in tel user (kifma tlab:
                // "haja lel kol" - moush personnalisée per role).
                // ------------------------------------------------------
                Text(
                  'about_us_closing'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: sizes.aboutUsClosingFontSize, fontWeight: FontWeight.w600, color: AppColors.vertpetsy, height: 1.5),
                ),

                SizedBox(height: sizes.aboutUsSectionGap),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pets, color: mutedTextColor, size: sizes.aboutUsIntroFontSize),
                      SizedBox(width: sizes.screenWidth * 0.02),
                      Text('about_us_signature'.tr(), style: TextStyle(color: mutedTextColor, fontStyle: FontStyle.italic, fontSize: sizes.aboutUsIntroFontSize * 0.9)),
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

  Widget _valueCard({
    required AppSizes sizes,
    required IconData icon,
    required Color iconColor,
    required String titleKey,
    required String bodyKey,
    required Color bodyTextColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sizes.aboutUsCardPadding),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: sizes.aboutUsCardIconSize,
                height: sizes.aboutUsCardIconSize,
                decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: sizes.aboutUsCardIconSize * 0.55),
              ),
              SizedBox(width: sizes.aboutUsCardIconGap),
              Expanded(
                child: Text(
                  titleKey.tr(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.aboutUsCardTitleFontSize, color: iconColor),
                ),
              ),
            ],
          ),
          SizedBox(height: sizes.aboutUsCardGap * 0.6),
          Text(
            bodyKey.tr(),
            style: TextStyle(fontSize: sizes.aboutUsCardBodyFontSize, color: bodyTextColor, height: 1.45),
          ),
        ],
      ),
    );
  }
}