import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;
  bool _loading = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get loading => _loading;

  Future<void> checkAuth() async {
    final token = await ApiService.getToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
    } else {
      // We store user data in prefs alongside the token so we can restore it
      // without an extra API call (the API has no /me endpoint yet)
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<bool> login({String? phone, String? email, required String password}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.login(phone: phone, email: email, password: password);
      await ApiService.saveToken(data['access_token']);
      _user = User.fromJson(data['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Connection error. Is the server running?';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    String? email,
    required String password,
    required String role,
    String? licenseNumber,
    String? vehicleType,
    String? vehiclePlate,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
        role: role,
        licenseNumber: licenseNumber,
        vehicleType: vehicleType,
        vehiclePlate: vehiclePlate,
      );
      // After register, log in automatically
      return await login(phone: phone, password: password);
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Connection error. Is the server running?';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
