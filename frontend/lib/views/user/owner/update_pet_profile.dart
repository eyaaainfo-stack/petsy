import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../models/pet_summary.dart';
import '../../../controllers/update_pet_profile_controller.dart';
import '../../../controllers/auth_session.dart';
import '../../../services/api_service.dart';
import '../../../widgets/message_dialog.dart';

// ============================================================================
// UpdatePetProfileScreen ("Update Pet Profile")
// ============================================================================
// 🔵 Wsulha mel bouton stylo fel PetProfileScreen (pet_profile.dart) -
// form m3amra mel data el 7aliya tel pet. Ki el user ydouss "Update",
// PATCH 7a9i9i (/api/pets/:petId), w el écran yerja3 (pop) b'el
// PetSummary el jdid (bch PetProfileScreen ye3mel rebuild b'el data
// el jdida, bla ma ye7taj refetch el liste kaملha).
//
// 🔵 REMARQUE: el mockup elli b3aththa fiha "Birthday" (date) - el
// data model el 7ali 3andou "Age" bark (raqam, mch date), fa 5deمt
// "Age" (nafs el data elli mawjouda déjà fel create_pet_profile.dart/
// pet_profile.dart) bch ma nbeddelch el schema el kamel bla ma
// tetlobha explicitement. Ken t7eb "Birthday" 7a9i9i, 9olli w nbeddel.
// ============================================================================
class UpdatePetProfileScreen extends StatefulWidget {
  final PetSummary pet;

  const UpdatePetProfileScreen({super.key, required this.pet});

  @override
  State<UpdatePetProfileScreen> createState() => _UpdatePetProfileScreenState();
}

