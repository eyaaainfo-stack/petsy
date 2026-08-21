import 'package:flutter/services.dart';

// ============================================================================
// PowerSaveService
// ============================================================================
// 🔵 ZID: Flutter ma3andouch access mubasharatan l "battery saver
// active wala le" - ghir el brightness (dark/light), eli mch kafya
// (battery saver forcé el dark theme fi barcha téléphones, w
// Flutter ma yfaraqch bin hedha w el user 5tar dark b rou7ou).
//
// Hedhi el class t3ayet native code (Android: PowerManager.isPowerSaveMode,
// iOS: ProcessInfo.isLowPowerModeEnabled) via method channel.
// ============================================================================
class PowerSaveService {
  static const MethodChannel _channel = MethodChannel('petsy/power_save');

  static Future<bool> isPowerSaveMode() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isPowerSaveMode');
      return result ?? false;
    } catch (_) {
      // Web, Windows, Linux (wala ay platform ma 3andhach el channel)
      // - n7asbou eli battery saver mafamech, bech ma na3wa9ouch l'app.
      return false;
    }
  }

  // --------------------------------------------------------------------
  // 🔵 ZID: twarri l'user el dialog systeme "Allow this app to ignore
  // battery optimizations?" - lowkan ydous "Allow", Android (stock)
  // ma ye9telch el app automatiquement fel battery saver / Doze mode.
  //
  // 🔴 GHIR Android "stock" battery optimization - Huawei "Protected
  // apps" couche mnfassla, mafamech API publique tetse2alha, lezemha
  // el user ydakhal l Settings b yedou.
  // --------------------------------------------------------------------
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}