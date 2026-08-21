import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/button.dart';
import '../../../widgets/outlined_button.dart';
import '../../../widgets/paw_widget.dart';
import '../../../controllers/create_sitter_profile_controller.dart';
import 'create_sitter_profile_2.dart';

// ============================================================================
// _SitterService: 7ou9oul teswira (id + translation key) - LIST fadhya
// bch nzidou/nna9sou services men blasa wa7da, mch mfarr9in fi kol el
// widget.
// ============================================================================
class _SitterService {
  final String id;
  final String labelKey;

  const _SitterService({required this.id, required this.labelKey});
}

// 🔵 "cat" / "dog" / "both" - esm el pet type mkhtar lel service.
enum SitterPetType { cat, dog, both }

// ============================================================================
// CreateSitterProfileScreen ("Tell us about your service")
// ============================================================================
// 🔵 Box WA7DA bark ("Services Offered") - mch 2 (Services + Rates
// mfasslin kifma fel mockup el asli). Kol service fih checkbox: ki
// tcochih, YEB9A OBLIGATOIRE t3amر PRIX (TextField) W t5tar el pet
// type (Cat/Dog/Both) - el zouz 7ou9oul yban ghir taht el service
// elli mcocha, mch dima bayninin.
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
  // 🔵 LIST el services - zid/na9es houni bark ken t7eb tbeddel el
  // liste (mathalan tzid "Pet Grooming") - el UI kaملha tetba3 wa7dha.
  static const List<_SitterService> _services = [
    _SitterService(id: 'house_sitting', labelKey: 'sitter_service_house_sitting'),
    _SitterService(id: 'dog_walking', labelKey: 'sitter_service_dog_walking'),
    _SitterService(id: 'doggy_day_care', labelKey: 'sitter_service_doggy_day_care'),
    _SitterService(id: 'boarding', labelKey: 'sitter_service_boarding'),
    _SitterService(id: 'overnight_stays', labelKey: 'sitter_service_overnight_stays'),
    _SitterService(id: 'home_visits', labelKey: 'sitter_service_home_visits'),
  ];

  // 🔵 3 "maps" mrattbin b'el "id" tel service - ki service mcocha
  // (_selected[id] == true), 3andou price controller + pet type tou3ou.
  final Map<String, bool> _selected = {for (final s in _services) s.id: false};
  final Map<String, TextEditingController> _priceControllers = {
    for (final s in _services) s.id: TextEditingController(),
  };
  final Map<String, SitterPetType?> _petTypes = {for (final s in _services) s.id: null};

  bool _triedSubmit = false; // 🔵 nwarriw erreurs ghir ba3d ma el user y7awel "Next" loula marra
  final CreateSitterProfileController _controller = CreateSitterProfileController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleService(String id) {
    setState(() {
      _selected[id] = !(_selected[id] ?? false);
      // 🔵 ken el user ye-décoche service, nmasso7 el data tou3ou
      // (bla ha price/pet type ye5demou "orphelins" lel service mch mcocha)
      if (_selected[id] == false) {
        _priceControllers[id]!.clear();
        _petTypes[id] = null;
      }
    });
  }

  bool get _hasAtLeastOneService => _selected.values.any((v) => v);

  bool _isServiceValid(String id) {
    if (_selected[id] != true) return true; // mch mcocha, ma te7tajch validation
    final priceText = _priceControllers[id]!.text.trim();
    final hasPrice = priceText.isNotEmpty && double.tryParse(priceText) != null;
    final hasPetType = _petTypes[id] != null;
    return hasPrice && hasPetType;
  }

  Future<void> _onNextPressed() async {
    if (_isSubmitting) return;

    setState(() => _triedSubmit = true);

    if (!_hasAtLeastOneService) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sitter_service_required_error'.tr())),
      );
      return;
    }

    final missingPrice = _services.any((s) =>
        _selected[s.id] == true &&
        (_priceControllers[s.id]!.text.trim().isEmpty || double.tryParse(_priceControllers[s.id]!.text.trim()) == null));
    if (missingPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sitter_price_required_error'.tr())),
      );
      return;
    }

    final missingPetType = _services.any((s) => _selected[s.id] == true && _petTypes[s.id] == null);
    if (missingPetType) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sitter_pet_type_required_error'.tr())),
      );
      return;
    }

    // 🔵 el "shape" elli el backend yestenna (nafs mant9 sitterServiceSchema
    // fel models/sitter.js): {serviceId, price, petType}.
    final List<Map<String, dynamic>> servicesPayload = [
      for (final s in _services)
        if (_selected[s.id] == true)
          {
            'serviceId': s.id,
            'price': double.parse(_priceControllers[s.id]!.text.trim()),
            'petType': _petTypes[s.id]!.name,
          },
    ];

    setState(() => _isSubmitting = true);

    // 🔴 FIX: kanet ghir TODO/debugPrint (mafamech appel API 7a9i9i) -
    // tاوة PATCH 7a9i9i (controllers/create_sitter_profile_controller.dart).
    final bool success = await _controller.submitServices(services: servicesPayload);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('login_generic_error'.tr())), // 🔵 réutilisation: rasala generic "connexion/server" déjà mawjouda
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateSitterProfile2Screen(
          sitterName: widget.sitterName,
          sitterCity: widget.sitterCity,
          sitterPhotoBytes: widget.sitterPhotoBytes,
          selectedServices: Map.of(_selected),
          servicesPrices: {
            for (final s in _services)
              if (_selected[s.id] == true) s.id: _priceControllers[s.id]!.text.trim(),
          },
          servicesPetTypes: {
            for (final s in _services)
              if (_selected[s.id] == true) s.id: _petTypes[s.id]?.name,
          },
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

  // --------------------------------------------------------------------
  // Sef wa7ed (checkbox + esm), w ki mcocha: price + pet type ta7tou.
  // --------------------------------------------------------------------
  Widget _serviceRow(_SitterService service, AppSizes sizes) {
    final bool isChecked = _selected[service.id] ?? false;
    final bool showError = _triedSubmit && isChecked && !_isServiceValid(service.id);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.006),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _toggleService(service.id),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: sizes.screenWidth * 0.012),
              child: Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    activeColor: AppColors.vertpetsy,
                    onChanged: (_) => _toggleService(service.id),
                  ),
                  Expanded(
                    child: Text(
                      service.labelKey.tr(),
                      style: TextStyle(
                        fontSize: sizes.screenWidth * 0.037,
                        fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔵 el 7ou9oul el obligatoires (price + pet type) yban ghir
          // ki el service mcocha - AnimatedSize bch el zheur/el5tifa2
          // ykoun "smooth" (mch tal3a/tenzel bla transition).
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: isChecked
                ? Padding(
                    padding: EdgeInsets.only(
                      left: sizes.screenWidth * 0.10,
                      right: sizes.screenWidth * 0.02,
                      bottom: sizes.screenHeight * 0.014,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Prix (obligatoire) ---
                        TextField(
                          controller: _priceControllers[service.id],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          onChanged: (_) => setState(() {}), // bch el bouton Next/erreur yetbaddlou live
                          style: TextStyle(fontSize: sizes.screenWidth * 0.035),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'sitter_service_price_hint'.tr(),
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: sizes.screenWidth * 0.033),
                            suffixText: 'TND',
                            suffixStyle: TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.w600, fontSize: sizes.screenWidth * 0.032),
                            contentPadding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.035, vertical: sizes.screenHeight * 0.012),
                            filled: true,
                            fillColor: AppColors.vertpetsy.withOpacity(0.07),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.vertpetsy.withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.vertpetsy, width: 1.8),
                            ),
                          ),
                        ),

                        SizedBox(height: sizes.screenHeight * 0.012),

                        // --- Pet type: Cat / Dog / Both (choix wa7ed bark) ---
                        Text(
                          'sitter_pet_type_label'.tr(),
                          style: TextStyle(
                            fontSize: sizes.screenWidth * 0.030,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: sizes.screenHeight * 0.008),
                        Row(
                          children: [
                            Expanded(
                              child: CustomOutlinedButton(
                                text: 'sitter_pet_type_cat'.tr(),
                                isSelected: _petTypes[service.id] == SitterPetType.cat,
                                height: sizes.screenHeight * 0.045,
                                fontFactor: 0.34,
                                onPressed: () => setState(() => _petTypes[service.id] = SitterPetType.cat),
                              ),
                            ),
                            SizedBox(width: sizes.screenWidth * 0.02),
                            Expanded(
                              child: CustomOutlinedButton(
                                text: 'sitter_pet_type_dog'.tr(),
                                isSelected: _petTypes[service.id] == SitterPetType.dog,
                                height: sizes.screenHeight * 0.045,
                                fontFactor: 0.34,
                                onPressed: () => setState(() => _petTypes[service.id] = SitterPetType.dog),
                              ),
                            ),
                            SizedBox(width: sizes.screenWidth * 0.02),
                            Expanded(
                              child: CustomOutlinedButton(
                                text: 'sitter_pet_type_both'.tr(),
                                isSelected: _petTypes[service.id] == SitterPetType.both,
                                height: sizes.screenHeight * 0.045,
                                fontFactor: 0.34,
                                onPressed: () => setState(() => _petTypes[service.id] = SitterPetType.both),
                              ),
                            ),
                          ],
                        ),

                        // 🔵 erreur mrakeza (color rouge) ghir ki el user
                        // 7awel "Next" w hedha el service mazel na9es.
                        if (showError) ...[
                          SizedBox(height: sizes.screenHeight * 0.006),
                          Text(
                            _priceControllers[service.id]!.text.trim().isEmpty ||
                                    double.tryParse(_priceControllers[service.id]!.text.trim()) == null
                                ? 'sitter_price_required_error'.tr()
                                : 'sitter_pet_type_required_error'.tr(),
                            style: TextStyle(color: AppColors.error, fontSize: sizes.screenWidth * 0.028),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
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
                  // Box WA7DA bark: "Services Offered" (checkbox + price +
                  // pet type mel dakhel, mch box mnfassla lel "Rates")
                  // ------------------------------------------------------
                  _pillCard(
                    sizes: sizes,
                    pillText: 'sitter_services_offered_label'.tr(),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final service in _services) _serviceRow(service, sizes),
                      ],
                    ),
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