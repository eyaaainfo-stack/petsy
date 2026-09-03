import 'package:flutter/material.dart';

// ============================================================================
// VerifiedBadge
// ============================================================================
// 🔵 ZID (kifma tlab: "el validation eli noksod biha hia kima el tick
// el zarka eli tji fel insta ala el pdp") - badge sghir dayer, azrag
// (nafs loun Instagram - #3897F0, mch AppColors.vertpetsy/pinkpetsy
// tel app 3ammadan, bch yeb9a "reconnaissable" kifha kif el référence
// elli tlab biha) + coche 5edhra ('check') - testa3melha m3a Stack+
// Positioned fou9 ay avatar (bottom-right, kifha kif Instagram).
//
// Exemple:
//   Stack(
//     children: [
//       CircleAvatar(...), // el PDP
//       if (isVerified) const Positioned(right: -2, bottom: -2, child: VerifiedBadge()),
//     ],
//   )
// ============================================================================
class VerifiedBadge extends StatelessWidget {
  final double size;

  const VerifiedBadge({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF3897F0), // 🔵 bleu Instagram (référence explicite tel tlab)
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size * 0.11),
      ),
      child: Icon(Icons.check, color: Colors.white, size: size * 0.65),
    );
  }
}