import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/button.dart';
import '../../../widgets/outlined_button.dart';
import '../../../controllers/auth_session.dart';
import '../../../controllers/user_create_profile_controller.dart';
import '../../../controllers/create_sitter_profile_controller.dart';
import '../../../models/my_profile_data.dart';
import '../../../services/api_service.dart';
import '../../../widgets/message_dialog.dart';

// 🔵 nafs el liste tel services (create_sitter_profile.dart) - class
// sghira, kopyitha houni bch UpdateProfileSitterScreen yeb9a standalone
// (bla import cross-screen, nafs convention mesta3mla fel app - chouf
// _HeaderIconButton fi profile_owner.dart/sitter_profile.dart).
class _UpdateService {
  final String id;
  final String labelKey;
  const _UpdateService({required this.id, required this.labelKey});
}

// ============================================================================
// UpdateProfileSitterScreen ("Update My Profile")
// ============================================================================
// 🔵 Wsulha mel "My Profile" (bouton stylo) - form m3amra mel data el
// 7aliya (Name/Birthday/City/Phone Number/About you) + photo (b stylo
// tel3 fou9ha, kifma tlabt).
// ============================================================================
class UpdateProfileSitterScreen extends StatefulWidget {
  final MyProfileData currentProfile;

  const UpdateProfileSitterScreen({super.key, required this.currentProfile});

  @override
  State<UpdateProfileSitterScreen> createState() => _UpdateProfileSitterScreenState();
}

