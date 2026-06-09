import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../services/api_service.dart';

class TripProvider extends ChangeNotifier {
  List<Trip> _myTrips = [];
  List<Trip> _availableTrips = [];
  List<Trip> _completedTrips = [];
  Trip? _activeTrip;
  bool _loading = false;
  String? _error;

  List<Trip> get myTrips => _myTrips;
  List<Trip> get availableTrips => _availableTrips;
  List<Trip> get completedTrips => _completedTrips;
  Trip? get activeTrip => _activeTrip;
  bool get loading => _loading;
  String? get error => _error;

  void _setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }

  void clearActiveTrip() {
    _activeTrip = null;
    notifyListeners();
  }

  Future<Trip?> bookRide({
    required String pickupLocation,
    required String destination,
    required String vehicleType,
    double? pickupLat,
    double? pickupLng,
    double? destLat,
    double? destLng,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final trip = await ApiService.createTrip(
        pickupLocation: pickupLocation,
        destination: destination,
        vehicleType: vehicleType,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        destLat: destLat,
        destLng: destLng,
      );
      _activeTrip = trip;
      _myTrips.insert(0, trip);
      notifyListeners();
      return trip;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMyTrips() async {
    _error = null;
    try {
      _myTrips = await ApiService.getMyTrips();
      final active = _myTrips.where((t) => t.isActive).firstOrNull;
      if (active?.status != _activeTrip?.status) {
        _activeTrip = active;
      }
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> loadDriverActiveTrip() async {
    _error = null;
    try {
      final trips = await ApiService.getMyDriverTrips();
      _completedTrips = trips.where((t) => t.status == 'completed').toList();
      final active = trips.where((t) =>
        t.status == 'accepted' ||
        t.status == 'driver_arrived' ||
        t.status == 'ongoing' ||
        t.status == 'completed'
      ).firstOrNull;
      if (active?.id != _activeTrip?.id || active?.status != _activeTrip?.status) {
        _activeTrip = active;
        notifyListeners();
      }
    } on ApiException catch (e) {
      _error = e.message;
    }
  }

  Future<bool> cancelTrip(int tripId) async {
    _setLoading(true);
    _error = null;
    try {
      final updated = await ApiService.cancelTrip(tripId);
      _updateTripInList(updated);
      if (_activeTrip?.id == tripId) _activeTrip = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAvailableTrips() async {
    _setLoading(true);
    _error = null;
    try {
      _availableTrips = await ApiService.getAvailableTrips();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> acceptTrip(int tripId) async {
    _setLoading(true);
    _error = null;
    try {
      final updated = await ApiService.acceptTrip(tripId);
      _activeTrip = updated;
      _availableTrips.removeWhere((t) => t.id == tripId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> completeTrip(int tripId) async {
    _setLoading(true);
    _error = null;
    try {
      final updated = await ApiService.completeTrip(tripId);
      _activeTrip = updated;
      _updateTripInList(updated);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _updateTripInList(Trip updated) {
    final idx = _myTrips.indexWhere((t) => t.id == updated.id);
    if (idx >= 0) _myTrips[idx] = updated;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}