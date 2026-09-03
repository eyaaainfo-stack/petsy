import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../controllers/admin_users_controller.dart';
import '../../../models/admin_validation_candidate.dart';
import '../../../models/admin_verification_settings.dart';
import '../../../services/api_service.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/paw_widget.dart';
import '../../../widgets/message_dialog.dart';

// ============================================================================
// AdminValidationsScreen ("Validation")
// ============================================================================
// 🔵 ZID: kifma tlab - "wkt el checklist tekmel tjii lel admin
// proposition bch ywalli valider - bouton ekher tht l'avis esmha
// validation" - queue el comptes (owner/sitter/courier, mch verified
// 3ad) elli el checklist tou3hom KAMLA (el backend déjà ye-filtri) -
// el admin ychouf el checklist w ye5tar "Valider" (proposition, mch
// confiance a3ma).
// ============================================================================
class AdminValidationsScreen extends StatefulWidget {
  const AdminValidationsScreen({super.key});

  @override
  State<AdminValidationsScreen> createState() => _AdminValidationsScreenState();
}

class _AdminValidationsScreenState extends State<AdminValidationsScreen> {
  final AdminUsersController _controller = AdminUsersController();

  List<AdminValidationCandidate>? _candidates;
  bool _isLoading = true;
  bool _hasError = false;
  // 🔵 id el compte elli 9ademou "Valider" 7ali (bch nwarrouh loading
  // 3al bouton mte3ou bark, mch el écran el kol).
  String? _validatingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final candidates = await _controller.fetchValidations();
    if (!mounted) return;