class _UpdateProfileSitterScreenState extends State<UpdateProfileSitterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _birthdayController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;
  late final TextEditingController _aboutController;

  final UserCreateProfileController _profileController = UserCreateProfileController();
  final CreateSitterProfileController _servicesController = CreateSitterProfileController();
  Uint8List? _newPhotoBytes; // 🔵 lowkan el user 5tar photo jdida (null = 5alli el 9dima)
  bool _isSubmitting = false;
  bool _triedSubmit = false;

  // 🔵 ZID (kifma tlabt): box "Services" - el services LKOL (mcochiin
  // wela le), m3ammrin bel data el 7aliya tel sitter (mch fadhyin).
  static const List<_UpdateService> _services = [
    _UpdateService(id: 'house_sitting', labelKey: 'sitter_service_house_sitting'),
    _UpdateService(id: 'dog_walking', labelKey: 'sitter_service_dog_walking'),
    _UpdateService(id: 'doggy_day_care', labelKey: 'sitter_service_doggy_day_care'),
    _UpdateService(id: 'boarding', labelKey: 'sitter_service_boarding'),
    _UpdateService(id: 'overnight_stays', labelKey: 'sitter_service_overnight_stays'),
    _UpdateService(id: 'home_visits', labelKey: 'sitter_service_home_visits'),
  ];
  final Map<String, bool> _selectedServices = {for (final s in _services) s.id: false};
  final Map<String, TextEditingController> _servicePriceControllers = {
    for (final s in _services) s.id: TextEditingController(),
  };
  final Map<String, String?> _servicePetTypes = {for (final s in _services) s.id: null};

  @override
  void initState() {
    super.initState();
    final p = widget.currentProfile;
    _nameController = TextEditingController(text: p.fullName);
    _birthdayController = TextEditingController(text: p.birthday);
    _cityController = TextEditingController(text: p.city);
    _phoneController = TextEditingController(text: p.phone);
    _aboutController = TextEditingController(text: p.bio);

    // 🔴 FIX (kifma tlabt): "kol chy m3ammar b eli 3malt bih el inscri,
    // ma fama chy nheb feragh" - el services el mawjoudin déjà fel
    // profile (signup) tawa mcochiin automatique, m3a el prix/pet type
    // mte3hom.
    for (final entry in p.services) {
      if (_selectedServices.containsKey(entry.serviceId)) {
        _selectedServices[entry.serviceId] = true;
        _servicePriceControllers[entry.serviceId]!.text = entry.price.toStringAsFixed(entry.price.truncateToDouble() == entry.price ? 0 : 2);
        _servicePetTypes[entry.serviceId] = entry.petType;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthdayController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    for (final controller in _servicePriceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: AppColors.vertpetsy),
                title: Text('gallery_option'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: AppColors.vertpetsy),
                title: Text('camera_option'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _newPhotoBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      showMessageDialog(context, 'login_generic_error'.tr());
    }
  }

  void _toggleService(String id) {
    setState(() {
      _selectedServices[id] = !(_selectedServices[id] ?? false);
      if (_selectedServices[id] == false) {
        _servicePriceControllers[id]!.clear();
        _servicePetTypes[id] = null;
      }
    });
  }

  Future<void> _onUpdatePressed() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _triedSubmit = true);

    // 🔵 ZID: validation el services (nafs mant9 create_sitter_profile.dart)
    // - service mcocha lezmou price + pet type, wa9tha bark.
    final missingPrice = _services.any((s) =>
        _selectedServices[s.id] == true &&
        (_servicePriceControllers[s.id]!.text.trim().isEmpty || double.tryParse(_servicePriceControllers[s.id]!.text.trim()) == null));
    if (missingPrice) {
      showMessageDialog(context, 'sitter_price_required_error'.tr());
      return;
    }
    final missingPetType = _services.any((s) => _selectedServices[s.id] == true && _servicePetTypes[s.id] == null);
    if (missingPetType) {
      showMessageDialog(context, 'sitter_pet_type_required_error'.tr());
      return;
    }

    setState(() => _isSubmitting = true);

    final bool profileSuccess = await _profileController.submitProfile(
      role: widget.currentProfile.role,
      name: _nameController.text,
      birthday: _birthdayController.text,
      city: _cityController.text,
      phone: _phoneController.text,
      aboutYou: _aboutController.text,
    );

    // 🔴 FIX (kifma tlabt): "el modification lkol nheb tetsajel" - el
    // services (zid/na77i/beddel price) tawa ye3ملهم PATCH 7a9i9i zeda
    // (bark el profile mch kafi).
    final List<Map<String, dynamic>> servicesPayload = [
      for (final s in _services)
        if (_selectedServices[s.id] == true)
          {
            'serviceId': s.id,
            'price': double.parse(_servicePriceControllers[s.id]!.text.trim()),
            'petType': _servicePetTypes[s.id],
          },
    ];
    final bool servicesSuccess = await _servicesController.submitServices(services: servicesPayload);

    // 🔵 photo: appel MNFASSEL bark lowkan el user 5tar photo jdida
    // (bla ma nab3thou el photo el 9dima mel jdid).
    bool photoSuccess = true;
    if (_newPhotoBytes != null && AuthSession.userId != null) {
      try {
        final response = await ApiService.uploadPhoto(
          '/users/${AuthSession.userId}/photo',
          _newPhotoBytes!,
          token: AuthSession.token,
        );
        photoSuccess = response.statusCode == 200;
      } catch (_) {
        photoSuccess = false;
      }
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!profileSuccess || !servicesSuccess || !photoSuccess) {
      showMessageDialog(context, 'login_generic_error'.tr());
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // yerja3 l "My Profile" (elli ye3mel refresh wa7dou)
  }

  Widget _updateServiceRow(_UpdateService service, AppSizes sizes) {
    final bool isChecked = _selectedServices[service.id] ?? false;
    final bool showError = _triedSubmit && isChecked &&
        (_servicePriceControllers[service.id]!.text.trim().isEmpty ||
            double.tryParse(_servicePriceControllers[service.id]!.text.trim()) == null ||
            _servicePetTypes[service.id] == null);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.004),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _toggleService(service.id),
            child: Row(
              children: [
                Checkbox(
                  value: isChecked,
                  activeColor: AppColors.pinkpetsy,
                  onChanged: (_) => _toggleService(service.id),
                ),
                Expanded(
                  child: Text(
                    service.labelKey.tr(),
                    style: TextStyle(fontSize: sizes.screenWidth * 0.036, fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: isChecked
                ? Padding(
                    padding: EdgeInsets.only(left: sizes.screenWidth * 0.10, right: sizes.screenWidth * 0.02, bottom: sizes.screenHeight * 0.014),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _servicePriceControllers[service.id],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'sitter_service_price_hint'.tr(),
                            suffixText: 'TND',
                            contentPadding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.035, vertical: sizes.screenHeight * 0.012),
                            filled: true,
                            fillColor: AppColors.vertpetsy.withOpacity(0.07),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.vertpetsy.withOpacity(0.5))),
                            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.vertpetsy, width: 1.8)),
                          ),
                        ),
                        SizedBox(height: sizes.screenHeight * 0.01),
                        Row(
                          children: [
                            Expanded(
                              child: CustomOutlinedButton(
                                text: 'sitter_pet_type_cat'.tr(),
                                isSelected: _servicePetTypes[service.id] == 'cat',
                                height: sizes.screenHeight * 0.045,
                                fontFactor: 0.34,
                                onPressed: () => setState(() => _servicePetTypes[service.id] = 'cat'),
                              ),
                            ),
                            SizedBox(width: sizes.screenWidth * 0.02),
                            Expanded(
                              child: CustomOutlinedButton(
                                text: 'sitter_pet_type_dog'.tr(),
                                isSelected: _servicePetTypes[service.id] == 'dog',
                                height: sizes.screenHeight * 0.045,
                                fontFactor: 0.34,
                                onPressed: () => setState(() => _servicePetTypes[service.id] = 'dog'),
                              ),
                            ),
                            SizedBox(width: sizes.screenWidth * 0.02),
                            Expanded(
                              child: CustomOutlinedButton(
                                text: 'sitter_pet_type_both'.tr(),
                                isSelected: _servicePetTypes[service.id] == 'both',
                                height: sizes.screenHeight * 0.045,
                                fontFactor: 0.34,
                                onPressed: () => setState(() => _servicePetTypes[service.id] = 'both'),
                              ),
                            ),
                          ],
                        ),
                        if (showError) ...[
                          SizedBox(height: sizes.screenHeight * 0.006),
                          Text(
                            (_servicePriceControllers[service.id]!.text.trim().isEmpty || double.tryParse(_servicePriceControllers[service.id]!.text.trim()) == null)
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

  Widget _fieldLabel(String text, AppSizes sizes) {
    return Text(
      text,
      style: TextStyle(fontSize: sizes.screenWidth * 0.037, fontWeight: FontWeight.bold, color: AppColors.pinkpetsy),
    );
  }

  InputDecoration _fieldDecoration({required BuildContext context, Widget? suffixIcon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.pinkpetsy.withOpacity(0.5)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.pinkpetsy, width: 1.8),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.error, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final p = widget.currentProfile;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: sizes.myProfileHorizontalPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: sizes.updateProfileTopGap),

                    Center(
                      child: Text(
                        'update_my_profile_title'.tr(),
                        style: TextStyle(fontSize: sizes.myProfileNameFontSize, fontWeight: FontWeight.bold),
                      ),
                    ),

                    SizedBox(height: sizes.myProfileSectionGap),

                    Center(
                      child: Text('update_your_photo_label'.tr(), style: TextStyle(fontSize: sizes.myProfileBodyFontSize, color: AppColors.pinkpetsy)),
                    ),
                    SizedBox(height: sizes.screenHeight * 0.012),

                    // ----------------------------------------------------
                    // Photo + stylo (kifma tlabt) - tap 3ala ay blasa
                    // mel widget yeftah el bottom sheet (gallery/camera)
                    // ----------------------------------------------------
                    Center(
                      child: GestureDetector(
                        onTap: _showPhotoSourceSheet,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: sizes.updateProfilePhotoSize,
                                height: sizes.updateProfilePhotoSize,
                                color: AppColors.vertpetsy.withOpacity(0.15),
                                child: _newPhotoBytes != null
                                    ? Image.memory(_newPhotoBytes!, fit: BoxFit.cover)
                                    : (p.photoUrl != null && p.photoUrl!.isNotEmpty)
                                        ? Image.network('${ApiService.mediaBaseUrl}${p.photoUrl}', fit: BoxFit.cover)
                                        : Icon(Icons.person, color: AppColors.vertpetsy, size: sizes.updateProfilePhotoSize * 0.5),
                              ),
                            ),
                            Positioned(
                              bottom: -6,
                              right: -6,
                              child: Container(
                                padding: EdgeInsets.all(sizes.screenWidth * 0.018),
                                decoration: BoxDecoration(
                                  color: AppColors.pinkpetsy,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                ),
                                child: Icon(Icons.edit, color: Colors.white, size: sizes.screenWidth * 0.045),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: sizes.myProfileSectionGap),

                    _fieldLabel('name_label'.tr(), sizes),
                    SizedBox(height: sizes.screenHeight * 0.008),
                    TextFormField(
                      controller: _nameController,
                      validator: ProfileValidators.name,
                      decoration: _fieldDecoration(context: context),
                    ),

                    SizedBox(height: sizes.screenHeight * 0.02),

                    _fieldLabel('birthday_label'.tr(), sizes),
                    SizedBox(height: sizes.screenHeight * 0.008),
                    TextFormField(
                      controller: _birthdayController,
                      readOnly: true,
                      onTap: _pickBirthday,
                      decoration: _fieldDecoration(
                        context: context,
                        suffixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.pinkpetsy.withOpacity(0.7)),
                      ),
                    ),

                    SizedBox(height: sizes.screenHeight * 0.02),

                    _fieldLabel('city_label'.tr(), sizes),
                    SizedBox(height: sizes.screenHeight * 0.008),
                    TextFormField(
                      controller: _cityController,
                      validator: ProfileValidators.name, // 🔵 nafs règle: mch fadhi
                      decoration: _fieldDecoration(context: context),
                    ),

                    SizedBox(height: sizes.screenHeight * 0.02),

                    _fieldLabel('phone_number_label'.tr(), sizes),
                    SizedBox(height: sizes.screenHeight * 0.008),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: ProfileValidators.phone,
                      decoration: _fieldDecoration(context: context),
                    ),

                    SizedBox(height: sizes.screenHeight * 0.02),

                    _fieldLabel('about_you_label'.tr(), sizes),
                    SizedBox(height: sizes.screenHeight * 0.008),
                    TextFormField(
                      controller: _aboutController,
                      maxLines: 4,
                      validator: (value) => ProfileValidators.aboutYou(value, widget.currentProfile.role),
                      decoration: _fieldDecoration(context: context),
                    ),

                    SizedBox(height: sizes.myProfileSectionGap),

                    // ----------------------------------------------------
                    // 🔵 ZID (kifma tlabt): box "Services" - LKOL (mcochiin
                    // wela le), ynajjam yzid (cochi) wela yna77i (décochi)
                    // - kol modification tetsajel ki tdouss "Update".
                    // ----------------------------------------------------
                    _fieldLabel('sitter_services_offered_label'.tr(), sizes),
                    SizedBox(height: sizes.screenHeight * 0.01),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.03, vertical: sizes.screenHeight * 0.006),
                      decoration: BoxDecoration(
                        color: AppColors.pinkpetsy.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.pinkpetsy.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [for (final service in _services) _updateServiceRow(service, sizes)],
                      ),
                    ),

                    SizedBox(height: sizes.myProfileSectionGap * 1.5),

                    Center(
                      child: CustomButton(
                        text: _isSubmitting ? 'loading_label'.tr() : 'update_button'.tr(),
                        color: AppColors.pinkpetsy,
                        widthFactor: 0.90,
                        heightFactor: 0.07,
                        fontFactor: 0.40,
                        enabled: !_isSubmitting,
                        onPressed: _onUpdatePressed,
                      ),
                    ),

                    SizedBox(height: sizes.myProfileBottomGap),
                  ],
                ),
              ),
            ),

            const CustomBackButton(),
          ],
        ),
      ),
    );
  }
}