class _UpdatePetProfileScreenState extends State<UpdatePetProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _breedController;
  late final TextEditingController _sizeController;
  late final TextEditingController _clinicNameController;
  late final TextEditingController _clinicPhoneController;

  late String _selectedGender; // 'female' / 'male'
  late Set<String> _selectedBehaviors;
  late Map<String, bool> _careInfo;
  Uint8List? _newPhotoBytes;

  final UpdatePetProfileController _controller = UpdatePetProfileController();
  bool _isSubmitting = false;

  static const List<String> _behaviorKeys = [
    'behavior_scared_new_people',
    'behavior_calm',
    'behavior_scared_animals',
    'behavior_active',
    'behavior_friendly',
    'behavior_angry',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.pet;
    _nameController = TextEditingController(text: p.name);
    _ageController = TextEditingController(text: p.age ?? '');
    _breedController = TextEditingController(text: p.breed ?? '');
    _sizeController = TextEditingController(text: p.size ?? '');
    _clinicNameController = TextEditingController(text: p.vetClinicName ?? '');
    _clinicPhoneController = TextEditingController(text: p.vetClinicPhone ?? '');
    _selectedGender = p.gender ?? 'female';
    _selectedBehaviors = Set.of(p.behaviors);
    _careInfo = {
      'microchipped': p.careInfo['microchipped'] ?? false,
      'vaccinated': p.careInfo['vaccinated'] ?? false,
      'neutered': p.careInfo['neutered'] ?? false,
      'medication': p.careInfo['medication'] ?? false,
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _breedController.dispose();
    _sizeController.dispose();
    _clinicNameController.dispose();
    _clinicPhoneController.dispose();
    super.dispose();
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
      showMessageDialog(context, 'photo_pick_error'.tr());
    }
  }

  Future<void> _onUpdatePressed() async {
    if (_isSubmitting) return;
    if (widget.pet.id == null) return; // 🔵 mafamech _id (ma yenajjamch ykoun) - safety net

    setState(() => _isSubmitting = true);

    final bool success = await _controller.updatePet(
      petId: widget.pet.id!,
      name: _nameController.text,
      age: _ageController.text,
      breed: _breedController.text,
      size: _sizeController.text,
      gender: _selectedGender,
      behaviors: _selectedBehaviors.toList(),
      careInfo: _careInfo,
      vetClinicName: _clinicNameController.text,
      vetClinicPhone: _clinicPhoneController.text,
    );

    // 🔵 photo: appel mnfassel bark lowkan el user 5tar photo jdida.
    bool photoSuccess = true;
    if (_newPhotoBytes != null) {
      try {
        final response = await ApiService.uploadPhoto(
          '/pets/${widget.pet.id}/photo',
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

    if (!success || !photoSuccess) {
      showMessageDialog(context, 'login_generic_error'.tr());
      return;
    }

    // 🔵 nrajj3ou PetSummary el JDID (bch PetProfileScreen y3amel
    // rebuild direct, bla ma ye7taj refetch el liste kaملha).
    final updatedPet = PetSummary(
      id: widget.pet.id,
      name: _nameController.text,
      petType: widget.pet.petType,
      photoBytes: _newPhotoBytes ?? widget.pet.photoBytes,
      photoUrl: _newPhotoBytes != null ? null : widget.pet.photoUrl,
      age: _ageController.text,
      breed: _breedController.text,
      size: _sizeController.text,
      gender: _selectedGender,
      behaviors: _selectedBehaviors.toList(),
      careInfo: _careInfo,
      vetClinicName: _clinicNameController.text,
      vetClinicPhone: _clinicPhoneController.text,
    );

    if (!mounted) return;
    Navigator.of(context).pop(updatedPet);
  }

  Widget _editableRow({required String label, required TextEditingController controller, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    final sizes = AppSizes.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizes.updatePetFieldGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: sizes.screenWidth * 0.28,
            child: Text(label, style: TextStyle(color: AppColors.pinkpetsy, fontSize: sizes.updatePetLabelFontSize)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.end,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: TextStyle(fontSize: sizes.updatePetValueFontSize, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.006),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.pinkpetsy.withOpacity(0.35))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.pinkpetsy, width: 1.6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _staticRow({required String label, required String value}) {
    final sizes = AppSizes.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizes.updatePetFieldGap),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: AppColors.pinkpetsy, fontSize: sizes.updatePetLabelFontSize))),
          Text(value, style: TextStyle(fontSize: sizes.updatePetValueFontSize, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ----------------------------------------------------------
              // Banner teal (back + title + paws), kifha kif el mockup
              // ----------------------------------------------------------
              Container(
                height: sizes.updatePetBannerHeight,
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: sizes.updatePetHorizontalPadding),
                decoration: BoxDecoration(
                  color: AppColors.vertpetsy,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: sizes.screenHeight * 0.01,
                      right: sizes.screenWidth * 0.02,
                      child: Icon(Icons.pets, color: Colors.white.withOpacity(0.6), size: sizes.updatePetPawSize),
                    ),
                    Positioned(
                      top: sizes.screenHeight * 0.045,
                      right: sizes.screenWidth * 0.10,
                      child: Icon(Icons.pets, color: Colors.white.withOpacity(0.4), size: sizes.updatePetPawSize * 0.75),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          ),
                          Text(
                            'update_pet_profile_title'.tr(),
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.updatePetTitleFontSize),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ----------------------------------------------------------
              // Photo + stylo
              // ----------------------------------------------------------
              SizedBox(height: sizes.updatePetSectionGap),
              Center(
                child: GestureDetector(
                  onTap: _showPhotoSourceSheet,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipOval(
                        child: Container(
                          width: sizes.updatePetPhotoSize,
                          height: sizes.updatePetPhotoSize,
                          color: AppColors.vertpetsy.withOpacity(0.15),
                          child: _newPhotoBytes != null
                              ? Image.memory(_newPhotoBytes!, fit: BoxFit.cover)
                              : widget.pet.photoUrl != null
                                  ? Image.network(widget.pet.photoUrl!, fit: BoxFit.cover)
                                  : Icon(widget.pet.icon, color: AppColors.vertpetsy, size: sizes.updatePetPhotoSize * 0.5),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: sizes.screenWidth * 0.02,
                        child: Container(
                          padding: EdgeInsets.all(sizes.screenWidth * 0.018),
                          decoration: BoxDecoration(color: AppColors.vertpetsy, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)),
                          child: Icon(Icons.edit, color: Colors.white, size: sizes.screenWidth * 0.04),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ----------------------------------------------------------
              // Champs (label rose + valeur, ligne rose ta7tha)
              // ----------------------------------------------------------
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sizes.updatePetHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: sizes.updatePetSectionGap),

                    _editableRow(label: 'name_label'.tr(), controller: _nameController),
                    _staticRow(label: 'pet_type_label'.tr(), value: widget.pet.petType == 'cat' ? 'Cat' : 'Dog'),
                    _editableRow(label: 'pet_breed_label'.tr(), controller: _breedController),

                    // Sex: 2 boutons Female/Male (mch text 3adi, bch
                    // ykoun editable 7a9i9atan)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: sizes.updatePetFieldGap),
                      child: Row(
                        children: [
                          SizedBox(
                            width: sizes.screenWidth * 0.28,
                            child: Text('gender_label'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontSize: sizes.updatePetLabelFontSize)),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ChoiceChip(
                                  label: Text('female_label'.tr()),
                                  selected: _selectedGender == 'female',
                                  onSelected: (_) => setState(() => _selectedGender = 'female'),
                                  selectedColor: AppColors.pinkpetsy.withOpacity(0.25),
                                ),
                                SizedBox(width: sizes.screenWidth * 0.02),
                                ChoiceChip(
                                  label: Text('male_label'.tr()),
                                  selected: _selectedGender == 'male',
                                  onSelected: (_) => setState(() => _selectedGender = 'male'),
                                  selectedColor: AppColors.pinkpetsy.withOpacity(0.25),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    _editableRow(label: 'pet_age_label'.tr(), controller: _ageController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    _editableRow(label: 'weight_kg_label'.tr(), controller: _sizeController, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]),

                    SizedBox(height: sizes.updatePetSectionGap),

                    // Behaviors (chips, multi-select)
                    Text('pet_behavior_include_label'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontSize: sizes.updatePetLabelFontSize)),
                    SizedBox(height: sizes.updatePetFieldGap),
                    Wrap(
                      spacing: sizes.screenWidth * 0.025,
                      runSpacing: sizes.screenHeight * 0.012,
                      children: _behaviorKeys.map((key) {
                        final bool isSelected = _selectedBehaviors.contains(key);
                        return ChoiceChip(
                          label: Text(key.tr()),
                          selected: isSelected,
                          selectedColor: AppColors.vertpetsy.withOpacity(0.25),
                          onSelected: (_) => setState(() {
                            if (!_selectedBehaviors.remove(key)) _selectedBehaviors.add(key);
                          }),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: sizes.updatePetSectionGap),

                    // Care info (Yes/No, 4 items)
                    Text('care_info_label'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontSize: sizes.updatePetLabelFontSize)),
                    SizedBox(height: sizes.updatePetFieldGap),
                    Row(
                      children: [
                        const Expanded(flex: 2, child: SizedBox()),
                        Expanded(child: Center(child: Text('yes_label'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold)))),
                        Expanded(child: Center(child: Text('no_label'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold)))),
                      ],
                    ),
                    _careInfoToggleRow('microchipped_label'.tr(), 'microchipped', sizes),
                    _careInfoToggleRow('vaccinated_label'.tr(), 'vaccinated', sizes),
                    _careInfoToggleRow('neutered_label'.tr(), 'neutered', sizes),
                    _careInfoToggleRow('medication_label'.tr(), 'medication', sizes),

                    SizedBox(height: sizes.updatePetSectionGap),

                    _editableRow(label: 'clinic_name_label'.tr(), controller: _clinicNameController),
                    _editableRow(label: 'phone_number_label'.tr(), controller: _clinicPhoneController, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),

                    SizedBox(height: sizes.updatePetSectionGap * 1.5),

                    SizedBox(
                      width: double.infinity,
                      height: sizes.screenHeight * 0.065,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _onUpdatePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pinkpetsy,
                          disabledBackgroundColor: AppColors.pinkpetsy.withOpacity(0.6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: Text(
                          _isSubmitting ? 'loading_label'.tr() : 'update_button'.tr(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    SizedBox(height: sizes.updatePetSectionGap),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _careInfoToggleRow(String label, String key, AppSizes sizes) {
    final bool value = _careInfo[key] ?? false;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.006),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(fontSize: sizes.updatePetValueFontSize))),
          Expanded(
            child: Center(
              child: Radio<bool>(
                value: true,
                groupValue: value,
                activeColor: AppColors.pinkpetsy,
                onChanged: (_) => setState(() => _careInfo[key] = true),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Radio<bool>(
                value: false,
                groupValue: value,
                activeColor: AppColors.pinkpetsy,
                onChanged: (_) => setState(() => _careInfo[key] = false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}