    setState(() {
      _candidates = candidates;
      _hasError = candidates == null;
      _isLoading = false;
    });
  }

  Future<void> _openSettingsDialog() async {
    final settings = await _controller.fetchVerificationSettings();
    if (!mounted) return;

    if (settings == null) {
      showMessageDialog(context, 'login_generic_error'.tr());
      return;
    }

    final sitterServicesCtrl = TextEditingController(text: '${settings.sitterMinServices}');
    final sitterClientsCtrl = TextEditingController(text: '${settings.sitterMinDistinctClients}');
    final sitterPercentCtrl = TextEditingController(text: settings.sitterMinGoodReviewPercent.toStringAsFixed(0));
    final ownerServicesCtrl = TextEditingController(text: '${settings.ownerMinServices}');
    final ownerPercentCtrl = TextEditingController(text: settings.ownerMinGoodReviewPercent.toStringAsFixed(0));

    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget numberField(TextEditingController ctrl, String label) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
                ),
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('verification_settings_title'.tr()),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    numberField(sitterServicesCtrl, 'sitter_min_services_label'.tr()),
                    numberField(sitterClientsCtrl, 'sitter_min_distinct_clients_label'.tr()),
                    numberField(sitterPercentCtrl, 'sitter_min_good_review_percent_label'.tr()),
                    numberField(ownerServicesCtrl, 'owner_min_services_label'.tr()),
                    numberField(ownerPercentCtrl, 'owner_min_good_review_percent_label'.tr()),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text('cancel_button'.tr())),
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          final newSettings = AdminVerificationSettings(
                            sitterMinServices: int.tryParse(sitterServicesCtrl.text) ?? settings.sitterMinServices,
                            sitterMinDistinctClients: int.tryParse(sitterClientsCtrl.text) ?? settings.sitterMinDistinctClients,
                            sitterMinGoodReviewPercent: double.tryParse(sitterPercentCtrl.text) ?? settings.sitterMinGoodReviewPercent,
                            ownerMinServices: int.tryParse(ownerServicesCtrl.text) ?? settings.ownerMinServices,
                            ownerMinGoodReviewPercent: double.tryParse(ownerPercentCtrl.text) ?? settings.ownerMinGoodReviewPercent,
                          );
                          final success = await _controller.updateVerificationSettings(newSettings);
                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();
                          if (!mounted) return;
                          showMessageDialog(context, success ? 'settings_saved_success'.tr() : 'login_generic_error'.tr());
                          // 🔵 el seuils etbeddlou - el liste "prêts" mumkin
                          // tetbeddel zeda (compte kan complete, tawa mch
                          // complete, wela l'3aks) - refresh.
                          if (success) _load();
                        },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('save_button'.tr(), style: const TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'role_owner_label'.tr();
      case 'sitter':
        return 'role_sitter_label'.tr();
      case 'courier':
        return 'role_courier_label'.tr();
      default:
        return role;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'owner':
        return AppColors.vertpetsy;
      case 'sitter':
        return AppColors.pinkpetsy;
      case 'courier':
        return AppColors.primarySeed;
      default:
        return AppColors.vertpetsy;
    }
  }

  // 🔵 esm el critère (backend) -> label mtarjem ("fullName" ->
  // "Nom complet") - reuse el keys 'checklist_*_label' (déjà mzoudin).
  String _checklistLabel(String key) {
    final trKey = 'checklist_${key}_label';
    final translated = trKey.tr();
    // ken el key ma3andouch traduction (mch mawjouda), easy_localization
    // yrajja3 el key nafsou - fallback sahel (esm el champ direct).
    return translated == trKey ? key : translated;
  }

  Future<void> _onValidatePressed(AdminValidationCandidate candidate) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('validate_confirm_title'.tr()),
        content: Text('validate_confirm_message'.tr(namedArgs: {'name': candidate.user.fullName.isNotEmpty ? candidate.user.fullName : candidate.user.email})),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text('cancel_button'.tr())),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('validate_button'.tr(), style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _validatingId = candidate.user.id);
    final bool success = await _controller.verifyUser(candidate.user.id);
    if (!mounted) return;

    setState(() => _validatingId = null);

    if (success) {
      setState(() => _candidates?.removeWhere((c) => c.user.id == candidate.user.id));
      showMessageDialog(context, 'account_verified_success'.tr());
    } else {
      showMessageDialog(context, 'login_generic_error'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            buildPetPaw(context: context, size: sizes.adminValidationsPawSize, topPercent: 0.025, leftPercent: 0.85, color: AppColors.vertpetsy.withOpacity(0.5)),

            RefreshIndicator(
              onRefresh: _load,
              color: AppColors.pinkpetsy,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: sizes.adminValidationsHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: sizes.adminValidationsTopGap),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'validations_title'.tr(),
                            style: TextStyle(fontSize: sizes.adminValidationsTitleFontSize, fontWeight: FontWeight.bold, color: AppColors.pinkpetsy),
                          ),
                        ),
                        // 🔵 ZID (kifma tlab): "khalli les conditions
                        // hedhom yodhhrou 3and el admin w ynajem
                        // yamlelhom modification") - réglages (seuils).
                        IconButton(
                          onPressed: _openSettingsDialog,
                          icon: Icon(Icons.settings_outlined, color: AppColors.vertpetsy, size: sizes.adminValidationsAvatarFontSize * 1.4),
                        ),
                      ],
                    ),
                    SizedBox(height: sizes.adminValidationsSectionGap),

                    if (_isLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.adminValidationsLoadingVerticalPad),
                        child: Center(child: CircularProgressIndicator(color: AppColors.vertpetsy)),
                      )
                    else if (_hasError)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.adminValidationsErrorVerticalPad),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.wifi_off_rounded, color: mutedTextColor.withOpacity(0.6), size: sizes.adminValidationsEmptyStateIcon),
                              SizedBox(height: sizes.adminValidationsErrorIconGap),
                              Text('stats_load_error'.tr(), textAlign: TextAlign.center, style: TextStyle(color: mutedTextColor)),
                              SizedBox(height: sizes.adminValidationsErrorButtonGap),
                              TextButton(
                                onPressed: _load,
                                child: Text('retry_button'.tr(), style: const TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_candidates != null && _candidates!.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.adminValidationsEmptyStateVerticalPad),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.verified_outlined, color: mutedTextColor.withOpacity(0.5), size: sizes.adminValidationsEmptyStateIcon),
                              SizedBox(height: sizes.adminValidationsErrorIconGap),
                              Text('no_validations_found_label'.tr(), textAlign: TextAlign.center, style: TextStyle(color: mutedTextColor)),
                            ],
                          ),
                        ),
                      )
                    else if (_candidates != null)
                      Column(
                        children: [
                          for (final candidate in _candidates!) ...[
                            _ValidationCard(
                              candidate: candidate,
                              roleLabel: _roleLabel(candidate.user.role),
                              roleColor: _roleColor(candidate.user.role),
                              checklistLabel: _checklistLabel,
                              isSubmitting: _validatingId == candidate.user.id,
                              onValidate: () => _onValidatePressed(candidate),
                            ),
                            SizedBox(height: sizes.adminValidationsCardGap),
                          ],
                        ],
                      ),

                    SizedBox(height: sizes.adminValidationsBottomGap),
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

// ============================================================================
// _ValidationCard: avatar+esm+role + checklist (kol el 7ou9oul ✓ 5edhra,
// el backend déjà ye-filtri ghir el comptes 100% kamlin) + bouton
// "Valider".
// ============================================================================
class _ValidationCard extends StatelessWidget {
  final AdminValidationCandidate candidate;
  final String roleLabel;
  final Color roleColor;
  final String Function(String) checklistLabel;
  final bool isSubmitting;
  final VoidCallback onValidate;

