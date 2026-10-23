import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/driver_constants.dart';

class DriverApiService {
  static final DriverApiService _instance = DriverApiService._internal();
  factory DriverApiService() => _instance;
  DriverApiService._internal();

  String? _token;
  String _language = 'en';

  String get language => _language;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('oitoto_driver_token');
    _language = prefs.getString('oitoto_driver_language') ?? 'en';
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('oitoto_driver_language', lang);
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('oitoto_driver_token', token);
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('oitoto_driver_token');
  }

  Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Language': _language,
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // --- AUTHENTICATION ---
  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.requestOtp}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'phone': phone, 'role': 'driver'}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp, {String? fullName, String vehicleCategory = 'toto'}) async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.verifyOtp}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'phone': phone,
        'otp': otp,
        'role': 'driver',
        'full_name': fullName,
        'category': vehicleCategory,
      }),
    );
    final json = jsonDecode(res.body);
    if (json['success'] == true && json['data']?['token'] != null) {
      await saveToken(json['data']['token']);
    }
    return json;
  }

  // --- DRIVER CONTROLS ---
  Future<Map<String, dynamic>> toggleOnline(bool isOnline) async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.toggleOnline}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'is_online': isOnline ? 1 : 0}),
    );
    return jsonDecode(res.body);
  }

  Future<void> updateLocation(double lat, double lng, {double heading = 0.0, double speed = 0.0, int? bookingId}) async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.updateLocation}');
    try {
      await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
          'heading': heading,
          'speed_kmh': speed,
          'booking_id': bookingId,
        }),
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.profile}');
    try {
      final res = await http.get(url, headers: _headers());
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        return json['data'];
      }
    } catch (_) {}
    return null;
  }

  // --- TRIP EXECUTION STEPS ---
  Future<Map<String, dynamic>?> getActiveTrip() async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.activeBooking}');
    try {
      final res = await http.get(url, headers: _headers());
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        return json['data'];
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> acceptTrip(int bookingId) async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.acceptBooking}/$bookingId/accept');
    final res = await http.post(url, headers: _headers());
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> markArrived(int bookingId) async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.arrivedAtPickup}/$bookingId/arrived');
    final res = await http.post(url, headers: _headers());
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> startTrip(int bookingId, String otp) async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.startTrip}/$bookingId/start-trip');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'otp': otp}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> completeTrip(int bookingId, double actualKm, {int waitingMins = 0}) async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.completeTrip}/$bookingId/complete-trip');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'actual_distance_km': actualKm,
        'waiting_duration_mins': waitingMins,
      }),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> confirmCash(int bookingId, double amount) async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.cashCollected}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'booking_id': bookingId,
        'amount': amount,
      }),
    );
    return jsonDecode(res.body);
  }

  // --- EARNINGS & WALLET ---
  Future<Map<String, dynamic>?> getEarnings() async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.earnings}');
    try {
      final res = await http.get(url, headers: _headers());
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        return json['data'];
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getWallet() async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.wallet}');
    try {
      final res = await http.get(url, headers: _headers());
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        return json['data'];
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> requestPayout(double amount, {String method = 'upi_vpa', String? upiId}) async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.requestPayout}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'amount': amount,
        'payout_method': method,
        'upi_id': upiId,
      }),
    );
    return jsonDecode(res.body);
  }

  // --- DOCUMENTS ---
  Future<List<dynamic>> getDocuments() async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.documents}');
    try {
      final res = await http.get(url, headers: _headers());
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        return json['data'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> uploadDocument(String docType, String docNumber, String filePath, {String? expiryDate}) async {
    final url = Uri.parse('${DriverConstants.baseUrl}${DriverConstants.uploadDocument}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'document_type': docType,
        'document_number': docNumber,
        'file_path': filePath,
        'expiry_date': expiryDate,
      }),
    );
    return jsonDecode(res.body);
  }
}
