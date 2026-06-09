import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../../config/theme.dart';
import '../../models/trip.dart';
import '../../models/payment.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../profile_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  int _tabIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadMyTrips();
    });
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) context.read<TripProvider>().loadMyTrips();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RwandaRide')),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          const _BookRideTab(),
          const _MyTripsTab(),
          const _PaymentsTab(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'My Trips'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Payments'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _BookRideTab extends StatelessWidget {
  const _BookRideTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    final activeTrip = provider.activeTrip;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activeTrip != null) _ActiveTripBanner(trip: activeTrip),

          // Hero booking card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF1A5276)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Where to?',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the button below to open the map and set your pickup and destination',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: activeTrip != null ? null : () {
                    Navigator.pushNamed(context, '/map-booking');
                  },
                  icon: const Icon(Icons.map, size: 20),
                  label: const Text('Open Map & Book Ride', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Rates info
          const Text('Rates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _RateCard(icon: Icons.two_wheeler, label: 'Moto', rate: '200 RWF/km', color: Colors.orange),
          const SizedBox(height: 8),
          _RateCard(icon: Icons.directions_car, label: 'Economy', rate: '350 RWF/km', color: AppTheme.primary),
          const SizedBox(height: 8),
          _RateCard(icon: Icons.car_rental, label: 'Standard', rate: '500 RWF/km', color: Colors.purple),
          const SizedBox(height: 8),
          _RateCard(icon: Icons.airport_shuttle, label: 'XL', rate: '700 RWF/km', color: AppTheme.success),
        ],
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String rate;
  final Color color;

  const _RateCard({required this.icon, required this.label, required this.rate, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const Spacer(),
          Text(rate, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ActiveTripBanner extends StatefulWidget {
  final Trip trip;
  const _ActiveTripBanner({required this.trip});

  @override
  State<_ActiveTripBanner> createState() => _ActiveTripBannerState();
}

class _ActiveTripBannerState extends State<_ActiveTripBanner> {
  Timer? _timer;
  Trip? _currentTrip;

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || _currentTrip == null) return;
      try {
        final detail = await ApiService.getTripDetail(_currentTrip!.id);
        if (!mounted) return;
        final newStatus = detail['status'] as String;
        if (newStatus != _currentTrip!.status) {
          setState(() {
            _currentTrip = Trip(
              id: _currentTrip!.id,
              riderId: _currentTrip!.riderId,
              driverId: _currentTrip!.driverId,
              pickupLocation: _currentTrip!.pickupLocation,
              destination: _currentTrip!.destination,
              fare: detail['fare'] != null ? (detail['fare'] as num).toDouble() : _currentTrip!.fare,
              status: newStatus,
              createdAt: _currentTrip!.createdAt,
            );
          });
          if (newStatus == 'completed') {
            _timer?.cancel();
            if (mounted) Navigator.pushNamed(context, '/invoice', arguments: _currentTrip);
          }
        }
      } catch (e) {}
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = _currentTrip!;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/rider/trip-detail', arguments: trip),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_car, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.statusLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  Text('To: ${trip.destination}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

class _MyTripsTab extends StatefulWidget {
  const _MyTripsTab();

  @override
  State<_MyTripsTab> createState() => _MyTripsTabState();
}

class _MyTripsTabState extends State<_MyTripsTab> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadMyTrips();
    });
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) context.read<TripProvider>().loadMyTrips();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    if (provider.loading && provider.myTrips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final trips = provider.myTrips;
    if (trips.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.history, size: 64, color: AppTheme.textMuted),
          SizedBox(height: 12),
          Text('No trips yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: provider.loadMyTrips,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: trips.length,
        itemBuilder: (ctx, i) {
          final trip = trips[i];
          return _TripTile(
            trip: trip,
            onTap: () => Navigator.pushNamed(context, '/rider/trip-detail', arguments: trip),
          );
        },
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  const _TripTile({required this.trip, required this.onTap});

  Color get _statusColor {
    switch (trip.status) {
      case 'requested': return Colors.orange;
      case 'accepted': return AppTheme.primary;
      case 'driver_arrived': return Colors.orange;
      case 'ongoing': return AppTheme.primary;
      case 'completed': return AppTheme.success;
      case 'paid': return AppTheme.success;
      default: return AppTheme.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Trip #${trip.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(trip.statusLabel,
                    style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.my_location, size: 14, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(trip.pickupLocation,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on, size: 14, color: AppTheme.danger),
              const SizedBox(width: 6),
              Expanded(child: Text(trip.destination,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            if (trip.fare != null) ...[
              const SizedBox(height: 8),
              Text('${trip.fare!.toStringAsFixed(0)} RWF',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _PaymentsTab extends StatefulWidget {
  const _PaymentsTab();

  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  List<Payment> _payments = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final payments = await ApiService.getMyPayments();
      if (mounted) setState(() => _payments = payments);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_payments.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_long, size: 64, color: AppTheme.textMuted),
          SizedBox(height: 12),
          Text('No payments yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _payments.length,
        itemBuilder: (ctx, i) => _PaymentTile(payment: _payments[i]),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.payments, color: AppTheme.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trip #${payment.tripId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(payment.method.toUpperCase(),
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Text('${payment.amount.toStringAsFixed(0)} RWF',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}