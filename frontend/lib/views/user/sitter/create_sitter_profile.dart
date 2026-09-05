import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/button.dart';
import '../../../widgets/paw_widget.dart';
import '../../../widgets/service_category_selector.dart';
import '../../../controllers/create_sitter_profile_controller.dart';
import 'create_sitter_profile_2.dart';
import '../../../widgets/message_dialog.dart';

// ============================================================================
// CreateSitterProfileScreen ("Tell us about your service")
// ============================================================================
// 🔴 FIX (kifma tlab: "les services nhbhom fi des titre w ki tenzel
// alihom yethallou hedhom... ken yhb yzid service ekher") - kanet liste
// flat (6 services, checkbox 3adiya) - tawa ServiceCategorySelector
// (widgets/service_category_selector.dart): categories accordion
// (Toilettage/Garde d'animaux/Promenade/Dressage) + "Autre" (custom,
// el sitter yzid service b ydik lowkan mafamech wa7ed ye9abbel).
// ============================================================================
class CreateSitterProfileScreen extends StatefulWidget {
  final String sitterName;
  final String sitterCity;
  final Uint8List? sitterPhotoBytes;

  const CreateSitterProfileScreen({
    super.key,
    required this.sitterName,
    required this.sitterCity,
    this.sitterPhotoBytes,
  });

  @override
  State<CreateSitterProfileScreen> createState() => _CreateSitterProfileScreenState();
}

class _CreateSitterProfileScreenState extends State<CreateSitterProfileScreen> {
  final GlobalKey<ServiceCategorySelectorState> _serviceSelectorKey = GlobalKey();
  final CreateSitterProfileController _controller = CreateSitterProfileController();
  bool _isSubmitting = false;

  Future<void> _onNextPressed() async {
    if (_isSubmitting) return;

    final selectorState = _serviceSelectorKey.currentState!;
    selectorState.markTriedSubmit();

    final String? errorKey = selectorState.validate();
    if (errorKey != null) {
      showMessageDialog(context, errorKey.tr());
      return;
    }

    final List<Map<String, dynamic>> servicesPayload = selectorState.getPayload();

    setState(() => _isSubmitting = true);

    final bool success = await _controller.submitServices(services: servicesPayload);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      showMessageDialog(context, 'login_generic_error'.tr());
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateSitterProfile2Screen(
          sitterName: widget.sitterName,
          sitterCity: widget.sitterCity,
          sitterPhotoBytes: widget.sitterPhotoBytes,
        ),
      ),
    );
  }

  // --------------------------------------------------------------------
  // Pill teal (header tel card) - "Services Offered"
  // --------------------------------------------------------------------
  Widget _sectionHeaderPill(String text, AppSizes sizes) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: sizes.screenWidth * 0.032),
      decoration: BoxDecoration(
        color: AppColors.vertpetsy,
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: sizes.screenWidth * 0.036,
        ),
      ),
    );
  }

  // Card b'border rose (kifha kif el mockup - mch fill teal)
  Widget _sectionCard({required Widget child, required AppSizes sizes}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sizes.screenWidth * 0.045),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.pinkpetsy.withOpacity(0.6), width: 1.6),
      ),
      child: child,
    );
  }

  // 🔵 Nafs el "pill overlapping card" pattern mawjoud fel écran
  // "Pet behavior and Care" (create_pet_profile_2.dart) - pillRise
  // NISBA mel pill nafsou (mch ra9m mnafsel), bch tab9a motawazna fi
  // ay hjm écran.
  Widget _pillCard({required String pillText, required Widget content, required AppSizes sizes}) {
    final double screenWidth = sizes.screenWidth;
    final double pillFontSize = screenWidth * 0.036;
    final double pillVerticalPadding = screenWidth * 0.032;
    final double pillHeight = (pillVerticalPadding * 2) + (pillFontSize * 1.3);
    final double pillRise = pillHeight * 0.35;
    final double overlapIntoCard = pillHeight - pillRise;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(top: pillRise),
          child: _sectionCard(
            sizes: sizes,
            child: Padding(
              padding: EdgeInsets.only(top: overlapIntoCard + sizes.screenHeight * 0.008),
              child: content,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: screenWidth * 0.05,
          right: screenWidth * 0.05,
          child: _sectionHeaderPill(pillText, sizes),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            buildPetPaw(context: context, size: sizes.sitterServicesPawSize1, topPercent: 0.025, leftPercent: 0.85, color: AppColors.pinkpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: sizes.sitterServicesPawSize2, topPercent: 0.85, leftPercent: 0.06, color: AppColors.vertpetsy.withOpacity(0.5)),

            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: sizes.sitterServicesHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: sizes.sitterServicesTopGap),

                  Text(
                    'sitter_service_screen_title'.tr(),
                    style: TextStyle(
                      fontSize: sizes.sitterServicesTitleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.vertpetsy,
                    ),
                  ),

                  SizedBox(height: sizes.sitterServicesTitleCardGap),

                  // ------------------------------------------------------
                  // Box WA7DA bark: "Services Offered" (categories accordion
                  // + "Autre" - chraht fel ServiceCategorySelector)
                  // ------------------------------------------------------
                  _pillCard(
                    sizes: sizes,
                    pillText: 'sitter_services_offered_label'.tr(),
                    content: ServiceCategorySelector(key: _serviceSelectorKey),
                  ),

                  SizedBox(height: sizes.sitterServicesRowGap * 2),

                  CustomButton(
                    text: _isSubmitting ? 'loading_label'.tr() : 'next_button'.tr(),
                    color: AppColors.pinkpetsy,
                    widthFactor: 0.90,
                    heightFactor: 0.07,
                    fontFactor: 0.40,
                    enabled: !_isSubmitting,
                    onPressed: _onNextPressed,
                  ),

                  SizedBox(height: sizes.sitterServicesBottomGap),
                ],
              ),
            ),

            // 🔙 Bouton retour - LAKHER fel Stack DIMA (mch 9bal el
            // ScrollView) - chrahtha b'proof fi see_all_pets.dart: Stack
            // ye3mel hit-test b'ordre 3aks, el ScrollView (7ata fi blasa
            // fadhya bصريا) yakhod el lamsa 9bal ma touselou.
            const CustomBackButton(),
          ],
        ),
      ),
    );
  }
}