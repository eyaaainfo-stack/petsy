import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../widgets/back_button.dart';
import '../../widgets/button.dart';
import '../../widgets/paw_widget.dart';
import '../../controllers/validators.dart';
import '../../controllers/auth_controller.dart';
import 'user_create_profile.dart';

// ============================================================================
// UserSignInScreen ("Sign up" - 7sab jdid)
// ============================================================================
// Nafs design/logo/titre/soutitre mte3 UserLoginScreen (fel nefs folder),
// ghir bla "Forgot Password?" (mch loji9i tab9a fi écran 7sab JDID, 7it
// mafamech "password ne5tel" 3la 7sab ma3andouch bd).
// ============================================================================
class UserSignInScreen extends StatefulWidget {
  final String role; // 'owner', 'sitter', wala 'courier'

  const UserSignInScreen({super.key, required this.role});

  @override
  State<UserSignInScreen> createState() => _UserSignInScreenState();
}

class _UserSignInScreenState extends State<UserSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final AuthController _authController = AuthController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🔵 signupPassword (mch loginPassword): rules 9awiya - 8 caractères,
  // 1 majuscule, 1 chiffre (chrahtha fel validators.dart)
  String? _validateEmail(String? value) => Validators.email(value);
  String? _validatePassword(String? value) => Validators.signupPassword(value);

  Future<void> _onSubmitPressed() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await _authController.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      role: widget.role,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // 🔵 ZID houni: kif el signup yenja7, nemchiw l'écran UserCreateProfile
    // (nafs role elli 5tarha el user mel account_type.dart)
    if (result.success) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => UserCreateProfileScreen(role: widget.role)),
      );
    } else {
      // 🔵 ZID: 9bal, kif el signup yefchel, ma kanech yban 7ata 7aja
      // (el user ma3rafch 3lech el bouton "ma yemchich"). Tاوة
      // nwarriwlou el message el sa7i7 (email mawjoud déjà, mafamech
      // connexion m3a el server, etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'login_generic_error'.tr())),
      );
    }
  }

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
      body: SafeArea(
        child: Stack(
          children: [
            buildPetPaw(context: context, size: screenSize.width * 0.08, topPercent: 0.03, leftPercent: 0.82, color: AppColors.pinkpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: screenSize.width * 0.075, topPercent: 0.86, leftPercent: 0.16, color: AppColors.pinkpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: screenSize.width * 0.06, topPercent: 0.905, leftPercent: 0.04, color: AppColors.pinkpetsy.withOpacity(0.6)),

            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: screenSize.height * 0.10),

                    Center(
                      child: Image.asset(
                        'assets/images/ppetsy.png',
                        width: screenSize.width * 0.56,
                        fit: BoxFit.contain,
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.022),

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

                    // 🔵 "Forgot Password?" et7a - m3andch ma3na hna
                    // (7sab jdid, mazel ma fama password ne5tel)

                    SizedBox(height: screenSize.height * 0.035),

                    Center(
                      child: CustomButton(
                        text: _isSubmitting ? 'loading_label'.tr() : 'signup_button'.tr(),
                        color: AppColors.pinkpetsy,
                        widthFactor: 0.90,
                        heightFactor: 0.07,
                        fontFactor: 0.40,
                        onPressed: _onSubmitPressed,
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.038),

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

            // 🔙 zdinaha HOUNI (lakher fel Stack) - chrahtha fel admin_login
            const CustomBackButton(),
          ],
        ),
      ),
    );
  }
}