import 'dart:convert';
import 'package:http/http.dart' as http;

// ============================================================================
// ApiService
// ============================================================================
// Class markazia lel appels HTTP el kol - kol el controllers (Auth,
// Profile, Pet...) ynajmou ysta3malouha, bch ma nkarrarouch el base URL
// w el headers fi kol fichier wa7dou.
// ============================================================================
class ApiService {
  // --------------------------------------------------------------------
  // 🔵 BADEL HOUNI 3ala 7sab win rayeh tjarrab:
  //   - Web (flutter run -d chrome)  : 'http://localhost:5000'
  //   - Émulateur Android            : 'http://10.0.2.2:5000'
  //   - iOS Simulator                : 'http://localhost:5000'
  //   - Device 7a9i9i (téléphone)    : 'http://<IP tel PC>:5000'
  //     (el IP tel PC: ipconfig fi terminal, w el PC w el téléphone
  //     lezmin fi nefs el WiFi)
  // --------------------------------------------------------------------
  static const String baseUrl = 'http://localhost:5000/api';

  static Future<http.Response> post(String path, Map<String, dynamic> body) {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> get(String path, {String? token}) {
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body, {String? token}) {
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  // 🔵 ZID: patch (el backend yesta3mel PATCH lel update profile, mch PUT)
  static Future<http.Response> patch(String path, Map<String, dynamic> body, {String? token}) {
    return http.patch(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }
}