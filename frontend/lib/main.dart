import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app.dart';


void main() async {
  // 1. Initialisation mta3 el-moteur
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialisation mta3 easy_localization
  await EasyLocalization.ensureInitialized();

  runApp(
    // N'ghellofou el-App b-EasyLocalization
    EasyLocalization(
      supportedLocales: const [Locale('fr'), Locale('ar'), Locale('en')],
      path: 'assets/translations', 
      fallbackLocale: const Locale('fr'), // Langue par défaut
      child: const MyApp(),
    ),
  );
}