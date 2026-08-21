import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;            
  final VoidCallback onPressed; 
  final Color? color;           
  final double widthFactor;   // نسبة عرض الزر بالنسبة للشاشة
  final double heightFactor;  // نسبة ارتفاع الزر بالنسبة للشاشة
  final double fontFactor;    // نسبة الخط بالنسبة لارتفاع الـ Button بَيْدُو (مثلاً 35%)

  // --------------------------------------------------------------------
  // 3 paramètres JDOD, kolhom optionnels (= null/false b'default) bch
  // el CustomButton el 9dima (fel language.dart, onboarding.dart...)
  // tab9a te5dem bla ma tetbeddel 7atta 7arf fiha.
  // --------------------------------------------------------------------
  final IconData? icon;      // logo/icone 9bal el text (null = mafamech)
  final String? subtitle;    // description sghira TAHT el text, JOWA el bouton
  final bool showArrow;      // "›" fel lakher (bch el bouton ykoun "selection")
  // 🔴 FIX: kanet na9sa - el bouton ma3andouch tari9a ynaHHi rou7ou
  // (disable) ki el appel API ye5dem (_isSubmitting). El guard "if
  // (_isSubmitting) return;" fel _onNextPressed ma yekfich (fama race
  // condition: 2 taps sri3in ynajjmou ye3addiw el zouz 9bal ma
  // _isSubmitting yetbeddel) - hedha elli sabbeb el double appel
  // (create profile -> photo upload x2 -> Navigator.push x2). Tawa:
  // enabled=false -> onPressed: null lel ElevatedButton - Flutter
  // NAFSOU yamна3 el lamsa (mch guard b'yedna), 100% amen.
  final bool enabled;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.widthFactor = 0.85,  
    this.heightFactor = 0.07, 
    this.fontFactor = 0.35,   // الخط ياخد 35% من ارتفاع الزر
    this.icon,
    this.subtitle,
    this.showArrow = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return SizedBox(
      width: screenSize.width * widthFactor,
      height: screenSize.height * heightFactor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // constraints.maxHeight هي ارتفاع الـ Button بالظبط
          final buttonHeight = constraints.maxHeight;

          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color ?? AppColors.pinkpetsy,
              disabledBackgroundColor: (color ?? AppColors.pinkpetsy).withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
              elevation: 2,
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.05),
            ),
            onPressed: enabled ? onPressed : null,
            // ------------------------------------------------------------
            // Row 3ala tool el bouton: [icon?] [text + subtitle?] [arrow?]
            // Lowkan icon/subtitle/showArrow kolhom mch mawjoudin (fel
            // boutons el 9dam kifha kif "next"/"suivant"), el Row tbeddel
            // wala 7aja fel chekel - el Text yeb9a f'nefs el west kifha
            // kif kan 9bal (Expanded + centered).
            // ------------------------------------------------------------
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: buttonHeight * 0.40),
                  SizedBox(width: screenSize.width * 0.03),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment:
                        subtitle == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        textAlign: subtitle == null ? TextAlign.center : TextAlign.start,
                        style: TextStyle(
                          color: Colors.white,
                          // الخط يحسب روحو بالـ % من ارتفاع الـ Button بيدو!
                          fontSize: buttonHeight * fontFactor, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // subtitle: description sghira, JOWA el bouton (mch
                      // barra), b'font a5aff (nesf el fontFactor tel text).
                      if (subtitle != null)
                        Padding(
                          padding: EdgeInsets.only(top: buttonHeight * 0.05),
                          child: Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: buttonHeight * fontFactor * 0.5,
                              fontWeight: FontWeight.normal,
                              height: 1.2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (showArrow)
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: buttonHeight * 0.28),
              ],
            ),
          );
        },
      ),
    );
  }
}
//CustomButton(
//  text: 'Valider',
//  color: AppColors.vertpetsy,
//  widthFactor: 0.90,  // ياخد 90% من عرض الشاشة
//  heightFactor: 0.08, // ياخد 8% من ارتفاع الشاشة
//  fontFactor: 0.40,   // يكبر الخط الشوية لـ 40% من ارتفاع الزر
//  onPressed: () {
//    // الخدمة متاعك هوني
//  },
//)
//
// EXEMPLE bel icon + subtitle + arrow (kifha kif account_type.dart):
//CustomButton(
//  text: 'Pet Owner',
//  subtitle: 'I have a pet and I'm looking for trusted care.',
//  icon: Icons.person,
//  showArrow: true,
//  widthFactor: 0.86,
//  heightFactor: 0.115,
//  fontFactor: 0.28,
//  onPressed: () {},
//)