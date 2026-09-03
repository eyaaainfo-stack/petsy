import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/account_security_controller.dart';
import '../../controllers/validators.dart';
import '../../widgets/back_button.dart';
import '../../widgets/button.dart';
import '../../widgets/message_dialog.dart';

// ============================================================================
// ChangePasswordScreen ("Confidentialité et sécurité" -> "Changer le
// mot de passe")
// ============================================================================
// 🔵 ZID: kifma tlab - "changer el mdp" (role el kol, 7ata l'admin) -
// password 9dim + jdid + confirmation (nafs validation tel signup -
// Validators.signupPassword).
// ============================================================================
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AccountSecurityController _controller = AccountSecurityController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _currentPasswordServerError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _currentPasswordServerError = null;
    });

    final result = await _controller.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      showMessageDialog(context, 'password_changed_success'.tr());
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } else {
      if (result.errorMessage == 'current_password_incorrect_error'.tr()) {
        setState(() => _currentPasswordServerError = result.errorMessage);
      }
      showMessageDialog(context, result.errorMessage ?? 'login_generic_error'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: sizes.fpHorizontalPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: sizes.fpTopGap + sizes.fpBackButtonSize),
                    Text(
                      'change_password_label'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.pinkpetsy, fontSize: sizes.fpTitleFontSize * 0.75),
                    ),
                    SizedBox(height: sizes.fpSectionGap * 1.5),

                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'password_required_error'.tr();
                        return _currentPasswordServerError;
                      },
                      decoration: _fieldDecoration(
                        isDark: isDark,
                        hintText: 'current_password_hint'.tr(),
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.vertpetsy),
                          onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                    ),
                    SizedBox(height: sizes.fpSectionGap),

                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      validator: Validators.signupPassword,
                      decoration: _fieldDecoration(
                        isDark: isDark,
                        hintText: 'new_password_hint'.tr(),
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.vertpetsy),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                    ),
                    SizedBox(height: sizes.fpSectionGap),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      validator: (value) {
                        if (value != _newPasswordController.text) return 'password_mismatch_error'.tr();
                        return null;
                      },
                      decoration: _fieldDecoration(
                        isDark: isDark,
                        hintText: 'confirm_new_password_hint'.tr(),
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.vertpetsy),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                    SizedBox(height: sizes.fpSectionGap * 1.5),

                    Center(
                      child: CustomButton(
                        text: _isSubmitting ? 'loading_label'.tr() : 'save_button'.tr(),
                        onPressed: _onSubmit,
                        enabled: !_isSubmitting,
                      ),
                    ),
                    SizedBox(height: sizes.fpSectionGap),
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

  InputDecoration _fieldDecoration({required bool isDark, required String hintText, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: AppColors.vertpetsy),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }
}