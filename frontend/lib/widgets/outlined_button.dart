import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSelected;
  final double? width;
  final double? height;
  final double fontFactor;
  final Widget? prefixIcon;

  const CustomOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isSelected = false,
    this.width,
    this.height,
    this.fontFactor = 0.35,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonHeight = constraints.maxHeight;

          final calculatedFontSize = buttonHeight.isFinite && buttonHeight > 0
              ? buttonHeight * fontFactor
              : 16.0;

          // 💡 GestureDetector: Nzeela 3adiya mghir 7ta wave/ripple effect
          return GestureDetector(
            onTap: onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20.0),
                // 🟢 Border: VertPetsy f'selection, gris clair f'unselected
                border: Border.all(
                  color: isSelected ? AppColors.vertpetsy : Colors.grey.shade400,
                  width: isSelected ? 2.0 : 1.0,
                ),
                // 🌫️ Shadow: Yeth'her ken kif ikoun selected khw
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.vertpetsy.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (prefixIcon != null) ...[
                    prefixIcon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: calculatedFontSize,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}