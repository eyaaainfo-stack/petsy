import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/theme_controller.dart';
import '../../widgets/back_button.dart';
import '../../widgets/outlined_button.dart';

// ============================================================================
// ThemeScreen ("theme.dart") - mchtarek bin owner w sitter
// ============================================================================
// 🔵 Wsulha mel Settings (sidebar, owner/sitter) - 3 khyarat: System
// default / Light / Dark. Ki tحقق b7ed, el app tetbeddel LIVE (bla
// restart) - ThemeController (ValueNotifier) yes3لدou el app.dart.
// ============================================================================
class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  ThemeMode? _selected;

  @override
  void initState() {
    super.initState();
    _selected = ThemeController.mode.value;
  }

  Future<void> _select(ThemeMode? mode) async {
    setState(() => _selected = mode);
    await ThemeController.setMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sizes.fpHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: sizes.fpTopGap + sizes.fpBackButtonSize),
                  Text(
                    'choose_theme_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.pinkpetsy, fontSize: sizes.fpTitleFontSize * 0.75),
                  ),
                  SizedBox(height: sizes.fpSectionGap * 1.5),

                  CustomOutlinedButton(
                    text: '☀️   ${'system_mode_label'.tr()}',
                    isSelected: _selected == null,
                    width: double.infinity,
                    height: sizes.screenHeight * 0.065,
                    fontFactor: 0.37,
                    onPressed: () => _select(null),
                  ),
                  SizedBox(height: sizes.fpSectionGap * 0.6),
                  CustomOutlinedButton(
                    text: '🌤️   ${'light_mode_label'.tr()}',
                    isSelected: _selected == ThemeMode.light,
                    width: double.infinity,
                    height: sizes.screenHeight * 0.065,
                    fontFactor: 0.37,
                    onPressed: () => _select(ThemeMode.light),
                  ),
                  SizedBox(height: sizes.fpSectionGap * 0.6),
                  CustomOutlinedButton(
                    text: '🌙   ${'dark_mode_label'.tr()}',
                    isSelected: _selected == ThemeMode.dark,
                    width: double.infinity,
                    height: sizes.screenHeight * 0.065,
                    fontFactor: 0.37,
                    onPressed: () => _select(ThemeMode.dark),
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