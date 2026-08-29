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
}