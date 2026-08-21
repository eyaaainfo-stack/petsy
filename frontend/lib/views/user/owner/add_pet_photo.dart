import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/button.dart';
import '../../../widgets/outlined_button.dart';
import '../../../widgets/paw_widget.dart';
import '../../../models/pet_summary.dart';
import '../../../services/api_service.dart';
import '../../../controllers/auth_session.dart';
import 'create_pet_profile.dart';
import 'profile_owner.dart';

// ============================================================================
// AddPetPhotoScreen
// ============================================================================
// Yji ba3d CreatePetProfile2Screen. Nafs mant9 el photo picker mawjoud
// fel UserCreateProfileScreen (galerie/camera), ghir houni khass bel
// pet (mch bel user), w el placeholder (9bal ma tet5tar photo) ywarri
// dog.png/cat.png 3ala 7sab el petType.
// ============================================================================
class AddPetPhotoScreen extends StatefulWidget {
  final String petType; // 'dog' wala 'cat' - bch nwarriw el placeholder sa7i7

  // 🔵 ZID: el data elli lezemha touwsel l'ProfileOwnerScreen fel a5er
  // (esm el owner, blastou) w el pets elli déjà tzadou 9bal (lowkan
  // el user dass "Add another pet" aktar men marra) + esm el pet HOUNI
  // (bch nzidouh l'lista ki nkamlou).
  final String ownerName;
  final String ownerCity;
  final String petName;
  final List<PetSummary> existingPets;
  final Uint8List? ownerPhotoBytes;

  // 🔵 ZID: kol el data el okhra (mel écran 1 w 2) - houni bess
  // el ma7atta el a5ira, tenbena l'PetSummary el kamla.
  final String? petAge;
  final String? petBreed;
  final String? petSize;
  final String? petGender;
  final List<String> petBehaviors;
  final Map<String, bool> petCareInfo;
  final String? petVetClinicName;
  final String? petVetClinicPhone;
  // 🔵 ZID: el ID el 7a9i9i (MongoDB, mel POST /api/pets elli déjà
  // sar fel écran 2) - lezmou bch na3rfou win nab3thou el photo
  // (POST /api/pets/:petId/photo).
  final String? petId;

  const AddPetPhotoScreen({
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
    this.petBehaviors = const [],
    this.petCareInfo = const {},
    this.petVetClinicName,
    this.petVetClinicPhone,
    this.petId,
  });

  @override
  State<AddPetPhotoScreen> createState() => _AddPetPhotoScreenState();
}

