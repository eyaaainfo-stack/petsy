import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/back_button.dart';
import '../../widgets/button.dart';
import '../../widgets/outlined_button.dart';
import '../../widgets/paw_widget.dart';
import '../../controllers/validators.dart';
import '../../controllers/auth_controller.dart';
import '../../repositories/pet_repository.dart';
import '../../services/api_service.dart';
import 'user_signin.dart';
import 'owner/profile_owner.dart';
import 'sitter/sitter_profile.dart';
import 'mdp_oublier_1.dart';

// ============================================================================
// UserLoginScreen ("Login" - 7sab MAWJOUD)
// ============================================================================
// Nafs logo/titre/soutitre/design mte3 UserSignInScreen, ghir el TARTIB
// mbeddel (inspiré mel design Facebook elli b3aththou):
//   Email -> Password -> Bouton "Login" -> "Forgot Password?" (TA7T el
//   bouton, mch fou9u) -> "Create new account" (CustomOutlinedButton,
//   mawjoud déjà fel widgets/) -> divider "Continue through" + social icons
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

  // 🔵 el "controller" el 7a9i9i (chrahtha 9bal): fih el mant9 (login)
  // mafi el widget, mch el UI.
  final AuthController _authController = AuthController();

  bool _isSubmitting = false;

  // 🔵 el 2 messages el 5ata mte3 el server (email ghalet / password
  // ghalet) - mokhtelfin 3ala el validators el 3adiyin (format check),
  // 7it houma yban فقط ba3d el appel lel "backend" (el mock houni).
  String? _emailServerError;
  String? _passwordServerError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) => Validators.email(value);
  String? _validatePassword(String? value) => Validators.loginPassword(value);

  Future<void> _onLoginPressed() async {
    if (_isSubmitting) return;

    // 1️⃣ format checks el 3adiyin loula (email/password fadhi wala
    // format ghalet) - lowkan ghalet, nou9fou hnaya bla appel backend.
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _emailServerError = null;
      _passwordServerError = null;
    });

    // 2️⃣ appel el "backend" (mock tawa, chrahtha fel auth_controller.dart)
    final result = await _authController.login(
      email: _emailController.text,
      password: _passwordController.text,
      role: widget.role,
    );

    if (!mounted) return;

    // 3️⃣ 3ala 7sab noue3 el 5ata, nwarriw el message TAHT el 7a9el
    // el SA7I7 (email walla password), kifha kif Facebook.
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

    if (result.success) {
      // 🔵 sa77e7t: tاوة njibou el pets el 7a9i9iyin mel backend (GET
      // /api/pets, protégée, ta3raf el owner mel token) - mch [] fadhya.
      if (result.role == 'owner') {
        final pets = await PetRepository.fetchOwnerPets();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ProfileOwnerScreen(
              ownerName: result.fullName ?? '',
              ownerCity: result.city ?? '',
              pets: pets,
              // 🔴 FIX: kanet na9sa - photo tel owner ma kanetch tban
              // ba3d login (mediaBaseUrl + el path relatif mel backend,
              // nafs mant9 PetRepository).
              ownerPhotoUrl: (result.photoUrl != null && result.photoUrl!.isNotEmpty)
                  ? '${ApiService.mediaBaseUrl}${result.photoUrl}'
                  : null,
            ),
          ),
          (route) => false,
        );
      } else if (result.role == 'sitter') {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => SitterProfileScreen(
              sitterName: result.fullName ?? '',
              sitterCity: result.city ?? '',
              sitterPhotoUrl: (result.photoUrl != null && result.photoUrl!.isNotEmpty)
                  ? '${ApiService.mediaBaseUrl}${result.photoUrl}'
                  : null,
            ),
          ),
          (route) => false,
        );
      }
      // TODO: navigation lel home mte3 el b39dhin (courier/admin)
    }
  }

  // Yemchi lel écran "Sign up" (7sab jdid), b'nefs el role
  void _onCreateAccountPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserSignInScreen(role: widget.role)),
    );
  }

  InputDecoration _fieldDecoration({
    required BuildContext context,
    required String hintText,
    Widget? suffixIcon,
    String? errorText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      suffixIcon: suffixIcon,
      // 🔵 errorText: lowkan el "backend" (mock) rja3 5ata mrattab
      // b'hedha el 7a9el (email/password), yban houni TA7T el 7a9el -
      // mokhtelef 3ala el validator (elli ychek format bess).
      errorText: errorText,
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

  Widget _fieldLabel(String text, AppSizes sizes) {
    return Text(
      text,
      style: TextStyle(
        fontSize: sizes.authFieldLabelFontSize,
        fontWeight: FontWeight.bold,
        color: AppColors.pinkpetsy,
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
            buildPetPaw(context: context, size: sizes.authPawSize1, topPercent: 0.03, leftPercent: 0.82, color: AppColors.pinkpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: sizes.authPawSize2, topPercent: 0.86, leftPercent: 0.16, color: AppColors.pinkpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: sizes.authPawSize3, topPercent: 0.905, leftPercent: 0.04, color: AppColors.pinkpetsy.withOpacity(0.6)),

            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: sizes.authHorizontalPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: sizes.authTopGap),

                    Center(
                      child: Image.asset(
                        'assets/images/ppetsy.png',
                        width: sizes.authLogoWidth,
                        fit: BoxFit.contain,
                      ),
                    ),

                    SizedBox(height: sizes.authLogoTitleGap),

                    Center(
                      child: Text(
                        'login_welcome_back_title'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: sizes.authTitleFontSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.vertpetsy,
                        ),
                      ),
                    ),
                    SizedBox(height: sizes.authTitleSubtitleGap),
                    Center(
                      child: Text(
                        'login_subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: sizes.authSubtitleFontSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.vertpetsy.withOpacity(0.85),
                        ),
                      ),
                    ),

                    SizedBox(height: sizes.authSubtitleFieldsGap),

                    // 1️⃣ Email
                    _fieldLabel('email_address_label'.tr(), sizes),
                    SizedBox(height: sizes.authLabelFieldGap),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      // kol ma el user yebda yekteb, nmasso7 el 5ata
                      // el "server" (mch loji9i tab9a t8ban ba3d ma
                      // bda ybadel el email)
                      onChanged: (_) {
                        if (_emailServerError != null) {
                          setState(() => _emailServerError = null);
                        }
                      },
                      decoration: _fieldDecoration(
                        context: context,
                        hintText: 'your_email_hint'.tr(),
                        errorText: _emailServerError,
                      ),
                    ),

                    SizedBox(height: sizes.authFieldsGap),

                    // 2️⃣ Password
                    _fieldLabel('password_label'.tr(), sizes),
                    SizedBox(height: sizes.authLabelFieldGap),
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
                        hintText: '••••••••',
                        errorText: _passwordServerError,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.pinkpetsy.withOpacity(0.7),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),

                    SizedBox(height: sizes.authLoginPreButtonGap),

                    // 3️⃣ Bouton "Login" (nafs CustomButton, text tbeddel
                    // l "login_button" mch "signup_button")
                    Center(
                      child: CustomButton(
                        text: _isSubmitting ? 'loading_label'.tr() : 'login_button'.tr(),
                        color: AppColors.pinkpetsy,
                        widthFactor: 0.90,
                        heightFactor: 0.07,
                        fontFactor: 0.40,
                        onPressed: _onLoginPressed,
                      ),
                    ),

                    SizedBox(height: sizes.authLoginButtonForgotGap),

                    // 4️⃣ "Forgot Password?" - TA7T el bouton (kifha kif
                    // Facebook), mch fou9u kifma kan fel design l'oula
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // 🔴 FIX: kanet TODO - tawa ymchi l "Reset
                          // Your Password" (mdp_oublier_1.dart), el role
                          // yousel mennou (bch el email yت7اقق mennou
                          // ykoun nefs el account type).
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => MdpOublier1Screen(role: widget.role)),
                          );
                        },
                        child: Text(
                          'forgot_password_button'.tr(),
                          style: TextStyle(
                            fontSize: sizes.authForgotPasswordFontSize,
                            color: AppColors.pinkpetsy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: sizes.authForgotCreateAccountGap),

                    // 5️⃣ "Create new account" - CustomOutlinedButton
                    // MAWJOUD déjà (widgets/outlined_button.dart), isSelected:
                    // true bch ya5ou border/loun vertpetsy (mch grey), 7it
                    // el widget ma3andouch paramètre "color" direct.
                    Center(
                      child: CustomOutlinedButton(
                        text: 'create_account_button'.tr(),
                        width: sizes.authButtonWidth,
                        height: sizes.authButtonHeight,
                        fontFactor: AppSizes.authCreateAccountFontFactor,
                        isSelected: true,
                        onPressed: _onCreateAccountPressed,
                      ),
                    ),

                    SizedBox(height: sizes.authDividerGap),

                    // 6️⃣ Divider "Continue through" + social icons (fel
                    // lakher, kifma tlabt)
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.pinkpetsy.withOpacity(0.4))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: sizes.authDividerPaddingH),
                          child: Text(
                            'continue_with_label'.tr(),
                            style: TextStyle(
                              color: AppColors.pinkpetsy,
                              fontWeight: FontWeight.w500,
                              fontSize: sizes.authDividerFontSize,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.pinkpetsy.withOpacity(0.4))),
                      ],
                    ),

                    SizedBox(height: sizes.authDividerSocialGap),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            // TODO: Google Sign-In
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Padding(
                            padding: EdgeInsets.all(sizes.authSocialIconPadding),
                            child: Icon(Icons.g_mobiledata_rounded, size: sizes.authGoogleIconSize, color: Colors.redAccent),
                          ),
                        ),
                        SizedBox(width: sizes.authSocialIconsGap),
                        InkWell(
                          onTap: () {
                            // TODO: Facebook Sign-In
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Padding(
                            padding: EdgeInsets.all(sizes.authSocialIconPadding),
                            child: Icon(Icons.facebook_rounded, size: sizes.authFacebookIconSize, color: const Color(0xFF1877F2)),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: sizes.authBottomGap),
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