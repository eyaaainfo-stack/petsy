import 'package:flutter/material.dart';

// ============================================================================
// AppSizes
// ============================================================================
// 🔵 Blasa WA7DA lel sizes el kol (%) - bdal ma ykounou mfarr9in (magic
// numbers) fi kol widget. Ken t7eb tbeddel size (mathalan button ykber/
// isghar, font ykber/isghar...), beddel el RATIO houni BARK - kol el
// app elli testa3melha tetba3 automatiquement.
//
// Kifech testa3melha fi widget:
//   final sizes = AppSizes.of(context);
//   ...
//   height: sizes.accountButtonHeight,
//
// (terja3lek el valeur el 7a9i9iya bel pixels, mahsouba mel ratio * size
// tel écran 7a9i9i - nafs el mantiq el 9dim, ghir centralisé).
// ============================================================================
class AppSizes {
  AppSizes._(this._screenSize);

  final Size _screenSize;

  static AppSizes of(BuildContext context) =>
      AppSizes._(MediaQuery.of(context).size);

  double get screenWidth => _screenSize.width;
  double get screenHeight => _screenSize.height;

  // --------------------------------------------------------------------
  // Account type buttons (views/user/account_type.dart)
  // --------------------------------------------------------------------
  static const double accountButtonWidthRatio = 0.7;
  static const double accountButtonHeightRatio = 0.11;
  static const double accountButtonPaddingHRatio = 0.03;
  static const double accountButtonPaddingVRatio = 0.03;
  static const double accountButtonIconRatio = 0.045;
  static const double accountButtonArrowIconRatio = 0.038;
  static const double accountButtonTitleFontRatio = 0.032;
  static const double accountButtonDescFontRatio = 0.021;
  static const double accountButtonGapRatio = 0.015;
  static const double accountButtonEndGapRatio = 0.02;
  static const double accountButtonTitleGapRatio = 0.003;

  double get accountButtonWidth => screenWidth * accountButtonWidthRatio;
  double get accountButtonHeight => screenHeight * accountButtonHeightRatio;
  double get accountButtonPaddingH => screenWidth * accountButtonPaddingHRatio;
  double get accountButtonPaddingV => screenHeight * accountButtonPaddingVRatio;
  double get accountButtonIconSize => screenWidth * accountButtonIconRatio;
  double get accountButtonArrowIconSize => screenWidth * accountButtonArrowIconRatio;
  double get accountButtonTitleFontSize => screenWidth * accountButtonTitleFontRatio;
  double get accountButtonDescFontSize => screenWidth * accountButtonDescFontRatio;
  double get accountButtonGap => screenWidth * accountButtonGapRatio;
  double get accountButtonEndGap => screenWidth * accountButtonEndGapRatio;
  double get accountButtonTitleGap => screenHeight * accountButtonTitleGapRatio;

  // --------------------------------------------------------------------
  // 🔵 ZID houni el sections l'okhrin ki tbeddel fichier ekhor (nafs
  // el mantiq: esm el widget/écran, mba3d el ratios mte3ou). Mathalan:
  //
  // // Welcome screen (views/user/welcome.dart)
  // static const double welcomeTitleFontRatio = 0.06;
  // double get welcomeTitleFontSize => screenWidth * welcomeTitleFontRatio;
  // --------------------------------------------------------------------

  // --------------------------------------------------------------------
  // Language screen (views/user/language.dart)
  //
  // 🔵 REMARQUE: el valeurs el 9dam kanou FIXES (mch %) - 80, 242, 30...
  // hedhom mel design original, mahsoubin par rapport écran "référence"
  // 390x844 (taille standard tel téléphone moderne, mathalan iPhone 12/13
  // logical points) - bch el proportion tebda EXACTEMENT kifha kif kanet
  // 9bal (bla ay far9 fel design 3al appareil el testa3mlou el dev), w
  // tawa TZID tetba3 el kobr tel écran (tkabber/tsaghar automatique).
  // --------------------------------------------------------------------
  static const double languagePawSize1Ratio = 80 / 390;
  static const double languagePawSize2Ratio = 70 / 390;
  static const double languagePawSize3Ratio = 30 / 390;
  static const double languagePawSize4Ratio = 60 / 390;
  static const double languagePawSize5Ratio = 40 / 390;
  static const double languagePawSize6Ratio = 19 / 390;

  static const double languageLogoWidthRatio = 242 / 390;
  static const double languageLogoHeightRatio = 57 / 844;

  static const double languageTitleFontRatio = 30 / 390;

  static const double languageBlockTopGapRatio = 24 / 844;
  static const double languageLogoTitleGapRatio = 24 / 844;
  static const double languageButtonGapRatio = 16 / 844;
  static const double languageBottomGapRatio = 10 / 844;

  static const double languageButtonWidthRatio = 0.85;
  static const double languageButtonHeightRatio = 0.1;

  double get languagePawSize1 => screenWidth * languagePawSize1Ratio;
  double get languagePawSize2 => screenWidth * languagePawSize2Ratio;
  double get languagePawSize3 => screenWidth * languagePawSize3Ratio;
  double get languagePawSize4 => screenWidth * languagePawSize4Ratio;
  double get languagePawSize5 => screenWidth * languagePawSize5Ratio;
  double get languagePawSize6 => screenWidth * languagePawSize6Ratio;

  double get languageLogoWidth => screenWidth * languageLogoWidthRatio;
  double get languageLogoHeight => screenHeight * languageLogoHeightRatio;

  double get languageTitleFontSize => screenWidth * languageTitleFontRatio;

  double get languageBlockTopGap => screenHeight * languageBlockTopGapRatio;
  double get languageLogoTitleGap => screenHeight * languageLogoTitleGapRatio;
  double get languageButtonGap => screenHeight * languageButtonGapRatio;
  double get languageBottomGap => screenHeight * languageBottomGapRatio;

  double get languageButtonWidth => screenWidth * languageButtonWidthRatio;
  double get languageButtonHeight => screenHeight * languageButtonHeightRatio;

  // --------------------------------------------------------------------
  // Splash screen (views/user/splash_decider.dart)
  // --------------------------------------------------------------------
  static const double splashLogoWidthRatio = 180 / 390;
  static const double splashLogoGapRatio = 24 / 844;

  double get splashLogoWidth => screenWidth * splashLogoWidthRatio;
  double get splashLogoGap => screenHeight * splashLogoGapRatio;

  // --------------------------------------------------------------------
  // Welcome screen (views/user/welcome.dart)
  // --------------------------------------------------------------------
  static const double welcomePawSize1Ratio = 0.10;
  static const double welcomePawSize2Ratio = 0.085;
  static const double welcomePawSize3Ratio = 0.075;
  static const double welcomePawSize4Ratio = 0.07;
  static const double welcomePawSize5Ratio = 0.06;
  static const double welcomePawSize6Ratio = 0.065;
  static const double welcomePawSize7Ratio = 0.075;

  static const double welcomeHorizontalPaddingRatio = 0.06;
  static const double welcomeTopGapRatio = 0.2;
  static const double welcomeImageWidthRatio = 0.80;
  static const double welcomeImageTitleGapRatio = 0.035;
  static const double welcomeTitleFontRatio = 0.072;
  static const double welcomeTitleSubtitleGapRatio = 0.014;
  static const double welcomeSubtitleFontRatio = 0.040;
  static const double welcomeBottomGapRatio = 0.04;

  double get welcomePawSize1 => screenWidth * welcomePawSize1Ratio;
  double get welcomePawSize2 => screenWidth * welcomePawSize2Ratio;
  double get welcomePawSize3 => screenWidth * welcomePawSize3Ratio;
  double get welcomePawSize4 => screenWidth * welcomePawSize4Ratio;
  double get welcomePawSize5 => screenWidth * welcomePawSize5Ratio;
  double get welcomePawSize6 => screenWidth * welcomePawSize6Ratio;
  double get welcomePawSize7 => screenWidth * welcomePawSize7Ratio;

  double get welcomeHorizontalPadding => screenWidth * welcomeHorizontalPaddingRatio;
  double get welcomeTopGap => screenHeight * welcomeTopGapRatio;
  double get welcomeImageWidth => screenWidth * welcomeImageWidthRatio;
  double get welcomeImageTitleGap => screenHeight * welcomeImageTitleGapRatio;
  double get welcomeTitleFontSize => screenWidth * welcomeTitleFontRatio;
  double get welcomeTitleSubtitleGap => screenHeight * welcomeTitleSubtitleGapRatio;
  double get welcomeSubtitleFontSize => screenWidth * welcomeSubtitleFontRatio;
  double get welcomeBottomGap => screenHeight * welcomeBottomGapRatio;

  // --------------------------------------------------------------------
  // Onboarding screen (views/user/onboarding.dart)
  // --------------------------------------------------------------------
  static const double onboardingPawSize1Ratio = 0.11;
  static const double onboardingPawSize2Ratio = 0.07;
  static const double onboardingSkipAreaHeightRatio = 0.06;
  static const double onboardingSkipPaddingHRatio = 0.02;
  static const double onboardingSkipFontRatio = 0.033;
  static const double onboardingPagePaddingHRatio = 0.08;
  static const double onboardingImageSizeRatio = 0.65;
  static const double onboardingTitleFontRatio = 0.045;
  static const double onboardingTitleSubtitleGapRatio = 0.018;
  static const double onboardingSubtitleFontRatio = 0.038;
  static const double onboardingDotMarginHRatio = 0.010;
  static const double onboardingDotActiveWidthRatio = 0.065;
  static const double onboardingDotInactiveWidthRatio = 0.020;
  static const double onboardingDotHeightRatio = 0.020;
  static const double onboardingDotRadiusRatio = 0.02;
  static const double onboardingDotsButtonGapRatio = 0.025;
  static const double onboardingBottomGapRatio = 0.03;

  double get onboardingPawSize1 => screenWidth * onboardingPawSize1Ratio;
  double get onboardingPawSize2 => screenWidth * onboardingPawSize2Ratio;
  double get onboardingSkipAreaHeight => screenHeight * onboardingSkipAreaHeightRatio;
  double get onboardingSkipPaddingH => screenWidth * onboardingSkipPaddingHRatio;
  double get onboardingSkipFontSize => screenWidth * onboardingSkipFontRatio;
  double get onboardingPagePaddingH => screenWidth * onboardingPagePaddingHRatio;
  double get onboardingImageSize => screenWidth * onboardingImageSizeRatio;
  double get onboardingTitleFontSize => screenWidth * onboardingTitleFontRatio;
  double get onboardingTitleSubtitleGap => screenHeight * onboardingTitleSubtitleGapRatio;
  double get onboardingSubtitleFontSize => screenWidth * onboardingSubtitleFontRatio;
  double get onboardingDotMarginH => screenWidth * onboardingDotMarginHRatio;
  double get onboardingDotActiveWidth => screenWidth * onboardingDotActiveWidthRatio;
  double get onboardingDotInactiveWidth => screenWidth * onboardingDotInactiveWidthRatio;
  double get onboardingDotHeight => screenWidth * onboardingDotHeightRatio;
  double get onboardingDotRadius => screenWidth * onboardingDotRadiusRatio;
  double get onboardingDotsButtonGap => screenHeight * onboardingDotsButtonGapRatio;
  double get onboardingBottomGap => screenHeight * onboardingBottomGapRatio;

