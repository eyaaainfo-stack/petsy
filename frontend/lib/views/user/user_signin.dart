import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../widgets/back_button.dart';
import '../../widgets/button.dart';
import '../../widgets/paw_widget.dart';

// ============================================================================
// UserLoginScreen
// ============================================================================
// Mbnia bch tetba9 el design (photo) elli b3aththa bel 7arf: label pink
// fou9 kol 7a9el, 7a9el b'border pink (mch filled kifha kif admin_login),
// "Welcome back" + soutitre b'loun teal (vertpetsy), bouton "Sign up".
// Testa3mel el 3 roles (owner/sitter/courier) 3an tari9 "role".
// ============================================================================
class UserLoginScreen extends StatefulWidget {
  final String role; // 'owner', 'sitter', wala 'courier'

  const UserLoginScreen({super.key, required this.role});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  void _onSubmitPressed() {
    if (_formKey.currentState!.validate()) {
      // TODO: authentification/inscription 7a9i9iya (API, role: widget.role)
    }
  }

  // Look tel 7a9el kifma fel design: border pink, mch filled b'loun ka7el/
  // grey kifha kif admin_login. Marra wa7da houni, mesta3mla mel 2 7ou9oul.
  InputDecoration _fieldDecoration({
    required BuildContext context,
    required String hintText,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      suffixIcon: suffixIcon,
      filled: true,
      // Theme-aware: abyedh fel light (kifha kif design), gris ka7el fel dark
      fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.pinkpetsy.withOpacity(0.5)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.pinkpetsy, width: 1.8),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.error, width: 1.2),
      ),
    );
  }

  // Label sghir pink fou9 kol 7a9el ("Email Address", "Password")
  Widget _fieldLabel(String text, double screenWidth) {
    return Text(
      text,
      style: TextStyle(
        fontSize: screenWidth * 0.037,
        fontWeight: FontWeight.bold,
        color: AppColors.pinkpetsy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      // Scaffold ya5ou el loun mel Theme automatique (dark/light) -
      // mahouch fixe "Colors.white" kifma kan 9bal.
      body: SafeArea(
        child: Stack(
          children: [
            // 🐾 Paws: 1 top-right + 2 bottom-left mkaddasin, kolhom pink
            // (kifha kif el design bel 7arf)
            buildPetPaw(context: context, size: screenSize.width * 0.08, topPercent: 0.03, leftPercent: 0.82, color: AppColors.pinkpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: screenSize.width * 0.075, topPercent: 0.86, leftPercent: 0.16, color: AppColors.pinkpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: screenSize.width * 0.06, topPercent: 0.905, leftPercent: 0.04, color: AppColors.pinkpetsy.withOpacity(0.6)),

            const CustomBackButton(),

            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: screenSize.height * 0.10),

                    // Logo PETSY (nafs asset mesta3mel fel app kaملها)
                    Center(
                      child: Image.asset(
                        'assets/images/ppetsy.png',
                        width: screenSize.width * 0.56,
                        fit: BoxFit.contain,
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.022),

                    // "Welcome back" + soutitre - loun teal (vertpetsy),
                    // mch pink (chrahtha ghalta 9bal, sa77e7tha)
                    Center(
                      child: Text(
                        'login_welcome_back_title'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenSize.width * 0.052,
                          fontWeight: FontWeight.bold,
                          color: AppColors.vertpetsy,
                        ),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.004),
                    Center(
                      child: Text(
                        'login_subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenSize.width * 0.043,
                          fontWeight: FontWeight.bold,
                          color: AppColors.vertpetsy.withOpacity(0.85),
                        ),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.045),

                    // 📧 Email
                    _fieldLabel('email_address_label'.tr(), screenSize.width),
                    SizedBox(height: screenSize.height * 0.008),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      decoration: _fieldDecoration(
                        context: context,
                        hintText: 'your_email_hint'.tr(),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.022),

                    // 🔒 Password
                    _fieldLabel('password_label'.tr(), screenSize.width),
                    SizedBox(height: screenSize.height * 0.008),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      decoration: _fieldDecoration(
                        context: context,
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.pinkpetsy.withOpacity(0.7),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.01),

                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () {
                          // TODO: navigation lel écran "Reset password"
                        },
                        child: Text(
                          'forgot_password_button'.tr(),
                          style: TextStyle(
                            fontSize: screenSize.width * 0.036,
                            color: AppColors.pinkpetsy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.018),

                    // 🔘 CustomButton mawjoud - text "Sign up" (kifma fel
                    // design bel 7arf)
                    Center(
                      child: CustomButton(
                        text: 'signup_button'.tr(),
                        color: AppColors.pinkpetsy,
                        widthFactor: 0.90,
                        heightFactor: 0.07,
                        fontFactor: 0.40,
                        onPressed: _onSubmitPressed,
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.038),

                    // Divider "Continue through"
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.pinkpetsy.withOpacity(0.4))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.03),
                          child: Text(
                            'continue_with_label'.tr(),
                            style: TextStyle(
                              color: AppColors.pinkpetsy,
                              fontWeight: FontWeight.w500,
                              fontSize: screenSize.width * 0.033,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.pinkpetsy.withOpacity(0.4))),
                      ],
                    ),

                    SizedBox(height: screenSize.height * 0.025),

                    // Social icons (placeholders - TODO)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            // TODO: Google Sign-In
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Padding(
                            padding: EdgeInsets.all(screenSize.width * 0.02),
                            child: Icon(Icons.g_mobiledata_rounded, size: screenSize.width * 0.11, color: Colors.redAccent),
                          ),
                        ),
                        SizedBox(width: screenSize.width * 0.05),
                        InkWell(
                          onTap: () {
                            // TODO: Facebook Sign-In
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Padding(
                            padding: EdgeInsets.all(screenSize.width * 0.02),
                            child: Icon(Icons.facebook_rounded, size: screenSize.width * 0.09, color: const Color(0xFF1877F2)),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: screenSize.height * 0.03),
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