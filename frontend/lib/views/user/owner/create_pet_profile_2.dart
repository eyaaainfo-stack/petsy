import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/button.dart';
import '../../../widgets/outlined_button.dart';
import '../../../widgets/paw_widget.dart';
import '../../../controllers/create_pet_profile_2_controller.dart';
import '../../../models/pet_summary.dart';
import 'add_pet_photo.dart';
import '../../../widgets/message_dialog.dart';

// ============================================================================
// CreatePetProfile2Screen ("Pet's behavior and care")
// ============================================================================
// Yji ba3d CreatePetProfileScreen. Fih 2 cards (behavior + care info)
// w formulaire "Veterinary info" (optionnel).
// ============================================================================
class CreatePetProfile2Screen extends StatefulWidget {
  final String petType; // 🔵 ZID: 'dog' wala 'cat' - lezmha touwsel l'add_pet_photo

  // 🔵 ZID: kaملha lezemha touwsel l'add_pet_photo -> profile_owner
  final String ownerName;
  final String ownerCity;
  final String petName;
  final List<PetSummary> existingPets;
  final Uint8List? ownerPhotoBytes;

  // 🔵 ZID: el data mel écran el loula (kanet tedhi3 houni)
  final String? petAge;
  final String? petBreed;
  final String? petSize;
  final String? petGender;

  const CreatePetProfile2Screen({
    super.key,
    required this.petType,
    required this.ownerName,
    required this.ownerCity,
    required this.petName,
    this.existingPets = const [],
    this.ownerPhotoBytes,
    this.petAge,
    this.petBreed,
    this.petSize,
    this.petGender,
  });

  @override
  State<CreatePetProfile2Screen> createState() => _CreatePetProfile2ScreenState();
}

class _CreatePetProfile2ScreenState extends State<CreatePetProfile2Screen> {
  final TextEditingController _clinicNameController = TextEditingController();
  final TextEditingController _clinicPhoneController = TextEditingController();

  final CreatePetProfile2Controller _controller = CreatePetProfile2Controller();

  // --------------------------------------------------------------------
  // Behaviors: multi-select (el user y5tar 9adecha yhebb - "Calm" W
  // "Friendly" fi nefs el wa9t mumkin), fa Set<String> (mch String wa7da).
  // --------------------------------------------------------------------
  final Set<String> _selectedBehaviors = {};

  static const List<String> _behaviorKeys = [
    'behavior_scared_new_people',
    'behavior_calm',
    'behavior_scared_animals',
    'behavior_active',
    'behavior_friendly',
    'behavior_angry',
  ];

  // --------------------------------------------------------------------
  // Care info: kol sujet (microchipped, vaccinated...) 3andou Yes/No -
  // bool (mch bool? tawa) - DEFAULT false ("No"), mch null (mazel ma
  // jaweb). El user tlab: "kol chy yji par défaut 3ala non".
  // --------------------------------------------------------------------
  final Map<String, bool> _careInfo = {
    'microchipped': false,
    'vaccinated': false,
    'neutered': false,
    'medication': false,
  };

  bool _isSubmitting = false;

  @override
  void dispose() {
    _clinicNameController.dispose();
    _clinicPhoneController.dispose();
    super.dispose();
  }

