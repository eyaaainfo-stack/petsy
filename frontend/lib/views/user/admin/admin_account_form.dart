import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../controllers/admin_users_controller.dart';
import '../../../controllers/validators.dart';
import '../../../models/admin_user.dart';
import '../../../widgets/button.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/paw_widget.dart';
import '../../../widgets/message_dialog.dart';

// ============================================================================
// AdminAccountFormScreen
// ============================================================================
// 🔵 ZID: kifma tlab - "poss eni na3mel création de compte kima f
// teswira ama b theme petsy" - écran wa7ed testa3mlou l create W edit
// (existingUser == null -> création, mch null -> modification).
//
// 🔵 el role (owner/sitter/courier/admin) yban GHIR fel mode création -
// modification el role ba3d ma el compte etkha9 mch supportée (chraht
// fel backend, adminController.js/updateUser - discriminator MongoDB
// mch loji9i tbeddel b'update 3adi).
// ============================================================================
class AdminAccountFormScreen extends StatefulWidget {
  final AdminUser? existingUser;
  // 🔵 ZID (kifma tlab: "badalhom b ajouter un autre admin") - ken el
  // admin principal, bdal Modifier/Supprimer, bouton "Ajouter un autre
  // admin" - houni bch el role ye39od "admin" mrakez direct (mch el
  // admin yfawet mrra thenya y5tarou mel chips).
  final String initialRole;

  const AdminAccountFormScreen({super.key, this.existingUser, this.initialRole = 'owner'});

  bool get isEditMode => existingUser != null;

  @override
  State<AdminAccountFormScreen> createState() => _AdminAccountFormScreenState();
}

