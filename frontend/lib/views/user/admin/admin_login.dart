import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/button.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/paw_widget.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/api_service.dart';
import 'admin_home.dart';

// ============================================================================
// AdminLoginView
// ============================================================================
// StatefulWidget (mch Stateless) 7it 3andna 7ajet elli tetbeddel fi runtime:
// - _obscurePassword (twarri/t5abbi el password)
// - el 2 TextEditingController (el text elli el user yekteb)
// ============================================================================
class AdminLoginView extends StatefulWidget {
  const AdminLoginView({super.key});

  @override
  State<AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<AdminLoginView> {
  // --------------------------------------------------------------------
  // GlobalKey<FormState>: bih nnajjmou n9olou lel Form "tval9idi rou7ek"
  // (يعني tcheck kol el validators tel TextFormField f'wa9t wa7ed) kif
  // el user yousghot ala "Login".
  // --------------------------------------------------------------------
  final _formKey = GlobalKey<FormState>();

  // Controllers: houma elli yehfdou el text elli el user kteb fel 7a9ol.
  // Lezemhom "dispose" (تحت) ki el écran yet7al, kif el PageController.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // true = el password mkhabbi (••••), false = bayen b'a7rouf
  bool _obscurePassword = true;

  // 🔵 ZID: el "controller" el 7a9i9i (nafs mant9 user_login.dart) - fih
  // el appel API, mch el widget.
  final AuthController _authController = AuthController();
  bool _isSubmitting = false;

  // 🔵 ZID: nafs mant9 user_login.dart - message el 5ata mel "server"
  // (mch format check) yban TAHT el 7a9el el sa7i7 (email wala password).
  String? _emailServerError;
  String? _passwordServerError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Validators: functions e5tebar el input, yerja3o null lowkan sa7i7,
  // wala message el 5ata lowkan ghalet. Flutter yesta3melhom automatique
  // ki t3iyet "_formKey.currentState!.validate()".
  // ------------------------------------------------------------------
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'email_required_error'.tr();
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'email_invalid_error'.tr();
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required_error'.tr();
    }
    return null;
  }

  Future<void> _onLoginPressed() async {
    if (_isSubmitting) return;

    // validate() yrawe7 true/false w yobbayen automatique el messages
    // el 5ata ta7t kol 7a9el ghalet (format - 9bal ma na3malou appel API).
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _emailServerError = null;
      _passwordServerError = null;
    });

    // 🔴 FIX: kanet TODO - tawa appel 7a9i9i (POST /auth/login, nafs
    // endpoint mowa77ad lel acteurs el kol - el backend ye3raf el role
    // mel document nafsou).
    final result = await _authController.login(
      email: _emailController.text,
      password: _passwordController.text,
      role: 'admin',
    );

    if (!mounted) return;

    // 🔵 ZID: el email mumkin ykoun sa7i7 W el password sa7i7 - lakin
    // el compte MCH admin (owner/sitter 3adiyin) - hedhi écran khassa
    // bel Admin bark, fa nerfudouha houni (mch nel backend, el login
    // el backend mowa77ad lel acteurs el kol 3ammadan).
    if (result.success && result.role != 'admin') {
      setState(() {
        _isSubmitting = false;
        _emailServerError = 'admin_login_not_admin_error'.tr();
      });
      return;
    }

    setState(() {
      _isSubmitting = false;
      switch (result.errorType) {
        case LoginErrorType.invalidEmail:
          _emailServerError = 'login_email_not_found_error'.tr();
          break;
        case LoginErrorType.invalidPassword:
          _passwordServerError = 'login_wrong_password_error'.tr();
          break;
        case LoginErrorType.generic:
          _emailServerError = 'login_generic_error'.tr();
          break;
        case LoginErrorType.none:
          break;
      }
    });

    if (result.success && result.role == 'admin') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AdminHomeScreen(
            adminName: result.fullName?.isNotEmpty == true ? result.fullName! : 'admin_badge_label'.tr(),
            adminPhotoUrl: (result.photoUrl != null && result.photoUrl!.isNotEmpty)
                ? '${ApiService.mediaBaseUrl}${result.photoUrl}'
                : null,
          ),
        ),
        (route) => false,
      );
    }
  }

  // ------------------------------------------------------------------
  // Helper: bnina el "look" (decoration) tel 7ou9oul marra wa7da houni,
  // bch el email w el password ykounou b'nefs el style bla ma nkarrarou
  // el code. Theme.of(context) houni bch el loun el 7a9el yetbeddel
  // wa7dou bin dark/light mode.
  // ------------------------------------------------------------------
  InputDecoration _fieldDecoration({
    required BuildContext context,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
    // 🔵 ZID: message el 5ata "mel server" (email mch mawjoud, password
    // ghalet...) - null = mafamech, el 7a9el ye39od normal.
    String? errorText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      prefixIcon: Icon(icon, color: AppColors.vertpetsy),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.pinkpetsy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 🐾 Paws decoratives (nafs style el app kaملها)
            buildPetPaw(context: context, size: screenSize.width * 0.08, topPercent: 0.02, leftPercent: 0.80, color: AppColors.vertpetsy.withOpacity(0.5)),
            buildPetPaw(context: context, size: screenSize.width * 0.06, topPercent: 0.10, leftPercent: 0.08, color: AppColors.pinkpetsy.withOpacity(0.4)),

            // ------------------------------------------------------------
            // SingleChildScrollView: JDID houni. Lezemna n7ottou el Form
            // fi widget "scrollable" 7it ki el keyboard yet7el (el user
            // ybda yekteb), el keyboard ya5ou par mel écran, w lowkan el
            // contenu mch scrollable, Flutter yet3ada "overflow error"
            // (contenu ye5ba ta7t el keyboard). Hedhi standard fi ay
            // écran fi input feh.
            // ------------------------------------------------------------
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: screenSize.height * 0.16),

                    // 🖼️ Logo el app (nafs image mawjouda déjà)
                    Center(
                      child: Image.asset(
                        'assets/images/ppetsy.png',
                        width: screenSize.width * 0.34,
                        fit: BoxFit.contain,
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.03),

                    // Badge sghir "Admin" - bch ywarri belli hedhi
                    // écran khassa bel Admin biss (mch ay user)
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.035,
                          vertical: screenSize.height * 0.007,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pinkpetsy.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings, size: screenSize.width * 0.04, color: AppColors.pinkpetsy),
                            SizedBox(width: screenSize.width * 0.015),
                            Text(
                              'admin_badge_label'.tr(),
                              style: TextStyle(
                                fontSize: screenSize.width * 0.032,
                                fontWeight: FontWeight.w600,
                                color: AppColors.pinkpetsy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.02),

                    Text(
                      'admin_login_title'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenSize.width * 0.062,
                        fontWeight: FontWeight.bold,
                        color: AppColors.pinkpetsy,
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.012),

                    Text(
                      'admin_login_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenSize.width * 0.036,
                        color: mutedTextColor,
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.045),

                    // 📧 7a9el el email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      // kol ma el user yebda yekteb, nmasso7 el 5ata
                      // el "server" (mch loji9i tab9a t8ban ba3d ma
                      // bda ybadel el email).
                      onChanged: (_) {
                        if (_emailServerError != null) {
                          setState(() => _emailServerError = null);
                        }
                      },
                      decoration: _fieldDecoration(
                        context: context,
                        hintText: 'email_hint'.tr(),
                        icon: Icons.email_outlined,
                        errorText: _emailServerError,
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.02),

                    // 🔒 7a9el el password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      onChanged: (_) {
                        if (_passwordServerError != null) {
                          setState(() => _passwordServerError = null);
                        }
                      },
                      decoration: _fieldDecoration(
                        context: context,
                        hintText: 'password_hint'.tr(),
                        icon: Icons.lock_outline,
                        errorText: _passwordServerError,
                        // Icon "3in" bch tewarri/t5abbi el password
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.vertpetsy,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.012),

                    // "Forgot password?" - fel lakher (right fel LTR,
                    // left fel RTL, automatique b AlignmentDirectional)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () {
                          // TODO: navigation lel écran "Reset password"
                        },
                        child: Text(
                          'forgot_password_button'.tr(),
                          style: TextStyle(
                            fontSize: screenSize.width * 0.034,
                            color: AppColors.vertpetsy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.03),

                    // 🔘 Bouton Login (CustomButton mawjoud, bla icon/subtitle)
                    Center(
                      child: CustomButton(
                        text: _isSubmitting ? 'loading_label'.tr() : 'login_button'.tr(),
                        color: AppColors.pinkpetsy,
                        widthFactor: 0.85,
                        heightFactor: 0.07,
                        fontFactor: 0.40,
                        enabled: !_isSubmitting,
                        onPressed: _onLoginPressed,
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.04),
                  ],
                ),
              ),
            ),

            // 🔙 Bouton retour - 🔵 zdinaha HOUNI (LAKHER fel Stack), mch
            // 9bal el SingleChildScrollView. 3lech? Stack yeh-hit-test
            // b'ordre 3aks (akher 3onsor fel list = fou9 el kol, yakhod
            // el lmsa el loula). Lowkan CustomBackButton 9bal el
            // ScrollView, el ScrollView (7ata lowkan el blasa fadhya
            // bصريا) tekhod el lmsa 9bal ma touselou.
            const CustomBackButton(),
          ],
        ),
      ),
    );
  }
}