  // --------------------------------------------------------------------
  // Auth screens (views/user/user_login.dart & views/user/user_signin.dart)
  //
  // 🔵 el zouz écrans 3andhom NAFS el header/logo/champs/social row (design
  // wa7ed) - fa el ratios el mochtarkin esmhom "auth*". Kol wa7ed 3andou
  // ba3d el ratios el 5assin bih bark (mathalan "forgot password" mawjouda
  // fel login bark) - esmhom "authLogin*" / "authSignup*".
  // --------------------------------------------------------------------
  static const double authPawSize1Ratio = 0.08;
  static const double authPawSize2Ratio = 0.075;
  static const double authPawSize3Ratio = 0.06;
  static const double authHorizontalPaddingRatio = 0.08;
  static const double authTopGapRatio = 0.10;
  static const double authLogoWidthRatio = 0.56;
  static const double authLogoTitleGapRatio = 0.022;
  static const double authTitleFontRatio = 0.052;
  static const double authTitleSubtitleGapRatio = 0.004;
  static const double authSubtitleFontRatio = 0.043;
  static const double authSubtitleFieldsGapRatio = 0.045;
  static const double authFieldLabelFontRatio = 0.037;
  static const double authLabelFieldGapRatio = 0.008;
  static const double authFieldsGapRatio = 0.022;
  static const double authButtonWidthRatio = 0.90;
  static const double authButtonHeightRatio = 0.07;
  static const double authDividerGapRatio = 0.038;
  static const double authDividerPaddingHRatio = 0.03;
  static const double authDividerFontRatio = 0.033;
  static const double authDividerSocialGapRatio = 0.025;
  static const double authSocialIconPaddingRatio = 0.02;
  static const double authGoogleIconSizeRatio = 0.11;
  static const double authSocialIconsGapRatio = 0.05;
  static const double authFacebookIconSizeRatio = 0.09;
  static const double authBottomGapRatio = 0.03;

  // Sign up (user_signin.dart) - gap 5ass bark
  static const double authSignupPreButtonGapRatio = 0.035;

  // Login (user_login.dart) - gaps/font 5assin bark
  static const double authLoginPreButtonGapRatio = 0.03;
  static const double authLoginButtonForgotGapRatio = 0.02;
  static const double authForgotPasswordFontRatio = 0.036;
  static const double authForgotCreateAccountGapRatio = 0.025;
  static const double authCreateAccountFontFactor = 0.38; // fontFactor (mch % l'écran, factor dakhli tel widget)

  double get authPawSize1 => screenWidth * authPawSize1Ratio;
  double get authPawSize2 => screenWidth * authPawSize2Ratio;
  double get authPawSize3 => screenWidth * authPawSize3Ratio;
  double get authHorizontalPadding => screenWidth * authHorizontalPaddingRatio;
  double get authTopGap => screenHeight * authTopGapRatio;
  double get authLogoWidth => screenWidth * authLogoWidthRatio;
  double get authLogoTitleGap => screenHeight * authLogoTitleGapRatio;
  double get authTitleFontSize => screenWidth * authTitleFontRatio;
  double get authTitleSubtitleGap => screenHeight * authTitleSubtitleGapRatio;
  double get authSubtitleFontSize => screenWidth * authSubtitleFontRatio;
  double get authSubtitleFieldsGap => screenHeight * authSubtitleFieldsGapRatio;
  double get authFieldLabelFontSize => screenWidth * authFieldLabelFontRatio;
  double get authLabelFieldGap => screenHeight * authLabelFieldGapRatio;
  double get authFieldsGap => screenHeight * authFieldsGapRatio;
  double get authButtonWidth => screenWidth * authButtonWidthRatio;
  double get authButtonHeight => screenHeight * authButtonHeightRatio;
  double get authDividerGap => screenHeight * authDividerGapRatio;
  double get authDividerPaddingH => screenWidth * authDividerPaddingHRatio;
  double get authDividerFontSize => screenWidth * authDividerFontRatio;
  double get authDividerSocialGap => screenHeight * authDividerSocialGapRatio;
  double get authSocialIconPadding => screenWidth * authSocialIconPaddingRatio;
  double get authGoogleIconSize => screenWidth * authGoogleIconSizeRatio;
  double get authSocialIconsGap => screenWidth * authSocialIconsGapRatio;
  double get authFacebookIconSize => screenWidth * authFacebookIconSizeRatio;
  double get authBottomGap => screenHeight * authBottomGapRatio;

  double get authSignupPreButtonGap => screenHeight * authSignupPreButtonGapRatio;

  double get authLoginPreButtonGap => screenHeight * authLoginPreButtonGapRatio;
  double get authLoginButtonForgotGap => screenHeight * authLoginButtonForgotGapRatio;
  double get authForgotPasswordFontSize => screenWidth * authForgotPasswordFontRatio;
  double get authForgotCreateAccountGap => screenHeight * authForgotCreateAccountGapRatio;

  // --------------------------------------------------------------------
  // Account type screen (views/user/account_type.dart) - el écran b rou7ou
  // (paws + logo + titre). El bouton (_AccountTypeButton) 3andou el
  // "accountButton*" section el fou9 fel fichier.
  // --------------------------------------------------------------------
  static const double accountTypePawSize1Ratio = 0.09;
  static const double accountTypePawSize2Ratio = 0.07;
  static const double accountTypePawSize3Ratio = 0.06;
  static const double accountTypePawSize4Ratio = 0.1;
  static const double accountTypePawSize5Ratio = 0.3;
  static const double accountTypePawSize6Ratio = 0.07;
  static const double accountTypePawSize7Ratio = 0.13;
  static const double accountTypePawSize8Ratio = 0.07;
  static const double accountTypePawSize9Ratio = 0.13;
  static const double accountTypePawSize10Ratio = 0.1;
  static const double accountTypePawSize11Ratio = 0.1;

  static const double accountTypeHorizontalPaddingRatio = 0.07;
  static const double accountTypeTopGapRatio = 0.15;
  static const double accountTypeLogoWidthRatio = 0.62;
  static const double accountTypeLogoTitleGapRatio = 0.08;
  static const double accountTypeTitleFontRatio = 0.052;
  static const double accountTypeTitleButtonsGapRatio = 0.029;
  static const double accountTypeButtonSpacingRatio = 0.022;
  static const double accountTypeBottomGapRatio = 0.02;

  double get accountTypePawSize1 => screenWidth * accountTypePawSize1Ratio;
  double get accountTypePawSize2 => screenWidth * accountTypePawSize2Ratio;
  double get accountTypePawSize3 => screenWidth * accountTypePawSize3Ratio;
  double get accountTypePawSize4 => screenWidth * accountTypePawSize4Ratio;
  double get accountTypePawSize5 => screenWidth * accountTypePawSize5Ratio;
  double get accountTypePawSize6 => screenWidth * accountTypePawSize6Ratio;
  double get accountTypePawSize7 => screenWidth * accountTypePawSize7Ratio;
  double get accountTypePawSize8 => screenWidth * accountTypePawSize8Ratio;
  double get accountTypePawSize9 => screenWidth * accountTypePawSize9Ratio;
  double get accountTypePawSize10 => screenWidth * accountTypePawSize10Ratio;
  double get accountTypePawSize11 => screenWidth * accountTypePawSize11Ratio;

  double get accountTypeHorizontalPadding => screenWidth * accountTypeHorizontalPaddingRatio;
  double get accountTypeTopGap => screenHeight * accountTypeTopGapRatio;
  double get accountTypeLogoWidth => screenWidth * accountTypeLogoWidthRatio;
  double get accountTypeLogoTitleGap => screenHeight * accountTypeLogoTitleGapRatio;
  double get accountTypeTitleFontSize => screenWidth * accountTypeTitleFontRatio;
  double get accountTypeTitleButtonsGap => screenHeight * accountTypeTitleButtonsGapRatio;
  double get accountTypeButtonSpacing => screenHeight * accountTypeButtonSpacingRatio;
  double get accountTypeBottomGap => screenHeight * accountTypeBottomGapRatio;

  // --------------------------------------------------------------------
  // Create sitter profile - services screen (views/user/sitter/create_sitter_profile.dart)
  // --------------------------------------------------------------------
  static const double sitterServicesPawSize1Ratio = 0.09;
  static const double sitterServicesPawSize2Ratio = 0.07;
  static const double sitterServicesHorizontalPaddingRatio = 0.06;
  static const double sitterServicesTopGapRatio = 0.09;
  static const double sitterServicesTitleFontRatio = 0.052;
  static const double sitterServicesTitleCardGapRatio = 0.03;
  static const double sitterServicesRowGapRatio = 0.018;
  static const double sitterServicesBottomGapRatio = 0.03;

  double get sitterServicesPawSize1 => screenWidth * sitterServicesPawSize1Ratio;
  double get sitterServicesPawSize2 => screenWidth * sitterServicesPawSize2Ratio;
  double get sitterServicesHorizontalPadding => screenWidth * sitterServicesHorizontalPaddingRatio;
  double get sitterServicesTopGap => screenHeight * sitterServicesTopGapRatio;
  double get sitterServicesTitleFontSize => screenWidth * sitterServicesTitleFontRatio;
  double get sitterServicesTitleCardGap => screenHeight * sitterServicesTitleCardGapRatio;
  double get sitterServicesRowGap => screenHeight * sitterServicesRowGapRatio;
  double get sitterServicesBottomGap => screenHeight * sitterServicesBottomGapRatio;

  // --------------------------------------------------------------------
  // Create sitter profile 2 - home & transport screen
  // (views/user/sitter/create_sitter_profile_2.dart)
  // --------------------------------------------------------------------
  static const double sitterHomePawSize1Ratio = 0.09;
  static const double sitterHomeHorizontalPaddingRatio = 0.06;
  static const double sitterHomeTopGapRatio = 0.09;
  static const double sitterHomeTitleFontRatio = 0.052;
  static const double sitterHomeTitleBoxGapRatio = 0.03;
  static const double sitterHomeBoxGapRatio = 0.022;
  static const double sitterHomeOptionIconSizeRatio = 0.09;
  static const double sitterHomeBottomGapRatio = 0.03;
  // 🔵 ZID (kifma tlab): "el card lkol ye5o l'image" (dog/cat, create_
  // sitter_profile_2.dart) - height fixe (Expanded te7taj hjm mbayyen).
  static const double sitterPetTypeCardHeightRatio = 0.32;

  double get sitterHomePawSize1 => screenWidth * sitterHomePawSize1Ratio;
  double get sitterHomeHorizontalPadding => screenWidth * sitterHomeHorizontalPaddingRatio;
  double get sitterHomeTopGap => screenHeight * sitterHomeTopGapRatio;
  double get sitterHomeTitleFontSize => screenWidth * sitterHomeTitleFontRatio;
  double get sitterHomeTitleBoxGap => screenHeight * sitterHomeTitleBoxGapRatio;
  double get sitterHomeBoxGap => screenHeight * sitterHomeBoxGapRatio;
  double get sitterHomeOptionIconSize => screenWidth * sitterHomeOptionIconSizeRatio;
  double get sitterHomeBottomGap => screenHeight * sitterHomeBottomGapRatio;
  double get sitterPetTypeCardHeight => screenHeight * sitterPetTypeCardHeightRatio;

  // --------------------------------------------------------------------
  // Sitter home screen (views/user/sitter/sitter_profile.dart)
  // --------------------------------------------------------------------
  static const double sitterProfileHorizontalPaddingRatio = 0.06;
  static const double sitterProfileTopGapRatio = 0.02;
  static const double sitterProfileAvatarRatio = 0.13;
  static const double sitterProfileHeaderNameFontRatio = 0.042;
  static const double sitterProfileHeaderCityFontRatio = 0.032;
  static const double sitterProfileIconButtonSizeRatio = 0.10;
  static const double sitterProfileSectionGapRatio = 0.03;
  static const double sitterProfileSectionTitleFontRatio = 0.042;
  static const double sitterProfileSectionTitleListGapRatio = 0.016;
  static const double sitterProfileTodayCardWidthRatio = 0.62;
  static const double sitterProfileTodayCardHeightRatio = 0.16;
  static const double sitterProfileTodayCardGapRatio = 0.03;
  static const double sitterProfileEmptyStateVerticalPadRatio = 0.045;
  static const double sitterProfileEmptyStateIconRatio = 0.11;
  static const double sitterProfileBottomGapRatio = 0.03;

