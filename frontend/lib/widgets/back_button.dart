import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomBackButton extends StatelessWidget {
  final Color? color;           // لون الأيقونة (إذا ما تحطّش ياخذ الـ TextDark)
  final Color? backgroundColor; // لون الدائرة من التالي (خلفية الفلسة)
  final VoidCallback? onPressed;// إذا تحب تعمل حاجة خاصة، وإلا يرجع للورا automatique

  const CustomBackButton({
    super.key,
    this.color,
    this.backgroundColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // نجيبو النسبة المئوية باش تجي متناسقة مع التليفونات الكل
    final double topPadding = MediaQuery.of(context).padding.top + 10;

    // Positioned.directional (mch Positioned 3adi): b'"start" mch "left".
    // Fel LTR (fr/en) "start" = left (kifha kif 9bal). Fel RTL (ar) "start"
    // = right automatique. Bla hedhi, el bouton kan yeb9a "left" fixe
    // hatta fel 3arbi, w hedha ghalet (fel RTL "back" el mfroudh yban
    // right, mch left).
    return Positioned.directional(
      textDirection: Directionality.of(context),
      top: topPadding,
      start: 16.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onPressed ?? () => Navigator.maybePop(context), 
          child: Container(
            width: 35.0,  
            height: 35.0,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white.withOpacity(0.5), 
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded, // أيقونة العودة المودرن
              size: 20.0,
              color: color ?? AppColors.textDark, // اللون اللّي تحددو أنت
            ),
          ),
        ),
      ),
    );
  }
}