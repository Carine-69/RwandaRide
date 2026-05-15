import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/trip.dart';
import '../models/payment.dart';

class ApiService {
  static const _tokenKey = 'auth_token';

  // ─── Token storage ───────────────────────────────

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ─── HTTP helpers ────────────────────────────────

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final detail = body['detail'] ?? 'Something went wrong';
      throw ApiException(detail.toString(), response.statusCode);
    }
    return body;
  }

  static List<dynamic> _decodeList(http.Response response) {
    if (response.statusCode >= 400) {
      final body = jsonDecode(response.body);
      final detail = body['detail'] ?? 'Something went wrong';
      throw ApiException(detail.toString(), response.statusCode);
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  // ─── Auth endpoints ──────────────────────────────

  static Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    String? email,
    required String password,
    required String role,
    String? licenseNumber,
    String? vehicleType,
    String? vehiclePlate,
  }) async {
    final body = {
      'name': name,
      'phone': phone,
      'password': password,
      'role': role,
      if (email != null && email.isNotEmpty) 'email': email,
      if (licenseNumber != null) 'license_number': licenseNumber,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (vehiclePlate != null) 'vehicle_plate': vehiclePlate,
    };
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> login({
    String? phone,
    String? email,
    required String password,
  }) async {
    final body = {
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
    };
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  static Future<void> setDriverStatus(String status) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/auth/driver/status?status=$status'),
      headers: headers,
    );
    _decode(response);
  }

  // ─── Trip endpoints ──────────────────────────────

  static Future<Trip> createTrip({
    required String pickupLocation,
    required String destination,
    double? pickupLat,
    double? pickupLng,
    double? destLat,
    double? destLng,
    required String vehicleType,
  }) async {
    final headers = await _authHeaders();
    final body = {
      'pickup_location': pickupLocation,
      'destination': destination,
      'vehicle_type': vehicleType,
      if (pickupLat != null) 'pickup_lat': pickupLat,
      if (pickupLng != null) 'pickup_lng': pickupLng,
      if (destLat != null) 'dest_lat': destLat,
      if (destLng != null) 'dest_lng': destLng,
    };
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/trips/'),
      headers: headers,
      body: jsonEncode(body),
    );
    return Trip.fromJson(_decode(response));
  }

  static Future<List<Trip>> getMyTrips() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/trips/my-trips'),
      headers: headers,
    );
    return _decodeList(response).map((j) => Trip.fromJson(j)).toList();
  }

  static Future<List<Trip>> getAvailableTrips() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/trips/available'),
      headers: headers,
    );
    return _decodeList(response).map((j) => Trip.fromJson(j)).toList();
  }

  static Future<Trip> acceptTrip(int tripId) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/trips/$tripId/accept'),
      headers: headers,
    );
    return Trip.fromJson(_decode(response));
  }

  static Future<Trip> completeTrip(int tripId) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/trips/$tripId/complete'),
      headers: headers,
    );
    return Trip.fromJson(_decode(response));
  }

  static Future<Trip> cancelTrip(int tripId) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/trips/$tripId/cancel'),
      headers: headers,
    );
    return Trip.fromJson(_decode(response));
  }

  static Future<Trip> getTrip(int tripId) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/trips/$tripId'),
      headers: headers,
    );
    return Trip.fromJson(_decode(response));
  }

static Future<Map<String, dynamic>> getTripDetail(int tripId) async {
  final headers = await _authHeaders();
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/trips/$tripId/detail'),
    headers: headers,
  );
  return _decode(response);
}

  // ─── Payment endpoints ───────────────────────────

  static Future<Payment> createPayment({
    required int tripId,
    required double amount,
    required String method,
  }) async {
    final headers = await _authHeaders();
    final body = {'trip_id': tripId, 'amount': amount, 'method': method};
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/'),
      headers: headers,
      body: jsonEncode(body),
    );
    return Payment.fromJson(_decode(response));
  }

  static Future<List<Payment>> getMyPayments() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/payments/my-payments'),
      headers: headers,
    );
    return _decodeList(response).map((j) => Payment.fromJson(j)).toList();
  }

  static Future<DriverEarnings> getMyEarnings() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/payments/my-earnings'),
      headers: headers,
    );
    return DriverEarnings.fromJson(_decode(response));
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
