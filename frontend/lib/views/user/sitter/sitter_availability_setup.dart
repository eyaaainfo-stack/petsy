import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/availability_picker.dart';
import '../../../controllers/availability_controller.dart';
import 'sitter_profile.dart';

// ============================================================================
// SitterAvailabilitySetupScreen (signup - "Yes" mel étape 9bal)
// ============================================================================
class SitterAvailabilitySetupScreen extends StatefulWidget {
  final String sitterName;
  final String sitterCity;
  final Uint8List? sitterPhotoBytes;

  const SitterAvailabilitySetupScreen({
    super.key,
    required this.sitterName,
    required this.sitterCity,
    this.sitterPhotoBytes,
  });

  @override
  State<SitterAvailabilitySetupScreen> createState() => _SitterAvailabilitySetupScreenState();
}

class _SitterAvailabilitySetupScreenState extends State<SitterAvailabilitySetupScreen> {
  final AvailabilityController _controller = AvailabilityController();
  Set<int> _recurringDaysOff = {};
  Set<DateTime> _specificDatesOff = {};
  bool _isSubmitting = false;

  Future<void> _onSave() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final success = await _controller.submitAvailability(
      recurringDaysOff: _recurringDaysOff.toList(),
      specificDatesOff: _specificDatesOff.toList(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile_submit_error'.tr())));
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SitterProfileScreen(sitterName: widget.sitterName, sitterCity: widget.sitterCity, sitterPhotoBytes: widget.sitterPhotoBytes),
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
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: sizes.bookingHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: sizes.bookingTopGap),
                  Center(
                    child: Text('availability_setup_title'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileNameFontSize)),
                  ),
                  SizedBox(height: sizes.myProfileSectionGap),
                  AvailabilityPicker(
                    onChanged: (value) {
                      _recurringDaysOff = value.recurringDaysOff;
                      _specificDatesOff = value.specificDatesOff;
                    },
                  ),
                  SizedBox(height: sizes.bookingSectionGap * 1.4),
                  SizedBox(
                    height: sizes.screenHeight * 0.06,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.vertpetsy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), elevation: 0),
                      onPressed: _isSubmitting ? null : _onSave,
                      child: Text(
                        _isSubmitting ? 'loading_label'.tr() : 'save_and_continue_button'.tr(),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.9),
                      ),
                    ),
                  ),
                  SizedBox(height: sizes.myProfileBottomGap),
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