  double get sitterProfileHorizontalPadding => screenWidth * sitterProfileHorizontalPaddingRatio;
  double get sitterProfileTopGap => screenHeight * sitterProfileTopGapRatio;
  double get sitterProfileAvatarRadius => screenWidth * sitterProfileAvatarRatio;
  double get sitterProfileHeaderNameFontSize => screenWidth * sitterProfileHeaderNameFontRatio;
  double get sitterProfileHeaderCityFontSize => screenWidth * sitterProfileHeaderCityFontRatio;
  double get sitterProfileIconButtonSize => screenWidth * sitterProfileIconButtonSizeRatio;
  double get sitterProfileSectionGap => screenHeight * sitterProfileSectionGapRatio;
  double get sitterProfileSectionTitleFontSize => screenWidth * sitterProfileSectionTitleFontRatio;
  double get sitterProfileSectionTitleListGap => screenHeight * sitterProfileSectionTitleListGapRatio;
  double get sitterProfileTodayCardWidth => screenWidth * sitterProfileTodayCardWidthRatio;
  double get sitterProfileTodayCardHeight => screenHeight * sitterProfileTodayCardHeightRatio;
  double get sitterProfileTodayCardGap => screenWidth * sitterProfileTodayCardGapRatio;
  double get sitterProfileEmptyStateVerticalPad => screenHeight * sitterProfileEmptyStateVerticalPadRatio;
  double get sitterProfileEmptyStateIconSize => screenWidth * sitterProfileEmptyStateIconRatio;
  double get sitterProfileBottomGap => screenHeight * sitterProfileBottomGapRatio;

  // --------------------------------------------------------------------
  // Sidebar sitter (widgets/drawers/sidebar_sitter.dart)
  // --------------------------------------------------------------------
  static const double sidebarWidthRatio = 0.74;
  static const double sidebarHeaderPaddingRatio = 0.06;
  static const double sidebarPhotoSizeRatio = 0.34;
  static const double sidebarNameFontRatio = 0.045;
  static const double sidebarPawSize1Ratio = 0.09;
  static const double sidebarPawSize2Ratio = 0.06;
  static const double sidebarItemFontRatio = 0.038;
  static const double sidebarItemIconRatio = 0.055;
  static const double sidebarItemVerticalPadRatio = 0.016;
  static const double sidebarAboutButtonHeightRatio = 0.065;

  double get sidebarWidth => screenWidth * sidebarWidthRatio;
  double get sidebarHeaderPadding => screenWidth * sidebarHeaderPaddingRatio;
  double get sidebarPhotoSize => screenWidth * sidebarPhotoSizeRatio;
  double get sidebarNameFontSize => screenWidth * sidebarNameFontRatio;
  double get sidebarPawSize1 => screenWidth * sidebarPawSize1Ratio;
  double get sidebarPawSize2 => screenWidth * sidebarPawSize2Ratio;
  double get sidebarItemFontSize => screenWidth * sidebarItemFontRatio;
  double get sidebarItemIconSize => screenWidth * sidebarItemIconRatio;
  double get sidebarItemVerticalPad => screenHeight * sidebarItemVerticalPadRatio;
  double get sidebarAboutButtonHeight => screenHeight * sidebarAboutButtonHeightRatio;

  // --------------------------------------------------------------------
  // My Profile (views/user/sitter/my_profile_sitter.dart)
  // --------------------------------------------------------------------
  static const double myProfileHorizontalPaddingRatio = 0.06;
  static const double myProfileTopGapRatio = 0.02;
  static const double myProfilePhotoSizeRatio = 0.16;
  static const double myProfileNameFontRatio = 0.045;
  static const double myProfileCityFontRatio = 0.032;
  static const double myProfileSectionGapRatio = 0.025;
  static const double myProfilePillFontRatio = 0.036;
  static const double myProfileBodyFontRatio = 0.033;
  static const double myProfileMiniCardIconRatio = 0.09;
  static const double myProfileBottomGapRatio = 0.03;

  double get myProfileHorizontalPadding => screenWidth * myProfileHorizontalPaddingRatio;
  double get myProfileTopGap => screenHeight * myProfileTopGapRatio;
  double get myProfilePhotoSize => screenWidth * myProfilePhotoSizeRatio;
  double get myProfileNameFontSize => screenWidth * myProfileNameFontRatio;
  double get myProfileCityFontSize => screenWidth * myProfileCityFontRatio;
  double get myProfileSectionGap => screenHeight * myProfileSectionGapRatio;
  double get myProfilePillFontSize => screenWidth * myProfilePillFontRatio;
  double get myProfileBodyFontSize => screenWidth * myProfileBodyFontRatio;
  double get myProfileMiniCardIconSize => screenWidth * myProfileMiniCardIconRatio;
  double get myProfileBottomGap => screenHeight * myProfileBottomGapRatio;

  // --------------------------------------------------------------------
  // Update My Profile (views/user/sitter/update_profile_sitter.dart)
  // --------------------------------------------------------------------
  static const double updateProfilePhotoSizeRatio = 0.28;
  static const double updateProfileTopGapRatio = 0.02;

  double get updateProfilePhotoSize => screenWidth * updateProfilePhotoSizeRatio;
  double get updateProfileTopGap => screenHeight * updateProfileTopGapRatio;

  // --------------------------------------------------------------------
  // Update Pet Profile (views/user/owner/update_pet_profile.dart)
  // --------------------------------------------------------------------
  static const double updatePetBannerHeightRatio = 0.16;
  static const double updatePetPhotoSizeRatio = 0.26;
  static const double updatePetTitleFontRatio = 0.048;
  static const double updatePetHorizontalPaddingRatio = 0.07;
  static const double updatePetLabelFontRatio = 0.033;
  static const double updatePetValueFontRatio = 0.036;
  static const double updatePetFieldGapRatio = 0.016;
  static const double updatePetSectionGapRatio = 0.028;
  static const double updatePetPawSizeRatio = 0.055;

  double get updatePetBannerHeight => screenHeight * updatePetBannerHeightRatio;
  double get updatePetPhotoSize => screenWidth * updatePetPhotoSizeRatio;
  double get updatePetTitleFontSize => screenWidth * updatePetTitleFontRatio;
  double get updatePetHorizontalPadding => screenWidth * updatePetHorizontalPaddingRatio;
  double get updatePetLabelFontSize => screenWidth * updatePetLabelFontRatio;
  double get updatePetValueFontSize => screenWidth * updatePetValueFontRatio;
  double get updatePetFieldGap => screenHeight * updatePetFieldGapRatio;
  double get updatePetSectionGap => screenHeight * updatePetSectionGapRatio;
  double get updatePetPawSize => screenWidth * updatePetPawSizeRatio;

  // --------------------------------------------------------------------
  // Forgot password flow (mdp_oublier_1/2/3.dart) - ratios mchtarkin
  // bin el 3 écrans (nafs structure: back button + paws + illustration
  // + titre + soutitre + champs + bouton).
  // --------------------------------------------------------------------
  static const double fpHorizontalPaddingRatio = 0.07;
  static const double fpTopGapRatio = 0.02;
  static const double fpBackButtonSizeRatio = 0.11;
  static const double fpPawSizeRatio = 0.07;
  static const double fpIllustrationSizeRatio = 0.45;
  static const double fpIllustrationIconRatio = 0.20;
  static const double fpTitleFontRatio = 0.058;
  static const double fpSubtitleFontRatio = 0.036;
  static const double fpSectionGapRatio = 0.03;
  static const double fpFieldGapRatio = 0.01;

  double get fpHorizontalPadding => screenWidth * fpHorizontalPaddingRatio;
  double get fpTopGap => screenHeight * fpTopGapRatio;
  double get fpBackButtonSize => screenWidth * fpBackButtonSizeRatio;
  double get fpPawSize => screenWidth * fpPawSizeRatio;
  double get fpIllustrationSize => screenWidth * fpIllustrationSizeRatio;
  double get fpIllustrationIconSize => screenWidth * fpIllustrationIconRatio;
  double get fpTitleFontSize => screenWidth * fpTitleFontRatio;
  double get fpSubtitleFontSize => screenWidth * fpSubtitleFontRatio;
  double get fpSectionGap => screenHeight * fpSectionGapRatio;
  double get fpFieldGap => screenHeight * fpFieldGapRatio;

  // --------------------------------------------------------------------
  // View Profile Sitter (views/user/sitter/view_profile_sitter.dart)
  // --------------------------------------------------------------------
  static const double vpsHeaderTopPaddingRatio = 0.025;
  static const double vpsHeaderBottomPaddingRatio = 0.02;
  static const double vpsPhotoSizeRatio = 0.24;
  static const double vpsPhotoPlaceholderIconRatio = 0.08;
  static const double vpsTabGapRatio = 0.06;
  static const double vpsTabUnderlineWidthRatio = 0.14;
  static const double vpsDividerGapRatio = 0.03;
  static const double vpsRequestButtonHeightRatio = 0.065;
  static const double vpsEmptyStateIconRatio = 0.12;
  static const double vpsEmptyStateVerticalPadRatio = 0.05;

  double get vpsHeaderTopPadding => screenHeight * vpsHeaderTopPaddingRatio;
  double get vpsHeaderBottomPadding => screenHeight * vpsHeaderBottomPaddingRatio;
  double get vpsPhotoSize => screenWidth * vpsPhotoSizeRatio;
  double get vpsPhotoPlaceholderIcon => screenWidth * vpsPhotoPlaceholderIconRatio;
  double get vpsTabGap => screenWidth * vpsTabGapRatio;
  double get vpsTabUnderlineWidth => screenWidth * vpsTabUnderlineWidthRatio;
  double get vpsDividerGap => screenHeight * vpsDividerGapRatio;
  double get vpsRequestButtonHeight => screenHeight * vpsRequestButtonHeightRatio;
  double get vpsEmptyStateIcon => screenWidth * vpsEmptyStateIconRatio;
  double get vpsEmptyStateVerticalPad => screenHeight * vpsEmptyStateVerticalPadRatio;

  // --------------------------------------------------------------------
  // Request a Book (views/user/owner/request_a_book.dart)
  // --------------------------------------------------------------------
  static const double rabHorizontalPaddingRatio = 0.06;
  static const double rabTopGapRatio = 0.02;
  static const double rabSectionGapRatio = 0.025;
  static const double rabCalendarDayHeightRatio = 0.1;
  static const double rabPetTileSizeRatio = 0.16;
  static const double rabAccommodationIconRatio = 0.09;

  double get rabHorizontalPadding => screenWidth * rabHorizontalPaddingRatio;
  double get rabTopGap => screenHeight * rabTopGapRatio;
  double get rabSectionGap => screenHeight * rabSectionGapRatio;
  double get rabCalendarDayHeight => screenHeight * rabCalendarDayHeightRatio;
  double get rabPetTileSize => screenWidth * rabPetTileSizeRatio;
  double get rabAccommodationIcon => screenWidth * rabAccommodationIconRatio;

  // --------------------------------------------------------------------
  // Notifications (views/user/notifications_screen.dart)
  // --------------------------------------------------------------------
  static const double notifHorizontalPaddingRatio = 0.06;
  static const double notifTopGapRatio = 0.02;
  static const double notifSectionGapRatio = 0.025;
  static const double notifIconSizeRatio = 0.09;
  static const double notifEmptyStateIconRatio = 0.14;

  double get notifHorizontalPadding => screenWidth * notifHorizontalPaddingRatio;
  double get notifTopGap => screenHeight * notifTopGapRatio;
  double get notifSectionGap => screenHeight * notifSectionGapRatio;
  double get notifIconSize => screenWidth * notifIconSizeRatio;
  double get notifEmptyStateIcon => screenWidth * notifEmptyStateIconRatio;

  // --------------------------------------------------------------------
  // My Favourites (views/user/owner/my_favourites_screen.dart)
  // --------------------------------------------------------------------
  static const double favHorizontalPaddingRatio = 0.06;
  static const double favTopGapRatio = 0.02;
  static const double favCardSpacingRatio = 0.03;
  static const double favPhotoHeightRatio = 0.16;
  static const double favEmptyStateIconRatio = 0.14;

  double get favHorizontalPadding => screenWidth * favHorizontalPaddingRatio;
  double get favTopGap => screenHeight * favTopGapRatio;
  double get favCardSpacing => screenWidth * favCardSpacingRatio;
  double get favPhotoHeight => screenHeight * favPhotoHeightRatio;
  double get favEmptyStateIcon => screenWidth * favEmptyStateIconRatio;

