import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/forgot_password_controller.dart';
import '../../controllers/validators.dart';
import '../../widgets/button.dart';
import '../../widgets/message_dialog.dart';

// ============================================================================
// MdpOublier3Screen ("Enter New Password")
// ============================================================================
// 🔴 Validation kifma tlab: "lezem el mdp kima el mdp el 2" - password
// w retype password lezmhom ykounou KIF KIF, w ma3andekch ynajjam
// tkamel ken mch mtabقين.
// ============================================================================
class MdpOublier3Screen extends StatefulWidget {
  final String email;
  final String resetToken;

  const MdpOublier3Screen({super.key, required this.email, required this.resetToken});

  @override
  State<MdpOublier3Screen> createState() => _MdpOublier3ScreenState();
}

class _MdpOublier3ScreenState extends State<MdpOublier3Screen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _retypeController = TextEditingController();
  final ForgotPasswordController _controller = ForgotPasswordController();
  bool _obscurePassword = true;
  bool _obscureRetype = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _retypeController.dispose();
    super.dispose();
  }

  Future<void> _onSetPasswordPressed() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await _controller.resetPassword(
      email: widget.email,
      resetToken: widget.resetToken,
      newPassword: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success) {
      showMessageDialog(context, result.errorMessage ?? 'login_generic_error'.tr());
      return;
    }

    if (!mounted) return;
    showMessageDialog(context, 'password_reset_success_label'.tr());

    // 🔵 nerja3ou l "user_login.dart" (elli bda mennou el flow kaملou) -
    // 3 écrans etzadou fel stack (1/2/3), fa 3 pops bch nerja3ou l'lil
    // écran elli 9bal el flow.
    for (int i = 0; i < 3; i++) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: sizes.fpTopGap,
              right: sizes.fpHorizontalPadding,
              child: Icon(Icons.pets, color: AppColors.pinkpetsy.withOpacity(0.6), size: sizes.fpPawSize),
            ),
            Positioned(
              top: sizes.fpTopGap + sizes.fpPawSize * 0.6,
              right: sizes.fpHorizontalPadding + sizes.fpPawSize * 0.7,
              child: Icon(Icons.pets, color: AppColors.pinkpetsy.withOpacity(0.4), size: sizes.fpPawSize * 0.7),
            ),

            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: sizes.fpHorizontalPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: sizes.fpTopGap),

                    InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: sizes.fpBackButtonSize,
                        height: sizes.fpBackButtonSize,
                        decoration: const BoxDecoration(color: AppColors.vertpetsy, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      ),
                    ),

                    SizedBox(height: sizes.fpSectionGap * 1.5),

                    Center(
                      child: Container(
                        width: sizes.fpIllustrationSize,
                        height: sizes.fpIllustrationSize,
                        decoration: BoxDecoration(color: AppColors.vertpetsy.withOpacity(0.10), shape: BoxShape.circle),
                        child: Icon(Icons.password_outlined, color: AppColors.vertpetsy, size: sizes.fpIllustrationIconSize),
                      ),
                    ),

                    SizedBox(height: sizes.fpSectionGap * 1.5),

                    Text(
                      'enter_new_password_title'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: sizes.fpTitleFontSize, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: sizes.fpFieldGap),
                    Text(
                      'enter_new_password_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: sizes.fpSubtitleFontSize, color: Colors.grey.shade600),
                    ),

                    SizedBox(height: sizes.fpSectionGap * 1.3),

                    Text('password_label'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.screenWidth * 0.037)),
                    SizedBox(height: sizes.fpFieldGap),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: Validators.signupPassword,
                      decoration: InputDecoration(
                        hintText: 'password_hint'.tr(),
                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.pinkpetsy.withOpacity(0.7)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.pinkpetsy.withOpacity(0.7)),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: AppColors.vertpetsy.withOpacity(0.08),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.pinkpetsy, width: 1.6)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.2)),
                      ),
                    ),

                    SizedBox(height: sizes.fpSectionGap),

                    Text('retype_password_label'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.screenWidth * 0.037)),
                    SizedBox(height: sizes.fpFieldGap),
                    TextFormField(
                      controller: _retypeController,
                      obscureText: _obscureRetype,
                      // 🔴 IMPORTANT (kifma tlab): "lezem el mdp kima el
                      // mdp el 2" - validator ye7e99e9 el 2 password kif
                      // kif, mch ghir "mch fadhi".
                      validator: (value) {
                        if (value == null || value.isEmpty) return null; // Validators.signupPassword déjà ye7e99e9 el "required" 3al 7a9el el loula
                        if (value != _passwordController.text) return 'passwords_do_not_match_error'.tr();
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'password_hint'.tr(),
                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.pinkpetsy.withOpacity(0.7)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureRetype ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.pinkpetsy.withOpacity(0.7)),
                          onPressed: () => setState(() => _obscureRetype = !_obscureRetype),
                        ),
                        filled: true,
                        fillColor: AppColors.vertpetsy.withOpacity(0.08),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.pinkpetsy, width: 1.6)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.2)),
                      ),
                    ),

                    SizedBox(height: sizes.fpSectionGap * 2),

                    CustomButton(
                      text: _isSubmitting ? 'loading_label'.tr() : 'set_new_password_button'.tr(),
                      color: AppColors.pinkpetsy,
                      widthFactor: 0.90,
                      heightFactor: 0.07,
                      fontFactor: 0.40,
                      enabled: !_isSubmitting,
                      onPressed: _onSetPasswordPressed,
                    ),

                    SizedBox(height: sizes.fpSectionGap),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}