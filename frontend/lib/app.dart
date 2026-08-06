import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'constants/app_colors.dart'; 
import '../views/user/language.dart';
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'petsy',

      // Config mta3 Traduction (Easy Localization)
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,// declarer dans main
      locale: context.locale, // declarer dans main

      // Config mta3 el-Mode Sombre / Claire Auto
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primarySeed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primarySeed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // mode-téléphone auto!

      
      home:LanguageView(),
    );
  }
}