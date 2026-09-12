import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/back_button.dart';
import '../../widgets/button.dart';
import '../../widgets/paw_widget.dart';
import '../../controllers/validators.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/message_dialog.dart';
import 'user_create_profile.dart';
import 'owner/profile_owner.dart';
import 'sitter/sitter_profile.dart';
import '../../repositories/pet_repository.dart';
import '../../services/api_service.dart';

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
  // 🔵 ZID (kifma tlab: "el mdp nektbou matrin w ken el marra el 2
  // mch kima lola tjini message d'erreur fi fenetre") - confirmation
  // password - chek fel _onSubmitPressed (popup, mch inline - kifma
  // tlab exactement).
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final AuthController _authController = AuthController();
  bool _isSubmitting = false;
  // 🔴 FIX (kifma tlab: "les message d'erreur eli kenou yjiw en rouge
  // rajaahom lkol") - "email déjà utilisé" kanet popup - tawa red
  // INLINE ta7t el 7a9el email (nafs mant9 admin_account_form.dart).
  String? _emailServerError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 🔵 signupPassword (mch loginPassword): rules 9awiya - 8 caractères,
  // 1 majuscule, 1 chiffre (chrahtha fel validators.dart)
  // 🔴 FIX: el email validator tawa yechek zeda _emailServerError (el
  // backend 9allou "email mawjoud déjà") - bch el message yban red
  // ta7t el 7a9el, mch popup.
  String? _validateEmail(String? value) {
    final String? formatError = Validators.email(value);
    if (formatError != null) return formatError;
    return _emailServerError;
  }

  String? _validatePassword(String? value) => Validators.signupPassword(value);

  Future<void> _onSubmitPressed() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _emailServerError = null;
    });

    final result = await _authController.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      role: widget.role,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // 🔴 FIX (kifma tlab: "nahhili el verification mta3 el email... c
    // pas la peine bch ta3mel verification") - VerifyEmailScreen
    // ma3adech mandatory - nemchiw direct l'UserCreateProfileScreen
    // (nafs role), kifha kif el flow tel Google Sign-In.
    if (result.success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => UserCreateProfileScreen(role: widget.role)),
        (route) => false,
      );
    } else if (result.errorMessage == 'signup_email_exists_error'.tr()) {
      // 🔴 FIX: red INLINE ta7t el 7a9el email (mch popup) - setState
      // ye5alli el field yerebuild, w _formKey.currentState!.validate()
      // yeb3ath el error message el jdid l'user (kifha kif el field
      // ye5tar "touché"/dirty, el error yban automatique).
      setState(() => _emailServerError = result.errorMessage);
      _formKey.currentState!.validate();
    } else {
      // 🔵 ZID: el errors l'okhrin (connexion, générique) - mabetnach
      // b'7a9el mu3ayan, tab9aou popup (nafs mant9 el b39dhin - CIN,
      // etc.).
      showMessageDialog(context, result.errorMessage ?? 'login_generic_error'.tr());
    }
  }

  // 🔵 ZID (kifma tlab: "Continue with Google") - houni écran SIGNUP,
  // "role" (widget.role) deja m3aloum - ken el email jdid, el compte
  // yet39od b'hedha el role MBACHER (bla ma ye7taj VerifyEmailScreen,
  // 7it Google deja verifi el email - isEmailVerified true mel backend).
  // Ken el email deja mawjoud (compte 3adi wela google), houni LOGIN
  // normal (nafs mant9 UserLoginScreen).
  bool _isGoogleSubmitting = false;
  Future<void> _onGooglePressed() async {
    if (_isGoogleSubmitting) return;
    setState(() => _isGoogleSubmitting = true);

    final result = await _authController.signInWithGoogle(role: widget.role);

    if (!mounted) return;
    setState(() => _isGoogleSubmitting = false);

    if (result.success) {
      await _navigateAfterGoogleAuth(
        role: result.role ?? widget.role,
        isProfileComplete: result.isProfileComplete,
        fullName: result.fullName,
        city: result.city,
        photoUrl: result.photoUrl,
        isVerified: result.isVerified,
        gender: result.gender,
      );
      return;
    }

    switch (result.errorType) {
      case GoogleAuthErrorType.cancelled:
        // el user 3andlou el picker w far 9bal ma ye5tar - bla error
        break;
      default:
        // "noAccountFound" mch mumkena houni (dima nab3thou role), fa
        // ay error okhor ("generic") ye5dem b'nafs el message.
        showMessageDialog(context, 'login_generic_error'.tr());
    }
  }

  Future<void> _navigateAfterGoogleAuth({
    required String role,
    required bool isProfileComplete,
    required String? fullName,
    required String? city,
    required String? photoUrl,
    required bool isVerified,
    required String? gender,
  }) async {
    if (!isProfileComplete) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => UserCreateProfileScreen(role: role)),
        (route) => false,
      );
      return;
    }

    if (role == 'owner') {
      final pets = await PetRepository.fetchOwnerPets();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ProfileOwnerScreen(
            ownerName: fullName ?? '',
            ownerCity: city ?? '',
            pets: pets,
            ownerPhotoUrl: (photoUrl != null && photoUrl.isNotEmpty) ? '${ApiService.mediaBaseUrl}$photoUrl' : null,
            isVerified: isVerified,
            gender: gender,
          ),
        ),
        (route) => false,
      );
    } else if (role == 'sitter') {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SitterProfileScreen(
            sitterName: fullName ?? '',
            sitterCity: city ?? '',
            sitterPhotoUrl: (photoUrl != null && photoUrl.isNotEmpty) ? '${ApiService.mediaBaseUrl}$photoUrl' : null,
            isVerified: isVerified,
            gender: gender,
          ),
        ),
        (route) => false,
      );
    }
    // TODO: navigation lel home mte3 el b39dhin (courier/admin)
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

                    // 📧 Email
                    _fieldLabel('email_address_label'.tr(), sizes),
                    SizedBox(height: sizes.authLabelFieldGap),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      decoration: _fieldDecoration(
                        context: context,
                        hintText: 'your_email_hint'.tr(),
                      ),
                    ),

                    SizedBox(height: sizes.authFieldsGap),

                    // 🔒 Password
                    _fieldLabel('password_label'.tr(), sizes),
                    SizedBox(height: sizes.authLabelFieldGap),
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

                    SizedBox(height: sizes.authFieldsGap),

                    // 🔒 Confirmer le mot de passe (kifma tlab: "el mdp
                    // nektbou matrin")
                    _fieldLabel('confirm_new_password_hint'.tr(), sizes),
                    SizedBox(height: sizes.authLabelFieldGap),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      // 🔴 FIX (kifma tlab: "khalliha message erreur en
                      // rouge tht el case mch fi fenetre") - kanet popup
                      // (showMessageDialog) fel _onSubmitPressed - tawa
                      // validator 3adi (nafs mant9 email/password) -
                      // text a7mar TA7T el case direct, kifha kif el
                      // validation errors l'okhrin el kol.
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'password_required_error'.tr();
                        if (value != _passwordController.text) return 'password_mismatch_error'.tr();
                        return null;
                      },
                      decoration: _fieldDecoration(
                        context: context,
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.pinkpetsy.withOpacity(0.7),
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                    ),

                    // 🔵 "Forgot Password?" et7a - m3andch ma3na hna
                    // (7sab jdid, mazel ma fama password ne5tel)

                    SizedBox(height: sizes.authSignupPreButtonGap),

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

                    SizedBox(height: sizes.authDividerGap),

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
                          onTap: _isGoogleSubmitting ? null : _onGooglePressed,
                          borderRadius: BorderRadius.circular(50),
                          child: Padding(
                            padding: EdgeInsets.all(sizes.authSocialIconPadding),
                            child: _isGoogleSubmitting
                                ? SizedBox(
                                    width: sizes.authGoogleIconSize,
                                    height: sizes.authGoogleIconSize,
                                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                                  )
                                : Icon(Icons.g_mobiledata_rounded, size: sizes.authGoogleIconSize, color: Colors.redAccent),
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