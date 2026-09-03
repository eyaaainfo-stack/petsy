import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../controllers/admin_users_controller.dart';
import '../../../models/admin_user.dart';
import '../../../models/admin_user_detail.dart';
import '../../../services/api_service.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/paw_widget.dart';
import '../../../widgets/stat_card.dart';
import 'admin_account_form.dart';
import '../../../widgets/message_dialog.dart';

// ============================================================================
// AdminAccountDetailScreen ("Utilisateurs")
// ============================================================================
// 🔵 ZID: kifma tlab (référence: screenshot auto-école) - "ki nenzel
// 3ala wa7ed mel acteurs, yjini esm/mail/num/ville, w ken sitter kadeh
// men service amlou/rofdho, w ken owner kadeh 3andou pet/talab/
// tkbelt/trafdhet".
//
// 🔴 Note (limite data model, mch bug): "Refusées" w "Annulées" mel
// backend 7isba WA7DA COMBINÉE (chraht kaملa fel adminController.js/
// getUserDetail) - el schema el 7ali mafamech status 'cancelled'
// mnfassel 3an 'rejected'.
// ============================================================================
class AdminAccountDetailScreen extends StatefulWidget {
  final AdminUser user;

  const AdminAccountDetailScreen({super.key, required this.user});

  @override
  State<AdminAccountDetailScreen> createState() => _AdminAccountDetailScreenState();
}

class _AdminAccountDetailScreenState extends State<AdminAccountDetailScreen> {
  final AdminUsersController _controller = AdminUsersController();

  AdminUserDetail? _detail;
  bool _isLoading = true;
  bool _hasError = false;

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

    final detail = await _controller.fetchUserDetail(widget.user.id);
    if (!mounted) return;