  Future<void> _onNextPressed() async {
    if (_isSubmitting) return;

    // 🔵 el behaviors mch TextFormField (Set, mch controller), fa
    // nchekkouha b'el yed - "obligatoire GHIR el vétérinaire optionnel".
    if (_selectedBehaviors.isEmpty) {
      showMessageDialog(context, 'behavior_required_error'.tr());
      return;
    }

    setState(() => _isSubmitting = true);

    // 🔵 sa77e7t: tاوة terja3 "petId" (String?), MCH "bool" - lowkan
    // null, ma5demch (chekki server/connexion, chrahtha fel SnackBar).
    final petId = await _controller.submitPetBehaviorAndCare(
      petType: widget.petType,
      name: widget.petName,
      age: widget.petAge,
      breed: widget.petBreed,
      size: widget.petSize,
      gender: widget.petGender,
      behaviors: _selectedBehaviors,
      careInfo: _careInfo,
      clinicName: _clinicNameController.text,
      clinicPhone: _clinicPhoneController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (petId == null) {
      showMessageDialog(context, 'pet_save_error'.tr());
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPetPhotoScreen(
          petType: widget.petType,
          ownerName: widget.ownerName,
          ownerCity: widget.ownerCity,
          petName: widget.petName,
          existingPets: widget.existingPets,
          ownerPhotoBytes: widget.ownerPhotoBytes,
          petAge: widget.petAge,
          petBreed: widget.petBreed,
          petSize: widget.petSize,
          petGender: widget.petGender,
          petBehaviors: _selectedBehaviors.toList(),
          petCareInfo: _careInfo,
          petVetClinicName: _clinicNameController.text,
          petVetClinicPhone: _clinicPhoneController.text,
          // 🔵 ZID: el ID el 7a9i9i (MongoDB) - lezmou bch AddPetPhotoScreen
          // ta3raf win tab3ath el photo (POST /api/pets/:petId/photo).
          petId: petId,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({required BuildContext context}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.vertpetsy.withOpacity(0.6)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.vertpetsy, width: 1.8),
      ),
    );
  }

  Widget _fieldLabel(String text, double screenWidth) {
    return Text(
      text,
      style: TextStyle(
        fontSize: screenWidth * 0.033,
        fontWeight: FontWeight.bold,
        color: AppColors.vertpetsy,
      ),
    );
  }

  // Pill rose (header tel 2 cards): "Pet's behavior include ..." / "Care info"
  Widget _sectionHeaderPill(String text, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
      decoration: BoxDecoration(
        color: AppColors.pinkpetsy,
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: screenWidth * 0.036,
        ),
      ),
    );
  }

  // Card teal fadhya (khalfiya tel 2 sections)
  Widget _sectionCard({required Widget child, required BuildContext context}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.vertpetsy.withOpacity(0.10) : AppColors.vertpetsy.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  // ==========================================================================
  // _pillCard: "dial" wa7ed bess (pillRise) ye7keb fi kolchi
  // ==========================================================================
  // 🔵 3lech ma knch tnajjam "tal3a" el pill: 9bal, el masafa barra el
  // card (0.025) w el masafa dakhel el card (0.02) kanou 2 ra9mayn
  // MFASSLIN (mch mرtab6in b b3adhom) - kif tbadel wa7ed, l'okhra
  // tab9a kifha, fa el pill tedkhol fel contenu (el behaviors/care info)
  // bdal ma to9af 3and 7doud el card.
  //
  // El 7al: n7esbou "pillHeight" el 7a9i9i (mel padding + font tel pill),
  // w "overlapIntoCard" (9addech mel pill ye5ouch fel card) YET7ESEB
  // AUTOMATIQUE mel "pillRise" - mch ra9m mnafsel.
  //
  // 👉 BADEL "pillRise" HOUNI BESS bch el pill tetla3 aktar/a9al -
  // el 7isab el ba9i (padding el card) yetbadel wa7dou m3aha.
  // ==========================================================================
  Widget _pillCard({
    required BuildContext context,
    required double screenWidth,
    required double screenHeight,
    required String pillText,
    required Widget content,
  }) {
    // hjm el pill el 7a9i9i (2x padding 3amoudi + strr el ktiba)
    final double pillFontSize = screenWidth * 0.033;
    final double pillVerticalPadding = screenWidth * 0.035;
    final double pillHeight = (pillVerticalPadding * 2) + (pillFontSize * 1.3);

    // 🔴 EL GHALTA ELLI KANET: "pillRise" 9bal kanet mahsouba mel
    // "screenHeight" (el 6oul), bainama "pillHeight" fou9 mahsouba mel
    // "screenWidth" (el 3ard). Fel téléphone el 3ard w el 6oul
    // taqriban nafs en-nisba dima (chekel mowa7ad), lakin fel browser
    // (Chrome, nafida tetmadad 7or) el 3ard w el 6oul ma3andhomch nefs
    // en-nisba - fa el 2 ra9mayn "yefta r9ou" 3an ba3dhom, w el pill
    // tghouss aktar mel card mte3ha (tban tkhabbi el ktiba).
    //
    // 🟢 EL 7AL: "pillRise" tawa NISBA MEL PILL NAFSOU (mch ra9m
    // mnafsel mahsoub mel height) - kif kbrat/sghrat el screen (3ard
    // WALA 6oul, howa kif), el 2 ra9mayn (pillRise w overlapIntoCard)
    // ykabrou/ysghrou b'nefs en-nisba, DIMA motawaznin, ay window
    // (téléphone wla PC, kbira wla sghira).
    final double pillRise = pillHeight * 0.35; // 👈 EL DIAL: bdel el %
    final double overlapIntoCard = pillHeight - pillRise;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(top: pillRise),
          child: _sectionCard(
            context: context,
            // el fasa5 dakhli = overlapIntoCard + housh zgheir, DIMA
            // metrabet bel 7isab fou9, mch ra9m mnafsel.
            child: Padding(
              padding: EdgeInsets.only(top: overlapIntoCard + screenHeight * 0.012),
              child: content,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: screenWidth * 0.06,
          right: screenWidth * 0.06,
          child: _sectionHeaderPill(pillText, screenWidth),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------
  // 🔵 Behaviors tاوة b CustomOutlinedButton (mawjoud déjà fel widgets/,
  // mch chip mfassel b'yedna) - w b'chekel "grid" mnadham (2 fi kol
  // sef), mch Wrap 7or (elli kan ysabbeb hjm mo5tlef mch mnadham).
  // --------------------------------------------------------------------
  Widget _behaviorButton(String key, double buttonWidth, double buttonHeight) {
    final bool isSelected = _selectedBehaviors.contains(key);

    return CustomOutlinedButton(
      text: key.tr(),
      width: buttonWidth,
      height: buttonHeight,
      isSelected: isSelected,
      fontFactor: 0.26,
      onPressed: () {
        setState(() {
          if (isSelected) {
            _selectedBehaviors.remove(key);
          } else {
            _selectedBehaviors.add(key);
          }
        });
      },
    );
  }

  // Sef (row) fih 2 behaviors jenb b3adhom
  Widget _behaviorRow(String key1, String key2, double screenWidth, double buttonWidth, double buttonHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.012),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _behaviorButton(key1, buttonWidth, buttonHeight),
          _behaviorButton(key2, buttonWidth, buttonHeight),
        ],
      ),
    );
  }

  // Sef (row) wa7ed fi "Care info" (esm + 2 Radio Yes/No)
  Widget _careInfoRow(String labelKey, String stateKey, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.012),
      child: Row(
        children: [
          Expanded(
            child: Text(
              labelKey.tr(),
              style: TextStyle(fontSize: screenWidth * 0.032),
            ),
          ),
          SizedBox(
            width: screenWidth * 0.14,
            child: Radio<bool>(
              value: true,
              groupValue: _careInfo[stateKey],
              activeColor: AppColors.pinkpetsy,
              onChanged: (value) => setState(() => _careInfo[stateKey] = value ?? false),
            ),
          ),
          SizedBox(
            width: screenWidth * 0.14,
            child: Radio<bool>(
              value: false,
              groupValue: _careInfo[stateKey],
              activeColor: AppColors.pinkpetsy,
              onChanged: (value) => setState(() => _careInfo[stateKey] = value ?? false),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.75) ?? Colors.black87;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            buildPetPaw(context: context, size: screenSize.width * 0.09, topPercent: 0.09, leftPercent: 0.04, color: AppColors.pinkpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: screenSize.width * 0.09, topPercent: 0.09, leftPercent: 0.85, color: AppColors.pinkpetsy.withOpacity(0.6)),

            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.07),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: screenSize.height * 0.09),

                  Text(
                    'pet_behavior_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenSize.width * 0.048,
                      fontWeight: FontWeight.bold,
                      color: AppColors.vertpetsy,
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.012),

                  Text(
                    'pet_profile_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenSize.width * 0.032,
                      color: mutedTextColor,
                      height: 1.35,
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.035),

                  // ----------------------------------------------------
                  // Card 1: "Pet's behavior include ..."
                  // ----------------------------------------------------
                  Builder(builder: (context) {
                    // hjm kol bouton: (3ard el card - gap) / 2, bch
                    // ykounou 2 f kol sef, mzabta, mch Wrap 7or.
                    final double cardInnerWidth = screenSize.width * 0.86 - 32;
                    final double gap = screenSize.width * 0.03;
                    final double buttonWidth = (cardInnerWidth - gap) / 2;
                    final double buttonHeight = screenSize.width * 0.16;

                    return _pillCard(
                      context: context,
                      screenWidth: screenSize.width,
                      screenHeight: screenSize.height,
                      pillText: 'pet_behavior_include_label'.tr(),
                      content: Column(
                        children: [
                          _behaviorRow(_behaviorKeys[0], _behaviorKeys[1], screenSize.width, buttonWidth, buttonHeight),
                          _behaviorRow(_behaviorKeys[2], _behaviorKeys[3], screenSize.width, buttonWidth, buttonHeight),
                          _behaviorRow(_behaviorKeys[4], _behaviorKeys[5], screenSize.width, buttonWidth, buttonHeight),
                        ],
                      ),
                    );
                  }),

                  SizedBox(height: screenSize.height * 0.035),

                  // ----------------------------------------------------
                  // Card 2: "Care info"
                  // ----------------------------------------------------
                  _pillCard(
                    context: context,
                    screenWidth: screenSize.width,
                    screenHeight: screenSize.height,
                    pillText: 'care_info_label'.tr(),
                    content: Column(
                      children: [
                        // header "Yes" / "No"
                        Row(
                          children: [
                            const Expanded(child: SizedBox()),
                            SizedBox(
                              width: screenSize.width * 0.14,
                              child: Text('yes_label'.tr(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            SizedBox(
                              width: screenSize.width * 0.14,
                              child: Text('no_label'.tr(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        _careInfoRow('microchipped_label', 'microchipped', screenSize.width),
                        _careInfoRow('vaccinated_label', 'vaccinated', screenSize.width),
                        _careInfoRow('neutered_label', 'neutered', screenSize.width),
                        _careInfoRow('medication_label', 'medication', screenSize.width),
                      ],
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.04),

                  Text(
                    'veterinary_info_label'.tr(),
                    style: TextStyle(
                      fontSize: screenSize.width * 0.036,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.02),

                  _fieldLabel('clinic_name_label'.tr(), screenSize.width),
                  SizedBox(height: screenSize.height * 0.008),
                  TextFormField(
                    controller: _clinicNameController,
                    decoration: _fieldDecoration(context: context),
                  ),

                  SizedBox(height: screenSize.height * 0.02),

                  _fieldLabel('phone_number_label'.tr(), screenSize.width),
                  SizedBox(height: screenSize.height * 0.008),
                  TextFormField(
                    controller: _clinicPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _fieldDecoration(context: context),
                  ),

                  SizedBox(height: screenSize.height * 0.04),

                  Center(
                    child: CustomButton(
                      text: _isSubmitting ? 'loading_label'.tr() : 'next_button'.tr(),
                      color: AppColors.vertpetsy,
                      widthFactor: 0.90,
                      heightFactor: 0.07,
                      fontFactor: 0.40,
                      onPressed: _onNextPressed,
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.04),
                ],
              ),
            ),

            // 🔙 zdinaha HOUNI (lakher fel Stack) - chrahtha fel admin_login
            const CustomBackButton(),
          ],
        ),
      ),
    );
  }
}