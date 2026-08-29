import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/button.dart';
import '../../../controllers/create_sitter_profile_2_controller.dart';
import 'sitter_availability_question.dart';

// 🔵 el 3 khiyarat "win ta3mor" - single select (wa7ed bark mel 3).
enum ResidenceType { apartment, house, countryHouse }

// ============================================================================
// CreateSitterProfile2Screen ("Home & Transport Details")
// ============================================================================
// 🔵 3 boxes (mch 4 kifma fel mockup el asli): el box el ra3ba
// ("Do you have a pet in your house?") w el box el 5amsa ("what type
// of pet") TAWA box WA7DA - ki tdouss "Yes", el Dog/Cat yban DIRECT
// ta7t ("Yes"/"No") fel nefs el box (AnimatedSize), bdal box mnfassla
// dima bayna (nafs mant9 create_sitter_profile.dart: service -> price).
// ============================================================================
class CreateSitterProfile2Screen extends StatefulWidget {
  final String sitterName;
  final String sitterCity;
  final Uint8List? sitterPhotoBytes;
  // 🔵 el data mel écran el 9bali (create_sitter_profile.dart) - nab3thouha
  // TODO ki ykoun el appel API el a5ir (POST el profile tel sitter kaملou).
  final Map<String, bool> selectedServices;
  final Map<String, String> servicesPrices;
  final Map<String, String?> servicesPetTypes;

  const CreateSitterProfile2Screen({
    super.key,
    required this.sitterName,
    required this.sitterCity,
    this.sitterPhotoBytes,
    this.selectedServices = const {},
    this.servicesPrices = const {},
    this.servicesPetTypes = const {},
  });

  @override
  State<CreateSitterProfile2Screen> createState() => _CreateSitterProfile2ScreenState();
}

class _CreateSitterProfile2ScreenState extends State<CreateSitterProfile2Screen> {
  ResidenceType? _residence;
  bool? _hasTransportation; // true=Yes, false=No, null=mazel ma jawebch
  bool? _hasPet; // true=Yes, false=No, null=mazel ma jawebch
  final Set<String> _ownedPetTypes = {}; // 'dog' / 'cat' - multi (ynajjam ykoun el zouz)

  bool _triedSubmit = false;
  final CreateSitterProfile2Controller _controller = CreateSitterProfile2Controller();
  bool _isSubmitting = false;

