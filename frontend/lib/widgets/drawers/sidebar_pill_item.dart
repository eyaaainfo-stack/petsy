import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';

// ============================================================================
// SidebarPillItem
// ============================================================================
// 🔵 ZID (kifma tlab: "nhb hatta el sitter wel owner" - nafs redesign
// tel SidebarAdmin) - widget PARTAGÉ (mch dupliqué 3 mrat) testa3mlou
// el 3 sidebars el kol (admin/owner/sitter) - bch el design yeb9a
// IDENTIQUE bin el 3, w ken lezmou tبديل fel mستقbل, blasa WA7DA bark.
//
// "pilule" (icon dayer coloré + label + chevron), background theme-
// aware (isDark?white.withOpacity(0.06):grey.shade100 - nafs
// convention el screens admin el kol) - bch yeb9a behi w yerta7 lih
// el 3in fi mode sombre W light.
//
// badgeCount: optionnel - number sghir (mathalan notifications ma9rou2ach)
// 9bal el chevron.
// ============================================================================
class SidebarPillItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int? badgeCount;

  const SidebarPillItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: sizes.sidebarPillPaddingH, vertical: sizes.sidebarPillPaddingV),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: sizes.sidebarPillIconCircle,
                height: sizes.sidebarPillIconCircle,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: sizes.sidebarPillIcon),
              ),
              SizedBox(width: sizes.sidebarPillTextGap),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: sizes.sidebarPillFontSize,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              if (badgeCount != null && badgeCount! > 0) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: sizes.sidebarPillBadgePaddingH, vertical: 2),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  constraints: BoxConstraints(minWidth: sizes.sidebarPillBadgeMinWidth),
                  child: Text(
                    badgeCount! > 99 ? '99+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.sidebarPillBadgeFontSize),
                  ),
                ),
                SizedBox(width: sizes.sidebarPillBadgeGap),
              ],
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4) ?? Colors.grey,
                size: sizes.sidebarPillChevron,
              ),
            ],
          ),
        ),
      ),
    );
  }
}