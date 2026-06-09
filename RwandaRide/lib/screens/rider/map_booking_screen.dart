import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../../config/theme.dart';
import '../../widgets/custom_button.dart';

class MapBookingScreen extends StatefulWidget {
  const MapBookingScreen({super.key});

  @override
  State<MapBookingScreen> createState() => _MapBookingScreenState();
}

class _MapBookingScreenState extends State<MapBookingScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final _pickupController = TextEditingController();
  final _destController = TextEditingController();

  LatLng? _pickupLatLng;
  LatLng? _destLatLng;
  LatLng _currentPosition = const LatLng(-1.9441, 30.0619); // Kigali default
  String _vehicleType = 'moto';
  bool _settingPickup = true;
  bool _loading = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  static const _vehicles = [
    {'type': 'moto', 'label': 'Moto', 'icon': Icons.two_wheeler, 'rate': '200'},
    {'type': 'economy', 'label': 'Economy', 'icon': Icons.directions_car, 'rate': '350'},
    {'type': 'standard', 'label': 'Standard', 'icon': Icons.car_rental, 'rate': '500'},
    {'type': 'xl', 'label': 'XL', 'icon': Icons.airport_shuttle, 'rate': '700'},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      final place = placemarks.first;
      final address = '${place.street}, ${place.locality}';

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _pickupLatLng = _currentPosition;
        _pickupController.text = address;
        _markers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: _currentPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Pickup', snippet: address),
        ));
      });

      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 15));
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _onMapTapped(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      final place = placemarks.first;
      final address = '${place.street}, ${place.locality}';

      setState(() {
        if (_settingPickup) {
          _pickupLatLng = position;
          _pickupController.text = address;
          _markers.removeWhere((m) => m.markerId.value == 'pickup');
          _markers.add(Marker(
            markerId: const MarkerId('pickup'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: 'Pickup', snippet: address),
          ));
        } else {
          _destLatLng = position;
          _destController.text = address;
          _markers.removeWhere((m) => m.markerId.value == 'destination');
          _markers.add(Marker(
            markerId: const MarkerId('destination'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: 'Destination', snippet: address),
          ));
        }

        if (_pickupLatLng != null && _destLatLng != null) {
          _drawRoute();
        }
      });
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
  }

  void _drawRoute() {
    if (_pickupLatLng == null || _destLatLng == null) return;
    setState(() {
      _polylines.clear();
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: [_pickupLatLng!, _destLatLng!],
        color: AppTheme.primary,
        width: 4,
      ));
    });
  }

  Future<void> _bookRide() async {
    if (_pickupLatLng == null || _destLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and destination on the map')),
      );
      return;
    }
    if (_pickupController.text.isEmpty || _destController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup and destination required')),
      );
      return;
    }

    setState(() => _loading = true);
    final trip = await context.read<TripProvider>().bookRide(
      pickupLocation: _pickupController.text.trim(),
      destination: _destController.text.trim(),
      vehicleType: _vehicleType,
      pickupLat: _pickupLatLng!.latitude,
      pickupLng: _pickupLatLng!.longitude,
      destLat: _destLatLng!.latitude,
      destLng: _destLatLng!.longitude,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (trip != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride requested! Waiting for a driver...'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } else {
      final err = context.read<TripProvider>().error ?? 'Failed to book ride';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book a Ride')),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) => _mapController.complete(controller),
                  onTap: _onMapTapped,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                ),

                // Pickup/Destination toggle
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _settingPickup = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _settingPickup ? AppTheme.success.withOpacity(0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: _settingPickup ? Border.all(color: AppTheme.success) : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.my_location, color: _settingPickup ? AppTheme.success : AppTheme.textMuted, size: 16),
                                    const SizedBox(width: 4),
                                    Text('Pickup', style: TextStyle(
                                      color: _settingPickup ? AppTheme.success : AppTheme.textMuted,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _settingPickup = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_settingPickup ? AppTheme.danger.withOpacity(0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: !_settingPickup ? Border.all(color: AppTheme.danger) : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.location_on, color: !_settingPickup ? AppTheme.danger : AppTheme.textMuted, size: 16),
                                    const SizedBox(width: 4),
                                    Text('Destination', style: TextStyle(
                                      color: !_settingPickup ? AppTheme.danger : AppTheme.textMuted,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Instruction
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _settingPickup
                          ? '📍 Tap map to set pickup location'
                          : '🎯 Tap map to set destination',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Booking form
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pickup
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.my_location, color: AppTheme.success, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        _pickupController.text.isEmpty ? 'Tap map to set pickup' : _pickupController.text,
                        style: TextStyle(
                          color: _pickupController.text.isEmpty ? AppTheme.textMuted : AppTheme.textDark,
                          fontSize: 13,
                        ),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 8),

                  // Destination
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.location_on, color: AppTheme.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        _destController.text.isEmpty ? 'Tap map to set destination' : _destController.text,
                        style: TextStyle(
                          color: _destController.text.isEmpty ? AppTheme.textMuted : AppTheme.textDark,
                          fontSize: 13,
                        ),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Vehicle type
                  SizedBox(
                    height: 60,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _vehicles.map((v) {
                        final selected = _vehicleType == v['type'];
                        return GestureDetector(
                          onTap: () => setState(() => _vehicleType = v['type'] as String),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.primary.withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? AppTheme.primary : const Color(0xFFDDE1E7),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(children: [
                              Icon(v['icon'] as IconData, color: selected ? AppTheme.primary : AppTheme.textMuted, size: 20),
                              const SizedBox(width: 6),
                              Text(v['label'] as String, style: TextStyle(
                                color: selected ? AppTheme.primary : AppTheme.textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  PrimaryButton(
                    label: 'Request Ride',
                    icon: Icons.directions_car,
                    loading: _loading,
                    onPressed: _pickupLatLng != null && _destLatLng != null ? _bookRide : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}