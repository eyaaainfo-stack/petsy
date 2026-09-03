import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

// ============================================================================
// StatCard: card mrabb3a (icon dayer fou9, chiffre kbir, label ta7t)
// ============================================================================
// 🔵 ZID: publique/mostaqilla (mch privée) bch AdminRegistrationsScreen
// ynajjam yesta3melha (mch duplication tel code).
//
// 🔴 FIX (crash confirmé): mch testa3mel Spacer()/Expanded jowa
// el Column - te7taj hauteur bornée mel parent, w mch dima l'8ir kifhé
// (mathalan Row jowa SingleChildScrollView = unbounded height -> crash).
// mainAxisSize.min + gap fixe = te5dem f'ay parent (Grid WALA Row) bla
// ay risque.
//
// 🔴 FIX (rappel AppSizes): sizes.statCardXxx (mch MediaQuery direct).
// ============================================================================
class StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const StatCard({super.key, required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(sizes.statCardPadding),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: sizes.statCardIconContainerSize,
            height: sizes.statCardIconContainerSize,
            decoration: BoxDecoration(color: color.withOpacity(0.16), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: sizes.statCardIconSize),
          ),
          SizedBox(height: sizes.statCardIconValueGap),
          Text(
            value,
            style: TextStyle(fontSize: sizes.statCardValueFontSize, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          SizedBox(height: sizes.statCardValueLabelGap),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: sizes.statCardLabelFontSize, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65)),
          ),
        ],
      ),
    );
  }
}