import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../models/booking_alternatives.dart';

// ============================================================================
// showBookingAlternativesDialog (feature "compatibilite entre animaux")
// ============================================================================
// 🔵 ZID: ki createBooking yرجع 409 (conflit category/capacite), request_
// a_book.dart yeste5dem hedha bch ywarri popup bel propositions:
//   A) "sameSitterSlots" - horaire ekher 3and NEFS el sitter. Tap ->
//      onPickSlot(checkIn, checkOut) (el caller ye3ammar el date/wa9t
//      mel jdid, el user ye3awed ydous "Send request").
//   B) "otherSitters" - sitters okhrin. Tap -> onPickSitter(sitterId)
//      (el caller ynajjam ymchi l'profile tou3ou, mathalan).
// ============================================================================
Future<void> showBookingAlternativesDialog(
  BuildContext context, {
  required BookingAlternatives alternatives,
  required void Function(DateTime checkIn, DateTime checkOut) onPickSlot,
  required void Function(String sitterId) onPickSitter,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final screenWidth = MediaQuery.of(sheetContext).size.width;

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            screenWidth * 0.06,
            screenWidth * 0.05,
            screenWidth * 0.06,
            screenWidth * 0.06,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  'booking_alternatives_title'.tr(),
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: AppColors.vertpetsy,
                  ),
                ),
                SizedBox(height: screenWidth * 0.015),
                Text(
                  'booking_alternatives_subtitle'.tr(),
                  style: TextStyle(fontSize: screenWidth * 0.033, color: Colors.grey.shade600),
                ),
                SizedBox(height: screenWidth * 0.05),

                if (alternatives.sameSitterSlots.isNotEmpty) ...[
                  Text(
                    'booking_alternatives_same_sitter_label'.tr(),
                    style: TextStyle(fontSize: screenWidth * 0.036, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: screenWidth * 0.03),
                  ...alternatives.sameSitterSlots.map(
                    (slot) => _SlotTile(
                      slot: slot,
                      screenWidth: screenWidth,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        onPickSlot(slot.checkIn, slot.checkOut);
                      },
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.05),
                ],

                if (alternatives.otherSitters.isNotEmpty) ...[
                  Text(
                    'booking_alternatives_other_sitters_label'.tr(),
                    style: TextStyle(fontSize: screenWidth * 0.036, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: screenWidth * 0.03),
                  ...alternatives.otherSitters.map(
                    (sitter) => _SitterTile(
                      sitter: sitter,
                      screenWidth: screenWidth,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        onPickSitter(sitter.sitterId);
                      },
                    ),
                  ),
                ],

                if (alternatives.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: screenWidth * 0.06),
                    child: Text(
                      'booking_alternatives_empty_label'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: screenWidth * 0.034, color: Colors.grey.shade600),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SlotTile extends StatelessWidget {
  final AlternativeSlot slot;
  final double screenWidth;
  final VoidCallback onTap;

  const _SlotTile({required this.slot, required this.screenWidth, required this.onTap});

  String _fmt(DateTime d) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} - ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.025),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.035),
          decoration: BoxDecoration(
            color: AppColors.vertpetsy.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.vertpetsy.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.event_available, color: AppColors.vertpetsy, size: screenWidth * 0.06),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  '${_fmt(slot.checkIn)}  \u2192  ${_fmt(slot.checkOut)}',
                  style: TextStyle(fontSize: screenWidth * 0.033, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.vertpetsy, size: screenWidth * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}

class _SitterTile extends StatelessWidget {
  final AlternativeSitter sitter;
  final double screenWidth;
  final VoidCallback onTap;

  const _SitterTile({required this.sitter, required this.screenWidth, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.025),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.035, vertical: screenWidth * 0.03),
          decoration: BoxDecoration(
            color: AppColors.pinkpetsy.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.pinkpetsy.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: screenWidth * 0.06,
                backgroundColor: AppColors.pinkpetsy.withOpacity(0.2),
                backgroundImage: (sitter.photoUrl != null && sitter.photoUrl!.isNotEmpty)
                    ? NetworkImage(sitter.photoUrl!)
                    : null,
                child: (sitter.photoUrl == null || sitter.photoUrl!.isEmpty)
                    ? Icon(Icons.person, color: AppColors.pinkpetsy, size: screenWidth * 0.06)
                    : null,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sitter.fullName, style: TextStyle(fontSize: screenWidth * 0.036, fontWeight: FontWeight.w700)),
                    if (sitter.city != null && sitter.city!.isNotEmpty)
                      Text(sitter.city!, style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025, vertical: screenWidth * 0.012),
                decoration: BoxDecoration(
                  color: sitter.isJoinGroup ? AppColors.vertpetsy.withOpacity(0.18) : AppColors.pinkpetsy.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sitter.isJoinGroup
                      ? 'booking_alternatives_badge_join_group'.tr(namedArgs: {'count': sitter.existingCount.toString()})
                      : 'booking_alternatives_badge_free'.tr(),
                  style: TextStyle(
                    fontSize: screenWidth * 0.026,
                    fontWeight: FontWeight.w700,
                    color: sitter.isJoinGroup ? AppColors.vertpetsy : AppColors.pinkpetsy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}