class _AddPetPhotoScreenState extends State<AddPetPhotoScreen> {
  // 🔵 Uint8List (bytes), MCH "File" (dart:io) - bch te5dem fel Flutter
  // WEB zeda (dart:io ma ye5demch fel web), chrahtha fel profile picker.
  Uint8List? _photoBytes;
  bool _isSubmitting = false;

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
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _photoBytes = bytes);
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

  Future<void> _onNextPressed() async {
    if (_isSubmitting) return;

    // 🔵 ZID: obligatoire tاوة - ma tنجمch tكمل bla ma tختار photo
    // lel pet (chrahtha: "manejjamch ken ma nkoun 3amalt selection").
    if (_photoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('pet_photo_required_error'.tr())),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // 🔵 ZID: print UNCONDITIONNEL (barra el "if") - bch nchoufou
    // bel-dha8t win el chemin ye9taa3: ken el print hedha ma bench
    // khaless, ye3ni el app mazelt testa3mel el code el 9dim (lezem
    // hot restart 'R'). Ken ban lakin petId=null, ye3ni el mochkla
    // fi create_pet_profile_2 (el POST /pets), mch houni.
    debugPrint('🟣 [AddPetPhoto._onNextPressed] petId=${widget.petId} hasToken=${AuthSession.token != null}');

    // 🔵 sa77e7t el bug el kbir: houni kan "Future.delayed" (rien),
    // el photo 3omرha ma tetba3thech - tاوة appel 7a9i9i, b'el petId
    // el 7a9i9i (mel POST /api/pets elli sar fel écran 2).
    String? photoUrl;
    if (widget.petId != null) {
      try {
        final response = await ApiService.uploadPhoto(
          '/pets/${widget.petId}/photo',
          _photoBytes!,
          token: AuthSession.token,
        );
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
          final Map<String, dynamic> pet = data['pet'] as Map<String, dynamic>;
          photoUrl = pet['photoUrl'] as String?;
        } else {
          // 🔵 ZID: kan el catch fadhi (silence) - mch nnajmou nchoufou
          // 3lech el upload yefchel (404? 500? multer error?). Tawa
          // yban fel terminal (flutter run console).
          debugPrint('⚠️ [uploadPetPhoto] status ${response.statusCode}: ${response.body}');
        }
      } catch (error) {
        // el upload fechel (server/connexion) - nkamlou 7ata kif,
        // el photo tab9a bالضبط mahfoudha b'el bytes (mémoire) l'had
        // el session, ghir mch fel backend.
        debugPrint('⚠️ [uploadPetPhoto] exception: $error');
      }
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // 🔵 ZID: nzidou el pet el 7ali (esmou + noue3ou + PHOTO tou3ou -
    // kanet tedhi3 houni, tاوة تسافر) l'lista tel pets elli déjà
    // tzadou 9bal, w nab3thou el kol l'ProfileOwnerScreen.
    final List<PetSummary> finalPets = [
      ...widget.existingPets,
      PetSummary(
        id: widget.petId,
        name: widget.petName,
        petType: widget.petType,
        photoBytes: _photoBytes,
        photoUrl: photoUrl,
        age: widget.petAge,
        breed: widget.petBreed,
        size: widget.petSize,
        gender: widget.petGender,
        behaviors: widget.petBehaviors,
        careInfo: widget.petCareInfo,
        vetClinicName: widget.petVetClinicName,
        vetClinicPhone: widget.petVetClinicPhone,
      ),
    ];

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ProfileOwnerScreen(
          ownerName: widget.ownerName,
          ownerCity: widget.ownerCity,
          pets: finalPets,
          // 🔵 ZID: kanet tedhi3 zeda - tاوة تسافر lel écran el akhir.
          ownerPhotoBytes: widget.ownerPhotoBytes,
        ),
      ),
      (route) => false, // yenna7i el stack kaملها (bla back lel signup flow)
    );
  }

  // --------------------------------------------------------------------
  // 🔵 ZID: "Add another pet" - ye3awed el flow el kamel mel loula
  // (CreatePetProfileScreen -> CreatePetProfile2Screen -> AddPetPhotoScreen)
  // b "push" (mch replace) - bch el user ynajjam ydous "Add another pet"
  // 3adet el marrat (kol marra tzid pet, w fel akher ay écran, "Next"
  // yemchi direct l'ProfileOwnerScreen w ynahi el stack kaملha).
  // --------------------------------------------------------------------
  Future<void> _onAddAnotherPetPressed() async {
    // 🔵 ZID: obligatoire zeda houni (nafs chart tel "Next").
    if (_photoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('pet_photo_required_error'.tr())),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    debugPrint('🟣 [AddPetPhoto._onAddAnotherPetPressed] petId=${widget.petId} hasToken=${AuthSession.token != null}');

    // 🔵 sa77e7t: nafs el bug tel "_onNextPressed" - kanet ma tab3athch
    // el photo lel backend 7ata (mch 7ata "Future.delayed" - walou).
    String? photoUrl;
    if (widget.petId != null) {
      try {
        final response = await ApiService.uploadPhoto(
          '/pets/${widget.petId}/photo',
          _photoBytes!,
          token: AuthSession.token,
        );
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
          final Map<String, dynamic> pet = data['pet'] as Map<String, dynamic>;
          photoUrl = pet['photoUrl'] as String?;
        } else {
          debugPrint('⚠️ [uploadPetPhoto] status ${response.statusCode}: ${response.body}');
        }
      } catch (error) {
        // el upload fechel - nkamlou 7ata kif, el photo tab9a mahfoudha
        // b'el bytes (mémoire) l'had el session bess.
        debugPrint('⚠️ [uploadPetPhoto] exception: $error');
      }
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final List<PetSummary> updatedExistingPets = [
      ...widget.existingPets,
      PetSummary(
        id: widget.petId,
        name: widget.petName,
        petType: widget.petType,
        photoBytes: _photoBytes,
        photoUrl: photoUrl,
        age: widget.petAge,
        breed: widget.petBreed,
        size: widget.petSize,
        gender: widget.petGender,
        behaviors: widget.petBehaviors,
        careInfo: widget.petCareInfo,
        vetClinicName: widget.petVetClinicName,
        vetClinicPhone: widget.petVetClinicPhone,
      ),
    ];

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePetProfileScreen(
          ownerName: widget.ownerName,
          ownerCity: widget.ownerCity,
          existingPets: updatedExistingPets,
          ownerPhotoBytes: widget.ownerPhotoBytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final String placeholderAsset =
        widget.petType == 'cat' ? 'assets/images/cat.png' : 'assets/images/dog.png';

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 🐾 Paws (fou9-yemin w ta7t-yesar, kifha kif el design)
            buildPetPaw(context: context, size: screenSize.width * 0.08, topPercent: 0.02, leftPercent: 0.86, color: AppColors.pinkpetsy.withOpacity(0.7)),
            buildPetPaw(context: context, size: screenSize.width * 0.09, topPercent: 0.86, leftPercent: 0.06, color: AppColors.pinkpetsy.withOpacity(0.7)),

            const CustomBackButton(),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
              child: Column(
                children: [
                  SizedBox(height: screenSize.height * 0.10),

                  Text(
                    'add_pet_photo_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenSize.width * 0.055,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),

                  const Spacer(),

                  // ----------------------------------------------------
                  // 📷 Mrabba3 b zawaya mdawra (mch dayra) + badge camera
                  // ----------------------------------------------------
                  GestureDetector(
                    onTap: _showImageSourceSheet,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: screenSize.width * 0.52,
                          height: screenSize.width * 0.52,
                          decoration: BoxDecoration(
                            // 🔵 badalna: mrabba3 b zawaya mdawra (mch
                            // dayra kamla) - el images (dog.png/cat.png)
                            // mrabba3in el chekel, fel dayra kanou el
                            // zawaya tetkas (ClipOval ye9tas ay 7aja
                            // barra el dayra, w el image mrabba3a feha
                            // zawaya).
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppColors.pinkpetsy, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: _photoBytes != null
                                ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                                // 🔵 BoxFit.cover direct (bla padding/contain):
                                // el image tekhdem el mrabba3 KAMEL, dog/cat
                                // yban kamlin bla ay fasa5 fadhi.
                                : Image.asset(placeholderAsset, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          bottom: -6,
                          right: -6,
                          child: Container(
                            width: screenSize.width * 0.11,
                            height: screenSize.width * 0.11,
                            decoration: BoxDecoration(
                              color: AppColors.pinkpetsy,
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2.5),
                            ),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: screenSize.width * 0.05),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.02),

                  Text(
                    'your_pet_photo_label'.tr(),
                    style: TextStyle(
                      fontSize: screenSize.width * 0.04,
                      fontWeight: FontWeight.w600,
                      color: AppColors.vertpetsy,
                    ),
                  ),

                  const Spacer(),

                  // 🔵 ZID: "Add another pet" - CustomOutlinedButton
                  // mawjoud déjà, fou9 el "Next" bالضبط.
                  CustomOutlinedButton(
                    text: 'add_another_pet_button'.tr(),
                    width: screenSize.width * 0.90,
                    height: screenSize.height * 0.065,
                    fontFactor: 0.32,
                    prefixIcon: Icon(Icons.add, color: AppColors.vertpetsy, size: screenSize.width * 0.05),
                    onPressed: _onAddAnotherPetPressed,
                  ),

                  SizedBox(height: screenSize.height * 0.015),

                  CustomButton(
                    text: _isSubmitting ? 'loading_label'.tr() : 'next_button'.tr(),
                    color: AppColors.vertpetsy,
                    widthFactor: 0.90,
                    heightFactor: 0.07,
                    fontFactor: 0.40,
                    onPressed: _onNextPressed,
                  ),

                  SizedBox(height: screenSize.height * 0.04),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}