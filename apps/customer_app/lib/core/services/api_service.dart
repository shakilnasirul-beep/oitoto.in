import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  String _language = 'en';

  String get language => _language;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('oitoto_token');
    _language = prefs.getString('oitoto_language') ?? 'en';
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('oitoto_language', lang);
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('oitoto_token', token);
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('oitoto_token');
  }

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

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
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.requestOtp}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'phone': phone, 'role': 'customer'}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp, {String? fullName}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyOtp}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'phone': phone,
        'otp': otp,
        'role': 'customer',
        'full_name': fullName,
      }),
    );
    final json = jsonDecode(res.body);
    if (json['success'] == true && json['data']?['token'] != null) {
      await saveToken(json['data']['token']);
    }
    return json;
  }

  // --- FARE & NEARBY TOTOS ---
  Future<List<dynamic>> getNearbyTotos(double lat, double lng, {double radius = 4.0}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.nearbyTotos}?pickup_lat=$lat&pickup_lng=$lng&radius_km=$radius');
    try {
      final res = await http.get(url, headers: _headers());
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        return json['data'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> estimateFare(double pLat, double pLng, double dLat, double dLng, {String? promo}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.estimateFare}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'pickup_lat': pLat,
        'pickup_lng': pLng,
        'drop_lat': dLat,
        'drop_lng': dLng,
        'promo_code': promo,
      }),
    );
    return jsonDecode(res.body);
  }

  // --- BOOKING ---
  Future<Map<String, dynamic>> createBooking({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String dropAddress,
    required double dropLat,
    required double dropLng,
    String paymentMode = 'cash',
    String? promoCode,
    String category = 'toto',
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createBooking}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'pickup_address': pickupAddress,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'drop_address': dropAddress,
        'drop_lat': dropLat,
        'drop_lng': dropLng,
        'payment_mode': paymentMode,
        'promo_code': promoCode,
        'category': category,
      }),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>?> getActiveBooking() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.activeBooking}');
    try {
      final res = await http.get(url, headers: _headers());
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        return json['data'];
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> cancelBooking(int bookingId, String reason) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cancelBooking}/$bookingId/cancel');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'reason': reason}),
    );
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getRideHistory() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.bookingHistory}');
    try {
      final res = await http.get(url, headers: _headers());
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        return json['data'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  // --- RATING & SOS ---
  Future<Map<String, dynamic>> submitRating(int bookingId, int rating, String tags, String comments) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.submitReview}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'booking_id': bookingId,
        'rating': rating,
        'tags': tags,
        'comments': comments,
      }),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> triggerSos(double lat, double lng, {int? bookingId}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.sosAlert}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'latitude': lat,
        'longitude': lng,
        'booking_id': bookingId,
      }),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.customerProfile}');
    try {
      final res = await http.get(url, headers: _headers());
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        return json['data'];
      }
    } catch (_) {}
    return null;
  }
}
