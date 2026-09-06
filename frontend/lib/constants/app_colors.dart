import 'package:flutter/material.dart';

class AppColors {
  // couleur principale app 
  static const Color primarySeed = Color(0xFF1A5F7A);
  static const Color pinkpetsy = Color(0xFFEC407A);
  static const Color vertpetsy = Color(0xFF6DCBB4);    

  static const Color error = Color(0xFFD32F2F);  
  static const Color success = Color(0xFF388E3C);  

  // 🔴 kanet na9sa: back_button.dart yesta3melha w kanet raise
  // "Undefined name 'textDark'" kol ma testa3mel CustomBackButton.
  static const Color textDark = Color(0xFF2D2D2D);

  // 🔵 ZID (kifma tlab: "ken el sitter wlle el owner male, my profile
  // owner w sitter badel el rose bel vert, w kenhom femelle khallih
  // rose") - l'accent color tel "My Profile" (owner/sitter) yet3ala9
  // b'el gender: male -> vertpetsy, female (wla mch mzid 3ad, ".mafamech
  // gender") -> pinkpetsy (el behavior el asli, bla ma yetbeddel).
  // Helper WA7ED houni (mch mkarrar fel 2 fichiers) - my_profile_owner.
  // dart w my_profile_sitter.dart el 2 yesta3malouh.
  static Color myProfileAccent(String? gender) => gender == 'male' ? vertpetsy : pinkpetsy;
}