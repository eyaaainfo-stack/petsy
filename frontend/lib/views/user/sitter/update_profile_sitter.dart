import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/button.dart';
import '../../../widgets/map.dart';
import '../../../widgets/service_category_selector.dart';
import '../../../controllers/auth_session.dart';
import '../../../controllers/user_create_profile_controller.dart';
import '../../../controllers/create_sitter_profile_controller.dart';
import '../../../models/my_profile_data.dart';
import '../../../services/api_service.dart';
import '../../../widgets/message_dialog.dart';

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
  // 🔴 FIX (kifma tlab: "el sitter wkt yhb yaml edit lel profile mteou
  // famma el emplacement wel genre neksin") - kanou mawjoudin GHIR fel
  // update_profile_owner.dart (el sitter 3omrou ma najjam ybeddel
  // location/gender mel "Update My Profile" tou3ou, 7atta lowkan
  // 3amrahom fel inscription - submitProfile() kan ye3mel PATCH bla
  // hedhom, fa kifma yeb9aw kifma déjà mzoudin, mch "editable").
  late final TextEditingController _locationController;

  final UserCreateProfileController _profileController = UserCreateProfileController();
  final CreateSitterProfileController _servicesController = CreateSitterProfileController();
  Uint8List? _newPhotoBytes; // 🔵 lowkan el user 5tar photo jdida (null = 5alli el 9dima)
  double? _selectedLat;
  double? _selectedLng;
  String? _locationName;
  String? _selectedGender;
  bool _isSubmitting = false;
  bool _triedSubmit = false;

  // 🔴 FIX (kifma tlab: "les services nhbhom fi des titre...") -
  // ServiceCategorySelector (widgets/service_category_selector.dart)
  // - categories accordion + "Autre", m3ammar mel services el 7aliya
  // (nafs mant9 create_sitter_profile.dart, tawa fi widget WA7ED
  // partagé bin el 2 écrans - bla duplication).
  final GlobalKey<ServiceCategorySelectorState> _serviceSelectorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final p = widget.currentProfile;
    _nameController = TextEditingController(text: p.fullName);
    _birthdayController = TextEditingController(text: p.birthday);
    _cityController = TextEditingController(text: p.city);
    _phoneController = TextEditingController(text: p.phone);
    _aboutController = TextEditingController(text: p.bio);
    // 🔴 FIX (kifma tlab: "famma el emplacement wel genre neksin") -
    // m3ammrin mel data el 7aliya (nafs mant9 update_profile_owner.dart).
    _locationController = TextEditingController(text: p.locationName ?? '');
    _locationName = p.locationName;
    _selectedGender = p.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthdayController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    _locationController.dispose();
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

  // 🔴 FIX (kifma tlab: "famma el emplacement... neksin") - nafs mant9
  // update_profile_owner.dart: yeftah LocationPickerScreen (widgets/
  // map.dart), yerja3 lat/lng + esm el blasa (reverse-geocoding).
  Future<void> _pickLocation() async {
    final LocationResult? result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );

    if (result != null) {
      setState(() {
        _selectedLat = result.latLng.latitude;
        _selectedLng = result.latLng.longitude;
        _locationName = result.placeName;
        _locationController.text = result.placeName;
      });

      // 🔵 ZID (kifma tlabt fel owner): nafs mant9 - ken el location
      // fi wilaya mo5talfa 3an el "City", nbaddlouha automatique + popup.
      final String? matchedGovernorate = matchTunisianGovernorate(result.rawStateName);
      if (matchedGovernorate != null && matchedGovernorate != _cityController.text && mounted) {
        final String oldCity = _cityController.text;
        setState(() => _cityController.text = matchedGovernorate);
        if (oldCity.isNotEmpty) {
          _showCityAutoChangedDialog(oldCity: oldCity, newCity: matchedGovernorate);
        }
      }
    }
  }

  void _showCityAutoChangedDialog({required String oldCity, required String newCity}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('city_auto_updated_title'.tr()),
          content: Text('city_auto_updated_message'.tr(namedArgs: {'oldCity': oldCity, 'newCity': newCity})),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('ok_button'.tr()),
            ),
          ],
        );
      },
    );
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

  Future<void> _onUpdatePressed() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _triedSubmit = true);

    // 🔴 FIX (kifma tlab: "les services nhbhom fi des titre... ken yhb
    // yzid service ekher") - validation/payload tawa mel ServiceCategorySelector
    // (widget partagé, chraht fel widgets/service_category_selector.dart).
    final selectorState = _serviceSelectorKey.currentState!;
    selectorState.markTriedSubmit();
    final String? servicesErrorKey = selectorState.validate();
    if (servicesErrorKey != null) {
      showMessageDialog(context, servicesErrorKey.tr());
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
      // 🔴 FIX (kifma tlab: "famma el emplacement wel genre neksin") -
      // kanou ma yeb3thouch khaless (submitProfile ma3andouch hedhom
      // fel appel, fa kol tبديل el sitter y3amlou fihom kan yenensa).
      location: (_selectedLat != null && _selectedLng != null) ? LatLng(_selectedLat!, _selectedLng!) : null,
      locationName: _locationName,
      gender: _selectedGender,
    );

    // 🔴 FIX (kifma tlabt): "el modification lkol nheb tetsajel" - el
    // services (zid/na77i/beddel price) tawa ye3ملهم PATCH 7a9i9i zeda
    // (bark el profile mch kafi).
    final List<Map<String, dynamic>> servicesPayload = selectorState.getPayload();
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

                    // 🔴 FIX (kifma tlab: "famma el emplacement wel
                    // genre neksin") - Gender (kanet mawjouda GHIR fel
                    // update_profile_owner.dart).
                    _fieldLabel('gender_label'.tr(), sizes),
                    SizedBox(height: sizes.screenHeight * 0.008),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _selectedGender = 'female'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _selectedGender == 'female' ? AppColors.pinkpetsy.withOpacity(0.15) : null,
                              side: BorderSide(color: _selectedGender == 'female' ? AppColors.pinkpetsy : AppColors.pinkpetsy.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.016),
                            ),
                            child: Text('female_label'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        SizedBox(width: sizes.screenWidth * 0.03),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _selectedGender = 'male'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _selectedGender == 'male' ? AppColors.pinkpetsy.withOpacity(0.15) : null,
                              side: BorderSide(color: _selectedGender == 'male' ? AppColors.pinkpetsy : AppColors.pinkpetsy.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.016),
                            ),
                            child: Text('male_label'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
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

                    // 🔴 FIX (kifma tlab: "famma el emplacement... neksin")
                    // - Localization (khariita) - kanet mawjouda GHIR
                    // fel update_profile_owner.dart.
                    _fieldLabel('localization_label'.tr(), sizes),
                    SizedBox(height: sizes.screenHeight * 0.008),
                    TextFormField(
                      controller: _locationController,
                      readOnly: true,
                      onTap: _pickLocation,
                      decoration: _fieldDecoration(context: context, suffixIcon: Icon(Icons.map_outlined, color: AppColors.pinkpetsy.withOpacity(0.7))),
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
                    // 🔴 FIX (kifma tlab: "les services nhbhom fi des
                    // titre... ken yhb yzid service ekher") - categories
                    // accordion + "Autre" (ServiceCategorySelector, widget
                    // partagé m3a create_sitter_profile.dart).
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
                      child: ServiceCategorySelector(key: _serviceSelectorKey, initialServices: p.services),
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