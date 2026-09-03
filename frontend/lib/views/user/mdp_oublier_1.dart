import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/forgot_password_controller.dart';
import '../../controllers/validators.dart';
import '../../widgets/button.dart';
import 'mdp_oublier_2.dart';
import '../../widgets/message_dialog.dart';

// ============================================================================
// MdpOublier1Screen ("Reset Your Password")
// ============================================================================
// 🔵 Wsulha mel bouton "Forgot Password?" (user_login.dart) - el "role"
// yousel mennou (kifma tlab: "el mail lezem ykoun mta3 el account type
// heka bda2t" - mch ynajjam ydakhal mail sitter fel flow tel owner).
//
// Validation: email lezem ykoun (1) mzoud (mch fadhi) w (2) mawjoud
// 7a9i9atan fel base **b nefs el role** - el backend (forgotPassword,
// filter {email, role}) howa elli ye7e99e9 el 2 chart.
// ============================================================================
class MdpOublier1Screen extends StatefulWidget {
  final String role;

  const MdpOublier1Screen({super.key, required this.role});

  @override
  State<MdpOublier1Screen> createState() => _MdpOublier1ScreenState();
}

class _MdpOublier1ScreenState extends State<MdpOublier1Screen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final ForgotPasswordController _controller = ForgotPasswordController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSendPressed() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await _controller.requestReset(email: _emailController.text.trim(), role: widget.role);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success) {
      // 🔵 message mel backend direct (déjà bel 7arf mfahoum, mathalan
      // "No account found with this email for this account type") -
      // hedhi bidhabt el 2 chart elli tlab (mzoud + mawjoud + nefs role).
      showMessageDialog(context, result.errorMessage ?? 'login_generic_error'.tr());
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MdpOublier2Screen(email: _emailController.text.trim(), role: widget.role),
      ),
    );
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

                    // 🔙 bouton retour (teal, dayra) - kifha kif mockup
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

                    // 🔵 illustration - mafamech asset 3andi mtaba9 lel
                    // mockup (laptop/lock design specifique), sta3malt
                    // icon fi dayra decorative bdalha.
                    Center(
                      child: Container(
                        width: sizes.fpIllustrationSize,
                        height: sizes.fpIllustrationSize,
                        decoration: BoxDecoration(color: AppColors.vertpetsy.withOpacity(0.10), shape: BoxShape.circle),
                        child: Icon(Icons.lock_reset, color: AppColors.vertpetsy, size: sizes.fpIllustrationIconSize),
                      ),
                    ),

                    SizedBox(height: sizes.fpSectionGap * 1.5),

                    Text(
                      'reset_password_title'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: sizes.fpTitleFontSize, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: sizes.fpFieldGap),
                    Text(
                      'reset_password_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: sizes.fpSubtitleFontSize, color: Colors.grey.shade600, height: 1.4),
                    ),

                    SizedBox(height: sizes.fpSectionGap * 1.3),

                    Text('email_address_label'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.screenWidth * 0.037)),
                    SizedBox(height: sizes.fpFieldGap),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      decoration: InputDecoration(
                        hintText: 'your_email_hint'.tr(),
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.pinkpetsy.withOpacity(0.7)),
                        filled: true,
                        fillColor: AppColors.vertpetsy.withOpacity(0.08),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.pinkpetsy, width: 1.6)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.2)),
                      ),
                    ),

                    SizedBox(height: sizes.fpSectionGap * 2),

                    CustomButton(
                      text: _isSubmitting ? 'loading_label'.tr() : 'send_verification_code_button'.tr(),
                      color: AppColors.pinkpetsy,
                      widthFactor: 0.90,
                      heightFactor: 0.07,
                      fontFactor: 0.40,
                      enabled: !_isSubmitting,
                      onPressed: _onSendPressed,
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