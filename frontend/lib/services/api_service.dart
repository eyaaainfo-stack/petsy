import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// ============================================================================
// ApiService
// ============================================================================
// Class markazia lel appels HTTP el kol - kol el controllers (Auth,
// Profile, Pet...) ynajmou ysta3malouha, bch ma nkarrarouch el base URL
// w el headers fi kol fichier wa7dou.
// ============================================================================
class ApiService {
  // 🔴 FIX: kol el appels kanou bla timeout - ken el réseau ye39ad
  // (battery saver, WiFi t3attel, server ma yjawebch...), l'appel
  // yestenna l l'infini w l'écran (mathalan SplashDecider) yeb9a
  // "3aleg" 3la loading bla ma yban ay erreur. Tawa kol appel
  // 3andou 8 secondes max, mba3d yrmi TimeoutException (el
  // "catch" fel appelant, mathalan _resolveHomeScreen, yal9a biha
  // w ykemmel bla ma yeb9a wa9ef).
  static const Duration _timeout = Duration(seconds: 8);
  // 🔴 FIX: uploadPhoto (multipart, image bytes) ye5ou wa9t aktar mel
  // appels l'okhrin (JSON sghir) - 8s kanou ynajjmou ye39dou el upload
  // 9bal ma ykammel (khousousan WiFi batia3/battery saver), w el photo
  // teb9a ma tetsajlch (photoUrl fadhya) bla ay erreur bayna l'user.
  static const Duration _uploadTimeout = Duration(seconds: 30);
  // --------------------------------------------------------------------
  // 🔵 BADEL HOUNI 3ala 7sab win rayeh tjarrab:
  //   - Web (flutter run -d chrome)  : 'http://localhost:5000'
  //   - Émulateur Android            : 'http://10.0.2.2:5000'
  //   - iOS Simulator                : 'http://localhost:5000'
  //   - Device 7a9i9i (téléphone)    : 'http://<192.168.1.201>:5000'
  //     (el IP tel PC: ipconfig fi terminal, w el PC w el téléphone
  //     lezmin fi nefs el WiFi)
  // --------------------------------------------------------------------
  static const String baseUrl = 'http://192.168.1.201:5000/api';

  // 🔵 ZID: lel photos (pets/users, mathalan "/uploads/pets/xxx.jpg")
  // - hedhi el routes TAHT el root (mch taht "/api"), fa lezemna base
  // mo5tlfa (bla el "/api" fel lekher). Ynajjam yestermlouha kol blasa
  // te7taj twarri photo mel backend (bdal ma tekteb el host el kamel
  // b'ydik fi kol fichier).
  static String get mediaBaseUrl => baseUrl.replaceAll('/api', '');

  static Future<http.Response> post(String path, Map<String, dynamic> body, {String? token}) {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(_timeout);
  }

  // --------------------------------------------------------------------
  // 🔵 ZID: uploadPhoto - lel routes elli ye5dhou image (multer fel
  // backend), MCH JSON 3adi - lezمha "multipart/form-data" (mch
  // "application/json"). Hedhi el bug el kbir elli kan: bnina el
  // routes fel backend (POST /api/pets/:id/photo, /users/:id/photo)
  // lakin el front 3omrou ma 3ayet biha - el photo tabqa GHIR fel
  // mémoire (Uint8List), ma tetba3thlach lel backend.
  //
  // "fieldName" LEZEM ykoun NAFS el esm elli el backend yestenna
  // (multer: upload.single('photo')) - chrahtha fel middleware/upload.js.
  // --------------------------------------------------------------------
  static Future<http.Response> uploadPhoto(
    String path,
    Uint8List photoBytes, {
    String? token,
    String fieldName = 'photo',
    String filename = 'photo.jpg',
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(http.MultipartFile.fromBytes(
      fieldName,
      photoBytes,
      filename: filename,
      // 🔴 FIX el bug el kbir: 9bal, ma kanch mrakez contentType - el
      // library "http" tab3ath default "application/octet-stream" (mch
      // "image/..."). El backend (middleware/upload.js, fileFilter)
      // yerfudh AY fichier mimetype tou3ou ma yebdach b "image/" - fa
      // KOL upload kan yetrafedh automatique 9bal ma yetsajjel fel
      // disque (uploads/ kant tab9a fadhya 7atta lowkan connexion/token
      // /petId kolhom sa7i7in). Tawa: contentType mrakez "image/jpeg"
      // (image_picker + imageQuality y5arrjou jpeg fel ghaleb) - el
      // fileFilter tawa ye9bel el fichier w yetsajjel 7a9i9atan.
      contentType: MediaType('image', 'jpeg'),
    ));

    final streamedResponse = await request.send().timeout(_uploadTimeout);
    // n7awlouha l'Response 3adiya (bch nnajmou n9raw response.body/
    // statusCode sahla, kifha kif el requêtes l'okhrin).
    return http.Response.fromStream(streamedResponse);
  }

  static Future<http.Response> get(String path, {String? token}) {
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(_timeout);
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body, {String? token}) {
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(_timeout);
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
    ).timeout(_timeout);
  }
}