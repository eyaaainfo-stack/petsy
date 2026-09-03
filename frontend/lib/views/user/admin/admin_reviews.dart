import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../controllers/admin_reviews_controller.dart';
import '../../../models/admin_review.dart';
import '../../../services/api_service.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/paw_widget.dart';

// ============================================================================
// AdminReviewsScreen ("Avis")
// ============================================================================
// 🔵 ZID: kifma tlab - "m3a gestion des comptes zidni bouton ekher
// esmou avis" - vue globale 3ala kol el "avis" (CheckoutQuestionnaire
// completed) - esm el reviewee (chkoun etwa9a3), rating (njoum),
// commentaire, breakdown (4 catégories), w chkoun katbou (reviewer)
// + wa9tha.
// ============================================================================
class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  final AdminReviewsController _controller = AdminReviewsController();
  final TextEditingController _searchController = TextEditingController();

  List<AdminReview>? _reviews;
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _debounce;
  // 🔵 ZID (kifma tlab: "les avis nhbhom mkassmin pour owner w sitter") -
  // 'all' / 'owner' / 'sitter' - ye-filtri 3ala "revieweeRole" (chkoun
  // etwa9a3, mch chkoun katab) - filtrage LOCAL (el 200 avis déjà
  // mjabdin mel backend, mafamech lezoum appel API zeyda - sehla).
  String _roleFilter = 'all';

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

    final reviews = await _controller.fetchReviews(search: _searchController.text);
    if (!mounted) return;

    setState(() {
      _reviews = reviews;
      _hasError = reviews == null;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  // 🔵 filtrage local (mch appel API) - sehla w wadh7a.
  List<AdminReview> get _filteredReviews {
    final all = _reviews ?? [];
    if (_roleFilter == 'all') return all;
    return all.where((r) => r.revieweeRole == _roleFilter).toList();
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

  // 🔵 "14/08/2026" - format sahel, bla package "intl" zeyda.
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
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
            buildPetPaw(context: context, size: sizes.adminReviewsPawSize, topPercent: 0.025, leftPercent: 0.85, color: AppColors.pinkpetsy.withOpacity(0.5)),

            RefreshIndicator(
              onRefresh: _load,
              color: AppColors.pinkpetsy,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: sizes.adminReviewsHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: sizes.adminReviewsTopGap),
                    Text(
                      'reviews_title'.tr(),
                      style: TextStyle(fontSize: sizes.adminReviewsTitleFontSize, fontWeight: FontWeight.bold, color: AppColors.pinkpetsy),
                    ),
                    SizedBox(height: sizes.adminReviewsSectionGap),

                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'reviews_search_hint'.tr(),
                        prefixIcon: Icon(Icons.search, color: AppColors.vertpetsy, size: sizes.adminReviewsSearchIcon),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.pinkpetsy, width: 1.5)),
                      ),
                      style: TextStyle(fontSize: sizes.adminReviewsSearchFontSize),
                    ),
                    SizedBox(height: sizes.adminReviewsFilterChipGap),

                    // ------------------------------------------------
                    // Onglets Owner/Sitter (kifma tlab: "mkassmin pour
                    // owner w sitter") - nafs style el chips tel
                    // "Gestion des comptes" (adminAccountsChip*).
                    // ------------------------------------------------
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _roleFilterChip('all', 'accounts_filter_all'.tr()),
                          SizedBox(width: sizes.adminAccountsChipSpacing),
                          _roleFilterChip('owner', 'role_owner_label'.tr()),
                          SizedBox(width: sizes.adminAccountsChipSpacing),
                          _roleFilterChip('sitter', 'role_sitter_label'.tr()),
                        ],
                      ),
                    ),
                    SizedBox(height: sizes.adminReviewsListGap),

                    if (_isLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.adminReviewsLoadingVerticalPad),
                        child: Center(child: CircularProgressIndicator(color: AppColors.vertpetsy)),
                      )
                    else if (_hasError)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.adminReviewsErrorVerticalPad),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.wifi_off_rounded, color: mutedTextColor.withOpacity(0.6), size: sizes.adminReviewsEmptyStateIcon),
                              SizedBox(height: sizes.adminReviewsErrorIconGap),
                              Text('stats_load_error'.tr(), textAlign: TextAlign.center, style: TextStyle(color: mutedTextColor)),
                              SizedBox(height: sizes.adminReviewsErrorButtonGap),
                              TextButton(
                                onPressed: _load,
                                child: Text('retry_button'.tr(), style: const TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_reviews != null && _filteredReviews.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.adminReviewsEmptyStateVerticalPad),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.rate_review_outlined, color: mutedTextColor.withOpacity(0.5), size: sizes.adminReviewsEmptyStateIcon),
                              SizedBox(height: sizes.adminReviewsErrorIconGap),
                              Text('no_reviews_found_label'.tr(), textAlign: TextAlign.center, style: TextStyle(color: mutedTextColor)),
                            ],
                          ),
                        ),
                      )
                    else if (_reviews != null)
                      Column(
                        children: [
                          for (final review in _filteredReviews) ...[
                            _ReviewCard(
                              review: review,
                              revieweeRoleLabel: _roleLabel(review.revieweeRole),
                              reviewerRoleLabel: _roleLabel(review.reviewerRole),
                              dateLabel: _formatDate(review.createdAt),
                              onTap: () => _showReviewDetail(context, review),
                            ),
                            SizedBox(height: sizes.adminReviewsCardGap),
                          ],
                        ],
                      ),

                    SizedBox(height: sizes.adminReviewsBottomGap),
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

  Widget _roleFilterChip(String role, String label) {
    final sizes = AppSizes.of(context);
    final bool selected = _roleFilter == role;
    return GestureDetector(
      onTap: () => setState(() => _roleFilter = role),
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

  // 🔵 ZID (kifma tlab: "kif nenzel ala 1 yjini les réponses ala el
  // questionnaire de les deux, kifkif ou kan") - bottom sheet sahla:
  // 2 blocs mkeb-bin (el avis el mich lik + el sibling, wla "mazel ma
  // jawebch" ken el sibling null) - TOUJOURS el 2, mch ghir ken conflit.
  void _showReviewDetail(BuildContext context, AdminReview review) {
    final sizes = AppSizes.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.all(sizes.adminReviewsHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: sizes.adminReviewsSectionGap),
                      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Text(
                    'both_responses_title'.tr(),
                    style: TextStyle(fontSize: sizes.adminReviewsTitleFontSize * 0.75, fontWeight: FontWeight.bold, color: AppColors.pinkpetsy),
                  ),
                  SizedBox(height: sizes.adminReviewsSectionGap),

                  // el avis el 7ali (card elli tappa 3lih el admin)
                  _AnswerBlock(
                    reviewerName: review.reviewerName,
                    reviewerRoleLabel: _roleLabel(review.reviewerRole),
                    status: review.status,
                    serviceDone: review.serviceDone,
                    serviceDoneReason: review.serviceDoneReason,
                    checkoutDone: review.checkoutDone,
                    paymentDone: review.paymentDone,
                    paymentNotDoneReason: review.paymentNotDoneReason,
                    satisfied: review.satisfied,
                    ratingTrust: review.ratingTrust,
                    ratingService: review.ratingService,
                    ratingCommunication: review.ratingCommunication,
                    ratingKnowledge: review.ratingKnowledge,
                    averageRating: review.averageRating,
                    reviewText: review.review,
                    dateLabel: _formatDate(review.createdAt),
                  ),
                  SizedBox(height: sizes.adminReviewsSectionGap),

                  // el avis tel "l'autre partie" (sibling) - wla
                  // placeholder ken mazel ma jawebch.
                  if (review.siblingReview != null)
                    _AnswerBlock(
                      reviewerName: review.siblingReview!.reviewerName,
                      reviewerRoleLabel: _roleLabel(review.siblingReview!.reviewerRole),
                      status: review.siblingReview!.status,
                      serviceDone: review.siblingReview!.serviceDone,
                      serviceDoneReason: review.siblingReview!.serviceDoneReason,
                      checkoutDone: review.siblingReview!.checkoutDone,
                      paymentDone: review.siblingReview!.paymentDone,
                      paymentNotDoneReason: review.siblingReview!.paymentNotDoneReason,
                      satisfied: review.siblingReview!.satisfied,
                      ratingTrust: review.siblingReview!.ratingTrust,
                      ratingService: review.siblingReview!.ratingService,
                      ratingCommunication: review.siblingReview!.ratingCommunication,
                      ratingKnowledge: review.siblingReview!.ratingKnowledge,
                      averageRating: review.siblingReview!.averageRating,
                      reviewText: review.siblingReview!.review,
                      dateLabel: _formatDate(review.siblingReview!.createdAt),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(sizes.adminReviewsCardPadding),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_empty_rounded, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
                          SizedBox(width: sizes.adminReviewsBreakdownGap),
                          Expanded(
                            child: Text(
                              'sibling_response_pending_label'.tr(),
                              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: sizes.adminReviewsSectionGap),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// _ReviewCard: reviewee (avatar+esm+role) + rating (njoum) + commentaire
// + breakdown (4 catégories) + footer (reviewer + date + satisfied icon).
// ============================================================================
class _ReviewCard extends StatelessWidget {
  final AdminReview review;
  final String revieweeRoleLabel;
  final String reviewerRoleLabel;
  final String dateLabel;
  final VoidCallback onTap;

  const _ReviewCard({
    required this.review,
    required this.revieweeRoleLabel,
    required this.reviewerRoleLabel,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;
    final Color dividerColor = (isDark ? Colors.white : Colors.black).withOpacity(0.08);
    // 🔵 ZID (kifma tlab: "ken jewbou aks ba3dhom fel oui/non tjini en
    // rouge, w ken el total mtaa etoiles a9al men 2 zeda tjini en
    // rouge") - flag WA7ED bark ("needsAttention") - background rouge
    // pastel (nafs style el app - AppColors.error.withOpacity) bdal el
    // gris el 3adi, + bordure rouge fine bch tban mel awla.
    final bool needsAttention = review.hasConflict || review.isLowRating;

    // 🔵 ZID (kifma tlab: "kif nenzel ala 1 yjini les réponses ala el
    // questionnaire de les deux") - Material+InkWell 3al card el kol -
    // tap = bottom sheet b'el 2 réponses (chraht fel _showReviewDetail).
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
      padding: EdgeInsets.all(sizes.adminReviewsCardPadding),
      decoration: BoxDecoration(
        color: needsAttention ? AppColors.error.withOpacity(isDark ? 0.14 : 0.08) : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(18),
        border: needsAttention ? Border.all(color: AppColors.error.withOpacity(0.4), width: 1.2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------------
          // Bandeau alerte (kifma tlab) - ghir ken conflit WALA note
          // ba33ida - message sahel/direct, bla ay jargon.
          // --------------------------------------------------------
          if (needsAttention) ...[
            if (review.hasConflict)
              Padding(
                padding: EdgeInsets.only(bottom: review.isLowRating ? sizes.adminReviewsBreakdownGap * 0.5 : 0),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error, size: sizes.adminReviewsSatisfiedIcon),
                    SizedBox(width: sizes.adminReviewsBreakdownGap * 0.4),
                    Expanded(
                      child: Text(
                        'review_conflict_warning'.tr(),
                        style: TextStyle(fontSize: sizes.adminReviewsFooterFontSize, fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            if (review.isLowRating)
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: sizes.adminReviewsSatisfiedIcon),
                  SizedBox(width: sizes.adminReviewsBreakdownGap * 0.4),
                  Expanded(
                    child: Text(
                      'review_low_rating_warning'.tr(),
                      style: TextStyle(fontSize: sizes.adminReviewsFooterFontSize, fontWeight: FontWeight.bold, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            SizedBox(height: sizes.adminReviewsDividerGap),
          ],

          // --------------------------------------------------------
          // Reviewee (chkoun etwa9a3) + rating moyenne
          // --------------------------------------------------------
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(sizes.adminReviewsAvatarSize * 0.35),
                child: Container(
                  width: sizes.adminReviewsAvatarSize,
                  height: sizes.adminReviewsAvatarSize,
                  color: AppColors.vertpetsy.withOpacity(0.16),
                  alignment: Alignment.center,
                  child: (review.revieweePhotoUrl.isNotEmpty)
                      ? Image.network(
                          '${ApiService.mediaBaseUrl}${review.revieweePhotoUrl}',
                          fit: BoxFit.cover,
                          width: sizes.adminReviewsAvatarSize,
                          height: sizes.adminReviewsAvatarSize,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: AppColors.vertpetsy, size: sizes.adminReviewsAvatarSize * 0.55),
                        )
                      : Icon(Icons.person, color: AppColors.vertpetsy, size: sizes.adminReviewsAvatarSize * 0.55),
                ),
              ),
              SizedBox(width: sizes.adminReviewsAvatarTextGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.revieweeName.isNotEmpty ? review.revieweeName : '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: sizes.adminReviewsNameFontSize, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                    SizedBox(height: sizes.adminReviewsNameRoleGap),
                    Text(
                      revieweeRoleLabel,
                      style: TextStyle(fontSize: sizes.adminReviewsRoleFontSize, fontWeight: FontWeight.w600, color: AppColors.vertpetsy),
                    ),
                  ],
                ),
              ),
              if (review.isFullyCompleted) ...[
                Icon(Icons.star_rounded, color: Colors.amber, size: sizes.adminReviewsStarIcon),
                SizedBox(width: sizes.adminReviewsBreakdownGap * 0.4),
                Text(
                  review.averageRating.toStringAsFixed(1),
                  style: TextStyle(fontSize: sizes.adminReviewsRatingFontSize, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
              ] else
                Container(
                  padding: EdgeInsets.symmetric(horizontal: sizes.adminReviewsBreakdownGap * 0.6, vertical: sizes.adminReviewsBreakdownGap * 0.25),
                  decoration: BoxDecoration(color: mutedTextColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    _statusLabel(review.status),
                    style: TextStyle(fontSize: sizes.adminReviewsBreakdownFontSize, fontWeight: FontWeight.w600, color: mutedTextColor),
                  ),
                ),
            ],
          ),

          // --------------------------------------------------------
          // Commentaire + breakdown - GHIR ken el questionnaire wesel
          // l'étape 4 (isFullyCompleted) - ken mazel, "tap pour voir
          // le détail" bark (el status badge fou9 déjà mfahhem).
          // --------------------------------------------------------
          if (review.isFullyCompleted) ...[
            SizedBox(height: sizes.adminReviewsReviewTextTopGap),
            Text(
              review.review.isNotEmpty ? review.review : 'review_no_comment_label'.tr(),
              style: TextStyle(
                fontSize: sizes.adminReviewsReviewTextFontSize,
                fontStyle: review.review.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                color: review.review.isNotEmpty ? Theme.of(context).textTheme.bodyLarge?.color : mutedTextColor,
                height: 1.35,
              ),
            ),

            SizedBox(height: sizes.adminReviewsDividerGap),
            Divider(height: 1, color: dividerColor),
            SizedBox(height: sizes.adminReviewsDividerGap),

            // ------------------------------------------------------
            // Breakdown (4 catégories) - reuse 'rating_*_label' (déjà
            // mawjoudin, questionnaire_rating_title feature).
            // ------------------------------------------------------
            Wrap(
              spacing: sizes.adminReviewsBreakdownGap,
              runSpacing: sizes.adminReviewsBreakdownGap * 0.5,
              children: [
                _breakdownChip(context, 'rating_trust_label'.tr(), review.ratingTrust),
                _breakdownChip(context, 'rating_service_label'.tr(), review.ratingService),
                _breakdownChip(context, 'rating_communication_label'.tr(), review.ratingCommunication),
                _breakdownChip(context, 'rating_knowledge_label'.tr(), review.ratingKnowledge),
              ],
            ),
          ] else ...[
            SizedBox(height: sizes.adminReviewsReviewTextTopGap),
            Text(
              review.serviceDone == false && review.serviceDoneReason.isNotEmpty
                  ? review.serviceDoneReason
                  : (review.paymentDone == false && review.paymentNotDoneReason.isNotEmpty ? review.paymentNotDoneReason : 'tap_for_details_label'.tr()),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: sizes.adminReviewsReviewTextFontSize, fontStyle: FontStyle.italic, color: mutedTextColor),
            ),
          ],

          // --------------------------------------------------------
          // Footer: satisfied icon + "Par {reviewer} (role)" + date
          // --------------------------------------------------------
          SizedBox(height: sizes.adminReviewsFooterTopGap),
          Row(
            children: [
              if (review.isFullyCompleted)
                Icon(
                  review.satisfied == true ? Icons.thumb_up_alt_rounded : Icons.thumb_down_alt_rounded,
                  color: review.satisfied == true ? AppColors.success : AppColors.error,
                  size: sizes.adminReviewsSatisfiedIcon,
                ),
              SizedBox(width: sizes.adminReviewsBreakdownGap * 0.5),
              Expanded(
                child: Text(
                  'review_by_label'.tr(namedArgs: {'name': review.reviewerName.isNotEmpty ? review.reviewerName : '—', 'role': reviewerRoleLabel}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: sizes.adminReviewsFooterFontSize, color: mutedTextColor),
                ),
              ),
              Text(dateLabel, style: TextStyle(fontSize: sizes.adminReviewsFooterFontSize, color: mutedTextColor)),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'status_pending_label'.tr();
      case 'awaiting_new_checkout':
        return 'status_awaiting_new_checkout_label'.tr();
      case 'stopped_service_not_done':
        return 'status_stopped_service_not_done_label'.tr();
      default:
        return status;
    }
  }

  Widget _breakdownChip(BuildContext context, String label, int? value) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;
    return Text(
      '$label ${value ?? '-'}',
      style: TextStyle(fontSize: sizes.adminReviewsBreakdownFontSize, color: mutedTextColor, fontWeight: FontWeight.w600),
    );
  }
}

// ============================================================================
// _AnswerBlock: réponse d'UNE partie (owner OU sitter) au questionnaire -
// testa3melha 2 mrat fel bottom sheet (_showReviewDetail) bch ywarri
// el 2 réponses mjem3in (kifma tlab: "les réponses de les deux, kifkif
// ou kan").
// ============================================================================
class _AnswerBlock extends StatelessWidget {
  final String reviewerName;
  final String reviewerRoleLabel;
  final String status;
  final bool? serviceDone;
  final String serviceDoneReason;
  final bool? checkoutDone;
  final bool? paymentDone;
  final String paymentNotDoneReason;
  final bool? satisfied;
  final int? ratingTrust;
  final int? ratingService;
  final int? ratingCommunication;
  final int? ratingKnowledge;
  final double averageRating;
  final String reviewText;
  final String dateLabel;

  const _AnswerBlock({
    required this.reviewerName,
    required this.reviewerRoleLabel,
    required this.status,
    required this.serviceDone,
    required this.serviceDoneReason,
    required this.checkoutDone,
    required this.paymentDone,
    required this.paymentNotDoneReason,
    required this.satisfied,
    required this.ratingTrust,
    required this.ratingService,
    required this.ratingCommunication,
    required this.ratingKnowledge,
    required this.averageRating,
    required this.reviewText,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;
    final Color dividerColor = (isDark ? Colors.white : Colors.black).withOpacity(0.08);
    // 🔵 ZID (kifma tlab: "nhb les réponses ala el questionnaire lkol,
    // mch ken l avis") - étape 4 (satisfaction+rating) tban GHIR ken
    // el questionnaire wselha ("satisfied" mch null) - lowkan mazel,
    // nwarrouh "pas encore atteint" bdal 0.0 njoum kadhba.
    final bool reachedSatisfactionStep = satisfied != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sizes.adminReviewsCardPadding),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'review_by_label'.tr(namedArgs: {'name': reviewerName.isNotEmpty ? reviewerName : '—', 'role': reviewerRoleLabel}),
                  style: TextStyle(fontSize: sizes.adminReviewsNameFontSize, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
              ),
              if (reachedSatisfactionStep) ...[
                Icon(
                  satisfied == true ? Icons.thumb_up_alt_rounded : Icons.thumb_down_alt_rounded,
                  color: satisfied == true ? AppColors.success : AppColors.error,
                  size: sizes.adminReviewsSatisfiedIcon,
                ),
                SizedBox(width: sizes.adminReviewsBreakdownGap * 0.4),
                Icon(Icons.star_rounded, color: Colors.amber, size: sizes.adminReviewsStarIcon),
                Text(
                  averageRating.toStringAsFixed(1),
                  style: TextStyle(fontSize: sizes.adminReviewsRatingFontSize, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
              ],
            ],
          ),
          SizedBox(height: sizes.adminReviewsNameRoleGap),
          Text(dateLabel, style: TextStyle(fontSize: sizes.adminReviewsRoleFontSize, color: mutedTextColor)),

          SizedBox(height: sizes.adminReviewsDividerGap),
          Divider(height: 1, color: dividerColor),
          SizedBox(height: sizes.adminReviewsDividerGap),

          // --------------------------------------------------------
          // Les 3 étapes el oula (kifma tlab: "el questionnaire lkol,
          // mch ken l avis") - service/checkout/paiement.
          // --------------------------------------------------------
          _stepRow(context, 'step_service_done_label'.tr(), serviceDone, reasonIfNo: serviceDoneReason),
          SizedBox(height: sizes.adminReviewsReviewTextTopGap),
          _stepRow(context, 'step_checkout_done_label'.tr(), checkoutDone),
          SizedBox(height: sizes.adminReviewsReviewTextTopGap),
          _stepRow(context, 'step_payment_done_label'.tr(), paymentDone, reasonIfNo: paymentNotDoneReason),

          SizedBox(height: sizes.adminReviewsDividerGap),
          Divider(height: 1, color: dividerColor),
          SizedBox(height: sizes.adminReviewsDividerGap),

          // --------------------------------------------------------
          // Étape 4: satisfaction + commentaire + breakdown - WALA
          // "pas encore atteint" ken el questionnaire mazel ma weselha.
          // --------------------------------------------------------
          Text(
            'satisfaction_step_label'.tr(),
            style: TextStyle(fontSize: sizes.adminReviewsRoleFontSize, color: mutedTextColor, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: sizes.adminReviewsReviewTextTopGap),
          if (!reachedSatisfactionStep)
            Text(
              'satisfaction_pending_label'.tr(),
              style: TextStyle(fontSize: sizes.adminReviewsReviewTextFontSize, fontStyle: FontStyle.italic, color: mutedTextColor),
            )
          else ...[
            Text(
              reviewText.isNotEmpty ? reviewText : 'review_no_comment_label'.tr(),
              style: TextStyle(
                fontSize: sizes.adminReviewsReviewTextFontSize,
                fontStyle: reviewText.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                color: reviewText.isNotEmpty ? Theme.of(context).textTheme.bodyLarge?.color : mutedTextColor,
                height: 1.35,
              ),
            ),
            SizedBox(height: sizes.adminReviewsDividerGap),
            Wrap(
              spacing: sizes.adminReviewsBreakdownGap,
              runSpacing: sizes.adminReviewsBreakdownGap * 0.5,
              children: [
                _chip(context, 'rating_trust_label'.tr(), ratingTrust),
                _chip(context, 'rating_service_label'.tr(), ratingService),
                _chip(context, 'rating_communication_label'.tr(), ratingCommunication),
                _chip(context, 'rating_knowledge_label'.tr(), ratingKnowledge),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 🔵 icon (✓ 5edhra/✗ 7amra/? griya ken null) + label + Oui/Non/– +
  // reason (ken "Non" w reason mawjouda).
  Widget _stepRow(BuildContext context, String label, bool? value, {String? reasonIfNo}) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;
    final IconData icon = value == null ? Icons.help_outline : (value ? Icons.check_circle : Icons.cancel);
    final Color color = value == null ? mutedTextColor : (value ? AppColors.success : AppColors.error);
    final String valueLabel = value == null ? 'not_provided_label'.tr() : (value ? 'yes_label'.tr() : 'no_label'.tr());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: sizes.adminReviewsSatisfiedIcon),
            SizedBox(width: sizes.adminReviewsBreakdownGap * 0.5),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: sizes.adminReviewsReviewTextFontSize, color: Theme.of(context).textTheme.bodyLarge?.color)),
            ),
            Text(valueLabel, style: TextStyle(fontSize: sizes.adminReviewsReviewTextFontSize, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        if (value == false && reasonIfNo != null && reasonIfNo.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: sizes.adminReviewsSatisfiedIcon + sizes.adminReviewsBreakdownGap * 0.5, top: 2),
            child: Text(
              reasonIfNo,
              style: TextStyle(fontSize: sizes.adminReviewsBreakdownFontSize, fontStyle: FontStyle.italic, color: mutedTextColor),
            ),
          ),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, int? value) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;
    return Text(
      '$label ${value ?? '-'}',
      style: TextStyle(fontSize: sizes.adminReviewsBreakdownFontSize, color: mutedTextColor, fontWeight: FontWeight.w600),
    );
  }
}