import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/drawers/sidebar_sitter.dart';
import '../../../widgets/verified_badge.dart';
import '../notifications_screen.dart';
import '../../../controllers/notification_controller.dart';
import '../../../controllers/request_controller.dart';
import '../../../controllers/sitter_calender_controller.dart';
import '../../../widgets/pet_avatars_stack.dart';
import 'request.dart';
import 'sitter_calender.dart';
import '../../../controllers/checkout_questionnaire_controller.dart';
import '../../../widgets/checkout_questionnaire_dialog.dart';
import '../../../models/sitter_service_catalog.dart';

// ============================================================================
// _TodayPatient / _UrgentServiceRequest
// ============================================================================
// 🔵 el "shape" tel data (kifha kif _SitterSummary fel profile_owner.dart)
// - LIST FADHYA tawa ("fregha" kifma tlabt), mch mock. Ki ykoun 3andek
// backend route (mathalan GET /api/sitters/today-patients w GET
// /api/sitters/urgent-requests), ghir 3amر el liste houni (initState)
// w el UI kaملha tetba3 wa7dha (déjà mbeniya lel data).
// ============================================================================
class _TodayPatient {
  final String bookingId; // 🔵 ZID: bch nnajjmou nvazrou -> request.dart (fromCalendar: true, "Cancel Booking" disponible)
  final List<SchedulePet> pets; // 🔴 FIX (kifma tlab): "par reservation mch par pet" - kol pets el booking m3a ba3dhom, mch card mnfassla likol wa7ed
  // 🔴 FIX (kifma tlab: "ma yjiwnich asemi les service lkol nhb just el
  // logo mtaa el categorie... les service eli zeydinhom zyeda atihom
  // logo +") - icons bark (déduplicated), mch les noms el kol - category
  // icon (mkass/dar...) lel services el catalogue, "+" lel services
  // custom (elli el sitter zad b ydik).
  final List<IconData> serviceIcons;
  final String date;
  final String time;

  const _TodayPatient({
    required this.bookingId,
    required this.pets,
    required this.serviceIcons,
    required this.date,
    required this.time,
  });
}

class _UrgentServiceRequest {
  final String id; // 🔵 ZID: bookingId - bch ndouzouha l'request.dart ki tdouss 3al card
  final String petNames; // 🔴 FIX: kanet "petName" wa7ed bark - tawa comma-joined (booking ynajjam ykoun fih ktar men pet wa7ed)
  final double? distanceKm; // 🔴 FIX: optionnel - null lowkan el 2 (sitter/owner) mazel ma 7attouch location
  final String description;
  final String? photoUrl;
  final String dateRange;
  final String timeRange;

  const _UrgentServiceRequest({
    required this.id,
    required this.petNames,
    this.distanceKm,
    required this.description,
    this.photoUrl,
    required this.dateRange,
    required this.timeRange,
  });
}

// ============================================================================
// SitterProfileScreen ("home" tel sitter, ba3d el creation tel profile)
// ============================================================================
class SitterProfileScreen extends StatefulWidget {
  final String sitterName;
  final String sitterCity;
  final Uint8List? sitterPhotoBytes; // bytes (mémoire, ba3d signup direct)
  final String? sitterPhotoUrl; // URL (mel backend, ba3d login mel jdid)
  // 🔵 ZID (kifma tlab: "nhbha el tick todhhor hatta fi profile... fel
  // home fel pdp mteou") - badge bleu 3al avatar tel header.
  final bool isVerified;
  // 🔵 ZID (kifma tlab: "ken el user homme nkhalliwh vert, keno femme
  // pink") - couleur el sidebar (header) 7asb el gender.
  final String? gender;

  const SitterProfileScreen({
    super.key,
    required this.sitterName,
    required this.sitterCity,
    this.sitterPhotoBytes,
    this.sitterPhotoUrl,
    this.isVerified = false,
    this.gender,
  });

  @override
  State<SitterProfileScreen> createState() => _SitterProfileScreenState();
}

