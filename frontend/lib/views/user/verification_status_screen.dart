import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/verification_controller.dart';
import '../../models/verification_status.dart';
import '../../widgets/back_button.dart';
import '../../widgets/paw_widget.dart';
import '../../widgets/message_dialog.dart';

// ============================================================================
// VerificationStatusScreen ("Vérification")
// ============================================================================
// 🔵 ZID: kifma tlab - "and el acteurs hotha fi interface jdida
// todkhlelha kif tenzel ala bouton verification fel side bar w kol ma
// conditions tsiir tetaamlelha tick automatiquement" - el owner/sitter/
// courier ychouf checklist + progress (kadeh 3andou / kadeh lezmou)
// mte3ou nafsou, w el tick ytebeddel automatique (data 7a9i9iya mel
// backend, mch statique).
//
// 🔴 FIX (kifma tlab: "fazet el cin kif yekmlou les conditions lkol w
// tjih fenetre... sawae el cin mteek men kodem w men telii") - popup
// automatique ki el conditions l'okhrin el kol (barra el CIN) ykounou
// True - ye5tar el user "front"+"back" (image_picker) w yeb3ath el 2
// f'nefs el appel.
// ============================================================================
class VerificationStatusScreen extends StatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  State<VerificationStatusScreen> createState() => _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  final VerificationController _controller = VerificationController();
  VerificationStatus? _status;
  bool _isLoading = true;
  bool _hasError = false;
  // 🔵 bch el popup ma yerja3ch yban 3ala kol rebuild/refresh mnfassel -
  // wa7da bark par "visite" tel écran.
  bool _cinPopupShown = false;

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

    final status = await _controller.fetchMyStatus();
    if (!mounted) return;

    setState(() {
      _status = status;
      _hasError = status == null;
      _isLoading = false;
    });

    _maybeShowCinPopup();
  }

  // 🔵 ZID (kifma tlab): "kif yekmlou les conditions lkol [barra el
  // CIN] tjih fenetre" - ken el critère 'cin' mawjoud fel checklist
  // (owner/sitter/courier el 3), mch True 3ad, W el critères l'okhrin
  // el kol True - popup automatique (wa7da bark).
  void _maybeShowCinPopup() {
    if (_status == null || _cinPopupShown) return;
    final checklist = _status!.checklist;
    if (!checklist.containsKey('cin') || checklist['cin'] == true) return;

    final bool othersComplete = checklist.entries.where((e) => e.key != 'cin').every((e) => e.value == true);
    if (!othersComplete) return;

    _cinPopupShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showCinUploadDialog();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  // 🔵 esm el critère (backend) -> label mtarjem - reuse el keys
  // 'checklist_*_label' (déjà mzoudin, nafs style tel admin_validations.dart).
  String _label(String key) {
    final trKey = 'checklist_${key}_label';
    final translated = trKey.tr();
    return translated == trKey ? key : translated;
  }

  // 🔵 el texte "progress" ta7t el label (mathalan "45/100") - null
  // lel critères el sahlin (bool bark, mafamech ra9m mrabout bihom).
  String? _progressText(String key, VerificationMetrics m) {
    switch (key) {
      case 'minServices':
        if (m.servicesCount == null || m.servicesRequired == null) return null;
        return '${m.servicesCount}/${m.servicesRequired}';
      case 'minDistinctClients':
        if (m.distinctClients == null || m.distinctClientsRequired == null) return null;
        return '${m.distinctClients}/${m.distinctClientsRequired}';
      case 'goodReviewPercent':
        if (m.goodReviewPercentRequired == null) return null;
        if (m.goodReviewPercent == null) return 'not_enough_reviews_label'.tr();
        return '${m.goodReviewPercent}% / ${m.goodReviewPercentRequired!.toStringAsFixed(0)}%';
      default:
        return null;
    }
  }

  // ==========================================================================
  // Popup upload CIN (recto+verso)
  // ==========================================================================
  void _showCinUploadDialog() {
    Uint8List? frontBytes;
    Uint8List? backBytes;
    bool isSubmitting = false;

    Future<void> pickImage(void Function(void Function()) setDialogState, bool isFront) async {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setDialogState(() {
        if (isFront) {
          frontBytes = bytes;
        } else {
          backBytes = bytes;
        }
      });
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget photoTile(String label, Uint8List? bytes, bool isFront) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => pickImage(setDialogState, isFront),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1.4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            color: AppColors.vertpetsy.withOpacity(0.1),
                            child: bytes != null
                                ? Image.memory(bytes, fit: BoxFit.cover)
                                : Icon(Icons.add_a_photo_outlined, color: AppColors.vertpetsy),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            }

            final bool canSubmit = frontBytes != null && backBytes != null && !isSubmitting;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('cin_popup_title'.tr()),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('cin_popup_message'.tr(), style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        photoTile('cin_pick_front_button'.tr(), frontBytes, true),
                        const SizedBox(width: 12),
                        photoTile('cin_pick_back_button'.tr(), backBytes, false),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text('later_button'.tr()),
                ),
                TextButton(
                  onPressed: !canSubmit
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          final success = await _controller.uploadCin(frontBytes: frontBytes!, backBytes: backBytes!);
                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();
                          if (!mounted) return;
                          showMessageDialog(context, success ? 'cin_upload_success'.tr() : 'cin_upload_error'.tr());
                          if (success) _load();
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('cin_send_button'.tr(), style: const TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
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
            buildPetPaw(context: context, size: sizes.verificationPawSize, topPercent: 0.025, leftPercent: 0.85, color: AppColors.vertpetsy.withOpacity(0.5)),

            RefreshIndicator(
              onRefresh: _load,
              color: AppColors.pinkpetsy,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: sizes.verificationHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: sizes.verificationTopGap),
                    Text(
                      'verification_title'.tr(),
                      style: TextStyle(fontSize: sizes.verificationTitleFontSize, fontWeight: FontWeight.bold, color: AppColors.pinkpetsy),
                    ),
                    SizedBox(height: sizes.verificationSectionGap),

                    if (_isLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.verificationLoadingVerticalPad),
                        child: Center(child: CircularProgressIndicator(color: AppColors.vertpetsy)),
                      )
                    else if (_hasError)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.verificationErrorVerticalPad),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.wifi_off_rounded, color: mutedTextColor.withOpacity(0.6), size: sizes.verificationBannerIcon),
                              SizedBox(height: sizes.verificationErrorIconGap),
                              Text('stats_load_error'.tr(), textAlign: TextAlign.center, style: TextStyle(color: mutedTextColor)),
                              SizedBox(height: sizes.verificationErrorButtonGap),
                              TextButton(
                                onPressed: _load,
                                child: Text('retry_button'.tr(), style: const TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_status != null) ...[
                      // --------------------------------------------------
                      // Bandeau status: vérifié (5edhra) / prêt-en attente
                      // (kahwa) / encore à compléter (teal, 3adi).
                      // --------------------------------------------------
                      _statusBanner(context, sizes),
                      SizedBox(height: sizes.verificationSectionGap),

                      // --------------------------------------------------
                      // Checklist (icon ✓/○ + label + progress ken mawjoud)
                      // 🔵 el ligne 'cin' tappable (ken mch met 3ad) -
                      // temchi l'nefs popup (mch ghir automatique).
                      // --------------------------------------------------
                      for (final entry in _status!.checklist.entries) ...[
                        _checklistRow(context, sizes, entry.key, entry.value, isDark, mutedTextColor),
                        SizedBox(height: sizes.verificationRowLabelProgressGap * 4),
                      ],
                    ],

                    SizedBox(height: sizes.verificationBottomGap),
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

  Widget _statusBanner(BuildContext context, AppSizes sizes) {
    final status = _status!;

    late final Color color;
    late final IconData icon;
    late final String message;
    String? sub;

    if (status.isVerified) {
      color = AppColors.success;
      icon = Icons.verified;
      message = 'verified_account_message'.tr();
      if (status.verifiedAt != null) {
        sub = 'verified_since_label'.tr(namedArgs: {'date': _formatDate(status.verifiedAt)});
      }
    } else if (status.isComplete) {
      color = Colors.amber.shade700;
      icon = Icons.hourglass_top_rounded;
      message = 'verification_ready_message'.tr();
    } else {
      color = AppColors.vertpetsy;
      icon = Icons.checklist_rounded;
      message = 'verification_in_progress_message'.tr();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sizes.verificationBannerPadding),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: sizes.verificationBannerIcon),
          SizedBox(width: sizes.verificationBannerIconGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: TextStyle(fontSize: sizes.verificationBannerFontSize, fontWeight: FontWeight.bold, color: color)),
                if (sub != null) ...[
                  SizedBox(height: sizes.verificationRowLabelProgressGap * 3),
                  Text(sub, style: TextStyle(fontSize: sizes.verificationRowProgressFontSize, color: color.withOpacity(0.85))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checklistRow(BuildContext context, AppSizes sizes, String key, bool met, bool isDark, Color mutedTextColor) {
    final String? progress = _progressText(key, _status!.metrics);
    final Color color = met ? AppColors.success : mutedTextColor;
    // 🔵 ZID: el ligne 'cin' (ken mch met 3ad) tappable - temchi l'nefs
    // popup manuellement (mch besoin nestenna el popup automatique).
    final bool isTappable = key == 'cin' && !met;

    final Widget row = Container(
      padding: EdgeInsets.all(sizes.verificationRowPadding),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
            size: sizes.verificationRowIcon,
          ),
          SizedBox(width: sizes.verificationRowTextGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label(key),
                  style: TextStyle(
                    fontSize: sizes.verificationRowLabelFontSize,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (progress != null) ...[
                  SizedBox(height: sizes.verificationRowLabelProgressGap),
                  Text(progress, style: TextStyle(fontSize: sizes.verificationRowProgressFontSize, color: mutedTextColor)),
                ],
              ],
            ),
          ),
          if (isTappable) Icon(Icons.chevron_right, color: mutedTextColor, size: sizes.verificationRowIcon),
        ],
      ),
    );

    if (!isTappable) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _showCinUploadDialog,
        child: row,
      ),
    );
  }
}