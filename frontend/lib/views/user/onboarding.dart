import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/button.dart';
import '../../widgets/paw_widget.dart';
import '../../widgets/back_button.dart';
import 'welcome.dart';

class _OnboardingPage {
  final String imagePath; // Path tel image fel assets (تحطها إنت)
  final String titleKey; // Key tel traduction (fel .json)
  final String subtitleKey; // Key tel traduction (fel .json)

  const _OnboardingPage({
    required this.imagePath,
    required this.titleKey,
    required this.subtitleKey,
  });
}

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      imagePath: 'assets/images/onboarding_1_trust.png',
      titleKey: 'onboarding_title_1',
      subtitleKey: 'onboarding_subtitle_1',
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding_2_booking.png',
      titleKey: 'onboarding_title_2',
      subtitleKey: 'onboarding_subtitle_2',
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding_3_chat.png',
      titleKey: 'onboarding_title_3',
      subtitleKey: 'onboarding_subtitle_3',
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding_4_schedule.png',
      titleKey: 'onboarding_title_4',
      subtitleKey: 'onboarding_subtitle_4',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    final bool isLastPage = _currentPage == _pages.length - 1;

    if (!isLastPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      // 🔵 Wsalna lel akher page -> nemchiw lel écran "Welcome to PETSY"
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WelcomeView()),
      );
    }
  }

  void _skip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // --------------------------------------------------------------------
  // 🔙 Back "dhki": lowkan mch fel loula page, yerja3 page wa7da (mch
  // el LanguageView). Lowkan fel loula page (index 0), yerja3 el route
  // (pop) lel LanguageView.
  // --------------------------------------------------------------------
  void _onBackPressed() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final bool isLastPage = _currentPage == _pages.length - 1;

    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            buildPetPaw(
              context: context,
              size: sizes.onboardingPawSize1,
              topPercent: 0.025,
              leftPercent: 0.1,
              color: AppColors.vertpetsy.withOpacity(0.5),
            ),
            buildPetPaw(
              context: context,
              size: sizes.onboardingPawSize2,
              topPercent: 0.027,
              leftPercent: 0.86,
              color: AppColors.pinkpetsy.withOpacity(0.4),
            ),

            // 🔙 Back button (dhki: page saba9a, wala LanguageView lowkan
            // fel loula page)
            CustomBackButton(onPressed: _onBackPressed),

            Column(
              children: [
                SizedBox(
                  height: sizes.onboardingSkipAreaHeight,
                  child: Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: sizes.onboardingSkipPaddingH),
                      child: isLastPage
                          ? null
                          : TextButton(
                              onPressed: _skip,
                              child: Text(
                                'skip_button'.tr(),
                                style: TextStyle(
                                  fontSize: sizes.onboardingSkipFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: mutedTextColor,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: sizes.onboardingPagePaddingH),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              page.imagePath,
                              width: sizes.onboardingImageSize,
                              height: sizes.onboardingImageSize,
                              fit: BoxFit.contain,
                            ),
                            Text(
                              page.titleKey.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: sizes.onboardingTitleFontSize,
                                fontWeight: FontWeight.bold,
                                color: AppColors.pinkpetsy,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: sizes.onboardingTitleSubtitleGap),
                            Text(
                              page.subtitleKey.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: sizes.onboardingSubtitleFontSize,
                                color: mutedTextColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    final bool isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.symmetric(horizontal: sizes.onboardingDotMarginH),
                      width: isActive ? sizes.onboardingDotActiveWidth : sizes.onboardingDotInactiveWidth,
                      height: sizes.onboardingDotHeight,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.pinkpetsy : AppColors.vertpetsy.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(sizes.onboardingDotRadius),
                      ),
                    );
                  }),
                ),

                SizedBox(height: sizes.onboardingDotsButtonGap),

                CustomButton(
                  text: isLastPage ? 'get_started_button'.tr() : 'next_button'.tr(),
                  color: AppColors.vertpetsy,
                  widthFactor: 0.84,
                  heightFactor: 0.07,
                  fontFactor: 0.40,
                  onPressed: _goToNextPage,
                ),

                SizedBox(height: sizes.onboardingBottomGap),
              ],
            ),
          ],
        ),
      ),
    );
  }
}