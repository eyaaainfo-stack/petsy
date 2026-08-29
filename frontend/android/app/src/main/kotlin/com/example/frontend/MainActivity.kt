package com.example.frontend

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// ============================================================================
// MainActivity
// ============================================================================
// 🔵 ZID: method channel "petsy/power_save" - 2 appels:
//   1) "isPowerSaveMode": n3arfou b sa7i7 ken battery saver active
//      (chrahtha fel app.dart - bch nemna3ou el theme min yebdel dark
//      wa7dou).
//   2) "requestIgnoreBatteryOptimizations": nwarriw l'user el dialog
//      systeme "Allow this app to ignore battery optimizations?" -
//      ken yedous "Allow", Android (stock) ma yet9telch el app/debug
//      connection automatiquement fel battery saver.
//
// 🔴 IMPORTANT: hedha ye5dem GHIR lel Android "stock" battery
// optimization. Huawei 3andha couche mnfassla (EMUI "Protected apps")
// eli mafamech API publique bech tetse2al mel code - lezemha el user
// ydakhal l Settings b yedou (chrahtha: dontkillmyapp.com/huawei).
// ============================================================================
class MainActivity : FlutterActivity() {
    private val powerSaveChannel = "petsy/power_save"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, powerSaveChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isPowerSaveMode" -> {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(powerManager.isPowerSaveMode)
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(powerManager.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        try {
                            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                            // 🔴 FIX: kanet t3ayet l "startActivity" 7atta ken
                            // el téléphone MSAKKER (screen off/locked) - fi
                            // ba3dh el appareils (khousousan Huawei/EMUI),
                            // hedha ynajjam yseb'bab crash/exit direct wa9t
                            // el launch (flutter run + phone msakker). Tawa:
                            // "isInteractive" (screen 7ay/mfattah) - lowkan
                            // el screen msakker, ma ne7awlouch nel3bou b'ha
                            // (ntar9awha lel marra el jaya elli el app tefte7
                            // w el screen mfattah).
                            if (!powerManager.isIgnoringBatteryOptimizations(packageName) && powerManager.isInteractive) {
                                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                    data = Uri.parse("package:$packageName")
                                }
                                startActivity(intent)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            // 🔵 ZID: certains manufacturers (Huawei/Xiaomi/Samsung
                            // b ROM mbadla) ynajjmou ma ye5demch ma3ahom hedha
                            // l'Intent - n-catch-iw bch l'app ma te-crashch, ghir
                            // el dialog ma yban-ch.
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}