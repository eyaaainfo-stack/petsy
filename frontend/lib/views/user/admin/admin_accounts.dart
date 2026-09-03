import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../controllers/admin_users_controller.dart';
import '../../../models/admin_user.dart';
import '../../../services/api_service.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/paw_widget.dart';
import 'admin_account_form.dart';
import 'admin_account_detail.dart';
import '../../../widgets/message_dialog.dart';

// ============================================================================
// AdminAccountsScreen ("Gestion des comptes")
// ============================================================================
// 🔵 ZID: kifma tlab - "bouton consulter/gestion des comptes - kif
// nenzel aliha tjini recherche par nom ya yjiwni les users lkol wla
// ena nkhtar - w poss eni na3mel création de compte kima f teswira
// (référence: interface auto-école) ama b theme petsy".
//
// 🔵 Design: nafs l'idée tel screenshot référence (search bar, filter
// chips par role, "X comptes" + bouton create, liste b'avatar/nom/
// role/email + edit/delete) - ghir b'theme Petsy (rose/vert, rounded,
// pastel - mch dark navbar tel référence).
// ============================================================================
class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  final AdminUsersController _controller = AdminUsersController();
  final TextEditingController _searchController = TextEditingController();

  List<AdminUser>? _users;
  bool _isLoading = true;
  bool _hasError = false;
  String _roleFilter = 'all';
  // 🔵 debounce: bch ma na3ytouch l'API 3ala kol 7arf yekteb el admin
  // (mathalan "fedi" = 4 appels) - ghir 350ms ba3d ma yo9od ye5arbet.
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final users = await _controller.fetchUsers(search: _searchController.text, role: _roleFilter);
    if (!mounted) return;

    setState(() {
      _users = users;
      _hasError = users == null;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  void _onFilterChanged(String role) {
    if (_roleFilter == role) return;
    setState(() => _roleFilter = role);
    _load();
  }

  Future<void> _onCreatePressed() async {
    final result = await Navigator.of(context).push<AdminUser>(
      MaterialPageRoute(builder: (_) => const AdminAccountFormScreen()),
    );
    if (result != null) _load();
  }

  Future<void> _onEditPressed(AdminUser user) async {
    final result = await Navigator.of(context).push<AdminUser>(
      MaterialPageRoute(builder: (_) => AdminAccountFormScreen(existingUser: user)),
    );
    if (result != null) _load();
  }

  // 🔵 ZID: kifma tlab - "ki nenzel ala wa7d mel les acteurs" - tap
  // 3al card el kol (mch ghir el icons edit/delete) yemchi l'écran
  // détail (infos perso + stats 7asb el role).
  Future<void> _onViewDetailPressed(AdminUser user) async {
    // 🔵 dima refresh ki el admin yerja3 (soit ba3d modification mel
    // écran détail, soit ba3d suppression, soit ghir retour 3adi) -
    // bch el liste tab9a up-to-date bla ay condition zeyda.
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdminAccountDetailScreen(user: user)),
    );
    _load();
  }

  Future<void> _onDeletePressed(AdminUser user) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('delete_account_confirm_title'.tr()),
        content: Text('delete_account_confirm_message'.tr(namedArgs: {'name': user.fullName.isNotEmpty ? user.fullName : user.email})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('cancel_button'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('delete_button'.tr(), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await _controller.deleteUser(user.id);
    if (!mounted) return;

    if (result.success) {
      setState(() => _users?.removeWhere((u) => u.id == user.id));
      showMessageDialog(context, 'account_deleted_success'.tr());
    } else {
      showMessageDialog(context, result.errorMessage ?? 'login_generic_error'.tr());
    }
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

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            buildPetPaw(context: context, size: sizes.adminAccountsPawSize, topPercent: 0.025, leftPercent: 0.85, color: AppColors.pinkpetsy.withOpacity(0.5)),

            RefreshIndicator(
              onRefresh: _load,
              color: AppColors.pinkpetsy,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: sizes.adminAccountsHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: sizes.adminAccountsTopGap),
                    Text(
                      'accounts_title'.tr(),
                      style: TextStyle(fontSize: sizes.adminAccountsTitleFontSize, fontWeight: FontWeight.bold, color: AppColors.pinkpetsy),
                    ),
                    SizedBox(height: sizes.adminAccountsSectionGap),

                    // ------------------------------------------------
                    // Recherche par nom / email
                    // ------------------------------------------------
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'accounts_search_hint'.tr(),
                        prefixIcon: Icon(Icons.search, color: AppColors.vertpetsy, size: sizes.adminAccountsSearchIcon),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.pinkpetsy, width: 1.5)),
                      ),
                      style: TextStyle(fontSize: sizes.adminAccountsSearchFontSize),
                    ),
                    SizedBox(height: sizes.adminAccountsFilterChipGap),

                    // ------------------------------------------------
                    // Filtre par role (Tous/Owners/Sitters/Couriers)
                    // ------------------------------------------------
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('all', 'accounts_filter_all'.tr()),
                          SizedBox(width: sizes.adminAccountsChipSpacing),
                          _filterChip('owner', 'role_owner_label'.tr()),
                          SizedBox(width: sizes.adminAccountsChipSpacing),
                          _filterChip('sitter', 'role_sitter_label'.tr()),
                          SizedBox(width: sizes.adminAccountsChipSpacing),
                          _filterChip('courier', 'role_courier_label'.tr()),
                        ],
                      ),
                    ),
                    SizedBox(height: sizes.adminAccountsCountRowGap),

                    // ------------------------------------------------
                    // "X comptes" + bouton "Créer un compte"
                    // ------------------------------------------------
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'accounts_count_label'.tr(namedArgs: {'count': '${_users?.length ?? 0}'}),
                            style: TextStyle(fontSize: sizes.adminAccountsCountFontSize, color: mutedTextColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                        GestureDetector(
                          onTap: _onCreatePressed,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: sizes.adminAccountsCreateButtonHPadding, vertical: sizes.adminAccountsCreateButtonVPadding),
                            decoration: BoxDecoration(color: AppColors.pinkpetsy, borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: Colors.white, size: sizes.adminAccountsCreateButtonIcon),
                                SizedBox(width: sizes.adminAccountsChipSpacing * 0.5),
                                Text(
                                  'create_account_button'.tr(),
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.adminAccountsCreateButtonFontSize),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: sizes.adminAccountsListGap),

                    // ------------------------------------------------
                    // Liste el comptes / états loading/erreur/vide
                    // ------------------------------------------------
                    if (_isLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.adminAccountsLoadingVerticalPad),
                        child: Center(child: CircularProgressIndicator(color: AppColors.vertpetsy)),
                      )
                    else if (_hasError)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.adminAccountsErrorVerticalPad),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.wifi_off_rounded, color: mutedTextColor.withOpacity(0.6), size: sizes.adminAccountsEmptyStateIcon),
                              SizedBox(height: sizes.adminAccountsErrorIconGap),
                              Text('stats_load_error'.tr(), textAlign: TextAlign.center, style: TextStyle(color: mutedTextColor)),
                              SizedBox(height: sizes.adminAccountsErrorButtonGap),
                              TextButton(
                                onPressed: _load,
                                child: Text('retry_button'.tr(), style: const TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_users != null && _users!.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.adminAccountsEmptyStateVerticalPad),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.person_search_outlined, color: mutedTextColor.withOpacity(0.5), size: sizes.adminAccountsEmptyStateIcon),
                              SizedBox(height: sizes.adminAccountsErrorIconGap),
                              Text('no_accounts_found_label'.tr(), textAlign: TextAlign.center, style: TextStyle(color: mutedTextColor)),
                            ],
                          ),
                        ),
                      )
                    else if (_users != null)
                      Column(
                        children: [
                          for (final user in _users!) ...[
                            _AccountCard(
                              user: user,
                              roleLabel: _roleLabel(user.role),
                              roleColor: _roleColor(user.role),
                              onTap: () => _onViewDetailPressed(user),
                              onEdit: () => _onEditPressed(user),
                              onDelete: () => _onDeletePressed(user),
                            ),
                            SizedBox(height: sizes.adminAccountsCardGap),
                          ],
                        ],
                      ),

                    SizedBox(height: sizes.adminAccountsBottomGap),
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

  Widget _filterChip(String role, String label) {
    final sizes = AppSizes.of(context);
    final bool selected = _roleFilter == role;
    return GestureDetector(
      onTap: () => _onFilterChanged(role),
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
}

// ============================================================================
// _AccountCard: avatar (photo wla initiales) + esm + role + email +
// icons edit/delete - nafs l'idée tel screenshot référence.
// ============================================================================
class _AccountCard extends StatelessWidget {
  final AdminUser user;
  final String roleLabel;
  final Color roleColor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.user,
    required this.roleLabel,
    required this.roleColor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;

    // 🔵 ZID: kifma tlab - "ki nenzel ala wa7d mel les acteurs" -
    // Material+InkWell 3al card el kol (tap = écran détail) - el
    // IconButton(edit/delete) jowaha ye5dou el tap el propre (Flutter
    // ye3ti automatique l'awlawiya lel widget el as8ar/el akther
    // spécifique fel gesture arena - "onTap" el Card mch yet3awa9)
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
      padding: EdgeInsets.all(sizes.adminAccountsCardPadding),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(sizes.adminAccountsAvatarSize * 0.35),
            child: Container(
              width: sizes.adminAccountsAvatarSize,
              height: sizes.adminAccountsAvatarSize,
              color: roleColor.withOpacity(0.16),
              alignment: Alignment.center,
              // 🔴 FIX ("khallihom bel pdp mte3hom"): kanet Image.network
              // (user.photoUrl) DIRECT - lakin photoUrl mel backend
              // chemin relatif ("/uploads/users/xxx.jpg"), mch URL kamla -
              // Image.network ma ynajjamch y-load-ih (icon "cassée").
              // Tawa: ApiService.mediaBaseUrl + photoUrl (nafs mant9
              // el app el kol - admin_login.dart/splash_decider.dart) +
              // errorBuilder (ken el photo 7a9i9i lakin fichier mfa9ed/
              // erreur réseau, twarri initiales bdal icon cassée, mch
              // twa9af el app).
              child: (user.photoUrl.isNotEmpty)
                  ? Image.network(
                      '${ApiService.mediaBaseUrl}${user.photoUrl}',
                      fit: BoxFit.cover,
                      width: sizes.adminAccountsAvatarSize,
                      height: sizes.adminAccountsAvatarSize,
                      errorBuilder: (context, error, stackTrace) => Text(
                        user.initials,
                        style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: sizes.adminAccountsAvatarFontSize),
                      ),
                    )
                  : Text(
                      user.initials,
                      style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: sizes.adminAccountsAvatarFontSize),
                    ),
            ),
          ),
          SizedBox(width: sizes.adminAccountsAvatarTextGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: sizes.adminAccountsNameFontSize, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                SizedBox(height: sizes.adminAccountsNameRoleGap),
                Text(
                  roleLabel,
                  style: TextStyle(fontSize: sizes.adminAccountsRoleFontSize, fontWeight: FontWeight.w600, color: roleColor),
                ),
                SizedBox(height: sizes.adminAccountsRoleEmailGap),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: sizes.adminAccountsEmailFontSize, color: mutedTextColor),
                ),
              ],
            ),
          ),
          // 🔵 ZID (kifma tlab: "el admin principale nhbou y39od fixe,
          // nahhili bouton modifier w supp") - el admin principal:
          // icon "lock" bark (mafamech edit/delete) - el bouton "Ajouter
          // un autre admin" mawjoud fel écran détail (tap 3al card).
          if (user.isPrincipalAdmin)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sizes.adminAccountsChipSpacing * 0.6),
              child: Icon(Icons.lock_outline, color: mutedTextColor, size: sizes.adminAccountsActionIcon),
            )
          else ...[
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, color: AppColors.vertpetsy, size: sizes.adminAccountsActionIcon),
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: AppColors.error, size: sizes.adminAccountsActionIcon),
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }
}