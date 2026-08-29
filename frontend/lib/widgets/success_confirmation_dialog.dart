import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';

// ============================================================================
// showSuccessConfirmationDialog
// ============================================================================
// 🔵 ZID (kifma tlab, "zid el fenetre hedhi fel widgets 5atar bech
// nesta3mlouha barsha") - popup mchtarek: tick (✓) dayra 5adhra/teal +
// message + bouton "OK". Yesta3mlou ay écran fel app (mch bark
// request_a_book.dart).
//
// Kifech testa3milha:
//   await showSuccessConfirmationDialog(context, message: 'Booking sent!');
// ============================================================================
Future<void> showSuccessConfirmationDialog(
  BuildContext context, {
  required String message,
  String? title,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: AppColors.vertpetsy.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: AppColors.vertpetsy, size: 56),
              ),
              const SizedBox(height: 18),
              if (title != null) ...[
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
              ],
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pinkpetsy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('ok_button'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}