import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../controllers/my_profile_controller.dart';
import '../../../controllers/reviews_controller.dart';
import '../../../models/my_profile_data.dart';
import '../../../services/api_service.dart';
import '../../../widgets/verified_badge.dart';
import '../owner/request_a_book.dart';

// ============================================================================
// ViewProfileSitterScreen ("Pet Sitter Profile") - READ-ONLY
// ============================================================================
// 🔵 Wsulha mel card tel sitter (profile_owner.dart) - "distanceKm"
// yousel mennha zeda (déjà mahsouba, backend Haversine) bch tban "X km
// away of you" fel header, kifma tlab.
//
// 🔴 FIX (kifma tlab): 2 tabs "Details" / "Reviews (N)" - N tawa 3adad
// 7a9i9i (mel questionnaires "completed"), w el reviews yban 7a9i9iyin
// (avatar/esm/wa9t/rating/text) - MECH "0" fake mazel.
// ============================================================================
class ViewProfileSitterScreen extends StatefulWidget {
  final String sitterId;
  final double? distanceKm;
  // 🔵 ZID (kifma tlab): "View sitter's profile" mel booking_details.dart
  // (owner ychouf candidate sitter bch ye5tar ye9bel/yerfudh) - houni
  // el owner GHIR ychouf, mch ye3mel talab jdid - "Request a Booking"
  // ma3andouch me3na (fama déjà booking mte3ellek fel workflow).
  final bool hideBookingButton;
  // 🔵 ZID (kifma tlab): "el review el jdid... en gris claire" - dass
  // 3al notification "new_review" -> el écran yeftah 3al tab "Reviews"
  // direct, w el review el mo3ayana (relatedReviewId) tban highlighted.
  final String? highlightReviewId;
  final bool openReviewsTab;

  const ViewProfileSitterScreen({
    super.key,
    required this.sitterId,
    this.distanceKm,
    this.hideBookingButton = false,
    this.highlightReviewId,
    this.openReviewsTab = false,
  });

  @override
  State<ViewProfileSitterScreen> createState() => _ViewProfileSitterScreenState();
}

class _ViewProfileSitterScreenState extends State<ViewProfileSitterScreen> {
  final MyProfileController _controller = MyProfileController();
  final ReviewsController _reviewsController = ReviewsController();
  MyProfileData? _profile;
  bool _isLoading = true;
  bool _hasError = false;
  late bool _showDetailsTab; // 🔵 true = "Details", false = "Reviews"

  // 🔴 FIX (kifma tlab): "el rating ma waletach todhhor fel profile" -
  // reviews 7a9i9iyin (mel questionnaire, ba3d checkout) - MECH "0" fake.
  List<UserReview> _reviews = [];
  bool _isLoadingReviews = false;
  bool _hasLoadedReviews = false;