class _SitterProfileScreenState extends State<SitterProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // 🔴 FIX: kanet mock (True dima, nafs mochkla profile_owner.dart) -
  // tawa data 7a9i9iya mel backend.
  bool _hasUnreadNotifications = false;
  final NotificationController _notificationController = NotificationController();
  // 🔴 FIX (kifma tlab: "kol reservation lyoum tji fi patients du jour") -
  // tawa REAL (GET /api/bookings/my-schedule, mfaltra 3ala "lyoum"),
  // mch list fadhya statique.
  final UrgentRequestsController _urgentController = UrgentRequestsController();
  final SitterCalenderController _calenderController = SitterCalenderController();

  List<_TodayPatient> _todayPatients = [];
  bool _isLoadingTodayPatients = true;

  // 🔴 FIX (kifma tlab): "Need urgent sitting services" - tawa REAL
  // (GET /api/bookings/urgent), mch list fadhya statique.
  List<_UrgentServiceRequest> _urgentServices = [];
  bool _isLoadingUrgent = true;

  // 🔴 FIX (kifma tlab: "les services nhbhom fi des titre...") -
  // sitterServiceLabelKeys mel catalogue partagé (bدal liste mkarrra).
  static Map<String, String> get _serviceLabelKeys => sitterServiceLabelKeys;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUnreadNotificationsCount();
    _fetchUrgentRequests();
    _fetchTodayPatients();
    // 🔵 ZID (kifma tlab): questionnaire ba3d el checkout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingQuestionnaires());
  }

  Future<void> _checkPendingQuestionnaires() async {
    final pending = await CheckoutQuestionnaireController().fetchPending();
    if (!mounted || pending.isEmpty) return;
    final completed = await CheckoutQuestionnaireDialog.show(context, pending.first.bookingId);
    if (completed && mounted) _checkPendingQuestionnaires();
  }

  Future<void> _fetchUnreadNotificationsCount() async {
    final count = await _notificationController.fetchUnreadCount();
    if (!mounted) return;
    setState(() => _hasUnreadNotifications = count > 0);
  }

  Future<void> _fetchUrgentRequests() async {
    setState(() => _isLoadingUrgent = true);
    final summaries = await _urgentController.fetchUrgentRequests();
    if (!mounted) return;
    setState(() {
      _urgentServices = summaries.map((s) {
        final String description = s.serviceIds.isEmpty
            ? '-'
            : s.serviceIds.map((id) => _serviceLabelKeys[id] != null ? _serviceLabelKeys[id]!.tr() : id).join(' + ');
        return _UrgentServiceRequest(
          id: s.id,
          petNames: s.petNames.isEmpty ? '-' : s.petNames,
          distanceKm: s.distanceKm,
          description: description,
          photoUrl: s.firstPetPhotoUrl,
          dateRange: _dateRangeLabel(s.checkIn, s.checkOut),
          timeRange: '${_timeLabel(s.checkIn)} - ${_timeLabel(s.checkOut)}',
        );
      }).toList();
      _isLoadingUrgent = false;
    });
  }

  String _dateRangeLabel(DateTime checkIn, DateTime checkOut) {
    final bool sameDay = checkIn.year == checkOut.year && checkIn.month == checkOut.month && checkIn.day == checkOut.day;
    if (sameDay) return '${checkIn.day} ${_monthNames[checkIn.month - 1]}';
    final bool sameMonth = checkIn.year == checkOut.year && checkIn.month == checkOut.month;
    if (sameMonth) return '${checkIn.day} - ${checkOut.day} ${_monthNames[checkIn.month - 1]}';
    return '${checkIn.day} ${_monthNames[checkIn.month - 1]} - ${checkOut.day} ${_monthNames[checkOut.month - 1]}';
  }

  // 🔵 ZID (fix timezone): ".toLocal()" 9bal .hour/.minute.
  String _timeLabel(DateTime t) {
    final local = t.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  // 🔵 ZID (kifma tlab): "eli deja 3malha ma yjich, ghir el todo" -
  // ZIDNA chart "now.isBefore(checkOut)" (booking déjà 5elset lyoum ->
  // ma tbanche). "par reservation mch par pet" - card WA7DA per
  // booking (mch per pet).
  Future<void> _fetchTodayPatients() async {
    setState(() => _isLoadingTodayPatients = true);
    final schedule = await _calenderController.fetchMySchedule();
    if (!mounted) return;

    final DateTime now = DateTime.now();
    final DateTime todayOnly = DateTime(now.year, now.month, now.day);
    // 🔵 ZID (fix timezone): ".toLocal()" 9bal .year/.month/.day - nafs
    // mochkla sitter_calender.dart (chrahtha houniki).
    DateTime dateOnly(DateTime d) {
      final local = d.toLocal();
      return DateTime(local.year, local.month, local.day);
    }

    final List<_TodayPatient> patients = [];
    for (final booking in schedule) {
      final bool coversToday = !todayOnly.isBefore(dateOnly(booking.checkIn)) && !todayOnly.isAfter(dateOnly(booking.checkOut));
      // 🔴 FIX: booking "lyoum" lakin déjà 5elset (checkOut 3adda) -
      // ma tbanche ("eli deja 3malha ma yjich").
      final bool notFinishedYet = now.isBefore(booking.checkOut);
      final bool shouldShow = coversToday && notFinishedYet;
      if (!shouldShow) continue;

      // 🔴 FIX (kifma tlab: "ma yjiwnich asemi les service lkol nhb just
      // el logo mtaa el categorie... les service eli zeydinhom zyeda
      // atihom logo +") - icon tel category (déduplicated, esm order
      // el bidaya, "LinkedHashSet" style) - "+" lel services custom.
      final List<IconData> serviceIcons = [];
      final Set<int> seenCodePoints = {};
      for (final id in booking.serviceIds) {
        final IconData icon = isCustomServiceId(id) ? Icons.add : (categoryIconForService(id) ?? Icons.pets);
        if (seenCodePoints.add(icon.codePoint)) serviceIcons.add(icon);
      }

      patients.add(_TodayPatient(
        bookingId: booking.id,
        pets: booking.pets,
        serviceIcons: serviceIcons,
        date: 'today_label'.tr(),
        time: '${_timeLabel(booking.checkIn)} - ${_timeLabel(booking.checkOut)}',
      ));
    }

    setState(() {
      _todayPatients = patients;
      _isLoadingTodayPatients = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    return Scaffold(
      key: _scaffoldKey,
      drawer: SidebarSitter(
        sitterName: widget.sitterName,
        sitterCity: widget.sitterCity,
        sitterPhotoBytes: widget.sitterPhotoBytes,
        sitterPhotoUrl: widget.sitterPhotoUrl,
        isVerified: widget.isVerified,
        gender: widget.gender,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: sizes.sitterProfileHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: sizes.sitterProfileTopGap),

              // ------------------------------------------------------
              // Header: photo (dayra) + esm/blasa + menu + notif
              // (nafs el structure tel ProfileOwnerScreen)
              // 🔵 ZID (kifma tlab: "el tick... fel home fel pdp
              // mteou") - Stack+Positioned, clipBehavior none.
              // ------------------------------------------------------
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipOval(
                        child: Container(
                          width: sizes.sitterProfileAvatarRadius,
                          height: sizes.sitterProfileAvatarRadius,
                          color: AppColors.vertpetsy.withOpacity(0.15),
                          child: widget.sitterPhotoBytes != null
                              ? Image.memory(widget.sitterPhotoBytes!, fit: BoxFit.cover)
                              : widget.sitterPhotoUrl != null
                                  ? Image.network(widget.sitterPhotoUrl!, fit: BoxFit.cover)
                                  : Icon(Icons.person, color: AppColors.vertpetsy, size: sizes.sitterProfileAvatarRadius * 0.6),
                        ),
                      ),
                      if (widget.isVerified)
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: VerifiedBadge(size: sizes.sitterProfileAvatarRadius * 0.3),
                        ),
                    ],
                  ),

                  SizedBox(width: sizes.screenWidth * 0.03),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'home_greeting'.tr(namedArgs: {'name': widget.sitterName}),
                          style: TextStyle(
                            fontSize: sizes.sitterProfileHeaderNameFontSize,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          '${widget.sitterCity}, ${'tunisia_label'.tr()}',
                          style: TextStyle(
                            fontSize: sizes.sitterProfileHeaderCityFontSize,
                            color: mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _HeaderIconButton(
                    icon: Icons.menu,
                    backgroundColor: AppColors.pinkpetsy,
                    size: sizes.sitterProfileIconButtonSize,
                    onTap: () {
                      // 🔴 FIX: kanet TODO (mafamech drawer) - tawa
                      // yeftah SidebarSitter (widgets/drawers/sidebar_sitter.dart).
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),

                  SizedBox(width: sizes.screenWidth * 0.02),

                  _HeaderIconButton(
                    icon: Icons.notifications_outlined,
                    backgroundColor: AppColors.vertpetsy,
                    size: sizes.sitterProfileIconButtonSize,
                    showBadge: _hasUnreadNotifications,
                    onTap: () {
                      setState(() => _hasUnreadNotifications = false);
                      // 🔴 FIX: kanet TODO - tawa ymchi l "Notifications".
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: sizes.sitterProfileSectionGap),

              // ------------------------------------------------------
              // "Today Patient"
              // ------------------------------------------------------
              Row(
                children: [
                  Text(
                    'today_patient_label'.tr(),
                    style: TextStyle(
                      fontSize: sizes.sitterProfileSectionTitleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  // 🔵 ZID (kifma tlab): dass 3al "See all" -> sitter_calender.dart
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SitterCalenderScreen()),
                      );
                    },
                    child: Text(
                      'see_all_label'.tr(),
                      style: TextStyle(
                        fontSize: sizes.screenWidth * 0.032,
                        fontWeight: FontWeight.w600,
                        color: AppColors.vertpetsy,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: sizes.sitterProfileSectionTitleListGap),

              // 🔵 3 7alet: loading, fregha (empty state, mch mock), wela data 7a9i9iya.
              _isLoadingTodayPatients
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: sizes.sitterProfileEmptyStateVerticalPad),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : _todayPatients.isEmpty
                      ? _emptyState(icon: Icons.pets, label: 'no_patients_today_label'.tr(), sizes: sizes, mutedTextColor: mutedTextColor)
                      : SizedBox(
                          height: sizes.sitterProfileTodayCardHeight,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _todayPatients.length,
                            separatorBuilder: (_, __) => SizedBox(width: sizes.sitterProfileTodayCardGap),
                            itemBuilder: (context, index) => _TodayPatientCard(patient: _todayPatients[index], sizes: sizes),
                          ),
                        ),

              SizedBox(height: sizes.sitterProfileSectionGap),

              // ------------------------------------------------------
              // "Need urgent sitting services"
              // ------------------------------------------------------
              Text(
                'need_urgent_services_label'.tr(),
                style: TextStyle(
                  fontSize: sizes.sitterProfileSectionTitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),

              SizedBox(height: sizes.sitterProfileSectionTitleListGap),

              // 🔵 3 7alet: loading, fregha (empty state, mch mock), wela data 7a9i9iya.
              _isLoadingUrgent
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: sizes.sitterProfileEmptyStateVerticalPad),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : _urgentServices.isEmpty
                      ? _emptyState(icon: Icons.volunteer_activism_outlined, label: 'no_urgent_services_label'.tr(), sizes: sizes, mutedTextColor: mutedTextColor)
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _urgentServices.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: sizes.screenWidth * 0.04,
                            mainAxisSpacing: sizes.screenHeight * 0.02,
                            childAspectRatio: 0.72,
                          ),
                          itemBuilder: (context, index) => _UrgentServiceCard(
                            request: _urgentServices[index],
                            sizes: sizes,
                            // 🔵 ZID (kifma tlab): dass 3al card -> request.dart.
                            // Ki yerja3 (accept/reject), n3awdou njibou el liste
                            // (el card elli 9bel/rafedh ma te5tefich mel grid).
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => RequestScreen(bookingId: _urgentServices[index].id)),
                              );
                              if (mounted) _fetchUrgentRequests();
                            },
                          ),
                        ),

              SizedBox(height: sizes.sitterProfileBottomGap),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String label, required AppSizes sizes, required Color mutedTextColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizes.sitterProfileEmptyStateVerticalPad),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: mutedTextColor.withOpacity(0.5), size: sizes.sitterProfileEmptyStateIconSize),
            SizedBox(height: sizes.screenHeight * 0.012),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedTextColor, fontSize: sizes.screenWidth * 0.034),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// _HeaderIconButton (nafs el widget mte3 profile_owner.dart - copié houni
