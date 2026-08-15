import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/button.dart';
import '../../../controllers/create_pet_profile_controller.dart';
import '../../../models/pet_summary.dart';
import 'create_pet_profile_2.dart';

// ============================================================================
// CreatePetProfileScreen
// ============================================================================
// Écran khass BISS bel "owner" (yji ba3d UserCreateProfileScreen lowkan
// widget.role == 'owner'). Design houni yesta3mel TEAL (vertpetsy) kel
// loun principal - mch pink kifha kif el écrans l'okhrin.
// ============================================================================
enum PetType { dog, cat }

class CreatePetProfileScreen extends StatefulWidget {
  // 🔵 ZID: bch el esm/blasa tel owner (w el pets elli déjà tzadou)
  // ykamlou ysafrou m3a el flow kaملha, lel a5er ProfileOwnerScreen.
  final String ownerName;
  final String ownerCity;
  final List<PetSummary> existingPets;
  // 🔵 ZID: el photo tel owner (mkhtara fel UserCreateProfileScreen) -
  // kanet tedhi3 houni, tاوة تسافر kaملها.
  final Uint8List? ownerPhotoBytes;

  const CreatePetProfileScreen({
    super.key,
    required this.ownerName,
    required this.ownerCity,
    this.existingPets = const [],
    this.ownerPhotoBytes,
  });

  @override
  State<CreatePetProfileScreen> createState() => _CreatePetProfileScreenState();
}