  // --------------------------------------------------------------------
  // My Bookings (views/user/owner/les_reservations.dart)
  // --------------------------------------------------------------------
  static const double bookingHorizontalPaddingRatio = 0.06;
  static const double bookingTopGapRatio = 0.02;
  static const double bookingSectionGapRatio = 0.025;
  static const double bookingCardPaddingRatio = 0.04;
  static const double bookingAvatarSizeRatio = 0.10;
  static const double bookingPillFontRatio = 0.028;
  static const double bookingEmptyStateIconRatio = 0.14;

  double get bookingHorizontalPadding => screenWidth * bookingHorizontalPaddingRatio;
  double get bookingTopGap => screenHeight * bookingTopGapRatio;
  double get bookingSectionGap => screenHeight * bookingSectionGapRatio;
  double get bookingCardPadding => screenWidth * bookingCardPaddingRatio;
  double get bookingAvatarSize => screenWidth * bookingAvatarSizeRatio;
  double get bookingPillFont => screenWidth * bookingPillFontRatio;
  double get bookingEmptyStateIcon => screenWidth * bookingEmptyStateIconRatio;

  // --------------------------------------------------------------------
  // Sitter Calendar (views/user/sitter/sitter_calender.dart)
  // --------------------------------------------------------------------
  static const double calendarHorizontalPaddingRatio = 0.05;
  static const double calendarTopGapRatio = 0.02;
  static const double calendarSectionGapRatio = 0.022;
  static const double calendarCellFontRatio = 0.032;
  static const double calendarDotSizeRatio = 0.012;
  static const double calendarEventIconSizeRatio = 0.11;

  double get calendarHorizontalPadding => screenWidth * calendarHorizontalPaddingRatio;
  double get calendarTopGap => screenHeight * calendarTopGapRatio;
  double get calendarSectionGap => screenHeight * calendarSectionGapRatio;
  double get calendarCellFont => screenWidth * calendarCellFontRatio;
  double get calendarDotSize => screenWidth * calendarDotSizeRatio;
  double get calendarEventIconSize => screenWidth * calendarEventIconSizeRatio;

  // --------------------------------------------------------------------
  // Admin Home (views/user/admin/admin_home.dart)
  // --------------------------------------------------------------------
  static const double adminHomeTopGapRatio = 0.02;
  static const double adminHomeHorizontalPaddingRatio = 0.06;
  static const double adminHomeAvatarSizeRatio = 0.13;
  static const double adminHomeAvatarIconRatio = 0.075;
  static const double adminHomeAvatarTextGapRatio = 0.03;
  static const double adminHomeNameFontRatio = 0.042;
  static const double adminHomeBadgeFontRatio = 0.032;
  static const double adminHomeMenuButtonSizeRatio = 0.10;
  static const double adminHomeMenuIconRatio = 0.055;
  static const double adminHomeHeaderSectionGapRatio = 0.04;
  static const double adminHomeSectionTitleFontRatio = 0.05;
  static const double adminHomeSectionTitleListGapRatio = 0.02;
  static const double adminHomeBottomGapRatio = 0.03;

  double get adminHomeTopGap => screenHeight * adminHomeTopGapRatio;
  double get adminHomeHorizontalPadding => screenWidth * adminHomeHorizontalPaddingRatio;
  double get adminHomeAvatarSize => screenWidth * adminHomeAvatarSizeRatio;
  double get adminHomeAvatarIcon => screenWidth * adminHomeAvatarIconRatio;
  double get adminHomeAvatarTextGap => screenWidth * adminHomeAvatarTextGapRatio;
  double get adminHomeNameFontSize => screenWidth * adminHomeNameFontRatio;
  double get adminHomeBadgeFontSize => screenWidth * adminHomeBadgeFontRatio;
  double get adminHomeMenuButtonSize => screenWidth * adminHomeMenuButtonSizeRatio;
  double get adminHomeMenuIconSize => screenWidth * adminHomeMenuIconRatio;
  double get adminHomeHeaderSectionGap => screenHeight * adminHomeHeaderSectionGapRatio;
  double get adminHomeSectionTitleFontSize => screenWidth * adminHomeSectionTitleFontRatio;
  double get adminHomeSectionTitleListGap => screenHeight * adminHomeSectionTitleListGapRatio;
  double get adminHomeBottomGap => screenHeight * adminHomeBottomGapRatio;

  // --------------------------------------------------------------------
  // Admin Menu Tile (widgets/admin_menu_tile.dart)
  // --------------------------------------------------------------------
  static const double adminTilePaddingHRatio = 0.04;
  static const double adminTilePaddingVRatio = 0.028;
  static const double adminTileAvatarSizeRatio = 0.11;
  static const double adminTileAvatarTextGapRatio = 0.035;
  static const double adminTileIconRatio = 0.055;
  static const double adminTileLabelFontRatio = 0.038;
  static const double adminTileBadgePaddingHRatio = 0.022;
  static const double adminTileBadgeMinWidthRatio = 0.06;
  static const double adminTileBadgeFontRatio = 0.028;
  static const double adminTileBadgeChevronGapRatio = 0.02;
  static const double adminTileChevronRatio = 0.055;

  double get adminTilePaddingH => screenWidth * adminTilePaddingHRatio;
  double get adminTilePaddingV => screenWidth * adminTilePaddingVRatio;
  double get adminTileAvatarSize => screenWidth * adminTileAvatarSizeRatio;
  double get adminTileAvatarTextGap => screenWidth * adminTileAvatarTextGapRatio;
  double get adminTileIconSize => screenWidth * adminTileIconRatio;
  double get adminTileLabelFontSize => screenWidth * adminTileLabelFontRatio;
  double get adminTileBadgePaddingH => screenWidth * adminTileBadgePaddingHRatio;
  double get adminTileBadgeMinWidth => screenWidth * adminTileBadgeMinWidthRatio;
  double get adminTileBadgeFontSize => screenWidth * adminTileBadgeFontRatio;
  double get adminTileBadgeChevronGap => screenWidth * adminTileBadgeChevronGapRatio;
  double get adminTileChevronSize => screenWidth * adminTileChevronRatio;

  // --------------------------------------------------------------------
  // Admin Statistics hub (views/user/admin/admin_statistics.dart)
  // --------------------------------------------------------------------
  static const double adminStatsPawSizeRatio = 0.09;
  static const double adminStatsHorizontalPaddingRatio = 0.06;
  static const double adminStatsTopGapRatio = 0.09;
  static const double adminStatsTitleFontRatio = 0.06;
  static const double adminStatsSectionGapRatio = 0.03;
  static const double adminStatsTileGapRatio = 0.018;
  static const double adminStatsBottomGapRatio = 0.03;

  double get adminStatsPawSize => screenWidth * adminStatsPawSizeRatio;
  double get adminStatsHorizontalPadding => screenWidth * adminStatsHorizontalPaddingRatio;
  double get adminStatsTopGap => screenHeight * adminStatsTopGapRatio;
  double get adminStatsTitleFontSize => screenWidth * adminStatsTitleFontRatio;
  double get adminStatsSectionGap => screenHeight * adminStatsSectionGapRatio;
  double get adminStatsTileGap => screenHeight * adminStatsTileGapRatio;
  double get adminStatsBottomGap => screenHeight * adminStatsBottomGapRatio;

  // --------------------------------------------------------------------
  // Admin Registrations (views/user/admin/admin_registrations.dart)
  // --------------------------------------------------------------------
  static const double adminRegPawSizeRatio = 0.09;
  static const double adminRegHorizontalPaddingRatio = 0.06;
  static const double adminRegTopGapRatio = 0.09;
  static const double adminRegTitleFontRatio = 0.06;
  static const double adminRegSectionGapRatio = 0.03;
  static const double adminRegLoadingVerticalPadRatio = 0.12;
  static const double adminRegErrorVerticalPadRatio = 0.1;
  static const double adminRegErrorIconRatio = 0.12;
  static const double adminRegErrorIconGapRatio = 0.015;
  static const double adminRegErrorButtonGapRatio = 0.02;
  static const double adminRegTotalCardPaddingRatio = 0.05;
  static const double adminRegTotalCardLabelFontRatio = 0.035;
  static const double adminRegTotalCardLabelValueGapRatio = 0.006;
  static const double adminRegTotalCardValueFontRatio = 0.11;
  static const double adminRegAfterTotalCardGapRatio = 0.03;
  static const double adminRegSectionTitleFontRatio = 0.038;
  static const double adminRegSectionTitleGridGapRatio = 0.015;
  static const double adminRegGridSpacingRatio = 0.04;
  static const double adminRegBottomGapRatio = 0.03;
  // 🔴 FIX (overflow StatCard): kanet GridView b'childAspectRatio 1.25
  // (magic number, mch AppSizes) - cell height mahsouba minha kanet
  // A9SAR mel contenu 7a9i9i tel StatCard (icon+value+label 2 lignes) -
  // "RenderFlex overflowed by 5.5 pixels". Tawa: Wrap b'width fixe
  // (mch height fixe) - kol StatCard yakhod el height elli te7tejou
  // el contenu tou3ha (robuste m3a ay lougha/police, mch magic ratio
  // yenkasar mel jdid ken label ytawwel).
  static const double adminRegCardWidthRatio = 0.42;

  double get adminRegPawSize => screenWidth * adminRegPawSizeRatio;
  double get adminRegHorizontalPadding => screenWidth * adminRegHorizontalPaddingRatio;
  double get adminRegTopGap => screenHeight * adminRegTopGapRatio;
  double get adminRegTitleFontSize => screenWidth * adminRegTitleFontRatio;
  double get adminRegSectionGap => screenHeight * adminRegSectionGapRatio;
  double get adminRegLoadingVerticalPad => screenHeight * adminRegLoadingVerticalPadRatio;
  double get adminRegErrorVerticalPad => screenHeight * adminRegErrorVerticalPadRatio;
  double get adminRegErrorIcon => screenWidth * adminRegErrorIconRatio;
  double get adminRegErrorIconGap => screenHeight * adminRegErrorIconGapRatio;
  double get adminRegErrorButtonGap => screenHeight * adminRegErrorButtonGapRatio;
  double get adminRegTotalCardPadding => screenWidth * adminRegTotalCardPaddingRatio;
  double get adminRegTotalCardLabelFontSize => screenWidth * adminRegTotalCardLabelFontRatio;
  double get adminRegTotalCardLabelValueGap => screenHeight * adminRegTotalCardLabelValueGapRatio;
  double get adminRegTotalCardValueFontSize => screenWidth * adminRegTotalCardValueFontRatio;
  double get adminRegAfterTotalCardGap => screenHeight * adminRegAfterTotalCardGapRatio;
  double get adminRegSectionTitleFontSize => screenWidth * adminRegSectionTitleFontRatio;
  double get adminRegSectionTitleGridGap => screenHeight * adminRegSectionTitleGridGapRatio;
  double get adminRegGridSpacing => screenWidth * adminRegGridSpacingRatio;
  double get adminRegBottomGap => screenHeight * adminRegBottomGapRatio;
  double get adminRegCardWidth => screenWidth * adminRegCardWidthRatio;

  // --------------------------------------------------------------------
  // Admin Dashboard (views/user/admin/admin_dashboard.dart)
  // --------------------------------------------------------------------
  static const double adminDashPawSizeRatio = 0.09;
  static const double adminDashHorizontalPaddingRatio = 0.06;
  static const double adminDashTopGapRatio = 0.09;
  static const double adminDashTitleFontRatio = 0.06;
  static const double adminDashTitleSubtitleGapRatio = 0.01;
  static const double adminDashSubtitleFontRatio = 0.033;
  static const double adminDashSubtitleSelectorGapRatio = 0.025;
  static const double adminDashSelectorPaddingHRatio = 0.04;
  static const double adminDashSelectorPaddingVRatio = 0.02;
  static const double adminDashSelectorFontRatio = 0.035;
  static const double adminDashSelectorChartGapRatio = 0.03;
  static const double adminDashLoadingVerticalPadRatio = 0.12;
  static const double adminDashErrorVerticalPadRatio = 0.1;
  static const double adminDashErrorIconRatio = 0.12;
  static const double adminDashErrorIconGapRatio = 0.015;
  static const double adminDashErrorButtonGapRatio = 0.02;
  static const double adminDashChartCardPaddingRatio = 0.04;
  static const double adminDashChartHeightRatio = 0.28;
  static const double adminDashBottomGapRatio = 0.03;