  @override
  void initState() {
    super.initState();
    _showDetailsTab = !widget.openReviewsTab;
    _load();
    if (widget.openReviewsTab) _loadReviews();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final profile = await _controller.fetchSitterPublicProfile(widget.sitterId);

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _isLoading = false;
      _hasError = profile == null;
    });
  }

  Future<void> _loadReviews() async {
    if (_hasLoadedReviews) return;
    setState(() => _isLoadingReviews = true);
    final result = await _reviewsController.fetchReviews(widget.sitterId);
    if (!mounted) return;
    setState(() {
      _reviews = result.reviews;
      _isLoadingReviews = false;
      _hasLoadedReviews = true;
    });
  }

  static const Map<String, String> _serviceLabelKeys = {
    'house_sitting': 'sitter_service_house_sitting',
    'dog_walking': 'sitter_service_dog_walking',
    'doggy_day_care': 'sitter_service_doggy_day_care',
    'boarding': 'sitter_service_boarding',
    'overnight_stays': 'sitter_service_overnight_stays',
    'home_visits': 'sitter_service_home_visits',
  };

  String _serviceLabel(String serviceId) {
    final key = _serviceLabelKeys[serviceId];
    return key != null ? key.tr() : serviceId;
  }

  String _residenceLabel(String? residenceType) {
    switch (residenceType) {
      case 'apartment':
        return 'sitter_residence_apartment'.tr();
      case 'house':
        return 'sitter_residence_house'.tr();
      case 'countryHouse':
        return 'sitter_residence_country_house'.tr();
      default:
        return '-';
    }
  }

  String _petTypeLabel(String petType) {
    switch (petType) {
      case 'cat':
        return 'sitter_pet_type_cat'.tr();
      case 'dog':
        return 'sitter_pet_type_dog'.tr();
      case 'both':
        return 'sitter_pet_type_both'.tr();
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;
    // 🔴 FIX: kanet color THABTA ("#E3F2FD", bleu clair) - dima nafsha
    // 7atta fel dark mode, tban khayeb (kontrast 7ad ma3a background
    // 3atmi). Tawa: teal ghami9 mourih (dark mode) / bleu clair
    // (light mode) - text (esm/city/distance) yeb9a ye9ra sa7i7 fel
    // zoùj 7alat.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color headerBgColor = isDark ? AppColors.vertpetsy.withOpacity(0.22) : const Color(0xFFE3F2FD);
    // 🔴 FIX (kifma tlab): fel dark mode, background el "Details/Avis"
    // (tabs) ynahha (transparent) - el header ye5alli el loun mte3ou.
    final Color tabsBgColor = isDark ? Colors.transparent : const Color(0xFFE3F2FD);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError || _profile == null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.1),
                          child: Text('no_profile_data_error'.tr(), textAlign: TextAlign.center, style: TextStyle(color: mutedTextColor)),
                        ),
                      )
                    : Column(
                        children: [
                          // ------------------------------------------------
                          // 🔴 FIX (kifma tlab): Header + About me + Tabs
                          // tawa "CONSTANT" (barra ay scroll) - GHIR el
                          // content ta7t "Details/Reviews" yetharrak
                          // (SingleChildScrollView ta7t, mfassel).
                          // ------------------------------------------------
                          _SitterHeader(profile: _profile!, distanceKm: widget.distanceKm, sizes: sizes, mutedTextColor: mutedTextColor, backgroundColor: headerBgColor),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: sizes.myProfileHorizontalPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: sizes.myProfileSectionGap),

                                // About me (bark lowkan mawjouda) - CONSTANT
                                if (_profile!.bio.isNotEmpty) ...[
                                  _ViewProfileSitterScreenPillCard(sizes: sizes, pillText: 'about_me_label'.tr(), content: Text(_profile!.bio, style: TextStyle(fontSize: sizes.myProfileBodyFontSize, height: 1.4))),
                                  SizedBox(height: sizes.myProfileSectionGap),
                                ],

                                // Tabs: "Details" | "Reviews (N)" - CONSTANT
                                // 🔴 FIX (kifma tlab): "les 2 bouton" b
                                // background "bleu clair" zeda (nafs
                                // loun el header), kifha kif el image.
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.02, vertical: sizes.screenHeight * 0.006),
                                  decoration: BoxDecoration(
                                    color: tabsBgColor,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: _tabButton(context: context, sizes: sizes, label: 'details_tab_label'.tr(), isActive: _showDetailsTab, onTap: () => setState(() => _showDetailsTab = true))),
                                      Expanded(
                                        child: _tabButton(
                                          context: context,
                                          sizes: sizes,
                                          label: '${'reviews_tab_label'.tr()} (${_profile!.reviewsCount})',
                                          isActive: !_showDetailsTab,
                                          onTap: () {
                                            setState(() => _showDetailsTab = false);
                                            _loadReviews();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(color: Colors.grey.withOpacity(0.25), height: sizes.vpsDividerGap),
                              ],
                            ),
                          ),

                          // 🔵 GHIR hedhi el partie tetharrak (scroll) -
                          // el content tel tab el mkhtar bark.
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(horizontal: sizes.myProfileHorizontalPadding),
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                alignment: Alignment.topCenter,
                                child: _showDetailsTab
                                    ? _DetailsTabContent(profile: _profile!, sizes: sizes, mutedTextColor: mutedTextColor, serviceLabel: _serviceLabel, petTypeLabel: _petTypeLabel, residenceLabel: _residenceLabel)
                                    : _ReviewsTabContent(sizes: sizes, mutedTextColor: mutedTextColor, isLoading: _isLoadingReviews, reviews: _reviews, highlightReviewId: widget.highlightReviewId),
                              ),
                            ),
                          ),

                          // "Request a book" - teal, kifma tlab - CONSTANT
                          // (mzabet fel a5er tel écran, mch lezmou scroll
                          // bch tel9ah).
                          // 🔵 ZID: mfaqoud lowkan "hideBookingButton"
                          // (chrahtha fou9, widget field).
                          if (!widget.hideBookingButton)
                          Padding(
                            padding: EdgeInsets.fromLTRB(sizes.myProfileHorizontalPadding, sizes.screenHeight * 0.015, sizes.myProfileHorizontalPadding, sizes.myProfileBottomGap),
                            child: SizedBox(
                              width: double.infinity,
                              height: sizes.vpsRequestButtonHeight,
                              child: ElevatedButton(
                                // 🔴 FIX: kanet TODO - tawa ymchi l
                                // "Request a Book" (request_a_book.dart).
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RequestABookScreen(
                                        sitterId: widget.sitterId,
                                        sitterName: _profile!.fullName,
                                        sitterServices: _profile!.services,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.vertpetsy,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                ),
                                child: Text('request_a_book_button'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
            // 🔴 FIX (kifma tlab): CustomBackButton (overlay) tna77a men
            // houni - tawa mdakhal DIRECT jowa el header (nefs sef el
            // photo/esm), mch overlay mnfassel.
          ],
        ),
      ),
    );
  }

  static Widget _tabButton({required BuildContext context, required AppSizes sizes, required String label, required bool isActive, required VoidCallback onTap}) {
    // 🔴 FIX (kifma tlab): "Colors.black87" kanet FIXE - fel dark mode
    // (background transparent, chrahtha 9bal), el text el aswad ma
    // yban-ch 7atta. Tawa: abyadh (active) / grey chwaya a5fef
    // (inactive) fel dark mode - aswad/grey fel light mode kifma kan.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activeColor = isDark ? Colors.white : Colors.black87;
    final Color inactiveColor = isDark ? Colors.white70 : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // 🔵 bch el nus el fadhi (mch ghir el text) tawa ynajjam ydouss zeda (Expanded kabber el zone)
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: sizes.myProfileBodyFontSize,
              fontWeight: FontWeight.bold,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
          SizedBox(height: sizes.screenHeight * 0.008),
          // 🔴 FIX (kifma tlab): "double.infinity" (mch width mo7addad
          // sghir) - tawa el underline ya5ou EL 3ORDH KAMEL tel nus
          // (Expanded), mch ghir ta7t el text.
          Container(height: 2.5, width: double.infinity, color: isActive ? AppColors.pinkpetsy : Colors.transparent),
        ],
      ),
    );
  }
}