// bch create_sitter_profile.dart yeb9a standalone, bla import cross-role
// mte3 owner/)
// ============================================================================
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final double size;
  final VoidCallback onTap;
  final bool showBadge;

  const _HeaderIconButton({
    required this.icon,
    required this.backgroundColor,
    required this.size,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(size * 0.35),
            ),
            child: Icon(icon, color: backgroundColor, size: size * 0.55),
          ),
          if (showBadge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// _TodayPatientCard (border teal, kifha kif el mockup: icon/photo + esm
// + badge, mba3d "Service Type" / date-time) - WA7DA per RESERVATION
// (kifma tlab: "par reservation mch par pet") - PetAvatarsStack lowkan
// ktar men pet wa7ed.
// ============================================================================
class _TodayPatientCard extends StatelessWidget {
  final _TodayPatient patient;
  final AppSizes sizes;

  const _TodayPatientCard({required this.patient, required this.sizes});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RequestScreen(bookingId: patient.bookingId, fromCalendar: true)),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
      width: sizes.sitterProfileTodayCardWidth,
      padding: EdgeInsets.all(sizes.screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.vertpetsy.withOpacity(0.5), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PetAvatarsStack(photoUrls: patient.pets.map((p) => p.photoUrl).toList(), avatarSize: sizes.screenWidth * 0.09),
              SizedBox(width: sizes.screenWidth * 0.02),
              Expanded(
                child: Text(
                  patient.pets.map((p) => p.name).join(', '),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.screenWidth * 0.036),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: sizes.screenWidth * 0.07,
                height: sizes.screenWidth * 0.07,
                decoration: BoxDecoration(color: AppColors.vertpetsy.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(Icons.check, color: AppColors.vertpetsy, size: sizes.screenWidth * 0.04),
              ),
            ],
          ),
          SizedBox(height: sizes.screenHeight * 0.012),
          Container(
            padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.025, vertical: sizes.screenHeight * 0.01),
            decoration: BoxDecoration(
              color: AppColors.pinkpetsy.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('service_type_label'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontSize: sizes.screenWidth * 0.026)),
                      SizedBox(height: sizes.screenHeight * 0.004),
                      // 🔴 FIX (kifma tlab: "ma yjiwnich asemi les
                      // service lkol nhb just el logo mtaa el categorie")
                      // - icons bark (déduplicated), mch les noms el
                      // kol - Wrap bch ma yfoutouch barra el card lowkan
                      // categories barcha.
                      Wrap(
                        spacing: sizes.screenWidth * 0.015,
                        runSpacing: sizes.screenHeight * 0.006,
                        children: patient.serviceIcons.isEmpty
                            ? [Icon(Icons.pets, size: sizes.screenWidth * 0.045, color: AppColors.pinkpetsy)]
                            : [
                                for (final icon in patient.serviceIcons)
                                  Icon(icon, size: sizes.screenWidth * 0.045, color: AppColors.pinkpetsy),
                              ],
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: sizes.screenHeight * 0.03, color: AppColors.pinkpetsy.withOpacity(0.3)),
                SizedBox(width: sizes.screenWidth * 0.02),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patient.date, style: TextStyle(fontWeight: FontWeight.w600, fontSize: sizes.screenWidth * 0.028)),
                      Text(patient.time, style: TextStyle(fontSize: sizes.screenWidth * 0.028)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ============================================================================
// _UrgentServiceCard (photo fou9, esm+distance, description, date/heure,
// icon rose mdawra fel lakher - kifha kif el mockup)
// ============================================================================
class _UrgentServiceCard extends StatelessWidget {
  final _UrgentServiceRequest request;
  final AppSizes sizes;
  final VoidCallback onTap;

  const _UrgentServiceCard({required this.request, required this.sizes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: EdgeInsets.all(sizes.screenWidth * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: request.photoUrl != null
                  ? Image.network(request.photoUrl!, fit: BoxFit.cover, width: double.infinity)
                  : Container(color: AppColors.vertpetsy.withOpacity(0.15), width: double.infinity, child: Icon(Icons.pets, color: AppColors.vertpetsy, size: sizes.screenWidth * 0.1)),
            ),
          ),
          SizedBox(height: sizes.screenHeight * 0.008),
          Row(
            children: [
              Expanded(
                child: Text(request.petNames, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.screenWidth * 0.034)),
              ),
              if (request.distanceKm != null)
                Text('${request.distanceKm}km', style: TextStyle(fontSize: sizes.screenWidth * 0.026, color: Colors.grey)),
            ],
          ),
          Text(request.description, style: TextStyle(fontSize: sizes.screenWidth * 0.028, color: Colors.grey)),
          SizedBox(height: sizes.screenHeight * 0.006),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: sizes.screenWidth * 0.028, color: AppColors.pinkpetsy),
              SizedBox(width: sizes.screenWidth * 0.012),
              Expanded(child: Text(request.dateRange, style: TextStyle(fontSize: sizes.screenWidth * 0.026))),
            ],
          ),
          Row(
            children: [
              Icon(Icons.access_time, size: sizes.screenWidth * 0.028, color: AppColors.pinkpetsy),
              SizedBox(width: sizes.screenWidth * 0.012),
              Expanded(child: Text(request.timeRange, style: TextStyle(fontSize: sizes.screenWidth * 0.026))),
              Container(
                width: sizes.screenWidth * 0.07,
                height: sizes.screenWidth * 0.07,
                decoration: BoxDecoration(border: Border.all(color: AppColors.pinkpetsy.withOpacity(0.5)), shape: BoxShape.circle),
                child: Icon(Icons.eco_outlined, size: sizes.screenWidth * 0.035, color: AppColors.pinkpetsy),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}