  double get adminDashPawSize => screenWidth * adminDashPawSizeRatio;
  double get adminDashHorizontalPadding => screenWidth * adminDashHorizontalPaddingRatio;
  double get adminDashTopGap => screenHeight * adminDashTopGapRatio;
  double get adminDashTitleFontSize => screenWidth * adminDashTitleFontRatio;
  double get adminDashTitleSubtitleGap => screenHeight * adminDashTitleSubtitleGapRatio;
  double get adminDashSubtitleFontSize => screenWidth * adminDashSubtitleFontRatio;
  double get adminDashSubtitleSelectorGap => screenHeight * adminDashSubtitleSelectorGapRatio;
  double get adminDashSelectorPaddingH => screenWidth * adminDashSelectorPaddingHRatio;
  double get adminDashSelectorPaddingV => screenWidth * adminDashSelectorPaddingVRatio;
  double get adminDashSelectorFontSize => screenWidth * adminDashSelectorFontRatio;
  double get adminDashSelectorChartGap => screenHeight * adminDashSelectorChartGapRatio;
  double get adminDashLoadingVerticalPad => screenHeight * adminDashLoadingVerticalPadRatio;
  double get adminDashErrorVerticalPad => screenHeight * adminDashErrorVerticalPadRatio;
  double get adminDashErrorIcon => screenWidth * adminDashErrorIconRatio;
  double get adminDashErrorIconGap => screenHeight * adminDashErrorIconGapRatio;
  double get adminDashErrorButtonGap => screenHeight * adminDashErrorButtonGapRatio;
  double get adminDashChartCardPadding => screenWidth * adminDashChartCardPaddingRatio;
  double get adminDashChartHeight => screenHeight * adminDashChartHeightRatio;
  double get adminDashBottomGap => screenHeight * adminDashBottomGapRatio;

  // --------------------------------------------------------------------
  // Stat Card (widgets/stat_card.dart)
  // --------------------------------------------------------------------
  static const double statCardPaddingRatio = 0.035;
  static const double statCardIconContainerSizeRatio = 0.1;
  static const double statCardIconSizeRatio = 0.05;
  static const double statCardIconValueGapRatio = 0.035;
  static const double statCardValueFontRatio = 0.065;
  static const double statCardValueLabelGapRatio = 0.008;
  static const double statCardLabelFontRatio = 0.03;

  double get statCardPadding => screenWidth * statCardPaddingRatio;
  double get statCardIconContainerSize => screenWidth * statCardIconContainerSizeRatio;
  double get statCardIconSize => screenWidth * statCardIconSizeRatio;
  double get statCardIconValueGap => screenWidth * statCardIconValueGapRatio;
  double get statCardValueFontSize => screenWidth * statCardValueFontRatio;
  double get statCardValueLabelGap => screenWidth * statCardValueLabelGapRatio;
  double get statCardLabelFontSize => screenWidth * statCardLabelFontRatio;

  // --------------------------------------------------------------------
  // Line Chart (widgets/line_chart_widget.dart)
  // --------------------------------------------------------------------
  static const double lineChartHeightRatio = 0.28;
  static const double lineChartAxisFontRatio = 0.026;
  static const double lineChartLegendFontRatio = 0.032;
  static const double lineChartLegendDotRatio = 0.024;
  static const double lineChartLegendGapRatio = 0.014;
  static const double lineChartLegendSpacingRatio = 0.04;
  static const double lineChartLegendRunSpacingRatio = 0.02;
  static const double lineChartLegendDotTextGapRatio = 0.015;
  static const double lineChartLeftPadRatio = 0.085;
  static const double lineChartBottomPadRatio = 0.058;
  static const double lineChartTopPadRatio = 0.025;
  static const double lineChartRightPadRatio = 0.015;
  static const double lineChartAxisLabelGapRatio = 0.015;
  static const double lineChartStrokeWidthRatio = 0.006;
  static const double lineChartDotRadiusRatio = 0.007;

  double get lineChartHeight => screenHeight * lineChartHeightRatio;
  double get lineChartAxisFontSize => screenWidth * lineChartAxisFontRatio;
  double get lineChartLegendFontSize => screenWidth * lineChartLegendFontRatio;
  double get lineChartLegendDotSize => screenWidth * lineChartLegendDotRatio;
  double get lineChartLegendGap => screenHeight * lineChartLegendGapRatio;
  double get lineChartLegendSpacing => screenWidth * lineChartLegendSpacingRatio;
  double get lineChartLegendRunSpacing => screenWidth * lineChartLegendRunSpacingRatio;
  double get lineChartLegendDotTextGap => screenWidth * lineChartLegendDotTextGapRatio;
  double get lineChartLeftPad => screenWidth * lineChartLeftPadRatio;
  double get lineChartBottomPad => screenWidth * lineChartBottomPadRatio;
  double get lineChartTopPad => screenWidth * lineChartTopPadRatio;
  double get lineChartRightPad => screenWidth * lineChartRightPadRatio;
  double get lineChartAxisLabelGap => screenWidth * lineChartAxisLabelGapRatio;
  double get lineChartStrokeWidth => screenWidth * lineChartStrokeWidthRatio;
  double get lineChartDotRadius => screenWidth * lineChartDotRadiusRatio;

  // --------------------------------------------------------------------
  // Admin Accounts (views/user/admin/admin_accounts.dart) - "Gestion
  // des comptes" (recherche/filtre/liste/create).
  // --------------------------------------------------------------------
  static const double adminAccountsPawSizeRatio = 0.09;
  static const double adminAccountsHorizontalPaddingRatio = 0.06;
  static const double adminAccountsTopGapRatio = 0.09;
  static const double adminAccountsTitleFontRatio = 0.06;
  static const double adminAccountsSectionGapRatio = 0.025;
  static const double adminAccountsSearchIconRatio = 0.05;
  static const double adminAccountsSearchFontRatio = 0.035;
  static const double adminAccountsFilterChipGapRatio = 0.02;
  static const double adminAccountsChipHPaddingRatio = 0.035;
  static const double adminAccountsChipVPaddingRatio = 0.018;
  static const double adminAccountsChipFontRatio = 0.032;
  static const double adminAccountsChipSpacingRatio = 0.02;
  static const double adminAccountsCountRowGapRatio = 0.025;
  static const double adminAccountsCountFontRatio = 0.034;
  static const double adminAccountsCreateButtonHPaddingRatio = 0.035;
  static const double adminAccountsCreateButtonVPaddingRatio = 0.018;
  static const double adminAccountsCreateButtonFontRatio = 0.032;
  static const double adminAccountsCreateButtonIconRatio = 0.04;
  static const double adminAccountsListGapRatio = 0.025;
  static const double adminAccountsCardGapRatio = 0.022;
  static const double adminAccountsCardPaddingRatio = 0.04;
  static const double adminAccountsAvatarSizeRatio = 0.13;
  static const double adminAccountsAvatarFontRatio = 0.04;
  static const double adminAccountsNameFontRatio = 0.038;
  static const double adminAccountsRoleFontRatio = 0.03;
  static const double adminAccountsEmailFontRatio = 0.03;
  static const double adminAccountsNameRoleGapRatio = 0.002;
  static const double adminAccountsRoleEmailGapRatio = 0.004;
  static const double adminAccountsAvatarTextGapRatio = 0.03;
  static const double adminAccountsActionIconSizeRatio = 0.05;
  static const double adminAccountsActionIconGapRatio = 0.02;
  static const double adminAccountsEmptyStateIconRatio = 0.12;
  static const double adminAccountsEmptyStateVerticalPadRatio = 0.1;
  static const double adminAccountsLoadingVerticalPadRatio = 0.12;
  static const double adminAccountsErrorVerticalPadRatio = 0.1;
  static const double adminAccountsErrorIconGapRatio = 0.015;
  static const double adminAccountsErrorButtonGapRatio = 0.02;
  static const double adminAccountsBottomGapRatio = 0.03;

  double get adminAccountsPawSize => screenWidth * adminAccountsPawSizeRatio;
  double get adminAccountsHorizontalPadding => screenWidth * adminAccountsHorizontalPaddingRatio;
  double get adminAccountsTopGap => screenHeight * adminAccountsTopGapRatio;
  double get adminAccountsTitleFontSize => screenWidth * adminAccountsTitleFontRatio;
  double get adminAccountsSectionGap => screenHeight * adminAccountsSectionGapRatio;
  double get adminAccountsSearchIcon => screenWidth * adminAccountsSearchIconRatio;
  double get adminAccountsSearchFontSize => screenWidth * adminAccountsSearchFontRatio;
  double get adminAccountsFilterChipGap => screenHeight * adminAccountsFilterChipGapRatio;
  double get adminAccountsChipHPadding => screenWidth * adminAccountsChipHPaddingRatio;
  double get adminAccountsChipVPadding => screenWidth * adminAccountsChipVPaddingRatio;
  double get adminAccountsChipFontSize => screenWidth * adminAccountsChipFontRatio;
  double get adminAccountsChipSpacing => screenWidth * adminAccountsChipSpacingRatio;
  double get adminAccountsCountRowGap => screenHeight * adminAccountsCountRowGapRatio;
  double get adminAccountsCountFontSize => screenWidth * adminAccountsCountFontRatio;
  double get adminAccountsCreateButtonHPadding => screenWidth * adminAccountsCreateButtonHPaddingRatio;
  double get adminAccountsCreateButtonVPadding => screenWidth * adminAccountsCreateButtonVPaddingRatio;
  double get adminAccountsCreateButtonFontSize => screenWidth * adminAccountsCreateButtonFontRatio;
  double get adminAccountsCreateButtonIcon => screenWidth * adminAccountsCreateButtonIconRatio;
  double get adminAccountsListGap => screenHeight * adminAccountsListGapRatio;
  double get adminAccountsCardGap => screenHeight * adminAccountsCardGapRatio;
  double get adminAccountsCardPadding => screenWidth * adminAccountsCardPaddingRatio;
  double get adminAccountsAvatarSize => screenWidth * adminAccountsAvatarSizeRatio;
  double get adminAccountsAvatarFontSize => screenWidth * adminAccountsAvatarFontRatio;
  double get adminAccountsNameFontSize => screenWidth * adminAccountsNameFontRatio;
  double get adminAccountsRoleFontSize => screenWidth * adminAccountsRoleFontRatio;
  double get adminAccountsEmailFontSize => screenWidth * adminAccountsEmailFontRatio;
  double get adminAccountsNameRoleGap => screenHeight * adminAccountsNameRoleGapRatio;
  double get adminAccountsRoleEmailGap => screenHeight * adminAccountsRoleEmailGapRatio;
  double get adminAccountsAvatarTextGap => screenWidth * adminAccountsAvatarTextGapRatio;
  double get adminAccountsActionIcon => screenWidth * adminAccountsActionIconSizeRatio;
  double get adminAccountsActionIconGap => screenWidth * adminAccountsActionIconGapRatio;
  double get adminAccountsEmptyStateIcon => screenWidth * adminAccountsEmptyStateIconRatio;
  double get adminAccountsEmptyStateVerticalPad => screenHeight * adminAccountsEmptyStateVerticalPadRatio;
  double get adminAccountsLoadingVerticalPad => screenHeight * adminAccountsLoadingVerticalPadRatio;
  double get adminAccountsErrorVerticalPad => screenHeight * adminAccountsErrorVerticalPadRatio;
  double get adminAccountsErrorIconGap => screenHeight * adminAccountsErrorIconGapRatio;
  double get adminAccountsErrorButtonGap => screenHeight * adminAccountsErrorButtonGapRatio;
  double get adminAccountsBottomGap => screenHeight * adminAccountsBottomGapRatio;

