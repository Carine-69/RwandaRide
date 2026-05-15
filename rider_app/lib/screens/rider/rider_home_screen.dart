import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../../config/theme.dart';
import '../../models/trip.dart';
import '../../models/payment.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  final _pickupController = TextEditingController();
  final _destController = TextEditingController();
  String _vehicleType = 'moto';
  int _tabIndex = 0;

  static const _vehicles = [
    {'type': 'moto', 'label': 'Moto', 'icon': Icons.two_wheeler, 'rate': '200'},
    {'type': 'economy', 'label': 'Economy', 'icon': Icons.directions_car, 'rate': '350'},
    {'type': 'standard', 'label': 'Standard', 'icon': Icons.car_rental, 'rate': '500'},
    {'type': 'xl', 'label': 'XL', 'icon': Icons.airport_shuttle, 'rate': '700'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadMyTrips();
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destController.dispose();
    super.dispose();
  }

  Future<void> _bookRide() async {
    if (_pickupController.text.isEmpty || _destController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter pickup and destination')),
      );
      return;
    }
    final trip = await context.read<TripProvider>().bookRide(
          pickupLocation: _pickupController.text.trim(),
          destination: _destController.text.trim(),
          vehicleType: _vehicleType,
        );
    if (!mounted) return;
    if (trip != null) {
      _pickupController.clear();
      _destController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride requested! Waiting for a driver...'), backgroundColor: AppTheme.success),
      );
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
      appBar: AppBar(
        title: const Text('RwandaRide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () {
              // Pop to root which triggers auth redirect
              Navigator.of(context).pushNamedAndRemoveUntil('/logout', (_) => false);
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _BookRideTab(
            pickupController: _pickupController,
            destController: _destController,
            vehicleType: _vehicleType,
            vehicles: _vehicles,
            onVehicleSelected: (v) => setState(() => _vehicleType = v),
            onBook: _bookRide,
          ),
          const _MyTripsTab(),
          const _PaymentsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'My Trips'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Payments'),
        ],
      ),
    );
  }
}

// ─── Book Ride Tab ────────────────────────────────

class _BookRideTab extends StatelessWidget {
  final TextEditingController pickupController;
  final TextEditingController destController;
  final String vehicleType;
  final List<Map<String, dynamic>> vehicles;
  final ValueChanged<String> onVehicleSelected;
  final VoidCallback onBook;

  const _BookRideTab({
    required this.pickupController,
    required this.destController,
    required this.vehicleType,
    required this.vehicles,
    required this.onVehicleSelected,
    required this.onBook,
  });

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
          const Text('Where to?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Pickup location',
            hint: 'e.g. Kigali Convention Centre',
            controller: pickupController,
            prefixIcon: Icons.my_location,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Destination',
            hint: 'e.g. Kimironko Market',
            controller: destController,
            prefixIcon: Icons.location_on,
          ),
          const SizedBox(height: 24),
          const Text('Choose vehicle', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          ...vehicles.map((v) => _VehicleOption(
                type: v['type'] as String,
                label: v['label'] as String,
                icon: v['icon'] as IconData,
                rate: v['rate'] as String,
                selected: vehicleType == v['type'],
                onTap: () => onVehicleSelected(v['type'] as String),
              )),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Request Ride',
            icon: Icons.directions_car,
            loading: provider.loading,
            onPressed: activeTrip != null ? null : onBook,
          ),
        ],
      ),
    );
  }
}

class _ActiveTripBanner extends StatelessWidget {
  final Trip trip;
  const _ActiveTripBanner({required this.trip});

  @override
  Widget build(BuildContext context) {
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

class _VehicleOption extends StatelessWidget {
  final String type;
  final String label;
  final IconData icon;
  final String rate;
  final bool selected;
  final VoidCallback onTap;

  const _VehicleOption({
    required this.type,
    required this.label,
    required this.icon,
    required this.rate,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.primary : const Color(0xFFDDE1E7), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppTheme.primary : AppTheme.textMuted, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? AppTheme.primary : AppTheme.textDark)),
            ),
            Text('$rate RWF/km',
                style: TextStyle(color: selected ? AppTheme.primary : AppTheme.textMuted, fontSize: 13)),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppTheme.primary : AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── My Trips Tab ─────────────────────────────────

class _MyTripsTab extends StatefulWidget {
  const _MyTripsTab();

  @override
  State<_MyTripsTab> createState() => _MyTripsTabState();
}

class _MyTripsTabState extends State<_MyTripsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadMyTrips();
    });
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
      case 'completed': return AppTheme.success;
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
                    color: _statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(trip.statusLabel,
                    style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.my_location, size: 14, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(trip.pickupLocation,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on, size: 14, color: AppTheme.danger),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(trip.destination,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
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

// ─── Payments Tab ─────────────────────────────────

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
                borderRadius: BorderRadius.circular(12),
              ),
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
            Text(
              '${payment.amount.toStringAsFixed(0)} RWF',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