  const _ValidationCard({
    required this.candidate,
    required this.roleLabel,
    required this.roleColor,
    required this.checklistLabel,
    required this.isSubmitting,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;

    return Container(
      padding: EdgeInsets.all(sizes.adminValidationsCardPadding),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(sizes.adminValidationsAvatarSize * 0.35),
                child: Container(
                  width: sizes.adminValidationsAvatarSize,
                  height: sizes.adminValidationsAvatarSize,
                  color: roleColor.withOpacity(0.16),
                  alignment: Alignment.center,
                  child: (candidate.user.photoUrl.isNotEmpty)
                      ? Image.network(
                          '${ApiService.mediaBaseUrl}${candidate.user.photoUrl}',
                          fit: BoxFit.cover,
                          width: sizes.adminValidationsAvatarSize,
                          height: sizes.adminValidationsAvatarSize,
                          errorBuilder: (context, error, stackTrace) => Text(
                            candidate.user.initials,
                            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: sizes.adminValidationsAvatarFontSize),
                          ),
                        )
                      : Text(
                          candidate.user.initials,
                          style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: sizes.adminValidationsAvatarFontSize),
                        ),
                ),
              ),
              SizedBox(width: sizes.adminValidationsAvatarTextGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.user.fullName.isNotEmpty ? candidate.user.fullName : candidate.user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: sizes.adminValidationsNameFontSize, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                    SizedBox(height: sizes.adminValidationsNameRoleGap),
                    Text(
                      roleLabel,
                      style: TextStyle(fontSize: sizes.adminValidationsRoleFontSize, fontWeight: FontWeight.w600, color: roleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ------------------------------------------------------
          // Checklist (el 7ou9oul el kol ✓ - el backend déjà
          // ye-filtri ghir el comptes 100% kamlin).
          // ------------------------------------------------------
          SizedBox(height: sizes.adminValidationsChecklistTopGap),
          Wrap(
            spacing: sizes.adminValidationsChecklistItemGap,
            runSpacing: sizes.adminValidationsChecklistItemGap * 0.6,
            children: candidate.checklist.keys.map((key) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: sizes.adminValidationsChecklistItemFontSize * 1.2),
                  SizedBox(width: sizes.adminValidationsChecklistItemGap * 0.4),
                  Text(
                    checklistLabel(key),
                    style: TextStyle(fontSize: sizes.adminValidationsChecklistItemFontSize, color: mutedTextColor),
                  ),
                ],
              );
            }).toList(),
          ),

          // ------------------------------------------------------
          // Pièce d'identité (CIN) recto/verso - kifma tlab: "9bal ma
          // el admin ya3mel valider lezmou ychouf el recto wel verso" -
          // TOUJOURS affichés houni (mch écran mnfassel) bch el admin
          // ynajjam ye5tar "Valider" b'ma3rifa kaملa, mch b'3ama.
          // ------------------------------------------------------
          SizedBox(height: sizes.adminValidationsChecklistTopGap),
          Text(
            'checklist_cin_label'.tr(),
            style: TextStyle(fontSize: sizes.adminValidationsRoleFontSize, fontWeight: FontWeight.w600, color: mutedTextColor),
          ),
          SizedBox(height: sizes.adminValidationsChecklistItemGap),
          Row(
            children: [
              Expanded(child: _CinPreview(label: 'cin_front_label'.tr(), url: candidate.user.cinFrontPhotoUrl)),
              SizedBox(width: sizes.adminValidationsChecklistItemGap),
              Expanded(child: _CinPreview(label: 'cin_back_label'.tr(), url: candidate.user.cinBackPhotoUrl)),
            ],
          ),

          // ------------------------------------------------------
          // Bouton "Valider"
          // ------------------------------------------------------
          SizedBox(height: sizes.adminValidationsButtonTopGap),
          SizedBox(
            width: double.infinity,
            height: sizes.adminValidationsButtonHeight,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : onValidate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.verified_outlined, color: Colors.white, size: 18),
              label: Text(
                isSubmitting ? 'loading_label'.tr() : 'validate_button'.tr(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _CinPreview: vignette recto/verso (tap = plein écran, kifma tlab:
// "lezmou ychouf el recto wel verso" - 9bal el clic 3ala "Valider").
// ============================================================================
class _CinPreview extends StatelessWidget {
  final String label;
  final String url;

  const _CinPreview({required this.label, required this.url});

  void _openFullScreen(BuildContext context) {
    if (url.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: InteractiveViewer(
            child: Image.network('${ApiService.mediaBaseUrl}$url', fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.55) ?? Colors.grey;

    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: mutedTextColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          AspectRatio(
            aspectRatio: 1.5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
                child: url.isNotEmpty
                    ? Image.network(
                        '${ApiService.mediaBaseUrl}$url',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.badge_outlined, color: mutedTextColor),
                      )
                    : Icon(Icons.hourglass_empty_rounded, color: mutedTextColor, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}