  // --------------------------------------------------------------------
  // Admin Account Form (views/user/admin/admin_account_form.dart) -
  // création/modification d'un compte.
  // --------------------------------------------------------------------
  static const double adminFormPawSizeRatio = 0.09;
  static const double adminFormHorizontalPaddingRatio = 0.07;
  static const double adminFormTopGapRatio = 0.09;
  static const double adminFormTitleFontRatio = 0.058;
  static const double adminFormSectionGapRatio = 0.03;
  static const double adminFormRoleLabelFontRatio = 0.036;
  static const double adminFormRoleLabelGapRatio = 0.012;
  static const double adminFormRoleChipGapRatio = 0.02;
  static const double adminFormFieldGapRatio = 0.02;
  static const double adminFormButtonTopGapRatio = 0.035;
  static const double adminFormBottomGapRatio = 0.04;

  double get adminFormPawSize => screenWidth * adminFormPawSizeRatio;
  double get adminFormHorizontalPadding => screenWidth * adminFormHorizontalPaddingRatio;
  double get adminFormTopGap => screenHeight * adminFormTopGapRatio;
  double get adminFormTitleFontSize => screenWidth * adminFormTitleFontRatio;
  double get adminFormSectionGap => screenHeight * adminFormSectionGapRatio;
  double get adminFormRoleLabelFontSize => screenWidth * adminFormRoleLabelFontRatio;
  double get adminFormRoleLabelGap => screenHeight * adminFormRoleLabelGapRatio;
  double get adminFormRoleChipGap => screenWidth * adminFormRoleChipGapRatio;
  double get adminFormFieldGap => screenHeight * adminFormFieldGapRatio;
  double get adminFormButtonTopGap => screenHeight * adminFormButtonTopGapRatio;
  double get adminFormBottomGap => screenHeight * adminFormBottomGapRatio;

  // --------------------------------------------------------------------
  // Admin Reviews (views/user/admin/admin_reviews.dart) - "Avis".
  // --------------------------------------------------------------------
  static const double adminReviewsPawSizeRatio = 0.09;
  static const double adminReviewsHorizontalPaddingRatio = 0.06;
  static const double adminReviewsTopGapRatio = 0.09;
  static const double adminReviewsTitleFontRatio = 0.06;
  static const double adminReviewsSectionGapRatio = 0.025;
  static const double adminReviewsSearchIconRatio = 0.05;
  static const double adminReviewsSearchFontRatio = 0.035;
  static const double adminReviewsListGapRatio = 0.025;
  static const double adminReviewsFilterChipGapRatio = 0.02;
  static const double adminReviewsCardGapRatio = 0.022;
  static const double adminReviewsCardPaddingRatio = 0.04;
  static const double adminReviewsAvatarSizeRatio = 0.11;
  static const double adminReviewsAvatarFontRatio = 0.036;
  static const double adminReviewsAvatarTextGapRatio = 0.03;
  static const double adminReviewsNameFontRatio = 0.038;
  static const double adminReviewsRoleFontRatio = 0.028;
  static const double adminReviewsNameRoleGapRatio = 0.002;
  static const double adminReviewsStarIconRatio = 0.045;
  static const double adminReviewsRatingFontRatio = 0.04;
  static const double adminReviewsSatisfiedIconRatio = 0.05;
  static const double adminReviewsReviewTextFontRatio = 0.033;
  static const double adminReviewsReviewTextTopGapRatio = 0.02;
  static const double adminReviewsDividerGapRatio = 0.02;
  static const double adminReviewsBreakdownFontRatio = 0.028;
  static const double adminReviewsBreakdownGapRatio = 0.02;
  static const double adminReviewsFooterFontRatio = 0.028;
  static const double adminReviewsFooterTopGapRatio = 0.015;
  static const double adminReviewsEmptyStateIconRatio = 0.12;
  static const double adminReviewsEmptyStateVerticalPadRatio = 0.1;
  static const double adminReviewsLoadingVerticalPadRatio = 0.12;
  static const double adminReviewsErrorVerticalPadRatio = 0.1;
  static const double adminReviewsErrorIconGapRatio = 0.015;
  static const double adminReviewsErrorButtonGapRatio = 0.02;
  static const double adminReviewsBottomGapRatio = 0.03;

  double get adminReviewsPawSize => screenWidth * adminReviewsPawSizeRatio;
  double get adminReviewsHorizontalPadding => screenWidth * adminReviewsHorizontalPaddingRatio;
  double get adminReviewsTopGap => screenHeight * adminReviewsTopGapRatio;
  double get adminReviewsTitleFontSize => screenWidth * adminReviewsTitleFontRatio;
  double get adminReviewsSectionGap => screenHeight * adminReviewsSectionGapRatio;
  double get adminReviewsSearchIcon => screenWidth * adminReviewsSearchIconRatio;
  double get adminReviewsSearchFontSize => screenWidth * adminReviewsSearchFontRatio;
  double get adminReviewsListGap => screenHeight * adminReviewsListGapRatio;
  double get adminReviewsFilterChipGap => screenHeight * adminReviewsFilterChipGapRatio;
  double get adminReviewsCardGap => screenHeight * adminReviewsCardGapRatio;
  double get adminReviewsCardPadding => screenWidth * adminReviewsCardPaddingRatio;
  double get adminReviewsAvatarSize => screenWidth * adminReviewsAvatarSizeRatio;
  double get adminReviewsAvatarFontSize => screenWidth * adminReviewsAvatarFontRatio;
  double get adminReviewsAvatarTextGap => screenWidth * adminReviewsAvatarTextGapRatio;
  double get adminReviewsNameFontSize => screenWidth * adminReviewsNameFontRatio;
  double get adminReviewsRoleFontSize => screenWidth * adminReviewsRoleFontRatio;
  double get adminReviewsNameRoleGap => screenHeight * adminReviewsNameRoleGapRatio;
  double get adminReviewsStarIcon => screenWidth * adminReviewsStarIconRatio;
  double get adminReviewsRatingFontSize => screenWidth * adminReviewsRatingFontRatio;
  double get adminReviewsSatisfiedIcon => screenWidth * adminReviewsSatisfiedIconRatio;
  double get adminReviewsReviewTextFontSize => screenWidth * adminReviewsReviewTextFontRatio;
  double get adminReviewsReviewTextTopGap => screenHeight * adminReviewsReviewTextTopGapRatio;
  double get adminReviewsDividerGap => screenHeight * adminReviewsDividerGapRatio;
  double get adminReviewsBreakdownFontSize => screenWidth * adminReviewsBreakdownFontRatio;
  double get adminReviewsBreakdownGap => screenWidth * adminReviewsBreakdownGapRatio;
  double get adminReviewsFooterFontSize => screenWidth * adminReviewsFooterFontRatio;
  double get adminReviewsFooterTopGap => screenHeight * adminReviewsFooterTopGapRatio;
  double get adminReviewsEmptyStateIcon => screenWidth * adminReviewsEmptyStateIconRatio;
  double get adminReviewsEmptyStateVerticalPad => screenHeight * adminReviewsEmptyStateVerticalPadRatio;
  double get adminReviewsLoadingVerticalPad => screenHeight * adminReviewsLoadingVerticalPadRatio;
  double get adminReviewsErrorVerticalPad => screenHeight * adminReviewsErrorVerticalPadRatio;
  double get adminReviewsErrorIconGap => screenHeight * adminReviewsErrorIconGapRatio;
  double get adminReviewsErrorButtonGap => screenHeight * adminReviewsErrorButtonGapRatio;
  double get adminReviewsBottomGap => screenHeight * adminReviewsBottomGapRatio;

  // --------------------------------------------------------------------
  // Admin Account Detail (views/user/admin/admin_account_detail.dart) -
  // "Utilisateurs" (fiche détaillée: infos perso + stats 7asb el role).
  // --------------------------------------------------------------------
  static const double adminDetailPawSizeRatio = 0.09;
  static const double adminDetailHorizontalPaddingRatio = 0.06;
  static const double adminDetailTopGapRatio = 0.09;
  static const double adminDetailAvatarSizeRatio = 0.22;
  static const double adminDetailAvatarFontRatio = 0.08;
  static const double adminDetailAvatarNameGapRatio = 0.02;
  static const double adminDetailNameFontRatio = 0.052;
  static const double adminDetailNameBadgeGapRatio = 0.01;
  static const double adminDetailBadgeHPaddingRatio = 0.035;
  static const double adminDetailBadgeVPaddingRatio = 0.014;
  static const double adminDetailBadgeFontRatio = 0.03;
  static const double adminDetailHeaderSectionGapRatio = 0.035;
  static const double adminDetailSectionTitleFontRatio = 0.034;
  static const double adminDetailSectionTitleGapRatio = 0.015;
  static const double adminDetailSectionGapRatio = 0.03;
  static const double adminDetailCardPaddingRatio = 0.04;
  static const double adminDetailRowIconSizeRatio = 0.1;
  static const double adminDetailRowIconInnerRatio = 0.05;
  static const double adminDetailRowTextGapRatio = 0.035;
  static const double adminDetailRowLabelFontRatio = 0.03;
  static const double adminDetailRowValueFontRatio = 0.036;
  static const double adminDetailRowLabelValueGapRatio = 0.003;
  static const double adminDetailRowVerticalPaddingRatio = 0.022;
  static const double adminDetailStatsGridSpacingRatio = 0.04;
  static const double adminDetailStatCardWidthRatio = 0.42;
  static const double adminDetailButtonGapRatio = 0.035;
  static const double adminDetailButtonHeightRatio = 0.065;
  static const double adminDetailLoadingVerticalPadRatio = 0.15;
  static const double adminDetailErrorVerticalPadRatio = 0.12;
  static const double adminDetailErrorIconGapRatio = 0.015;
  static const double adminDetailErrorButtonGapRatio = 0.02;
  static const double adminDetailBottomGapRatio = 0.04;

  double get adminDetailPawSize => screenWidth * adminDetailPawSizeRatio;
  double get adminDetailHorizontalPadding => screenWidth * adminDetailHorizontalPaddingRatio;
  double get adminDetailTopGap => screenHeight * adminDetailTopGapRatio;
  double get adminDetailAvatarSize => screenWidth * adminDetailAvatarSizeRatio;
  double get adminDetailAvatarFontSize => screenWidth * adminDetailAvatarFontRatio;
  double get adminDetailAvatarNameGap => screenHeight * adminDetailAvatarNameGapRatio;
  double get adminDetailNameFontSize => screenWidth * adminDetailNameFontRatio;
  double get adminDetailNameBadgeGap => screenHeight * adminDetailNameBadgeGapRatio;
  double get adminDetailBadgeHPadding => screenWidth * adminDetailBadgeHPaddingRatio;
  double get adminDetailBadgeVPadding => screenWidth * adminDetailBadgeVPaddingRatio;
  double get adminDetailBadgeFontSize => screenWidth * adminDetailBadgeFontRatio;
  double get adminDetailHeaderSectionGap => screenHeight * adminDetailHeaderSectionGapRatio;
  double get adminDetailSectionTitleFontSize => screenWidth * adminDetailSectionTitleFontRatio;
  double get adminDetailSectionTitleGap => screenHeight * adminDetailSectionTitleGapRatio;
  double get adminDetailSectionGap => screenHeight * adminDetailSectionGapRatio;
  double get adminDetailCardPadding => screenWidth * adminDetailCardPaddingRatio;
  double get adminDetailRowIconSize => screenWidth * adminDetailRowIconSizeRatio;
  double get adminDetailRowIconInner => screenWidth * adminDetailRowIconInnerRatio;
  double get adminDetailRowTextGap => screenWidth * adminDetailRowTextGapRatio;
  double get adminDetailRowLabelFontSize => screenWidth * adminDetailRowLabelFontRatio;
  double get adminDetailRowValueFontSize => screenWidth * adminDetailRowValueFontRatio;
  double get adminDetailRowLabelValueGap => screenHeight * adminDetailRowLabelValueGapRatio;
  double get adminDetailRowVerticalPadding => screenHeight * adminDetailRowVerticalPaddingRatio;
  double get adminDetailStatsGridSpacing => screenWidth * adminDetailStatsGridSpacingRatio;
  double get adminDetailStatCardWidth => screenWidth * adminDetailStatCardWidthRatio;
  double get adminDetailButtonGap => screenWidth * adminDetailButtonGapRatio;
  double get adminDetailButtonHeight => screenHeight * adminDetailButtonHeightRatio;
  double get adminDetailLoadingVerticalPad => screenHeight * adminDetailLoadingVerticalPadRatio;
  double get adminDetailErrorVerticalPad => screenHeight * adminDetailErrorVerticalPadRatio;
  double get adminDetailErrorIconGap => screenHeight * adminDetailErrorIconGapRatio;
  double get adminDetailErrorButtonGap => screenHeight * adminDetailErrorButtonGapRatio;
  double get adminDetailBottomGap => screenHeight * adminDetailBottomGapRatio;

