import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../constants/app_colors.dart';
import '../../widgets/back_button.dart';
import '../../widgets/button.dart';
import '../../widgets/paw_widget.dart';
import '../../widgets/map.dart';
import '../../widgets/photo_crop_screen.dart';
import '../../controllers/user_create_profile_controller.dart';
import '../../controllers/auth_session.dart';
import '../../services/api_service.dart';
import 'owner/create_pet_profile.dart';
import 'sitter/create_sitter_profile.dart';

// ============================================================================
// UserCreateProfileScreen
// ============================================================================
class UserCreateProfileScreen extends StatefulWidget {
  final String role;

  const UserCreateProfileScreen({super.key, required this.role});

  @override
  State<UserCreateProfileScreen> createState() => _UserCreateProfileScreenState();
}

class _UserCreateProfileScreenState extends State<UserCreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // 🔵 ZID: el "raw" ar9am tel phone (bla "+216 " prefix/spaces) - houwa
  // elli el backend/écrans l'okhrin (booking_details.dart, request.dart...)
  // yentaظrouh (8 ar9am bark, nafs el convention el 9dima).
  String get _rawPhoneDigits {
    String digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('216')) digits = digits.substring(3);
    return digits;
  }
  final TextEditingController _aboutController = TextEditingController();
  // 🔵 ZID houni: text elli yban fel 7a9el "Localization" (mch el user
  // yekteb fih, ghir yban feh el coordonnées ba3d ma y5tar mel khariita)
  final TextEditingController _locationController = TextEditingController();

  // 🔵 el LatLng el 7a9i9i (elli bch tab3ath lel backend) - el
  // controller (fouq) howa ghir "l3arda" (display), houni el data.
  LatLng? _selectedLocation;
  // 🔴 FIX: kanet na9sa - esm el blasa (bel 7arf, mch ghir lat/lng)
  // mel reverse-geocoding (widgets/map.dart).
  String? _locationName;

  // 🔵 ZID (kifma tlabt): Gender - "male"/"female" wela null (mazel
  // ma5tarch).
  String? _selectedGender;

  final UserCreateProfileController _profileController = UserCreateProfileController();
  bool _isSubmitting = false;

  // --------------------------------------------------------------------
  // 🔵 ZID (kifma tlab): "el esm unique kima el insta" - check LIVE
  // (debounced, 500ms ba3d ma el user yew9ef yekteb) ki el esm disponible
  // wla le. null = mazel ma tchekkatch (wela el esm 9asser barcha/vide).
  // --------------------------------------------------------------------
  Timer? _nameCheckDebounce;
  bool _checkingName = false;
  bool? _nameAvailable;
  String? _lastCheckedName;

  // --------------------------------------------------------------------
  // 🔵 el photo: Uint8List (bytes), MCH "File" (dart:io). 3lech? 7it
  // "dart:io" ma te5demch fel Flutter WEB (el app tejri fel Chrome fel
  // testing tou3ek) - Uint8List + Image.memory() khadmin fel mobile
  // W el web bla farq.
  // --------------------------------------------------------------------
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    // 🔵 ZID (kifma tlab): "+216" yban men el bidaya (mch bark ki el
    // user ybda yekteb) - cursor mba3d el prefix direct.
    _phoneController.value = const TextEditingValue(
      text: '+216 ',
      selection: TextSelection.collapsed(offset: 5),
    );
  }

  void _onNameChanged() {
    final String name = _nameController.text.trim();
    _nameCheckDebounce?.cancel();

    // 🔵 esm 9asser barcha (mathalan 7arf wa7ed) wela vide - ma nchekkouch,
    // n5aliw el état "neutre" (bla check icon).
    if (name.length < 2) {
      setState(() {
        _checkingName = false;
        _nameAvailable = null;
        _lastCheckedName = null;
      });
      return;
    }

    setState(() => _checkingName = true);
    _nameCheckDebounce = Timer(const Duration(milliseconds: 500), () async {
      final available = await _profileController.checkNameAvailability(name);
      if (!mounted) return;
      // 🔵 el user ynajjam ykemmel yekteb wa9t el appel - nchekkou el
      // esm mazel nafsou 9bal ma nesta3mlou el réponse (bla ha, réponse
      // batia ynajjam ye5ta3 el état 3ala esm jdid).
      if (_nameController.text.trim() != name) return;
      setState(() {
        _checkingName = false;
        _nameAvailable = available;
        _lastCheckedName = name;
      });
    });
  }

  @override
  void dispose() {
    _nameCheckDebounce?.cancel();
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _birthdayController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------
  // Photo: ki tdouss 3al badge camera, twarri bottom sheet fiha "Galerie"
  // w "Appareil photo" - el user y5tar mnin.
  // --------------------------------------------------------------------
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
      if (picked == null) return; // el user 3ellel (cancel)

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      // 🔴 FIX (kifma tlab): "kima el insta" - 9bal ma nesta3mlouha
      // direct, el user y'eddi (drag) w y-zoumi bch ye5tar chnou el
      // jozz elli yban. Lowkan "Cancel" (null) - n5alliw el photo el
      // 9dima (lowkan mawjouda) bla ma nbeddlouha.
      final cropped = await PhotoCropScreen.show(context, bytes);
      if (!mounted || cropped == null) return;
      setState(() => _profileImageBytes = cropped);
    } catch (_) {
      // 🔵 ZID: lowkan el user rafedh el permission (kamera/galerie),
      // wala 5ata fel plugin - nwarriw SnackBar bdal ma l'app te-crash
      // wala teskot bla ay rasala.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('photo_pick_error'.tr())),
      );
    }
  }

  // --------------------------------------------------------------------
  // Localization: yeftah LocationPickerScreen (widgets/map.dart) -
  // "await Navigator.push<LatLng>" ken el écran ba3ed ma yet7al yerja3
  // "value" (bel "pop(value)"), n7ottouha houni fel "result".
  // --------------------------------------------------------------------
  Future<void> _pickLocation() async {
    final LocationResult? result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLocation: _selectedLocation),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result.latLng;
        // 🔴 FIX: kanet twarri ghir "lat, lng" (coordonnées) - tawa
        // esm el blasa 7a9i9i (reverse-geocoding, mel LocationPickerScreen).
        _locationName = result.placeName;
        _locationController.text = result.placeName;
      });

      // 🔵 ZID (kifma tlabt): ken el location el mkhtara fi wilaya
      // MO5TALFA 3an el "City" el mkhtara déjà, nbaddlouha automatique
      // + nwarriw popup (bch el user y3ref 3lech tbaddlet, mch tetbaddel
      // "b'sokot").
      final String? matchedGovernorate = matchTunisianGovernorate(result.rawStateName);
      debugPrint('🗺️ [_pickLocation] rawStateName="${result.rawStateName}" matchedGovernorate="$matchedGovernorate" currentCity="${_cityController.text}"');
      if (matchedGovernorate != null && matchedGovernorate != _cityController.text && mounted) {
        final String oldCity = _cityController.text;
        setState(() => _cityController.text = matchedGovernorate);
        // 🔵 el popup ghir lowkan kan 3andou city mkhtara déjà (mch
        // el loula marra, wa9tha "badalna" 7aja mch mawjouda asasan).
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

  // --------------------------------------------------------------------
  // City: mch TextField 3adi - bottom sheet feha 24 wilaya, el user
  // y5tar mnhom, mayekteich b'yedou.
  // --------------------------------------------------------------------
  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final screenSize = MediaQuery.of(context).size;
        return SafeArea(
          child: SizedBox(
            height: screenSize.height * 0.6,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(screenSize.width * 0.04),
                  child: Text(
                    'select_city_title'.tr(),
                    style: TextStyle(
                      fontSize: screenSize.width * 0.045,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pinkpetsy,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: tunisiaGovernorates.length,
                    itemBuilder: (context, index) {
                      final governorate = tunisiaGovernorates[index];
                      return ListTile(
                        title: Text(governorate),
                        onTap: () {
                          setState(() => _cityController.text = governorate);
                          Navigator.pop(sheetContext);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Future<void> _onNextPressed() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await _profileController.submitProfile(
      role: widget.role,
      name: _nameController.text,
      birthday: _birthdayController.text,
      city: _cityController.text,
      // 🔴 FIX (kifma tlab): el 7a9el tawa formaté ("+216 XX XXX XXX")
      // lel USER bark - el backend w el ba9i tel écrans (booking_
      // details.dart, request.dart...) yentaظرou 8 ar9am bark (bla
      // prefix/spaces) - n7ottou el "raw" houni.
      phone: _rawPhoneDigits,
      aboutYou: _aboutController.text,
      location: _selectedLocation,
      locationName: _locationName,
      gender: _selectedGender,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      // 🔵 ZID: filet de sécurité - lowkan el check live ma l7e9ch
      // (mathalan submit sri3 barcha) w el backend rafedh (esm meakhoud
      // entre temps), n3allmou el user (mch ne5liwha silence kifma
      // kanet 9bal).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile_submit_error'.tr())),
      );
      return;
    }

    // 🔵 ZID: print UNCONDITIONNEL - bch nchoufou ken el code el jdid
    // ye5dem khaless (ken ma bench, lezem hot restart 'R'), w ken el
    // guard (_profileImageBytes/userId) howa elli null.
    debugPrint('🟣 [UserCreateProfile._onNextPressed] hasPhoto=${_profileImageBytes != null} userId=${AuthSession.userId}');

    // 🔵 sa77e7t el bug el kbir: houni kanet el photo (avatar el user)
    // ma tetba3thech lel backend KHALESS (mafamech 7atta appel) - kanet
    // tab9a fel mémoire bess (bytes) w tsafer bin el écrans bch tban
    // fel UI, lakin el fichier 3omrou ma yousel l'uploads/users/ 7a9i9i.
    // Tawa: appel 7a9i9i, ba3d ma el profile (fullName/city/...) yetsajel.
    if (_profileImageBytes != null && AuthSession.userId != null) {
      try {
        final response = await ApiService.uploadPhoto(
          '/users/${AuthSession.userId}/photo',
          _profileImageBytes!,
          token: AuthSession.token,
        );
        if (response.statusCode != 200) {
          // 🔵 ZID: dima kan el catch fadhi (silence) - mch nnajmou
          // nchoufou 3lech el upload yefchel. Tawa yban fel terminal
          // (flutter run console) 3ala 9al ma tsir.
          debugPrint('⚠️ [uploadUserPhoto] status ${response.statusCode}: ${response.body}');
        }
      } catch (error) {
        debugPrint('⚠️ [uploadUserPhoto] exception: $error');
        // 🔵 ma ne7bsouch el flow (l'user yekmel l'CreatePetProfileScreen
        // 7ata lowkan el photo ma etle3tech) - ghir n-logguiw bch nnajmou
        // nchoufou el ghalta el marra el jaya.
      }
    }

    // 🔵 ZID houni: lowkan el role "owner", nemchiw l'écran PetProfileScreen
    // (bch yzid pets tou3ou). "sitter" -> CreateSitterProfileScreen (el
    // 2 écrans el jdad: services+prices, mba3d home&transport). "courier"
    // mazel TODO (home mte3ou).
    if (widget.role == 'owner') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreatePetProfileScreen(
            ownerName: _nameController.text,
            ownerCity: _cityController.text,
            // 🔵 ZID: el photo mkhtara houni (avatar picker fou9) kanet
            // tedhi3 (ma tab3athech lel écrans elli baadha) - tاوة تسافر.
            ownerPhotoBytes: _profileImageBytes,
          ),
        ),
      );
    } else if (widget.role == 'sitter') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateSitterProfileScreen(
            sitterName: _nameController.text,
            sitterCity: _cityController.text,
            sitterPhotoBytes: _profileImageBytes,
          ),
        ),
      );
    } else {
      // TODO: navigation lel home mte3 el role (widget.role) - courier
    }
  }

  InputDecoration _fieldDecoration({required BuildContext context, Widget? suffixIcon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.pinkpetsy.withOpacity(0.5)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.pinkpetsy, width: 1.8),
      ),
      // 🔵 msg el 5ata: border a7mar + text a7mar explicite (bch tban
      // "en rouge" akid, mch tetrak lel Theme el default)
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
      errorStyle: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
    );
  }

  Widget _fieldLabel(String text, double screenWidth) {
    return Text(
      text,
      style: TextStyle(
        fontSize: screenWidth * 0.037,
        fontWeight: FontWeight.bold,
        color: AppColors.pinkpetsy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            buildPetPaw(context: context, size: screenSize.width * 0.09, topPercent: 0.025, leftPercent: 0.80, color: AppColors.pinkpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: screenSize.width * 0.065, topPercent: 0.06, leftPercent: 0.88, color: AppColors.pinkpetsy.withOpacity(0.6)),

            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: screenSize.height * 0.09),

                    Center(
                      child: Text(
                        'create_profile_title'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenSize.width * 0.052,
                          fontWeight: FontWeight.bold,
                          color: AppColors.vertpetsy,
                        ),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.004),
                    Center(
                      child: Text(
                        'create_profile_subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenSize.width * 0.046,
                          fontWeight: FontWeight.bold,
                          color: AppColors.pinkpetsy,
                        ),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.03),

                    // 📷 Avatar + badge camera -> el bottom sheet (Galerie/Camera)
                    Center(
                      child: GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: screenSize.width * 0.14,
                              backgroundColor: AppColors.vertpetsy.withOpacity(0.15),
                              // lowkan 3andna photo mkhtara, twarriha; lowkan
                              // le, el icon el default el shakhs (person)
                              backgroundImage: _profileImageBytes != null ? MemoryImage(_profileImageBytes!) : null,
                              child: _profileImageBytes == null
                                  ? Icon(Icons.person, size: screenSize.width * 0.16, color: Colors.black87)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: screenSize.width * 0.005,
                              child: Container(
                                width: screenSize.width * 0.09,
                                height: screenSize.width * 0.09,
                                decoration: BoxDecoration(
                                  color: AppColors.vertpetsy,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2.5),
                                ),
                                child: Icon(Icons.camera_alt, size: screenSize.width * 0.045, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.012),

                    Center(
                      child: Text(
                        'add_photo_label'.tr(),
                        style: TextStyle(
                          fontSize: screenSize.width * 0.036,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.035),

                    // Name
                    _fieldLabel('name_label'.tr(), screenSize.width),
                    SizedBox(height: screenSize.height * 0.008),
                    TextFormField(
                      controller: _nameController,
                      validator: (value) {
                        final baseError = ProfileValidators.name(value);
                        if (baseError != null) return baseError;
                        // 🔵 el submit ma ykemmelch lowkan el esm meakhoud
                        // (chekkatnah live) - blastha nban rasala ta7t el
                        // 7a9el (kifma el mockup insta).
                        if (_nameAvailable == false && _lastCheckedName == value?.trim()) {
                          return 'name_taken_error'.tr();
                        }
                        return null;
                      },
                      decoration: _fieldDecoration(
                        context: context,
                        suffixIcon: _checkingName
                            ? Padding(
                                padding: EdgeInsets.all(screenSize.width * 0.035),
                                child: SizedBox(
                                  width: screenSize.width * 0.04,
                                  height: screenSize.width * 0.04,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.vertpetsy),
                                ),
                              )
                            : (_nameAvailable != null && _lastCheckedName == _nameController.text.trim())
                                ? Icon(
                                    _nameAvailable == true ? Icons.check_circle : Icons.cancel,
                                    color: _nameAvailable == true ? AppColors.success : AppColors.error,
                                  )
                                : null,
                      ),
                    ),
                    // 🔵 ZID (kifma tlab): rasala ta7t el 7a9el (mch bess
                    // el icon) - "disponible" (vert) wela "meakhoud" (a7mar),
                    // nafs mant9 el insta/fb.
                    if (!_checkingName && _nameAvailable != null && _lastCheckedName == _nameController.text.trim()) ...[
                      SizedBox(height: screenSize.height * 0.006),
                      Text(
                        _nameAvailable == true ? 'name_available_label'.tr() : 'name_taken_error'.tr(),
                        style: TextStyle(
                          fontSize: screenSize.width * 0.03,
                          color: _nameAvailable == true ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    SizedBox(height: screenSize.height * 0.02),

                    // Birthday
                    _fieldLabel('birthday_label'.tr(), screenSize.width),
                    SizedBox(height: screenSize.height * 0.008),
                    TextFormField(
                      controller: _birthdayController,
                      readOnly: true,
                      onTap: _pickBirthday,
                      decoration: _fieldDecoration(
                        context: context,
                        suffixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.pinkpetsy.withOpacity(0.7), size: screenSize.width * 0.05),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.02),

                    // 🔵 ZID (kifma tlabt): Gender - 2 boutons (Male/Female),
                    // choix wa7ed bark (nafs el pattern tel pet gender fi
                    // create_pet_profile.dart).
                    _fieldLabel('gender_label'.tr(), screenSize.width),
                    SizedBox(height: screenSize.height * 0.008),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _selectedGender = 'female'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _selectedGender == 'female' ? AppColors.pinkpetsy.withOpacity(0.15) : null,
                              side: BorderSide(color: _selectedGender == 'female' ? AppColors.pinkpetsy : AppColors.pinkpetsy.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.016),
                            ),
                            child: Text('female_label'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        SizedBox(width: screenSize.width * 0.03),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _selectedGender = 'male'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _selectedGender == 'male' ? AppColors.pinkpetsy.withOpacity(0.15) : null,
                              side: BorderSide(color: _selectedGender == 'male' ? AppColors.pinkpetsy : AppColors.pinkpetsy.withValues(alpha: 0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.016),
                            ),
                            child: Text('male_label'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: screenSize.height * 0.02),

                    // 🔴 FIX (kifma tlab): "Localization" tawa 9bal
                    // "City" (mch ba3دها) - Localization -> yeftah el
                    // khariita (widgets/map.dart)
                    _fieldLabel('localization_label'.tr(), screenSize.width),
                    SizedBox(height: screenSize.height * 0.008),
                    TextFormField(
                      controller: _locationController,
                      readOnly: true,
                      onTap: _pickLocation,
                      decoration: _fieldDecoration(
                        context: context,
                        suffixIcon: Icon(Icons.map_outlined, color: AppColors.pinkpetsy.withOpacity(0.7), size: screenSize.width * 0.05),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.02),

                    // City -> bottom sheet bel 24 wilaya (mch TextField 3adi)
                    _fieldLabel('city_label'.tr(), screenSize.width),
                    SizedBox(height: screenSize.height * 0.008),
                    TextFormField(
                      controller: _cityController,
                      readOnly: true,
                      onTap: _showCityPicker,
                      decoration: _fieldDecoration(
                        context: context,
                        suffixIcon: Icon(Icons.location_on_outlined, color: AppColors.pinkpetsy.withOpacity(0.7), size: screenSize.width * 0.05),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.02),

                    // Phone Number -> "+216 XX XXX XXX" (kifma tlab) -
                    // el user yekteb ar9am bark, el prefix+spaces
                    // yet7otou automatique.
                    _fieldLabel('phone_number_label'.tr(), screenSize.width),
                    SizedBox(height: screenSize.height * 0.008),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_TunisianPhoneFormatter()],
                      validator: ProfileValidators.phone,
                      decoration: _fieldDecoration(context: context),
                    ),

                    SizedBox(height: screenSize.height * 0.02),

                    // About you -> obligatoire GHIR lel sitter/courier
                    _fieldLabel('about_you_label'.tr(), screenSize.width),
                    SizedBox(height: screenSize.height * 0.008),
                    TextFormField(
                      controller: _aboutController,
                      maxLines: 4,
                      validator: (value) => ProfileValidators.aboutYou(value, widget.role),
                      decoration: _fieldDecoration(context: context),
                    ),

                    SizedBox(height: screenSize.height * 0.04),

                    Center(
                      child: CustomButton(
                        text: _isSubmitting ? 'loading_label'.tr() : 'next_button'.tr(),
                        color: AppColors.pinkpetsy,
                        widthFactor: 0.90,
                        heightFactor: 0.07,
                        fontFactor: 0.40,
                        enabled: !_isSubmitting,
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

// ============================================================================
// _TunisianPhoneFormatter
// ============================================================================
// 🔵 ZID (kifma tlab): "+216 [espace] 2num [espace] 3num [espace] 3num"
// - ki el user yekteb ar9am bark, el prefix "+216 " w el spaces (2-3-3)
// yet7otou automatique. El "raw" (bla formatting) yousel mel getter
// "_rawPhoneDigits" (fou9) - houni bark UI/UX, mch data 7a9i9iya.
// ============================================================================
class _TunisianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('216')) digits = digits.substring(3);
    if (digits.length > 8) digits = digits.substring(0, 8);

    final StringBuffer buffer = StringBuffer('+216 ');
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i == 1 || i == 4) && i != digits.length - 1) buffer.write(' ');
    }
    final String formatted = buffer.toString();

    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}