  Future<void> _onDonePressed() async {
    if (_isSubmitting) return;

    setState(() => _triedSubmit = true);

    if (_residence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sitter_residence_required_error'.tr())),
      );
      return;
    }
    if (_hasTransportation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sitter_transportation_required_error'.tr())),
      );
      return;
    }
    if (_hasPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sitter_has_pet_required_error'.tr())),
      );
      return;
    }
    if (_hasPet == true && _ownedPetTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sitter_own_pet_type_required_error'.tr())),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // 🔴 FIX: kanet ghir TODO/debugPrint - tاوة PATCH 7a9i9i
    // (controllers/create_sitter_profile_2_controller.dart).
    final bool success = await _controller.submitHomeAndTransport(
      residenceType: _residence!.name,
      hasTransportation: _hasTransportation!,
      hasPetAtHome: _hasPet!,
      ownedPetTypes: _ownedPetTypes.toList(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('login_generic_error'.tr())),
      );
      return;
    }

    if (!mounted) return;
    // 🔵 ZID (kifma tlab): étape jdida ("3andek ayemet ma thebbech
    // tekhdem fihom?") 9bal ma nemchiw l'home - mch direct SitterProfileScreen.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SitterAvailabilityQuestionScreen(
          sitterName: widget.sitterName,
          sitterCity: widget.sitterCity,
          sitterPhotoBytes: widget.sitterPhotoBytes,
        ),
      ),
      (route) => false, // ynahi el stack kaملha (signup flow) - nafs mant9 el owner
    );
  }

  // --------------------------------------------------------------------
  // Box b'border teal + fill rose pale (kifha kif el mockup el jdid -
  // MA9LOUB 3an create_sitter_profile.dart: houni el border teal, mch
  // rose, w el titre TEXT 3adi FI el box, mch pill "tal3a" barra.
  // --------------------------------------------------------------------
  Widget _questionBox({required String title, required Widget content, required AppSizes sizes}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sizes.screenWidth * 0.04),
      decoration: BoxDecoration(
        color: AppColors.pinkpetsy.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.vertpetsy.withOpacity(0.55), width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: sizes.screenWidth * 0.037,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: sizes.screenHeight * 0.016),
          content,
        ],
      ),
    );
  }

  // 🔵 card mrabba3a b'icon (wala image asset) + esm (Apartment/House/
  // Country House/Dog/Cat) - isSelected: border w fill ybadlou loun.
  //
  // 🔴 FIX (RenderFlex overflow): "width" tawa OPTIONNEL. 9bal, el card
  // kanet DIMA tetra9ba b'"screenWidth * widthFactor" - yaani % mel
  // écran KAMEL, MCH mel espace elli fadhi 7a9i9atan (el box 3andou
  // padding+border, w el Row 3andha 2 cards + spaceEvenly) - fa el 2
  // cards flou b'el zoùz ykabrou aktar mel espace disponible (overflow
  // b'3 pixels, exactement el erreur elli bantlek). El fix el sa7i7
  // (mch "na9as chwaya el ratio" - fragile, ye3tam el hjm el écran):
  // "width" null -> el card ma3andhach hjm fixe, tel9a el hjm mel
  // "Expanded" elli tzid touh (fel Row) - dima yeb9a fi 9ade el espace
  // el 7a9i9i, ay hjm écran.
  Widget _iconOptionCard({
    IconData? icon,
    String? imageAsset, // 🔵 ZID: lel Dog/Cat (photos 7a9i9iyin, mch icon generic)
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required AppSizes sizes,
    double? width, // null = ya5ou el hjm mel parent (Expanded) - safer
    // 🔴 FIX (kifma tlab): "el card lkol ye5o l'image mtaa el pet, thto
    // el type" - dog/cat bark (mch Apartment/House/CountryHouse, lezmou
    // yeb9aw kifhom kanou, icon+label b'padding). Ki true: el image
    // TEKHOU EL CARD KAMEL (edge-to-edge, bla padding), w el label
    // yban f'bande TA7T el image (mch fou9ha b'padding kifma 9bal).
    bool fillImage = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (fillImage && imageAsset != null) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔴 FIX (kifma tlab: "el chat w chien mch fel card, thet
            // el card") - el card (border/rounded) tawa IMAGE BARK
            // (kaملha, edge-to-edge) - el label ("Dog"/"Cat") 5arjou,
            // TA7T el card (mch f'bande jouwaha).
            Container(
              width: width,
              height: sizes.sitterPetTypeCardHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.vertpetsy : AppColors.pinkpetsy.withOpacity(0.35),
                  width: isSelected ? 2.5 : 1.2,
                ),
              ),
              child: Image.asset(imageAsset, width: double.infinity, fit: BoxFit.cover),
            ),
            SizedBox(height: sizes.screenHeight * 0.008),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: sizes.screenWidth * 0.033,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.vertpetsy : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.018, horizontal: sizes.screenWidth * 0.02),
        decoration: BoxDecoration(
          // 🔴 FIX (kifma tlab: "dark mode ma 3jebnich el alwen") - kanet
          // "Colors.white" THABTA (ay theme) - fel dark mode kan yban
          // murabba3 abyadh fa9i3 (w el label mba3d ma yban - text fatih
          // fou9 abyadh). Tawa: dark -> tint fatih SHWAYA (mch abyadh
          // slim), light -> abyadh kifma kan.
          color: isSelected ? AppColors.pinkpetsy.withOpacity(0.18) : (isDark ? Colors.white.withOpacity(0.06) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.vertpetsy : AppColors.pinkpetsy.withOpacity(0.35),
            width: isSelected ? 2.0 : 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            imageAsset != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      imageAsset,
                      width: sizes.sitterHomeOptionIconSize,
                      height: sizes.sitterHomeOptionIconSize,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(icon, size: sizes.sitterHomeOptionIconSize, color: AppColors.pinkpetsy),
            SizedBox(height: sizes.screenHeight * 0.008),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: sizes.screenWidth * 0.033,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔵 sef Yes/No (checkbox) - single select b'yedna (mch vrai Checkbox
  // widget - lowkan tdouss "Yes" ki "No" mcocha, "No" yet-décochi
  // automatique, w l3aks - ma3neha radio, mch multi-checkbox 7a9i9i).
  Widget _yesNoRow({required bool? value, required ValueChanged<bool> onChanged, required AppSizes sizes}) {
    return Row(
      children: [
        _yesNoCheckbox(label: 'yes_label'.tr(), isChecked: value == true, onTap: () => onChanged(true), sizes: sizes),
        SizedBox(width: sizes.screenWidth * 0.08),
        _yesNoCheckbox(label: 'no_label'.tr(), isChecked: value == false, onTap: () => onChanged(false), sizes: sizes),
      ],
    );
  }

  Widget _yesNoCheckbox({required String label, required bool isChecked, required VoidCallback onTap, required AppSizes sizes}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: sizes.screenWidth * 0.05,
            height: sizes.screenWidth * 0.05,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.vertpetsy, width: 1.6),
              color: isChecked ? AppColors.vertpetsy : Colors.transparent,
            ),
            child: isChecked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          SizedBox(width: sizes.screenWidth * 0.02),
          Text(label, style: TextStyle(fontSize: sizes.screenWidth * 0.036)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final bool showResidenceError = _triedSubmit && _residence == null;
    final bool showTransportError = _triedSubmit && _hasTransportation == null;
    final bool showPetError = _triedSubmit && _hasPet == null;
    final bool showPetTypeError = _triedSubmit && _hasPet == true && _ownedPetTypes.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: sizes.sitterHomeHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: sizes.sitterHomeTopGap),

                  Text(
                    'home_transport_details_title'.tr(),
                    style: TextStyle(
                      fontSize: sizes.sitterHomeTitleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),

                  SizedBox(height: sizes.sitterHomeTitleBoxGap),

                  // -------------------- Box 1: Où résidez-vous --------------------
                  _questionBox(
                    sizes: sizes,
                    title: 'sitter_reside_question'.tr(),
                    content: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _iconOptionCard(
                                icon: Icons.apartment,
                                label: 'sitter_residence_apartment'.tr(),
                                isSelected: _residence == ResidenceType.apartment,
                                onTap: () => setState(() => _residence = ResidenceType.apartment),
                                sizes: sizes,
                              ),
                            ),
                            SizedBox(width: sizes.screenWidth * 0.03),
                            Expanded(
                              child: _iconOptionCard(
                                icon: Icons.house,
                                label: 'sitter_residence_house'.tr(),
                                isSelected: _residence == ResidenceType.house,
                                onTap: () => setState(() => _residence = ResidenceType.house),
                                sizes: sizes,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: sizes.screenHeight * 0.016),
                        Center(
                          child: _iconOptionCard(
                            icon: Icons.cottage,
                            label: 'sitter_residence_country_house'.tr(),
                            isSelected: _residence == ResidenceType.countryHouse,
                            onTap: () => setState(() => _residence = ResidenceType.countryHouse),
                            sizes: sizes,
                            width: sizes.screenWidth * 0.42, // 🔵 standalone (mch fi Row m3a card okhra) - width fixe OK houni
                          ),
                        ),
                        if (showResidenceError) ...[
                          SizedBox(height: sizes.screenHeight * 0.01),
                          Text('sitter_residence_required_error'.tr(), style: TextStyle(color: AppColors.error, fontSize: sizes.screenWidth * 0.03)),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: sizes.sitterHomeBoxGap),

                  // -------------------- Box 2: Transport --------------------
                  _questionBox(
                    sizes: sizes,
                    title: 'sitter_transportation_question'.tr(),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _yesNoRow(value: _hasTransportation, onChanged: (v) => setState(() => _hasTransportation = v), sizes: sizes),
                        if (showTransportError) ...[
                          SizedBox(height: sizes.screenHeight * 0.008),
                          Text('sitter_transportation_required_error'.tr(), style: TextStyle(color: AppColors.error, fontSize: sizes.screenWidth * 0.03)),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: sizes.sitterHomeBoxGap),

                  // -------------------- Box 3: Pet chez toi + type (MERGÉS) --------------------
                  _questionBox(
                    sizes: sizes,
                    title: 'sitter_has_pet_question'.tr(),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _yesNoRow(
                          value: _hasPet,
                          onChanged: (v) => setState(() {
                            _hasPet = v;
                            // 🔵 ken el user ybaddel l"No" mel jdid, nmasso7
                            // el selection (bla ha data "orpheline")
                            if (v == false) _ownedPetTypes.clear();
                          }),
                          sizes: sizes,
                        ),
                        if (showPetError) ...[
                          SizedBox(height: sizes.screenHeight * 0.008),
                          Text('sitter_has_pet_required_error'.tr(), style: TextStyle(color: AppColors.error, fontSize: sizes.screenWidth * 0.03)),
                        ],

                        // 🔴 FIX (kifma tlabt): "what type of pet" tawa
                        // yban DIRECT ta7t "Yes"/"No" (nefs el box), ghir
                        // ki "Yes" mcocha - AnimatedSize bch el zheur
                        // ykoun smooth (mch box mnfassla dima bayna).
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _hasPet == true
                              ? Padding(
                                  padding: EdgeInsets.only(top: sizes.screenHeight * 0.018),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'sitter_pet_type_question'.tr(),
                                        style: TextStyle(
                                          fontSize: sizes.screenWidth * 0.033,
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.75),
                                        ),
                                      ),
                                      SizedBox(height: sizes.screenHeight * 0.014),
                                      Row(
                                        children: [
                                          // 🔴 FIX: kanet Icons.pets generic
                                          // lel zouz (mafamech icon dog/cat
                                          // 5ass fel Material Icons) - tawa
                                          // el images el 7a9i9iyin mel
                                          // assets/images/dog.png w cat.png.
                                          Expanded(
                                            child: _iconOptionCard(
                                              imageAsset: 'assets/images/dog.png',
                                              fillImage: true,
                                              label: 'sitter_pet_type_dog'.tr(),
                                              isSelected: _ownedPetTypes.contains('dog'),
                                              onTap: () => setState(() {
                                                if (!_ownedPetTypes.remove('dog')) _ownedPetTypes.add('dog');
                                              }),
                                              sizes: sizes,
                                            ),
                                          ),
                                          SizedBox(width: sizes.screenWidth * 0.03),
                                          Expanded(
                                            child: _iconOptionCard(
                                              imageAsset: 'assets/images/cat.png',
                                              fillImage: true,
                                              label: 'sitter_pet_type_cat'.tr(),
                                              isSelected: _ownedPetTypes.contains('cat'),
                                              onTap: () => setState(() {
                                                if (!_ownedPetTypes.remove('cat')) _ownedPetTypes.add('cat');
                                              }),
                                              sizes: sizes,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (showPetTypeError) ...[
                                        SizedBox(height: sizes.screenHeight * 0.01),
                                        Text('sitter_own_pet_type_required_error'.tr(), style: TextStyle(color: AppColors.error, fontSize: sizes.screenWidth * 0.03)),
                                      ],
                                    ],
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: sizes.sitterHomeBoxGap * 1.5),

                  CustomButton(
                    text: _isSubmitting ? 'loading_label'.tr() : 'done_button'.tr(),
                    color: AppColors.pinkpetsy,
                    widthFactor: 0.90,
                    heightFactor: 0.07,
                    fontFactor: 0.40,
                    enabled: !_isSubmitting,
                    onPressed: _onDonePressed,
                  ),

                  SizedBox(height: sizes.sitterHomeBottomGap),
                ],
              ),
            ),

            // 🔙 LAKHER fel Stack DIMA (mch 9bal el ScrollView) - chrahtha
            // b'proof fi see_all_pets.dart.
            const CustomBackButton(),
          ],
        ),
      ),
    );
  }
}