class _CreatePetProfileScreenState extends State<CreatePetProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();

  final CreatePetProfileController _controller = CreatePetProfileController();

  PetType? _selectedPetType;
  String? _selectedGender; // 'female' wala 'male'
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _breedController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> _onNextPressed() async {
    if (_isSubmitting) return;

    if (_selectedPetType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('pet_type_required_error'.tr())),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await _controller.submitPetProfile(
      petType: _selectedPetType == PetType.dog ? 'dog' : 'cat',
      name: _nameController.text,
      age: _ageController.text,
      breed: _breedController.text,
      size: _sizeController.text,
      gender: _selectedGender,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      // 🔵 ZID houni: nemchiw l'écran CreatePetProfile2Screen (behavior/care)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreatePetProfile2Screen(
            petType: _selectedPetType == PetType.cat ? 'cat' : 'dog',
            ownerName: widget.ownerName,
            ownerCity: widget.ownerCity,
            petName: _nameController.text,
            existingPets: widget.existingPets,
            ownerPhotoBytes: widget.ownerPhotoBytes,
            // 🔵 ZID: kanou yedhi3ou houni (ma ysaferouch lel écrans
            // elli baadhom) - tاوة تسافر.
            petAge: _ageController.text,
            petBreed: _breedController.text,
            petSize: _sizeController.text,
            petGender: _selectedGender,
          ),
        ),
      );
    }
  }

  InputDecoration _fieldDecoration({required BuildContext context, String? suffixText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      // 🔵 suffixText: "ans" wala "kg" - Flutter ywarriha b'chekel natif
      // jowa el 7a9el (mch jozz mel text elli el user yekteb/yebda3thou),
      // bch nab9awou nnajmou nchekkou el ra9m b'sohoula (mch "5 ans" text).
      suffixText: suffixText,
      suffixStyle: TextStyle(color: AppColors.vertpetsy.withOpacity(0.8), fontWeight: FontWeight.w600),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.vertpetsy.withOpacity(0.6)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.vertpetsy, width: 1.8),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.error, width: 1.2),
      ),
      errorStyle: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
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

  Widget _buildPetTypeCard({
    required PetType type,
    required String imagePath,
    required String labelKey,
    required double screenWidth,
  }) {
    final bool isSelected = _selectedPetType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedPetType = type),
      child: Column(
        children: [
          Container(
            width: screenWidth * 0.30,
            height: screenWidth * 0.30,
            // 🔵 7ithna el padding elli kanet t5alli fasa5 bin el border
            // w el image (chrahtha: "yekhdo el bouton kamel").
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.vertpetsy : AppColors.pinkpetsy.withOpacity(0.5),
                width: isSelected ? 2.5 : 1.5,
              ),
            ),
            // 🔵 ClipRRect: bch el image tet9ass 3ala chekel el zawaya
            // mdawra (bla ClipRRect, el image tokhroj barra el zawaya).
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              // 🔵 BoxFit.cover (mch contain): el image tekhdem el
              // container KAMEL (tet9ass lowkan lezem), bla ay fasa5
              // fadhi (noir wla abyedh) yban.
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            labelKey.tr(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.030,
              color: Theme.of(context).textTheme.bodyLarge?.color,
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
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.07),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: screenSize.height * 0.09),

                    Text(
                      'pet_profile_title'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenSize.width * 0.052,
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

                    Text(
                      'pet_type_question'.tr(),
                      style: TextStyle(
                        fontSize: screenSize.width * 0.038,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.015),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPetTypeCard(
                          type: PetType.dog,
                          imagePath: 'assets/images/dog.png',
                          labelKey: 'dog_label',
                          screenWidth: screenSize.width,
                        ),
                        SizedBox(width: screenSize.width * 0.10),
                        _buildPetTypeCard(
                          type: PetType.cat,
                          imagePath: 'assets/images/cat.png',
                          labelKey: 'cat_label',
                          screenWidth: screenSize.width,
                        ),
                      ],
                    ),

                    SizedBox(height: screenSize.height * 0.035),

                    _fieldLabel('name_label'.tr(), screenSize.width),
                    SizedBox(height: screenSize.height * 0.008),
                    TextFormField(
                      controller: _nameController,
                      validator: PetProfileValidators.petName,
                      decoration: _fieldDecoration(context: context),
                    ),

                    SizedBox(height: screenSize.height * 0.02),

                    _fieldLabel('pet_age_label'.tr(), screenSize.width),
                    SizedBox(height: screenSize.height * 0.008),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      // 🔵 inputFormatters: TAWA fel 7a9i9a manna3in aya
                      // 7arf mch ra9m (mch bess "iken" el keyboard yban
                      // ar9am - el keyboardType wa7dou ma yem na3ch
                      // el user yekteb 7roufa fiziki ala PC/web).
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      // 🔵 el max ye5tlef bin dog/cat - houwa lil2an
                      // _selectedPetType déjà mena9ach ma yb9ach null
                      // (nchekkouh 9bal el validate() fel _onNextPressed)
                      validator: (value) => PetProfileValidators.petAge(
                        value,
                        _selectedPetType == PetType.cat ? 'cat' : 'dog',
                      ),
                      decoration: _fieldDecoration(context: context, suffixText: 'ans'),
                    ),

                    SizedBox(height: screenSize.height * 0.02),

                    _fieldLabel('pet_breed_label'.tr(), screenSize.width),
                    SizedBox(height: screenSize.height * 0.008),
                    TextFormField(
                      controller: _breedController,
                      decoration: _fieldDecoration(context: context),
                    ),

                    SizedBox(height: screenSize.height * 0.02),

                    _fieldLabel('pet_size_label'.tr(), screenSize.width),
                    SizedBox(height: screenSize.height * 0.008),
                    TextFormField(
                      controller: _sizeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      // ar9am + no9ta 3achariya wa7da bess
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      validator: (value) => PetProfileValidators.petSize(
                        value,
                        _selectedPetType == PetType.cat ? 'cat' : 'dog',
                      ),
                      decoration: _fieldDecoration(context: context, suffixText: 'kg'),
                    ),

                    SizedBox(height: screenSize.height * 0.025),

                    _fieldLabel('gender_label'.tr(), screenSize.width),
                    SizedBox(height: screenSize.height * 0.005),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'female',
                          groupValue: _selectedGender,
                          activeColor: AppColors.vertpetsy,
                          onChanged: (value) => setState(() => _selectedGender = value),
                        ),
                        Text('female_label'.tr()),
                        SizedBox(width: screenSize.width * 0.08),
                        Radio<String>(
                          value: 'male',
                          groupValue: _selectedGender,
                          activeColor: AppColors.vertpetsy,
                          onChanged: (value) => setState(() => _selectedGender = value),
                        ),
                        Text('male_label'.tr()),
                        const Spacer(),
                        Icon(Icons.pets, color: AppColors.pinkpetsy.withOpacity(0.7), size: screenSize.width * 0.06),
                      ],
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
            ),

            // 🔙 zdinaha HOUNI (lakher fel Stack) - chrahtha fel admin_login
            const CustomBackButton(),
          ],
        ),
      ),
    );
  }
}