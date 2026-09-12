import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/account_security_controller.dart';
import '../../controllers/auth_session.dart';
import '../../models/pet_summary.dart';
import '../../repositories/pet_repository.dart';
import '../../widgets/back_button.dart';
import '../../widgets/message_dialog.dart';
import 'account_type.dart';
import 'change_password_screen.dart';

// ============================================================================
// SecuritySettingsScreen ("Confidentialité et sécurité")
// ============================================================================
// 🔵 ZID: kifma tlab - "el users tetzedelhom fel parametre changer el
// mdp wle faza kima el confidentialite mtaa el fb fiha changer le mdp
// w supprimer le compte" - écran fih "Changer le mot de passe" (role
// el kol) + "Supprimer mon compte" (owner/sitter/courier bark - l'admin
// nhbou "just changer le mdp").
// ============================================================================
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final AccountSecurityController _controller = AccountSecurityController();
  bool _isDeleting = false;
  // 🔵 ZID (kifma tlab: "supprimer le compte mtaa pets") - loading state
  // waqt el fetch tel liste tel pets (popup) w waqt el delete 7a9i9i.
  bool _isDeletingPet = false;

  // ==========================================================================
  // Flux "Supprimer mon compte": avertissement -> mot de passe -> appel API
  // -> déconnexion + retour à l'écran de connexion.
  // ==========================================================================
  Future<void> _onDeleteAccountPressed() async {
    final bool? confirmedWarning = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('delete_my_account_title'.tr()),
        content: Text('delete_my_account_warning'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text('cancel_button'.tr())),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('continue_button'.tr(), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmedWarning != true) return;
    if (!mounted) return;

    final TextEditingController passwordController = TextEditingController();
    bool obscure = true;

    final String? password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('confirm_password_title'.tr()),
            content: TextField(
              controller: passwordController,
              obscureText: obscure,
              decoration: InputDecoration(
                hintText: 'password_hint'.tr(),
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setDialogState(() => obscure = !obscure),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text('cancel_button'.tr())),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(passwordController.text),
                child: Text('delete_button'.tr(), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    if (password == null || password.isEmpty) return;
    if (!mounted) return;

    setState(() => _isDeleting = true);
    final result = await _controller.deleteAccount(password: password);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (result.success) {
      await AuthSession.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AccountTypeView()),
        (route) => false,
      );
    } else {
      showMessageDialog(context, result.errorMessage ?? 'login_generic_error'.tr());
    }
  }

  // ==========================================================================
  // Flux "Supprimer un animal" (kifma tlab: "tht supprimer mon compte
  // supprimer le compte mtaa pets... tjik liste mtaa el pets... w
  // tkhtar whd w tefskhou") - liste tel pets (bottom sheet) -> confirmation
  // (dialog avertissement) -> appel API -> refresh el liste.
  // ==========================================================================
  Future<void> _onDeletePetPressed() async {
    setState(() => _isDeletingPet = true);
    final pets = await PetRepository.fetchOwnerPets();
    if (!mounted) return;
    setState(() => _isDeletingPet = false);

    if (pets.isEmpty) {
      showMessageDialog(context, 'no_pets_to_delete_error'.tr());
      return;
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        final sizes = AppSizes.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(sizes.screenWidth * 0.06, sizes.screenWidth * 0.05, sizes.screenWidth * 0.06, sizes.screenWidth * 0.06),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('select_pet_to_delete_title'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                SizedBox(height: sizes.screenHeight * 0.015),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: pets.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.grey.withOpacity(0.15)),
                    itemBuilder: (context, index) {
                      final PetSummary pet = pets[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: sizes.screenWidth * 0.06,
                          backgroundColor: AppColors.pinkpetsy.withOpacity(0.12),
                          backgroundImage: pet.photoUrl != null ? NetworkImage(pet.photoUrl!) : null,
                          child: pet.photoUrl == null ? Icon(Icons.pets, color: AppColors.pinkpetsy) : null,
                        ),
                        title: Text(pet.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.delete_outline, color: AppColors.error),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _confirmAndDeletePet(pet);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndDeletePet(PetSummary pet) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('delete_pet_title'.tr()),
        content: Text('delete_pet_warning'.tr(namedArgs: {'name': pet.name})),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text('cancel_button'.tr())),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('delete_button'.tr(), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;
    if (pet.id == null) return;

    setState(() => _isDeletingPet = true);
    final result = await PetRepository.deletePet(pet.id!);
    if (!mounted) return;
    setState(() => _isDeletingPet = false);

    if (result.success) {
      showMessageDialog(context, 'pet_deleted_success_label'.tr());
    } else {
      showMessageDialog(context, result.errorMessage ?? 'login_generic_error'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sizes.fpHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: sizes.fpTopGap + sizes.fpBackButtonSize),
                  Text(
                    'security_settings_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.pinkpetsy, fontSize: sizes.fpTitleFontSize * 0.75),
                  ),
                  SizedBox(height: sizes.fpSectionGap * 1.5),

                  _settingsRow(
                    sizes: sizes,
                    icon: Icons.lock_outline,
                    label: 'change_password_label'.tr(),
                    mutedTextColor: mutedTextColor,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                    },
                  ),

                  // 🔵 ZID (kifma tlab: "elli tarfou khyr amlhouli. el
                  // admin nhb just changer le mdp") - "Supprimer mon
                  // compte" mafamech lel Admin (houwa ye7ذef mel
                  // "Gestion des comptes" bark, W bl protections
                  // l'okhrin - principal admin etc.).
                  if (AuthSession.userRole != 'admin') ...[
                    Divider(color: AppColors.pinkpetsy.withOpacity(0.15)),
                    _settingsRow(
                      sizes: sizes,
                      icon: Icons.delete_outline,
                      label: 'delete_my_account_label'.tr(),
                      mutedTextColor: AppColors.error,
                      iconColor: AppColors.error,
                      isLoading: _isDeleting,
                      onTap: _isDeleting ? null : _onDeleteAccountPressed,
                    ),
                  ],

                  // 🔵 ZID (kifma tlab: "nzid bouton fel parametre fel
                  // confidentialite tht supprimer mon compte, supprimer
                  // le compte mtaa pets... tjik liste mtaa el pets w
                  // tkhtar whd w tefskhou") - "owner" bark (houwa el
                  // wa7id eli 3andou pets).
                  if (AuthSession.userRole == 'owner') ...[
                    Divider(color: AppColors.pinkpetsy.withOpacity(0.15)),
                    _settingsRow(
                      sizes: sizes,
                      icon: Icons.pets,
                      label: 'delete_pet_label'.tr(),
                      mutedTextColor: AppColors.error,
                      iconColor: AppColors.error,
                      isLoading: _isDeletingPet,
                      onTap: _isDeletingPet ? null : _onDeletePetPressed,
                    ),
                  ],
                ],
              ),
            ),

            const CustomBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _settingsRow({
    required AppSizes sizes,
    required IconData icon,
    required String label,
    required Color mutedTextColor,
    Color? iconColor,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.018),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.pinkpetsy, size: sizes.screenWidth * 0.06),
            SizedBox(width: sizes.screenWidth * 0.04),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: sizes.myProfileBodyFontSize, color: iconColor),
              ),
            ),
            if (isLoading)
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: mutedTextColor))
            else
              Icon(Icons.chevron_right, color: mutedTextColor),
          ],
        ),
      ),
    );
  }
}