  // --------------------------------------------------------------------
  // Admin Validations (views/user/admin/admin_validations.dart) -
  // "Validation" (queue el comptes prêts, checklist kamla).
  // --------------------------------------------------------------------
  static const double adminValidationsPawSizeRatio = 0.09;
  static const double adminValidationsHorizontalPaddingRatio = 0.06;
  static const double adminValidationsTopGapRatio = 0.09;
  static const double adminValidationsTitleFontRatio = 0.06;
  static const double adminValidationsSectionGapRatio = 0.025;
  static const double adminValidationsCardGapRatio = 0.022;
  static const double adminValidationsCardPaddingRatio = 0.04;
  static const double adminValidationsAvatarSizeRatio = 0.13;
  static const double adminValidationsAvatarFontRatio = 0.04;
  static const double adminValidationsAvatarTextGapRatio = 0.03;
  static const double adminValidationsNameFontRatio = 0.038;
  static const double adminValidationsRoleFontRatio = 0.03;
  static const double adminValidationsNameRoleGapRatio = 0.002;
  static const double adminValidationsChecklistTopGapRatio = 0.02;
  static const double adminValidationsChecklistItemFontRatio = 0.028;
  static const double adminValidationsChecklistItemGapRatio = 0.015;
  static const double adminValidationsButtonTopGapRatio = 0.02;
  static const double adminValidationsButtonHeightRatio = 0.055;
  static const double adminValidationsLoadingVerticalPadRatio = 0.12;
  static const double adminValidationsErrorVerticalPadRatio = 0.1;
  static const double adminValidationsErrorIconGapRatio = 0.015;
  static const double adminValidationsErrorButtonGapRatio = 0.02;
  static const double adminValidationsEmptyStateIconRatio = 0.12;
  static const double adminValidationsEmptyStateVerticalPadRatio = 0.15;
  static const double adminValidationsBottomGapRatio = 0.03;

  double get adminValidationsPawSize => screenWidth * adminValidationsPawSizeRatio;
  double get adminValidationsHorizontalPadding => screenWidth * adminValidationsHorizontalPaddingRatio;
  double get adminValidationsTopGap => screenHeight * adminValidationsTopGapRatio;
  double get adminValidationsTitleFontSize => screenWidth * adminValidationsTitleFontRatio;
  double get adminValidationsSectionGap => screenHeight * adminValidationsSectionGapRatio;
  double get adminValidationsCardGap => screenHeight * adminValidationsCardGapRatio;
  double get adminValidationsCardPadding => screenWidth * adminValidationsCardPaddingRatio;
  double get adminValidationsAvatarSize => screenWidth * adminValidationsAvatarSizeRatio;
  double get adminValidationsAvatarFontSize => screenWidth * adminValidationsAvatarFontRatio;
  double get adminValidationsAvatarTextGap => screenWidth * adminValidationsAvatarTextGapRatio;
  double get adminValidationsNameFontSize => screenWidth * adminValidationsNameFontRatio;
  double get adminValidationsRoleFontSize => screenWidth * adminValidationsRoleFontRatio;
  double get adminValidationsNameRoleGap => screenHeight * adminValidationsNameRoleGapRatio;
  double get adminValidationsChecklistTopGap => screenHeight * adminValidationsChecklistTopGapRatio;
  double get adminValidationsChecklistItemFontSize => screenWidth * adminValidationsChecklistItemFontRatio;
  double get adminValidationsChecklistItemGap => screenWidth * adminValidationsChecklistItemGapRatio;
  double get adminValidationsButtonTopGap => screenHeight * adminValidationsButtonTopGapRatio;
  double get adminValidationsButtonHeight => screenHeight * adminValidationsButtonHeightRatio;
  double get adminValidationsLoadingVerticalPad => screenHeight * adminValidationsLoadingVerticalPadRatio;
  double get adminValidationsErrorVerticalPad => screenHeight * adminValidationsErrorVerticalPadRatio;
  double get adminValidationsErrorIconGap => screenHeight * adminValidationsErrorIconGapRatio;
  double get adminValidationsErrorButtonGap => screenHeight * adminValidationsErrorButtonGapRatio;
  double get adminValidationsEmptyStateIcon => screenWidth * adminValidationsEmptyStateIconRatio;
  double get adminValidationsEmptyStateVerticalPad => screenHeight * adminValidationsEmptyStateVerticalPadRatio;
  double get adminValidationsBottomGap => screenHeight * adminValidationsBottomGapRatio;

  // --------------------------------------------------------------------
  // Verification Status (views/user/verification_status_screen.dart) -
  // "Vérification" (sidebar owner/sitter - checklist + progress).
  // --------------------------------------------------------------------
  static const double verificationPawSizeRatio = 0.09;
  static const double verificationHorizontalPaddingRatio = 0.06;
  static const double verificationTopGapRatio = 0.09;
  static const double verificationTitleFontRatio = 0.06;
  static const double verificationSectionGapRatio = 0.03;
  static const double verificationBannerPaddingRatio = 0.045;
  static const double verificationBannerIconRatio = 0.09;
  static const double verificationBannerIconGapRatio = 0.02;
  static const double verificationBannerFontRatio = 0.036;
  static const double verificationRowPaddingRatio = 0.032;
  static const double verificationRowIconRatio = 0.06;
  static const double verificationRowTextGapRatio = 0.035;
  static const double verificationRowLabelFontRatio = 0.036;
  static const double verificationRowProgressFontRatio = 0.03;
  static const double verificationRowLabelProgressGapRatio = 0.003;
  static const double verificationLoadingVerticalPadRatio = 0.15;
  static const double verificationErrorVerticalPadRatio = 0.12;
  static const double verificationErrorIconGapRatio = 0.015;
  static const double verificationErrorButtonGapRatio = 0.02;
  static const double verificationBottomGapRatio = 0.04;

  double get verificationPawSize => screenWidth * verificationPawSizeRatio;
  double get verificationHorizontalPadding => screenWidth * verificationHorizontalPaddingRatio;
  double get verificationTopGap => screenHeight * verificationTopGapRatio;
  double get verificationTitleFontSize => screenWidth * verificationTitleFontRatio;
  double get verificationSectionGap => screenHeight * verificationSectionGapRatio;
  double get verificationBannerPadding => screenWidth * verificationBannerPaddingRatio;
  double get verificationBannerIcon => screenWidth * verificationBannerIconRatio;
  double get verificationBannerIconGap => screenHeight * verificationBannerIconGapRatio;
  double get verificationBannerFontSize => screenWidth * verificationBannerFontRatio;
  double get verificationRowPadding => screenWidth * verificationRowPaddingRatio;
  double get verificationRowIcon => screenWidth * verificationRowIconRatio;
  double get verificationRowTextGap => screenWidth * verificationRowTextGapRatio;
  double get verificationRowLabelFontSize => screenWidth * verificationRowLabelFontRatio;
  double get verificationRowProgressFontSize => screenWidth * verificationRowProgressFontRatio;
  double get verificationRowLabelProgressGap => screenHeight * verificationRowLabelProgressGapRatio;
  double get verificationLoadingVerticalPad => screenHeight * verificationLoadingVerticalPadRatio;
  double get verificationErrorVerticalPad => screenHeight * verificationErrorVerticalPadRatio;
  double get verificationErrorIconGap => screenHeight * verificationErrorIconGapRatio;
  double get verificationErrorButtonGap => screenHeight * verificationErrorButtonGapRatio;
  double get verificationBottomGap => screenHeight * verificationBottomGapRatio;

  // --------------------------------------------------------------------
  // Admin Sidebar (widgets/drawers/sidebar_admin.dart) - redesign
  // "moderne" (kifma tlab: "design mteeha mch ajebnii, badlholi b whd
  // ekher ykoun moderne, les couleurs bhyin, yrayhou el ein f mode
  // sombre wla light").
  // --------------------------------------------------------------------
  static const double adminSidebarHeaderPaddingRatio = 0.055;
  static const double adminSidebarAvatarSizeRatio = 0.22;
  static const double adminSidebarAvatarIconRatio = 0.11;
  static const double adminSidebarAvatarNameGapRatio = 0.018;
  static const double adminSidebarNameFontRatio = 0.05;
  static const double adminSidebarNameBadgeGapRatio = 0.01;
  static const double adminSidebarBadgeHPaddingRatio = 0.03;
  static const double adminSidebarBadgeVPaddingRatio = 0.012;
  static const double adminSidebarBadgeFontRatio = 0.03;
  static const double adminSidebarPawSizeRatio = 0.09;
  static const double adminSidebarListTopGapRatio = 0.02;
  static const double adminSidebarListHorizontalPaddingRatio = 0.05;
  static const double adminSidebarItemPaddingHRatio = 0.035;
  static const double adminSidebarItemPaddingVRatio = 0.028;
  static const double adminSidebarItemIconCircleRatio = 0.1;
  static const double adminSidebarItemIconRatio = 0.05;
  static const double adminSidebarItemTextGapRatio = 0.032;
  static const double adminSidebarItemFontRatio = 0.037;
  static const double adminSidebarItemChevronRatio = 0.045;
  static const double adminSidebarItemGapRatio = 0.016;
  static const double adminSidebarLogoutGapRatio = 0.03;

  double get adminSidebarHeaderPadding => screenWidth * adminSidebarHeaderPaddingRatio;
  double get adminSidebarAvatarSize => screenWidth * adminSidebarAvatarSizeRatio;
  double get adminSidebarAvatarIcon => screenWidth * adminSidebarAvatarIconRatio;
  double get adminSidebarAvatarNameGap => screenHeight * adminSidebarAvatarNameGapRatio;
  double get adminSidebarNameFontSize => screenWidth * adminSidebarNameFontRatio;
  double get adminSidebarNameBadgeGap => screenHeight * adminSidebarNameBadgeGapRatio;
  double get adminSidebarBadgeHPadding => screenWidth * adminSidebarBadgeHPaddingRatio;
  double get adminSidebarBadgeVPadding => screenWidth * adminSidebarBadgeVPaddingRatio;
  double get adminSidebarBadgeFontSize => screenWidth * adminSidebarBadgeFontRatio;
  double get adminSidebarPawSize => screenWidth * adminSidebarPawSizeRatio;
  double get adminSidebarListTopGap => screenHeight * adminSidebarListTopGapRatio;
  double get adminSidebarListHorizontalPadding => screenWidth * adminSidebarListHorizontalPaddingRatio;
  double get adminSidebarItemPaddingH => screenWidth * adminSidebarItemPaddingHRatio;
  double get adminSidebarItemPaddingV => screenWidth * adminSidebarItemPaddingVRatio;
  double get adminSidebarItemIconCircle => screenWidth * adminSidebarItemIconCircleRatio;
  double get adminSidebarItemIcon => screenWidth * adminSidebarItemIconRatio;
  double get adminSidebarItemTextGap => screenWidth * adminSidebarItemTextGapRatio;
  double get adminSidebarItemFontSize => screenWidth * adminSidebarItemFontRatio;
  double get adminSidebarItemChevron => screenWidth * adminSidebarItemChevronRatio;
  double get adminSidebarItemGap => screenHeight * adminSidebarItemGapRatio;
  double get adminSidebarLogoutGap => screenHeight * adminSidebarLogoutGapRatio;

