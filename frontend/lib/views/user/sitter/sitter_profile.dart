import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/drawers/sidebar_sitter.dart';

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
  final String petName;
  final String gender;
  final String? petPhotoUrl;
  final String serviceType;
  final String date;
  final String time;

  const _TodayPatient({
    required this.petName,
    required this.gender,
    this.petPhotoUrl,
    required this.serviceType,
    required this.date,
    required this.time,
  });
}

class _UrgentServiceRequest {
  final String petName;
  final double distanceKm;
  final String description;
  final String? photoUrl;
  final String dateRange;
  final String timeRange;

  const _UrgentServiceRequest({
    required this.petName,
    required this.distanceKm,
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

  const SitterProfileScreen({
    super.key,
    required this.sitterName,
    required this.sitterCity,
    this.sitterPhotoBytes,
    this.sitterPhotoUrl,
  });

  @override
  State<SitterProfileScreen> createState() => _SitterProfileScreenState();
}

class _SitterProfileScreenState extends State<SitterProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasUnreadNotifications = true; // 🔴 mock - no9ta 7amra bark (kifha kif profile_owner.dart)

  // 🔵 TAWA REAL: listet fadhya (mch mock) - te7taj backend routes mazel
  // ma tzadouch. TODO: appel API fel initState() (nafs mant9
  // _fetchSitters() fel profile_owner.dart) ki el backend ykoun jahez.
  final List<_TodayPatient> _todayPatients = [];
  final List<_UrgentServiceRequest> _urgentServices = [];

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
              // ------------------------------------------------------
              Row(
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
                      // TODO: navigation lel écran notifications
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
                  Text(
                    'see_all_label'.tr(),
                    style: TextStyle(
                      fontSize: sizes.screenWidth * 0.032,
                      fontWeight: FontWeight.w600,
                      color: AppColors.vertpetsy,
                    ),
                  ),
                ],
              ),

              SizedBox(height: sizes.sitterProfileSectionTitleListGap),

              // 🔵 "fregha" kifma tlabt - empty state (bla mock data),
              // nafs mant9 "no_sitters_available_label" fel profile_owner.
              _todayPatients.isEmpty
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

              // 🔵 "fregha" zeda - empty state bark.
              _urgentServices.isEmpty
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
                      itemBuilder: (context, index) => _UrgentServiceCard(request: _urgentServices[index], sizes: sizes),
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
// + gender + badge, mba3d "Service Type" / date-time)
// ============================================================================
class _TodayPatientCard extends StatelessWidget {
  final _TodayPatient patient;
  final AppSizes sizes;

  const _TodayPatientCard({required this.patient, required this.sizes});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              ClipOval(
                child: Container(
                  width: sizes.screenWidth * 0.09,
                  height: sizes.screenWidth * 0.09,
                  color: AppColors.pinkpetsy.withOpacity(0.12),
                  child: patient.petPhotoUrl != null
                      ? Image.network(patient.petPhotoUrl!, fit: BoxFit.cover)
                      : Icon(Icons.pets, color: AppColors.pinkpetsy, size: sizes.screenWidth * 0.05),
                ),
              ),
              SizedBox(width: sizes.screenWidth * 0.02),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient.petName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.screenWidth * 0.036)),
                    Text(patient.gender, style: TextStyle(fontSize: sizes.screenWidth * 0.028, color: Colors.grey)),
                  ],
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
                      Text(patient.serviceType, style: TextStyle(fontWeight: FontWeight.w600, fontSize: sizes.screenWidth * 0.030)),
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

  const _UrgentServiceCard({required this.request, required this.sizes});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                child: Text(request.petName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.screenWidth * 0.034)),
              ),
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
    );
  }
}