class _AdminAccountFormScreenState extends State<AdminAccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  // 🔴 FIX (kifma tlab: "el modification eli ynajem yaamlha el admin
  // nhbha hiya bidha eli todhhor fel données mtaa el user") - city/
  // birthday kanou affichés fel écran détail lakin mch modifiables -
  // tawa zeydinhom houni (create W edit el 2).
  final _cityController = TextEditingController();
  final _birthdayController = TextEditingController();

  final AdminUsersController _controller = AdminUsersController();

  late String _selectedRole;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _emailServerError;
  // 🔴 FIX (kifma tlab: "fazet el cin... el USER nafsou") - _cinBytes/
  // _isUploadingCin/upload UI etna77aou 3ammadan - el CIN tawa el user
  // yeb3ath biha (verification_status_screen.dart), mch l'admin houni.

  @override
  void initState() {
    super.initState();
    // 🔴 FIX: "widget" mch disponible fel field initializer (yet7ott
    // ghir mel framework BA3D el constructeur, 9bal initState()) -
    // l'appel el sa7i7 houwa houni, mch "late ... = widget.xxx" fou9.
    _selectedRole = widget.initialRole;
    if (widget.isEditMode) {
      final AdminUser u = widget.existingUser!;
      _fullNameController.text = u.fullName;
      _emailController.text = u.email;
      _phoneController.text = u.phone;
      _cityController.text = u.city;
      _birthdayController.text = u.birthday;
      _selectedRole = u.role;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _emailServerError = null;
    });

    final AdminUserFormResult result;
    if (widget.isEditMode) {
      result = await _controller.updateUser(
        id: widget.existingUser!.id,
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        birthday: _birthdayController.text.trim(),
        // 🔵 ZID: optionnel - fadhi = password ma yetbeddelch (chraht
        // fel controller).
        password: _passwordController.text,
      );
    } else {
      result = await _controller.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        birthday: _birthdayController.text.trim(),
        role: _selectedRole,
      );
    }

    if (!mounted) return;

    if (result.success) {
      // 🔵 nrejjaou el AdminUser el jdid/mbaddel l'AdminAccountsScreen -
      // bch ta3mel refresh mba3ad bla appel API zeyda (GET users mel jdid).
      Navigator.of(context).pop(result.user);
    } else {
      setState(() {
        _isSubmitting = false;
        if (result.errorMessage == 'signup_email_exists_error'.tr()) {
          _emailServerError = result.errorMessage;
        }
      });
      if (mounted) {
        showMessageDialog(context, result.errorMessage ?? 'login_generic_error'.tr());
      }
    }
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      prefixIcon: Icon(icon, color: AppColors.vertpetsy),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.pinkpetsy, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.error, width: 1.2)),
    );
  }

  Widget _roleChip(String role, String label) {
    final sizes = AppSizes.of(context);
    final bool selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: sizes.adminAccountsChipHPadding, vertical: sizes.adminAccountsChipVPadding),
        decoration: BoxDecoration(
          color: selected ? AppColors.pinkpetsy : AppColors.vertpetsy.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: sizes.adminAccountsChipFontSize,
          ),
        ),
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
            buildPetPaw(context: context, size: sizes.adminFormPawSize, topPercent: 0.025, leftPercent: 0.85, color: AppColors.vertpetsy.withOpacity(0.5)),

            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: sizes.adminFormHorizontalPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: sizes.adminFormTopGap),
                    Text(
                      widget.isEditMode ? 'edit_account_title'.tr() : 'create_account_title'.tr(),
                      style: TextStyle(fontSize: sizes.adminFormTitleFontSize, fontWeight: FontWeight.bold, color: AppColors.pinkpetsy),
                    ),
                    SizedBox(height: sizes.adminFormSectionGap),

                    if (!widget.isEditMode) ...[
                      Text(
                        'account_role_label'.tr(),
                        style: TextStyle(fontSize: sizes.adminFormRoleLabelFontSize, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      SizedBox(height: sizes.adminFormRoleLabelGap),
                      Wrap(
                        spacing: sizes.adminFormRoleChipGap,
                        runSpacing: sizes.adminFormRoleChipGap,
                        children: [
                          _roleChip('owner', 'role_owner_label'.tr()),
                          _roleChip('sitter', 'role_sitter_label'.tr()),
                          _roleChip('courier', 'role_courier_label'.tr()),
                          _roleChip('admin', 'role_admin_label'.tr()),
                        ],
                      ),
                      SizedBox(height: sizes.adminFormSectionGap),
                    ],

                    TextFormField(
                      controller: _fullNameController,
                      decoration: _fieldDecoration(hintText: 'full_name_hint'.tr(), icon: Icons.person_outline),
                    ),
                    SizedBox(height: sizes.adminFormFieldGap),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      onChanged: (_) {
                        if (_emailServerError != null) setState(() => _emailServerError = null);
                      },
                      decoration: _fieldDecoration(hintText: 'email_hint'.tr(), icon: Icons.email_outlined, errorText: _emailServerError),
                    ),
                    SizedBox(height: sizes.adminFormFieldGap),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _fieldDecoration(hintText: 'phone_hint'.tr(), icon: Icons.phone_outlined),
                    ),
                    SizedBox(height: sizes.adminFormFieldGap),

                    // 🔴 FIX (kifma tlab): city/birthday - kanou affichés
                    // fel écran détail lakin mch modifiables mel formulaire.
                    TextFormField(
                      controller: _cityController,
                      decoration: _fieldDecoration(hintText: 'city_label'.tr(), icon: Icons.location_city_outlined),
                    ),
                    SizedBox(height: sizes.adminFormFieldGap),

                    TextFormField(
                      controller: _birthdayController,
                      keyboardType: TextInputType.datetime,
                      decoration: _fieldDecoration(hintText: 'birthday_hint'.tr(), icon: Icons.cake_outlined),
                    ),

                    SizedBox(height: sizes.adminFormFieldGap),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      // 🔵 ZID (kifma tlab: "les données mtaa el admin
                      // nom mail w mdp num telephone w ville") - fel
                      // mode création, password obligatoire (validator
                      // 7a9i9i). Fel mode modification, optionnel -
                      // fadhi = ma yetbeddelch, fa validator ye5dem
                      // ghir ken el user KETEB 7aja (mch fadhi 3ali9a).
                      validator: widget.isEditMode
                          ? (value) => (value == null || value.isEmpty) ? null : Validators.signupPassword(value)
                          : Validators.signupPassword,
                      decoration: _fieldDecoration(
                        hintText: widget.isEditMode ? 'new_password_hint'.tr() : 'password_hint'.tr(),
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.vertpetsy),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),

                    SizedBox(height: sizes.adminFormButtonTopGap),
                    Center(
                      child: CustomButton(
                        text: _isSubmitting ? 'loading_label'.tr() : 'save_button'.tr(),
                        color: AppColors.pinkpetsy,
                        widthFactor: 0.85,
                        heightFactor: 0.07,
                        fontFactor: 0.40,
                        enabled: !_isSubmitting,
                        onPressed: _onSubmit,
                      ),
                    ),
                    SizedBox(height: sizes.adminFormBottomGap),
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
}