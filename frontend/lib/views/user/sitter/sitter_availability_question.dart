import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import 'sitter_availability_setup.dart';
import 'sitter_profile.dart';

// ============================================================================
// SitterAvailabilityQuestionScreen (signup - étape jdida)
// ============================================================================
// 🔵 ZID (kifma tlab): "fel inscription yjih sou2el est ce que 3andek
// ayemet ma thebbech tekhdem fihom" - Yes -> SitterAvailabilitySetupScreen
// (nafs l'écran, calendrier tel picker) - No -> direct SitterProfileScreen
// (kifha kif kanet 9bal).
// ============================================================================
class SitterAvailabilityQuestionScreen extends StatelessWidget {
  final String sitterName;
  final String sitterCity;
  final Uint8List? sitterPhotoBytes;

  const SitterAvailabilityQuestionScreen({
    super.key,
    required this.sitterName,
    required this.sitterCity,
    this.sitterPhotoBytes,
  });

  void _goToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SitterProfileScreen(sitterName: sitterName, sitterCity: sitterCity, sitterPhotoBytes: sitterPhotoBytes),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sizes.bookingHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_outlined, color: AppColors.pinkpetsy, size: sizes.screenWidth * 0.16),
                  SizedBox(height: sizes.screenHeight * 0.02),
                  Text(
                    'availability_question_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileNameFontSize * 0.85),
                  ),
                  SizedBox(height: sizes.screenHeight * 0.01),
                  Text(
                    'availability_question_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.85, color: Colors.grey),
                  ),
                  SizedBox(height: sizes.screenHeight * 0.04),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: sizes.screenHeight * 0.06,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.vertpetsy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), elevation: 0),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SitterAvailabilitySetupScreen(sitterName: sitterName, sitterCity: sitterCity, sitterPhotoBytes: sitterPhotoBytes),
                                ),
                              );
                            },
                            child: Text('yes_label'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.9)),
                          ),
                        ),
                      ),
                      SizedBox(width: sizes.screenWidth * 0.03),
                      Expanded(
                        child: SizedBox(
                          height: sizes.screenHeight * 0.06,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pinkpetsy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), elevation: 0),
                            onPressed: () => _goToHome(context),
                            child: Text('no_label'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.9)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const CustomBackButton(),
          ],
        ),
      ),
    );
  }
}