  // --------------------------------------------------------------------
  // Sidebar Pill Item (widgets/drawers/sidebar_pill_item.dart) - widget
  // PARTAGÉ (kifma tlab: "nhb hatta el sitter wel owner") - nafs
  // composant testa3mlou el 3 sidebars el kol (admin/owner/sitter),
  // bch el design yeb9a IDENTIQUE bin el 3.
  // --------------------------------------------------------------------
  static const double sidebarPillPaddingHRatio = 0.035;
  static const double sidebarPillPaddingVRatio = 0.028;
  static const double sidebarPillIconCircleRatio = 0.1;
  static const double sidebarPillIconRatio = 0.05;
  static const double sidebarPillTextGapRatio = 0.032;
  static const double sidebarPillFontRatio = 0.037;
  static const double sidebarPillChevronRatio = 0.045;
  static const double sidebarPillGapRatio = 0.016;
  static const double sidebarPillBadgeMinWidthRatio = 0.055;
  static const double sidebarPillBadgePaddingHRatio = 0.018;
  static const double sidebarPillBadgeFontRatio = 0.026;
  static const double sidebarPillBadgeGapRatio = 0.02;
  static const double sidebarVerifiedBadgeRatio = 0.055;

  double get sidebarPillPaddingH => screenWidth * sidebarPillPaddingHRatio;
  double get sidebarPillPaddingV => screenWidth * sidebarPillPaddingVRatio;
  double get sidebarPillIconCircle => screenWidth * sidebarPillIconCircleRatio;
  double get sidebarPillIcon => screenWidth * sidebarPillIconRatio;
  double get sidebarPillTextGap => screenWidth * sidebarPillTextGapRatio;
  double get sidebarPillFontSize => screenWidth * sidebarPillFontRatio;
  double get sidebarPillChevron => screenWidth * sidebarPillChevronRatio;
  double get sidebarPillGap => screenHeight * sidebarPillGapRatio;
  double get sidebarPillBadgeMinWidth => screenWidth * sidebarPillBadgeMinWidthRatio;
  double get sidebarPillBadgePaddingH => screenWidth * sidebarPillBadgePaddingHRatio;
  double get sidebarPillBadgeFontSize => screenWidth * sidebarPillBadgeFontRatio;
  double get sidebarPillBadgeGap => screenWidth * sidebarPillBadgeGapRatio;
  double get sidebarVerifiedBadgeSize => screenWidth * sidebarVerifiedBadgeRatio;

  // --------------------------------------------------------------------
  // Messages List (views/user/messages_list_screen.dart) - messagerie
  // "kima Messenger" (kifma tlab): titre + barre de recherche + bulles
  // (stories) + liste conversations.
  // --------------------------------------------------------------------
  static const double messagesTopGapRatio = 0.02;
  static const double messagesHorizontalPaddingRatio = 0.05;
  static const double messagesTitleFontRatio = 0.06;
  static const double messagesSectionGapRatio = 0.022;
  static const double messagesSearchIconRatio = 0.05;
  static const double messagesSearchFontRatio = 0.035;
  static const double messagesSearchPaddingHRatio = 0.04;
  static const double messagesSearchPaddingVRatio = 0.03;
  static const double messagesBubbleSizeRatio = 0.16;
  static const double messagesBubbleGapRatio = 0.03;
  static const double messagesBubbleNameFontRatio = 0.026;
  static const double messagesBubbleNameGapRatio = 0.008;
  static const double messagesBubbleNameWidthRatio = 0.18;
  static const double messagesConvAvatarSizeRatio = 0.14;
  static const double messagesConvNameFontRatio = 0.04;
  static const double messagesConvPreviewFontRatio = 0.033;
  static const double messagesConvTimeFontRatio = 0.028;
  static const double messagesConvPaddingVRatio = 0.018;
  static const double messagesConvGapRatio = 0.006;
  static const double messagesConvRowGapRatio = 0.006;
  static const double messagesEmptyStateIconRatio = 0.14;
  static const double messagesEmptyStateVerticalPadRatio = 0.1;
  static const double messagesUnreadBadgeMinWidthRatio = 0.05;
  static const double messagesUnreadBadgeFontRatio = 0.026;

  double get messagesTopGap => screenHeight * messagesTopGapRatio;
  double get messagesHorizontalPadding => screenWidth * messagesHorizontalPaddingRatio;
  double get messagesTitleFontSize => screenWidth * messagesTitleFontRatio;
  double get messagesSectionGap => screenHeight * messagesSectionGapRatio;
  double get messagesSearchIcon => screenWidth * messagesSearchIconRatio;
  double get messagesSearchFontSize => screenWidth * messagesSearchFontRatio;
  double get messagesSearchPaddingH => screenWidth * messagesSearchPaddingHRatio;
  double get messagesSearchPaddingV => screenWidth * messagesSearchPaddingVRatio;
  double get messagesBubbleSize => screenWidth * messagesBubbleSizeRatio;
  double get messagesBubbleGap => screenWidth * messagesBubbleGapRatio;
  double get messagesBubbleNameFontSize => screenWidth * messagesBubbleNameFontRatio;
  double get messagesBubbleNameGap => screenHeight * messagesBubbleNameGapRatio;
  double get messagesBubbleNameWidth => screenWidth * messagesBubbleNameWidthRatio;
  double get messagesConvAvatarSize => screenWidth * messagesConvAvatarSizeRatio;
  double get messagesConvNameFontSize => screenWidth * messagesConvNameFontRatio;
  double get messagesConvPreviewFontSize => screenWidth * messagesConvPreviewFontRatio;
  double get messagesConvTimeFontSize => screenWidth * messagesConvTimeFontRatio;
  double get messagesConvPaddingV => screenHeight * messagesConvPaddingVRatio;
  double get messagesConvGap => screenHeight * messagesConvGapRatio;
  double get messagesConvRowGap => screenWidth * messagesConvRowGapRatio;
  double get messagesEmptyStateIcon => screenWidth * messagesEmptyStateIconRatio;
  double get messagesEmptyStateVerticalPad => screenHeight * messagesEmptyStateVerticalPadRatio;
  double get messagesUnreadBadgeMinWidth => screenWidth * messagesUnreadBadgeMinWidthRatio;
  double get messagesUnreadBadgeFontSize => screenWidth * messagesUnreadBadgeFontRatio;

  // --------------------------------------------------------------------
  // Chat (views/user/chat_screen.dart) - conversation individuelle:
  // bulles de message (texte/photo) + barre input + camera (gal/appareil).
  // --------------------------------------------------------------------
  static const double chatHeaderAvatarSizeRatio = 0.11;
  static const double chatHeaderNameFontRatio = 0.042;
  static const double chatHeaderSubFontRatio = 0.03;
  static const double chatHeaderPaddingHRatio = 0.04;
  static const double chatHeaderPaddingVRatio = 0.022;
  static const double chatListPaddingHRatio = 0.04;
  static const double chatListPaddingVRatio = 0.02;
  static const double chatBubbleMaxWidthRatio = 0.74;
  static const double chatBubblePaddingHRatio = 0.04;
  static const double chatBubblePaddingVRatio = 0.024;
  static const double chatBubbleFontRatio = 0.036;
  static const double chatBubbleTimeFontRatio = 0.025;
  static const double chatBubbleGapRatio = 0.01;
  static const double chatBubbleImageMaxWidthRatio = 0.55;
  static const double chatBubbleImageRadiusRatio = 0.045;
  static const double chatDateSeparatorFontRatio = 0.03;
  static const double chatDateSeparatorGapRatio = 0.02;
  static const double chatInputBarPaddingHRatio = 0.03;
  static const double chatInputBarPaddingVRatio = 0.018;
  static const double chatInputFontRatio = 0.036;
  static const double chatInputIconRatio = 0.065;
  static const double chatSendButtonSizeRatio = 0.105;
  static const double chatEmptyStateIconRatio = 0.16;
  static const double chatEmptyStateVerticalPadRatio = 0.16;

  double get chatHeaderAvatarSize => screenWidth * chatHeaderAvatarSizeRatio;
  double get chatHeaderNameFontSize => screenWidth * chatHeaderNameFontRatio;
  double get chatHeaderSubFontSize => screenWidth * chatHeaderSubFontRatio;
  double get chatHeaderPaddingH => screenWidth * chatHeaderPaddingHRatio;
  double get chatHeaderPaddingV => screenWidth * chatHeaderPaddingVRatio;
  double get chatListPaddingH => screenWidth * chatListPaddingHRatio;
  double get chatListPaddingV => screenHeight * chatListPaddingVRatio;
  double get chatBubbleMaxWidth => screenWidth * chatBubbleMaxWidthRatio;
  double get chatBubblePaddingH => screenWidth * chatBubblePaddingHRatio;
  double get chatBubblePaddingV => screenWidth * chatBubblePaddingVRatio;
  double get chatBubbleFontSize => screenWidth * chatBubbleFontRatio;
  double get chatBubbleTimeFontSize => screenWidth * chatBubbleTimeFontRatio;
  double get chatBubbleGap => screenHeight * chatBubbleGapRatio;
  double get chatBubbleImageMaxWidth => screenWidth * chatBubbleImageMaxWidthRatio;
  double get chatBubbleImageRadius => screenWidth * chatBubbleImageRadiusRatio;
  double get chatDateSeparatorFontSize => screenWidth * chatDateSeparatorFontRatio;
  double get chatDateSeparatorGap => screenHeight * chatDateSeparatorGapRatio;
  double get chatInputBarPaddingH => screenWidth * chatInputBarPaddingHRatio;
  double get chatInputBarPaddingV => screenWidth * chatInputBarPaddingVRatio;
  double get chatInputFontSize => screenWidth * chatInputFontRatio;
  double get chatInputIcon => screenWidth * chatInputIconRatio;
  double get chatSendButtonSize => screenWidth * chatSendButtonSizeRatio;
  double get chatEmptyStateIcon => screenWidth * chatEmptyStateIconRatio;
  double get chatEmptyStateVerticalPad => screenHeight * chatEmptyStateVerticalPadRatio;

  // --------------------------------------------------------------------
  // About Us (views/user/about_us_screen.dart) - kifma tlab: "interface
  // about us mahleha w fiha klem touchant".
  // --------------------------------------------------------------------
  static const double aboutUsTopGapRatio = 0.015;
  static const double aboutUsHorizontalPaddingRatio = 0.06;
  static const double aboutUsTitleFontRatio = 0.062;
  static const double aboutUsHeroRadiusRatio = 0.05;
  static const double aboutUsSectionGapRatio = 0.03;
  static const double aboutUsIntroFontRatio = 0.038;
  static const double aboutUsCardPaddingRatio = 0.045;
  static const double aboutUsCardGapRatio = 0.03;
  static const double aboutUsCardIconSizeRatio = 0.09;
  static const double aboutUsCardIconGapRatio = 0.035;
  static const double aboutUsCardTitleFontRatio = 0.042;
  static const double aboutUsCardBodyFontRatio = 0.034;
  static const double aboutUsClosingFontRatio = 0.04;

  double get aboutUsTopGap => screenHeight * aboutUsTopGapRatio;
  double get aboutUsHorizontalPadding => screenWidth * aboutUsHorizontalPaddingRatio;
  double get aboutUsTitleFontSize => screenWidth * aboutUsTitleFontRatio;
  double get aboutUsHeroRadius => screenWidth * aboutUsHeroRadiusRatio;
  double get aboutUsSectionGap => screenHeight * aboutUsSectionGapRatio;
  double get aboutUsIntroFontSize => screenWidth * aboutUsIntroFontRatio;
  double get aboutUsCardPadding => screenWidth * aboutUsCardPaddingRatio;
  double get aboutUsCardGap => screenHeight * aboutUsCardGapRatio;
  double get aboutUsCardIconSize => screenWidth * aboutUsCardIconSizeRatio;
  double get aboutUsCardIconGap => screenWidth * aboutUsCardIconGapRatio;
  double get aboutUsCardTitleFontSize => screenWidth * aboutUsCardTitleFontRatio;
  double get aboutUsCardBodyFontSize => screenWidth * aboutUsCardBodyFontRatio;
  double get aboutUsClosingFontSize => screenWidth * aboutUsClosingFontRatio;
}