// ============================================================================
// _SitterHeader: box wa7da (pale bg) - photo + esm + blasa + distance
// ============================================================================
class _SitterHeader extends StatelessWidget {
  final MyProfileData profile;
  final double? distanceKm;
  final AppSizes sizes;
  final Color mutedTextColor;
  final Color backgroundColor;

  const _SitterHeader({required this.profile, required this.distanceKm, required this.sizes, required this.mutedTextColor, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(sizes.myProfileHorizontalPadding, sizes.vpsHeaderTopPadding, sizes.myProfileHorizontalPadding, sizes.vpsHeaderBottomPadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔴 FIX (kifma tlab): back button tawa DAKHEL el header, fi
          // NEFS es-sef mte3 el photo/esm (mch overlay mnfassel elli
          // yeb9a fou9 dima, bla ma yت7اذى m3a el photo).
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: sizes.screenWidth * 0.09,
              height: sizes.screenWidth * 0.09,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), shape: BoxShape.circle),
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.pinkpetsy, size: sizes.screenWidth * 0.045),
            ),
          ),
          SizedBox(width: sizes.screenWidth * 0.03),

          // 🔴 FIX (kifma tlab): photo AKBAR (mrabb3a, nafs convention
          // tel sitter), bحدا el back button مباشرة.
          // 🔵 ZID (kifma tlab: "el tick bhdha pdp hta el users lokhrin
          // yrawha") - Stack+Positioned (bottom-right, kifha kif Instagram).
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: sizes.vpsPhotoSize,
                  height: sizes.vpsPhotoSize,
                  color: AppColors.vertpetsy.withOpacity(0.15),
                  child: profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                      ? Image.network('${ApiService.mediaBaseUrl}${profile.photoUrl}', fit: BoxFit.cover)
                      : Icon(Icons.person, color: AppColors.vertpetsy, size: sizes.vpsPhotoPlaceholderIcon),
                ),
              ),
              if (profile.isVerified)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: VerifiedBadge(size: sizes.vpsPhotoSize * 0.24),
                ),
            ],
          ),
          SizedBox(width: sizes.screenWidth * 0.04),
          Expanded(
            child: Padding(
              // 🔵 chwaya padding fou9 bch el esm y2azi m3a el back
              // button/photo (mch mla9i tamaman fou9, kifha kif el image).
              padding: EdgeInsets.only(top: sizes.screenHeight * 0.008),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(profile.fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileNameFontSize * 0.85)),
                SizedBox(height: sizes.screenHeight * 0.004),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: sizes.myProfileCityFontSize, color: AppColors.pinkpetsy),
                    SizedBox(width: sizes.screenWidth * 0.01),
                    Text('${profile.city}, ${'tunisia_label'.tr()}', style: TextStyle(fontSize: sizes.myProfileCityFontSize, color: AppColors.pinkpetsy)),
                  ],
                ),
                SizedBox(height: sizes.screenHeight * 0.004),
                // 🔵 ZID (kifma tlab): "X km away of you"
                Text(
                  distanceKm != null ? 'distance_away_label'.tr(namedArgs: {'distance': distanceKm.toString()}) : '-',
                  style: TextStyle(fontSize: sizes.myProfileCityFontSize * 0.95, color: mutedTextColor),
                ),
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _DetailsTabContent: I live in/transport + Rates (box WA7DA bark -
// service + price + pet type, kifma tlab el a5ir)
// ============================================================================
class _DetailsTabContent extends StatelessWidget {
  final MyProfileData profile;
  final AppSizes sizes;
  final Color mutedTextColor;
  final String Function(String) serviceLabel;
  final String Function(String) petTypeLabel;
  final String Function(String?) residenceLabel;

  const _DetailsTabContent({
    required this.profile,
    required this.sizes,
    required this.mutedTextColor,
    required this.serviceLabel,
    required this.petTypeLabel,
    required this.residenceLabel,
  });

  Widget _miniInfoCard({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.018, horizontal: sizes.screenWidth * 0.02),
        decoration: BoxDecoration(color: AppColors.pinkpetsy.withOpacity(0.10), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: sizes.screenWidth * 0.026, color: mutedTextColor)),
            SizedBox(height: sizes.screenHeight * 0.008),
            Icon(icon, color: AppColors.pinkpetsy, size: sizes.myProfileMiniCardIconSize),
            SizedBox(height: sizes.screenHeight * 0.006),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.screenWidth * 0.032)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _miniInfoCard(icon: Icons.home_outlined, label: 'i_live_in_label'.tr(), value: residenceLabel(profile.residenceType)),
            SizedBox(width: sizes.screenWidth * 0.03),
            _miniInfoCard(
              icon: profile.hasTransportation == true ? Icons.directions_car_outlined : Icons.directions_walk,
              label: 'means_of_transportation_label'.tr(),
              value: profile.hasTransportation == true ? 'has_car_label'.tr() : 'no_car_label'.tr(),
            ),
          ],
        ),

        if (profile.services.isNotEmpty) ...[
          SizedBox(height: sizes.myProfileSectionGap),

          // 🔴 FIX (kifma tlab el a5ir): box WA7DA bark - kol service:
          // esm 3al YESAR, prix 3AL YEMIN (badalt, kanet a el yesar) -
          // w ta7tou naw3 el pet (Cat/Dog/Both). Esm el pill "Services
          // Offered" (badalt "Rates", kifma tlab).
          _ViewProfileSitterScreenPillCard(
            sizes: sizes,
            pillText: 'sitter_services_offered_label'.tr(),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final service in profile.services)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.01),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(serviceLabel(service.serviceId), style: TextStyle(fontSize: sizes.myProfileBodyFontSize, fontWeight: FontWeight.w600))),
                            SizedBox(width: sizes.screenWidth * 0.025),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.025, vertical: sizes.screenHeight * 0.004),
                              decoration: BoxDecoration(color: AppColors.pinkpetsy, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                '${service.price.toStringAsFixed(0)} DT',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.85),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: sizes.screenWidth * 0.02, top: sizes.screenHeight * 0.004),
                          child: Row(
                            children: [
                              Icon(Icons.pets, size: sizes.myProfileBodyFontSize * 0.75, color: mutedTextColor),
                              SizedBox(width: sizes.screenWidth * 0.015),
                              Text(petTypeLabel(service.petType), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.85, color: mutedTextColor)),
                            ],
                          ),
                        ),
                        if (service != profile.services.last)
                          Padding(
                            padding: EdgeInsets.only(top: sizes.screenHeight * 0.01),
                            child: Divider(color: AppColors.pinkpetsy.withOpacity(0.2), height: 1),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// 🔵 pill card standalone (widget mnfassel, bch el zoùj box el jdad
// ynajmou yeste5dموها, w "About me" zeda).
class _ViewProfileSitterScreenPillCard extends StatelessWidget {
  final AppSizes sizes;
  final String pillText;
  final Widget content;

  const _ViewProfileSitterScreenPillCard({required this.sizes, required this.pillText, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.012),
          decoration: BoxDecoration(color: AppColors.pinkpetsy, borderRadius: BorderRadius.circular(30)),
          alignment: Alignment.center,
          child: Text(pillText, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.myProfilePillFontSize)),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(sizes.screenWidth * 0.05, sizes.screenHeight * 0.022, sizes.screenWidth * 0.05, sizes.screenHeight * 0.018),
          decoration: BoxDecoration(color: AppColors.pinkpetsy.withOpacity(0.10), borderRadius: BorderRadius.circular(18)),
          child: content,
        ),
      ],
    );
  }
}

