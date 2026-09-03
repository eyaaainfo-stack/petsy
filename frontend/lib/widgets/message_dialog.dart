import 'package:flutter/material.dart';

// ============================================================================
// showMessageDialog
// ============================================================================
// 🔵 ZID (kifma tlab: "ay snackbar tji fal app nhbha twalli tji fi
// fenetre") - remplace ScaffoldMessenger.showSnackBar el app el KOL
// (64 appel, 28 fichier).
//
// 🔴 FIX (kifma tlab: "nhb just les snackbar eli kenou yjiw mellouta
// en gris ywalliw fi fenetre w mnghir ok w yokodo nafs el wkt eli
// kenou yokodouh") - kanet AlertDialog b'bouton "OK" (el user lezmou
// yal9as bidou bch tighleg) - tawa: MAFAMECH bouton, tghaleg WA7DHA
// automatique ba3d 4 secondes (Duration.zero->4000ms = el durée par
// défaut tel SnackBar Flutter el asli, kifma kanet 9bal).
// ============================================================================
void showMessageDialog(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      // 🔵 el timer yetlaggi automatique wa9t el widget ye5la9 (build) -
      // "dialogContext.mounted" ye7mina (ken el user lawwa7 barra
      // yedou/navigah 9bal el 4 secondes, ma nnajjmouch ن3addiw
      // Navigator.pop 3ala route mch mawjouda).
      Future.delayed(const Duration(milliseconds: 4000), () {
        if (dialogContext.mounted) {
          Navigator.of(dialogContext).pop();
        }
      });

      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text(message, textAlign: TextAlign.center),
      );
    },
  );
}