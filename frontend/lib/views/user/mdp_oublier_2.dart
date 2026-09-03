import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/forgot_password_controller.dart';
import '../../widgets/button.dart';
import 'mdp_oublier_3.dart';
import '../../widgets/message_dialog.dart';

// ============================================================================
// MdpOublier2Screen ("Confirm Your Email")
// ============================================================================
class MdpOublier2Screen extends StatefulWidget {
  final String email;
  final String role;

  const MdpOublier2Screen({super.key, required this.email, required this.role});

  @override
  State<MdpOublier2Screen> createState() => _MdpOublier2ScreenState();
}

class _MdpOublier2ScreenState extends State<MdpOublier2Screen> {
  final TextEditingController _codeController = TextEditingController();
  final ForgotPasswordController _controller = ForgotPasswordController();
  bool _isSubmitting = false;
  bool _isResending = false;

  // 🔵 countdown "Resend in 3:03" (kifha kif el mockup) - 5 d9ay9 (300s),
  // nafs el mudda tel expiry tel code fel backend.
  int _secondsLeft = 300;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 300);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _onResendPressed() async {
    if (_isResending || _secondsLeft > 0) return;
    setState(() => _isResending = true);

    final result = await _controller.requestReset(email: widget.email, role: widget.role);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (result.success) {
      _startTimer();
    } else {
      showMessageDialog(context, result.errorMessage ?? 'login_generic_error'.tr());
    }
  }

  Future<void> _onVerifyPressed() async {
    if (_isSubmitting) return;
    if (_codeController.text.trim().length != 5) {
      showMessageDialog(context, 'enter_verification_code_label'.tr());
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _controller.verifyCode(email: widget.email, code: _codeController.text.trim());

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success || result.resetToken == null) {
      showMessageDialog(context, result.errorMessage ?? 'login_generic_error'.tr());
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MdpOublier3Screen(email: widget.email, resetToken: result.resetToken!),
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
                      decoration: BoxDecoration(color: AppColors.pinkpetsy.withOpacity(0.10), shape: BoxShape.circle),
                      child: Icon(Icons.mark_email_read_outlined, color: AppColors.pinkpetsy, size: sizes.fpIllustrationIconSize),
                    ),
                  ),

                  SizedBox(height: sizes.fpSectionGap * 1.5),

                  Text(
                    'confirm_email_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: sizes.fpTitleFontSize, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: sizes.fpFieldGap),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(fontSize: sizes.fpSubtitleFontSize, color: Colors.grey.shade600, height: 1.4),
                      children: [
                        TextSpan(text: '${'confirm_email_subtitle'.tr()}\n'),
                        TextSpan(text: widget.email, style: const TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                  SizedBox(height: sizes.fpSectionGap * 1.3),

                  Text('enter_verification_code_label'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.screenWidth * 0.037)),
                  SizedBox(height: sizes.fpFieldGap),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                    style: TextStyle(fontSize: sizes.screenWidth * 0.05, fontWeight: FontWeight.bold, letterSpacing: 4),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.mail_outline, color: AppColors.pinkpetsy.withOpacity(0.7)),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Center(
                          widthFactor: 1,
                          child: _secondsLeft > 0
                              ? Text('resend_in_label'.tr(namedArgs: {'time': _formattedTime}), style: TextStyle(color: Colors.grey.shade600, fontSize: sizes.screenWidth * 0.028))
                              : GestureDetector(
                                  onTap: _onResendPressed,
                                  child: Text(
                                    _isResending ? 'loading_label'.tr() : 'resend_code_label'.tr(),
                                    style: const TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.w600),
                                  ),
                                ),
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.vertpetsy.withOpacity(0.08),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.pinkpetsy, width: 1.6)),
                    ),
                  ),

                  SizedBox(height: sizes.fpSectionGap * 2),

                  CustomButton(
                    text: _isSubmitting ? 'loading_label'.tr() : 'verify_set_new_password_button'.tr(),
                    color: AppColors.pinkpetsy,
                    widthFactor: 0.90,
                    heightFactor: 0.07,
                    fontFactor: 0.36,
                    enabled: !_isSubmitting,
                    onPressed: _onVerifyPressed,
                  ),

                  SizedBox(height: sizes.fpSectionGap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}