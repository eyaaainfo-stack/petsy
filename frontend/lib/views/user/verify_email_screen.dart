import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/email_verification_controller.dart';
import '../../controllers/auth_session.dart';
import '../../widgets/button.dart';
import '../../widgets/message_dialog.dart';
import 'account_type.dart';
import 'splash_decider.dart';

// ============================================================================
// VerifyEmailScreen
// ============================================================================
// 🔵 ZID (kifma tlab: "el email ykoun réellement mawjoud - vérification
// bloquante") - écran jdid, nafs UI tel MdpOublier2Screen (code 5
// ra9mat) - ghir houni l'CONFIRMATION el email nafsou (mch reset
// password). Ma3andouch bouton "back"/"skip" - el user LEZMOU
// yconfirmi 9bal ma ykammel (kifma tlab: "ma ynajjamch yekhdem bel
// app 7atta yconfirmi el email" - bloquant).
//
// Yban f 2 7alat:
//   1) mbacher ba3d el signup (user_signin.dart) - 9BAL UserCreate
//      ProfileScreen.
//   2) ki el user y3awad ydakhal (login mnfassel, wela session
//      mahfoudha - splash_decider.dart) w mazel ma confirmech el
//      email mel marra el loula.
// El 2 7alat: ba3d success, "SplashDecider" (mch navigation direct
// l'écran mo7addad) - houwa el "source of truth" el wa7id l'routing
// (ye3raf ken el profile kammel wala la, w ay role) - mabetnach
// b'logique mkarrra houni.
// ============================================================================
class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final TextEditingController _codeController = TextEditingController();
  final EmailVerificationController _controller = EmailVerificationController();
  bool _isSubmitting = false;
  bool _isResending = false;

  // 🔵 countdown "Resend in X:XX" (nafs mant9 MdpOublier2Screen) - 15
  // d9i9a (900s), nafs el mudda tel expiry tel code fel backend
  // (emailVerificationCodeExpiry).
  int _secondsLeft = 900;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 900);
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

    final result = await _controller.resend(email: widget.email);

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

    final result = await _controller.verifyEmail(email: widget.email, code: _codeController.text.trim());

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success) {
      showMessageDialog(context, result.errorMessage ?? 'login_generic_error'.tr());
      return;
    }

    if (!mounted) return;
    // 🔵 ZID: mch navigation direct - SplashDecider ye3raf win ymchi
    // (UserCreateProfileScreen ken el profile mazel ma kammelch, wela
    // el home tel role - AuthSession déjà mahfoudha mel signup/login).
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashDecider()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);

    return PopScope(
      // 🔴 IMPORTANT (kifma tlab: "ma ynajjamch yekhdem bel app 7atta
      // yconfirmi el email" - bloquant) - mafamech bouton "back" (mch
      // kifma MdpOublier2Screen), w "PopScope(canPop: false)" ye7bes
      // el back-gesture/bouton physique tel Android zeda (bla ha, el
      // user ynajjam ye5rej mel écran hedha bla ma yconfirmi).
      canPop: false,
      child: Scaffold(
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

                    // 🔵 ZID: bouton "Se déconnecter" (mch "back") -
                    // l'user eli 5tar had email bel ghalta (typo)
                    // ynajjam ghi yerja3 l'login/signup (mch ye39od
                    // "khaltat" fel écran hedha l'abad).
                    Align(
                      alignment: Alignment.topLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          await AuthSession.clear();
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AccountTypeView()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout, size: 18, color: Colors.grey),
                        label: Text('log_out_label'.tr(), style: const TextStyle(color: Colors.grey)),
                      ),
                    ),

                    SizedBox(height: sizes.fpSectionGap),

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
                      text: _isSubmitting ? 'loading_label'.tr() : 'verify_email_button'.tr(),
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
      ),
    );
  }
}