    setState(() {
      _detail = detail;
      _hasError = detail == null;
      _isLoading = false;
    });
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'role_owner_label'.tr();
      case 'sitter':
        return 'role_sitter_label'.tr();
      case 'courier':
        return 'role_courier_label'.tr();
      case 'admin':
        return 'role_admin_label'.tr();
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
      case 'admin':
        return AppColors.error;
      default:
        return AppColors.vertpetsy;
    }
  }

  Future<void> _onEditPressed() async {
    final result = await Navigator.of(context).push<AdminUser>(
      MaterialPageRoute(builder: (_) => AdminAccountFormScreen(existingUser: widget.user)),
    );
    if (result != null) _load();
  }

  Future<void> _onDeletePressed() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('delete_account_confirm_title'.tr()),
        content: Text('delete_account_confirm_message'.tr(namedArgs: {'name': widget.user.fullName.isNotEmpty ? widget.user.fullName : widget.user.email})),
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

    final result = await _controller.deleteUser(widget.user.id);
    if (!mounted) return;

    if (result.success) {
      // 🔵 nrejjaou "true" l'AdminAccountsScreen - bch ta3mel refresh
      // (el compte etfassa5 - ma3adech mawjoud fel liste).
      Navigator.of(context).pop(true);
    } else {
      showMessageDialog(context, result.errorMessage ?? 'login_generic_error'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;
    final Color roleColor = _roleColor(widget.user.role);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            buildPetPaw(context: context, size: sizes.adminDetailPawSize, topPercent: 0.025, leftPercent: 0.85, color: AppColors.vertpetsy.withOpacity(0.5)),

            RefreshIndicator(
              onRefresh: _load,
              color: AppColors.pinkpetsy,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: sizes.adminDetailHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: sizes.adminDetailTopGap),

                    // --------------------------------------------------
                    // Header: avatar + esm + badge role
                    // --------------------------------------------------
                    Center(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(sizes.adminDetailAvatarSize * 0.32),
                            child: Container(
                              width: sizes.adminDetailAvatarSize,
                              height: sizes.adminDetailAvatarSize,
                              color: roleColor.withOpacity(0.16),
                              alignment: Alignment.center,
                              child: (widget.user.photoUrl.isNotEmpty)
                                  ? Image.network(
                                      '${ApiService.mediaBaseUrl}${widget.user.photoUrl}',
                                      fit: BoxFit.cover,
                                      width: sizes.adminDetailAvatarSize,
                                      height: sizes.adminDetailAvatarSize,
                                      errorBuilder: (context, error, stackTrace) => Text(
                                        widget.user.initials,
                                        style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: sizes.adminDetailAvatarFontSize),
                                      ),
                                    )
                                  : Text(
                                      widget.user.initials,
                                      style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: sizes.adminDetailAvatarFontSize),
                                    ),
                            ),
                          ),
                          SizedBox(height: sizes.adminDetailAvatarNameGap),
                          Text(
                            widget.user.fullName.isNotEmpty ? widget.user.fullName : widget.user.email,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: sizes.adminDetailNameFontSize, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                          SizedBox(height: sizes.adminDetailNameBadgeGap),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: sizes.adminDetailBadgeHPadding, vertical: sizes.adminDetailBadgeVPadding),
                            decoration: BoxDecoration(color: roleColor, borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              _roleLabel(widget.user.role),
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.adminDetailBadgeFontSize),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: sizes.adminDetailHeaderSectionGap),

                    if (_isLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.adminDetailLoadingVerticalPad),
                        child: Center(child: CircularProgressIndicator(color: AppColors.vertpetsy)),
                      )
                    else if (_hasError)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.adminDetailErrorVerticalPad),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.wifi_off_rounded, color: mutedTextColor.withOpacity(0.6), size: sizes.adminReviewsEmptyStateIcon),
                              SizedBox(height: sizes.adminDetailErrorIconGap),
                              Text('stats_load_error'.tr(), textAlign: TextAlign.center, style: TextStyle(color: mutedTextColor)),
                              SizedBox(height: sizes.adminDetailErrorButtonGap),
                              TextButton(
                                onPressed: _load,
                                child: Text('retry_button'.tr(), style: const TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_detail != null) ...[
                      // --------------------------------------------------
                      // Informations personnelles
                      // --------------------------------------------------
                      Text(
                        'personal_info_section_label'.tr(),
                        style: TextStyle(fontSize: sizes.adminDetailSectionTitleFontSize, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      SizedBox(height: sizes.adminDetailSectionTitleGap),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: sizes.adminDetailCardPadding),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            _InfoRow(icon: Icons.person_outline, color: AppColors.vertpetsy, label: 'name_label'.tr(), value: _detail!.user.fullName),
                            _rowDivider(context),
                            _InfoRow(icon: Icons.email_outlined, color: AppColors.pinkpetsy, label: 'email_label'.tr(), value: _detail!.user.email),
                            _rowDivider(context),
                            _InfoRow(icon: Icons.phone_outlined, color: AppColors.vertpetsy, label: 'phone_label'.tr(), value: _detail!.user.phone),
                            _rowDivider(context),
                            _InfoRow(icon: Icons.location_city_outlined, color: AppColors.pinkpetsy, label: 'city_label'.tr(), value: _detail!.user.city, isLast: _detail!.user.birthday.isEmpty),
                            if (_detail!.user.birthday.isNotEmpty) ...[
                              _rowDivider(context),
                              _InfoRow(icon: Icons.cake_outlined, color: AppColors.vertpetsy, label: 'birthday_label'.tr(), value: _detail!.user.birthday, isLast: true),
                            ],
                          ],
                        ),
                      ),

                      // --------------------------------------------------
                      // Pièce d'identité (CIN) - READ-ONLY (kifma tlab:
                      // "fazet el cin... el USER nafsou yeb3ath biha") -
                      // l'admin yechouf bark (bch yverifi 9bal "Valider"),
                      // ma ynajjamch ye3addel/yeb3ath mel formulaire.
                      // ------------------------------------------------
                      if (_detail!.user.cinFrontPhotoUrl.isNotEmpty || _detail!.user.cinBackPhotoUrl.isNotEmpty) ...[
                        SizedBox(height: sizes.adminDetailSectionGap),
                        Text(
                          'checklist_cin_label'.tr(),
                          style: TextStyle(fontSize: sizes.adminDetailSectionTitleFontSize, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        SizedBox(height: sizes.adminDetailSectionTitleGap),
                        Row(
                          children: [
                            Expanded(child: _CinThumbnail(label: 'cin_front_label'.tr(), url: _detail!.user.cinFrontPhotoUrl)),
                            SizedBox(width: sizes.adminDetailButtonGap),
                            Expanded(child: _CinThumbnail(label: 'cin_back_label'.tr(), url: _detail!.user.cinBackPhotoUrl)),
                          ],
                        ),
                      ],

                      // --------------------------------------------------
                      // Statistiques (owner WALA sitter bark - courier/
                      // admin ma3andhomch stats specifiques houni)
                      // --------------------------------------------------
                      if (_detail!.ownerStats != null) ...[
                        SizedBox(height: sizes.adminDetailSectionGap),
                        Text(
                          'account_stats_section_label'.tr(),
                          style: TextStyle(fontSize: sizes.adminDetailSectionTitleFontSize, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        SizedBox(height: sizes.adminDetailSectionTitleGap),
                        Wrap(
                          spacing: sizes.adminDetailStatsGridSpacing,
                          runSpacing: sizes.adminDetailStatsGridSpacing,
                          children: [
                            SizedBox(width: sizes.adminDetailStatCardWidth, child: StatCard(icon: Icons.pets, color: AppColors.vertpetsy, value: '${_detail!.ownerStats!.petsCount}', label: 'pets_owned_label'.tr())),
                            SizedBox(width: sizes.adminDetailStatCardWidth, child: StatCard(icon: Icons.send_outlined, color: AppColors.pinkpetsy, value: '${_detail!.ownerStats!.requestsCount}', label: 'requests_sent_label'.tr())),
                            SizedBox(width: sizes.adminDetailStatCardWidth, child: StatCard(icon: Icons.check_circle_outline, color: AppColors.vertpetsy, value: '${_detail!.ownerStats!.acceptedCount}', label: 'requests_accepted_label'.tr())),
                            SizedBox(width: sizes.adminDetailStatCardWidth, child: StatCard(icon: Icons.cancel_outlined, color: AppColors.pinkpetsy, value: '${_detail!.ownerStats!.refusedCount}', label: 'requests_refused_cancelled_label'.tr())),
                          ],
                        ),
                      ],

                      if (_detail!.sitterStats != null) ...[
                        SizedBox(height: sizes.adminDetailSectionGap),
                        Text(
                          'account_stats_section_label'.tr(),
                          style: TextStyle(fontSize: sizes.adminDetailSectionTitleFontSize, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        SizedBox(height: sizes.adminDetailSectionTitleGap),
                        Wrap(
                          spacing: sizes.adminDetailStatsGridSpacing,
                          runSpacing: sizes.adminDetailStatsGridSpacing,
                          children: [
                            SizedBox(width: sizes.adminDetailStatCardWidth, child: StatCard(icon: Icons.check_circle_outline, color: AppColors.vertpetsy, value: '${_detail!.sitterStats!.completedCount}', label: 'services_completed_label'.tr())),
                            SizedBox(width: sizes.adminDetailStatCardWidth, child: StatCard(icon: Icons.cancel_outlined, color: AppColors.pinkpetsy, value: '${_detail!.sitterStats!.refusedCount}', label: 'services_refused_cancelled_label'.tr())),
                          ],
                        ),
                      ],

                      // --------------------------------------------------
                      // Modifier / Supprimer - WALA "Ajouter un autre
                      // admin" ken el compte houwa el admin principal
                      // (kifma tlab: "el admin principale nhbou y39od
                      // fixe, nahhili bouton modifier w supp w badlhom
                      // b ajouter un autre admin").
                      // --------------------------------------------------
                      SizedBox(height: sizes.adminDetailSectionGap),
                      if (widget.user.isPrincipalAdmin)
                        SizedBox(
                          width: double.infinity,
                          height: sizes.adminDetailButtonHeight,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.of(context).push<AdminUser>(
                                MaterialPageRoute(builder: (_) => const AdminAccountFormScreen(initialRole: 'admin')),
                              );
                              if (result != null && mounted) Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.pinkpetsy,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 18),
                            label: Text('add_another_admin_button'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: sizes.adminDetailButtonHeight,
                                child: ElevatedButton.icon(
                                  onPressed: _onEditPressed,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.textDark,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                                  label: Text('edit_button'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            SizedBox(width: sizes.adminDetailButtonGap),
                            Expanded(
                              child: SizedBox(
                                height: sizes.adminDetailButtonHeight,
                                child: OutlinedButton.icon(
                                  onPressed: _onDeletePressed,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.error, width: 1.4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                  label: Text('delete_button'.tr(), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],

                    SizedBox(height: sizes.adminDetailBottomGap),
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

  Widget _rowDivider(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(height: 1, color: (isDark ? Colors.white : Colors.black).withOpacity(0.08));
  }
}

// ============================================================================
// _InfoRow: icon (dayer coloré) + label (muted) + value (bold) - nafs
// l'idée tel screenshot référence ("Nom & Prénom", "Email"...).
// ============================================================================
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({required this.icon, required this.color, required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.55) ?? Colors.grey;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizes.adminDetailRowVerticalPadding),
      child: Row(
        children: [
          Container(
            width: sizes.adminDetailRowIconSize,
            height: sizes.adminDetailRowIconSize,
            decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: sizes.adminDetailRowIconInner),
          ),
          SizedBox(width: sizes.adminDetailRowTextGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: sizes.adminDetailRowLabelFontSize, color: mutedTextColor, fontWeight: FontWeight.w600)),
                SizedBox(height: sizes.adminDetailRowLabelValueGap),
                Text(
                  value.isNotEmpty ? value : 'not_provided_label'.tr(),
                  style: TextStyle(
                    fontSize: sizes.adminDetailRowValueFontSize,
                    fontWeight: FontWeight.w600,
                    color: value.isNotEmpty ? Theme.of(context).textTheme.bodyLarge?.color : mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _CinThumbnail: recto/verso CIN - READ-ONLY (kifma tlab: "fazet el
// cin... el USER nafsou yeb3ath biha") - l'admin yechouf bark.
// ============================================================================
class _CinThumbnail extends StatelessWidget {
  final String label;
  final String url;

  const _CinThumbnail({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.55) ?? Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: mutedTextColor, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1.6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
              child: url.isNotEmpty
                  ? Image.network(
                      '${ApiService.mediaBaseUrl}$url',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.badge_outlined, color: mutedTextColor),
                    )
                  : Icon(Icons.badge_outlined, color: mutedTextColor),
            ),
          ),
        ),
      ],
    );
  }
}