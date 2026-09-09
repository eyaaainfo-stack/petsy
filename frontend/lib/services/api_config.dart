// ============================================================================
// ApiConfig
// ============================================================================
// Kol el URLs el mumkina lel backend, mjam3in fi blasa wa7da - 3ala 7sab
// win rayeh tjarrab el app (chrome, émulateur, téléphone 7a9i9i...).
//
// Bch tbadel: badel GHIR "target" hnaya taht (ApiConfig.target), w
// ApiService (w bel tali l'app kollha) ye5dem automatique m3a el URL
// es-sa7i7a. Ma3adech lezemek tfattech fel api_service.dart wla tbadel
// string manuel kol ma tbadel win rayeh tjarrab.
// ============================================================================

enum ApiTarget {
  /// flutter run -d chrome (web) - el backend ye5dem fi nefs el machine.
  web,

  /// Émulateur Android - 10.0.2.2 houwa l'alias li "localhost tel PC"
  /// mel dakhel tel émulateur (mch el IP 7a9i9i).
  androidEmulator,

  /// iOS Simulator - nefs el machine tel backend, kifha "web".
  iosSimulator,

  /// Téléphone 7a9i9i (USB wla WiFi) - lezemek l'IP tel PC (ipconfig
  /// fi terminal Windows, wla ifconfig / ip addr fi Mac/Linux), w el
  /// PC w et-téléphone lezmin fi NEFS el WiFi.
  physicalDevice,
}

class ApiConfig {
 // ApiTarget.physicalDevice;  wla ApiTarget.web
  static const ApiTarget target = ApiTarget.physicalDevice;


  static const String physicalDeviceIp = '192.168.1.201';

  static const int port = 5000;

  static String get baseUrl {
    switch (target) {
      case ApiTarget.web:
        return 'http://localhost:$port/api';
      case ApiTarget.androidEmulator:
        return 'http://10.0.2.2:$port/api';
      case ApiTarget.iosSimulator:
        return 'http://localhost:$port/api';
      case ApiTarget.physicalDevice:
        return 'http://$physicalDeviceIp:$port/api';
    }
  }
}