// ============================================================================
// _ReviewsTabContent: liste des reviews 7a9i9iyin (avatar/esm/wa9t/
// rating/text, kifha kif el mockup) - "highlightReviewId" (lowkan
// mawjoud) ywarri el review el jdida b'background gris (kifma tlab:
// "en gris claire come si hedha houa el jdid").
// ============================================================================
class _ReviewsTabContent extends StatelessWidget {
  final AppSizes sizes;
  final Color mutedTextColor;
  final bool isLoading;
  final List<UserReview> reviews;
  final String? highlightReviewId;

  const _ReviewsTabContent({
    required this.sizes,
    required this.mutedTextColor,
    required this.isLoading,
    required this.reviews,
    this.highlightReviewId,
  });

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just_now_label'.tr();
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.vpsEmptyStateVerticalPad),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (reviews.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.vpsEmptyStateVerticalPad),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.star_border, color: mutedTextColor.withOpacity(0.5), size: sizes.vpsEmptyStateIcon),
              SizedBox(height: sizes.screenHeight * 0.012),
              Text('no_reviews_yet_label'.tr(), style: TextStyle(color: mutedTextColor)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final review in reviews) ...[
          _reviewCard(review, isNew: review.id == highlightReviewId),
          SizedBox(height: sizes.screenHeight * 0.014),
        ],
      ],
    );
  }

  Widget _reviewCard(UserReview review, {required bool isNew}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sizes.screenWidth * 0.035),
      decoration: BoxDecoration(
        // 🔵 ZID (kifma tlab): "en gris claire" - el review el jdida
        // (relatedReviewId mel notification) tban b'background gris,
        // "kifma hedha el jdid".
        color: isNew ? Colors.grey.withOpacity(0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: Container(
                  width: sizes.screenWidth * 0.1,
                  height: sizes.screenWidth * 0.1,
                  color: AppColors.pinkpetsy.withOpacity(0.15),
                  child: review.reviewerPhotoUrl != null
                      ? Image.network(review.reviewerPhotoUrl!, fit: BoxFit.cover)
                      : Icon(Icons.person, color: AppColors.pinkpetsy, size: sizes.screenWidth * 0.06),
                ),
              ),
              SizedBox(width: sizes.screenWidth * 0.025),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.92)),
                    Text(_relativeTime(review.createdAt), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.72, color: mutedTextColor)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: sizes.screenHeight * 0.01),
          Row(
            children: [
              Text(review.averageRating.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.95, color: Colors.amber.shade800)),
              SizedBox(width: sizes.screenWidth * 0.015),
              ..._starIcons(review.averageRating),
            ],
          ),
          if (review.review.isNotEmpty) ...[
            SizedBox(height: sizes.screenHeight * 0.008),
            Text(review.review, style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.85, height: 1.35)),
          ],
        ],
      ),
    );
  }

  List<Widget> _starIcons(double rating) {
    return List.generate(5, (i) {
      final double diff = rating - i;
      IconData icon;
      if (diff >= 1) {
        icon = Icons.star;
      } else if (diff >= 0.5) {
        icon = Icons.star_half;
      } else {
        icon = Icons.star_border;
      }
      return Icon(icon, color: Colors.amber, size: sizes.myProfileBodyFontSize * 0.95);
    });
  }
}