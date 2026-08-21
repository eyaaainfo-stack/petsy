import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'constants/app_colors.dart';
import 'services/power_save_service.dart';
import 'views/user/splash_decider.dart';

// ============================================================================
// MyApp
// ============================================================================
// 🔴 FIX: bdelnaha min StatelessWidget l StatefulWidget bech nnajmou
// netba3aw el mode-tlf (light/dark) 7a9i9i, mch StatelessWidget +
// ThemeMode.system eli kan ye5altali bin "user 5tar dark b rou7ou"
// w "battery saver farrad dark automatiquement" (nafs signal el
// brightness fel zouz 7alat - Flutter/Android ma yfar9ouch).
//
// El mantiq tawa:
//   1) Nesma3ou el brightness (didChangePlatformBrightness).
//   2) Kol taghyir, nas2lou PowerSaveService ken battery saver active.
//   3) Ken active -> n-ignore-aw el taghyir (n5alliw el theme kif
//      ma howa, mch force light wala dark - ghir el "jump" el
//      automatique el battery saver eli n-ignoriwh).
//   4) Ken mahouch active -> netba3ou el brightness el jdid (light/
//      dark, kifma el user 5tar mel Settings mte3ou).
// ============================================================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncThemeWithSystem();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    _syncThemeWithSystem();
  }

  Future<void> _syncThemeWithSystem() async {
    final bool powerSaveActive = await PowerSaveService.isPowerSaveMode();
    if (powerSaveActive) return; // n-ignore-aw - mch battery eli t9arrar

    final Brightness systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final ThemeMode next =
        systemBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;

    if (mounted && next != _themeMode) {
      setState(() => _themeMode = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'petsy',

      // Config mta3 Traduction (Easy Localization)
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales, // declarer dans main
      locale: context.locale, // declarer dans main

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
      themeMode: _themeMode,

      home: const SplashDecider(),
    );
  }
}