import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

// ============================================================================
// AdminMenuTile
// ============================================================================
// 🔵 ZID: el "bouton" tel Admin (Home + Statistics hub) - nafs style
// elli tlab (screenshot: pilule ronde, background pastel, avatar dayer
// 3al yesar, esm fel west, chevron 3al lakher) - ghir bدل ma tkoun photo
// tel pet (PetTile), houni icon (statistics/inscriptions/dashboard...)
// 7it el Admin ma3andouch "photo" lel section.
//
// 🔴 FIX (rappel AppSizes): kanou el sizes el kol mel MediaQuery direct -
// tawa AppSizes.of(context) (sizes.adminTileXxx), nafs mant9 el app.
//
// 🔵 badgeCount: optionnel - number sghir 9bal el chevron (mathalan
// "3 pending bookings") - null/0 = mafamech badge.
// ============================================================================
class AdminMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int? badgeCount;

  const AdminMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.vertpetsy,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.55) ?? Colors.grey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: sizes.adminTilePaddingH,
            vertical: sizes.adminTilePaddingV,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.16 : 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // avatar dayer (rond) - nafs l'idée tel photo tel pet, ghir
              // b'icon (l'Admin ma3andouch photo par section).
              Container(
                width: sizes.adminTileAvatarSize,
                height: sizes.adminTileAvatarSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: sizes.adminTileIconSize),
              ),
              SizedBox(width: sizes.adminTileAvatarTextGap),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: sizes.adminTileLabelFontSize,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              if (badgeCount != null && badgeCount! > 0) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: sizes.adminTileBadgePaddingH, vertical: 2),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  constraints: BoxConstraints(minWidth: sizes.adminTileBadgeMinWidth),
                  child: Text(
                    badgeCount! > 99 ? '99+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: sizes.adminTileBadgeFontSize,
                    ),
                  ),
                ),
                SizedBox(width: sizes.adminTileBadgeChevronGap),
              ],
              Icon(Icons.chevron_right, color: mutedTextColor, size: sizes.adminTileChevronSize),
            ],
          ),
        ),
      ),
    );
  }
}