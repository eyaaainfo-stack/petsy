import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';

// ============================================================================
// SidebarItem: sef wa7ed fel menu (icon + label + chevron + divider)
// ============================================================================
// 🔵 ZID: mchtaraka bin SidebarSitter w SidebarOwner (w ay sidebar ekhor
// jay, mathalan courier/admin) - bdal ma nkarrarouha fi kol fichier.
// (kanet "_SidebarItem" privée fi sidebar_sitter.dart bark - tawa public
// w fi fichier mnfassel).
// ============================================================================
class SidebarItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final VoidCallback onTap;
  final AppSizes sizes;
  final bool showDivider;
  // 🔵 ZID: badge b ra9m (mathalan notifications ma9rou2ach) - null/0 =
  // mafamech badge 7atta.
  final int? badgeCount;

  const SidebarItem({
    super.key,
    required this.icon,
    this.iconColor,
    required this.label,
    required this.onTap,
    required this.sizes,
    this.showDivider = true,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.sidebarItemVerticalPad),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor ?? Colors.white, size: sizes.sidebarItemIconSize),
                SizedBox(width: sizes.screenWidth * 0.04),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: Colors.white, fontSize: sizes.sidebarItemFontSize, fontWeight: FontWeight.w600),
                  ),
                ),
                if (badgeCount != null && badgeCount! > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    constraints: const BoxConstraints(minWidth: 20),
                    child: Text(
                      badgeCount! > 99 ? '99+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: iconColor ?? Colors.teal.shade700, fontWeight: FontWeight.bold, fontSize: sizes.sidebarItemFontSize * 0.75),
                    ),
                  ),
                  SizedBox(width: sizes.screenWidth * 0.02),
                ],
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.8), size: sizes.sidebarItemIconSize * 0.8),
              ],
            ),
            if (showDivider) ...[
              SizedBox(height: sizes.sidebarItemVerticalPad),
              Divider(color: Colors.white.withOpacity(0.35), height: 1),
            ],
          ],
        ),
      ),
    );
  }
}