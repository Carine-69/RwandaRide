import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/trip.dart';
import '../../providers/trip_provider.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../widgets/custom_button.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  Trip? _trip;
  Map<String, dynamic>? _tripDetail;
  String _paymentMethod = 'cash';
  bool _paying = false;
  bool _loadingDetail = false;

  static const _paymentMethods = ['cash', 'mtn_mobile', 'airtel_money'];
  static const _paymentLabels = {
    'cash': 'Cash',
    'mtn_mobile': 'MTN Mobile Money',
    'airtel_money': 'Airtel Money',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_trip == null) {
      _trip = ModalRoute.of(context)!.settings.arguments as Trip?;
      if (_trip != null) _fetchDetail();
    }
  }

  Future<void> _fetchDetail() async {
    if (_trip == null) return;
    setState(() => _loadingDetail = true);
    try {
      final detail = await ApiService.getTripDetail(_trip!.id);
      if (mounted) setState(() => _tripDetail = detail);
    } catch (e) {
      // silently fail, just won't show driver details
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  Future<void> _cancel() async {
    if (_trip == null) return;
    final ok = await context.read<TripProvider>().cancelTrip(_trip!.id);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip cancelled'), backgroundColor: AppTheme.danger),
      );
    } else {
      final err = context.read<TripProvider>().error ?? 'Failed to cancel';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.danger),
      );
    }
  }

  Future<void> _pay() async {
    if (_trip == null || _trip!.fare == null) return;
    setState(() => _paying = true);
    try {
      await ApiService.createPayment(
        tripId: _trip!.id,
        amount: _trip!.fare!,
        method: _paymentMethod,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful!'), backgroundColor: AppTheme.success),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    if (trip == null) return const Scaffold(body: Center(child: Text('Trip not found')));

    final driver = _tripDetail?['driver'];

    return Scaffold(
      appBar: AppBar(title: Text('Trip #${trip.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusCard(trip: trip),
            const SizedBox(height: 20),

            // Driver card — shown when driver is assigned
            if (driver != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Driver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(Icons.person, color: AppTheme.primary, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(driver['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(driver['phone'], style: const TextStyle(color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone, color: AppTheme.primary),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.directions_car, color: AppTheme.textMuted, size: 20),
                          const SizedBox(width: 8),
                          Text(driver['vehicle_type'].toString().toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.textDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              driver['vehicle_plate'],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_loadingDetail) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
            ],

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _RouteRow(icon: Icons.my_location, color: AppTheme.primary, label: trip.pickupLocation, title: 'Pickup'),
                    Padding(
                      padding: const EdgeInsets.only(left: 11),
                      child: Container(width: 2, height: 24, color: const Color(0xFFDDE1E7)),
                    ),
                    _RouteRow(icon: Icons.location_on, color: AppTheme.danger, label: trip.destination, title: 'Destination'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (trip.fare != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_outlined, color: AppTheme.success, size: 28),
                      const SizedBox(width: 12),
                      const Text('Fare', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const Spacer(),
                      Text(
                        '${trip.fare!.toStringAsFixed(0)} RWF',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            if (trip.isCompleted && trip.fare != null) ...[
              const Text('Payment method', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              ..._paymentMethods.map((m) => RadioListTile<String>(
                    value: m,
                    groupValue: _paymentMethod,
                    onChanged: (v) => setState(() => _paymentMethod = v!),
                    title: Text(_paymentLabels[m]!),
                    activeColor: AppTheme.primary,
                    contentPadding: EdgeInsets.zero,
                  )),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Pay ${trip.fare!.toStringAsFixed(0)} RWF',
                icon: Icons.payments,
                color: AppTheme.success,
                loading: _paying,
                onPressed: _pay,
              ),
            ],

            if (trip.canCancel) ...[
              const SizedBox(height: 12),
              DangerButton(
                label: 'Cancel Trip',
                loading: context.watch<TripProvider>().loading,
                onPressed: _cancel,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Trip trip;
  const _StatusCard({required this.trip});

  Color get _color {
    switch (trip.status) {
      case 'requested': return Colors.orange;
      case 'accepted': return AppTheme.primary;
      case 'completed': return AppTheme.success;
      default: return AppTheme.danger;
    }
  }

  IconData get _icon {
    switch (trip.status) {
      case 'requested': return Icons.search;
      case 'accepted': return Icons.directions_car;
      case 'completed': return Icons.check_circle;
      default: return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _color, size: 32),
          const SizedBox(width: 12),
          Text(trip.statusLabel,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _color)),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String label;

  const _RouteRow({required this.icon, required this.color, required this.title, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}