import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/account_security_controller.dart';
import '../../controllers/auth_session.dart';
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