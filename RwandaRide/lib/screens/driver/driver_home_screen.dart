import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../models/trip.dart';
import '../../widgets/custom_button.dart';
import '../profile_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _tabIndex = 0;
  bool _online = false;
  bool _togglingStatus = false;

  Future<void> _toggleStatus() async {
    setState(() => _togglingStatus = true);
    try {
      final newStatus = _online ? 'offline' : 'online';
      await ApiService.setDriverStatus(newStatus);
      setState(() => _online = !_online);
      if (_online) context.read<TripProvider>().loadAvailableTrips();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _togglingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RwandaRide Driver')),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _StatusTab(online: _online, toggling: _togglingStatus, onToggle: _toggleStatus),
          const _AvailableTripsTab(),
          const _WalletTab(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) {
          setState(() => _tabIndex = i);
          if (i == 1 && _online) context.read<TripProvider>().loadAvailableTrips();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.power_settings_new_outlined), selectedIcon: Icon(Icons.power_settings_new), label: 'Status'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Available'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _StatusTab extends StatefulWidget {
  final bool online;
  final bool toggling;
  final VoidCallback onToggle;

  const _StatusTab({required this.online, required this.toggling, required this.onToggle});

  @override
  State<_StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<_StatusTab> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) context.read<TripProvider>().loadDriverActiveTrip();
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
    final activeTrip = provider.activeTrip;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.online
                    ? [AppTheme.success, const Color(0xFF27AE60)]
                    : [AppTheme.textMuted, const Color(0xFF95A5A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(widget.online ? Icons.wifi : Icons.wifi_off, size: 56, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  widget.online ? 'You are Online' : 'You are Offline',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.online ? 'Receiving trip requests' : 'Go online to receive trips',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: widget.toggling ? null : widget.onToggle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: widget.online ? AppTheme.success : AppTheme.textMuted,
                    ),
                    child: widget.toggling
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.online ? 'Go Offline' : 'Go Online',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (activeTrip != null) ...[
            const Text('Current Trip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            const _ActiveDriverTripCard(),
          ],

          if (!widget.online && activeTrip == null) ...[
            const Spacer(),
            const Center(
              child: Column(children: [
                Icon(Icons.directions_car, size: 80, color: Color(0xFFDDE1E7)),
                SizedBox(height: 12),
                Text('Go online to start earning', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
              ]),
            ),
            const Spacer(),
          ],
        ],
      ),
    );
  }
}

class _ActiveDriverTripCard extends StatefulWidget {
  const _ActiveDriverTripCard();

  @override
  State<_ActiveDriverTripCard> createState() => _ActiveDriverTripCardState();
}

class _ActiveDriverTripCardState extends State<_ActiveDriverTripCard> {
  bool _notified = false;
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    final trip = provider.activeTrip;
    if (trip == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.directions_car, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(trip.statusLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.my_location, size: 14, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(trip.pickupLocation, style: const TextStyle(fontSize: 13))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on, size: 14, color: AppTheme.danger),
              const SizedBox(width: 6),
              Expanded(child: Text(trip.destination, style: const TextStyle(fontSize: 13))),
            ]),
            if (trip.fare != null) ...[
              const SizedBox(height: 8),
              Text('Fare: ${trip.fare!.toStringAsFixed(0)} RWF',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 12),

            if (trip.status == 'accepted') ...[
              if (_notified)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(child: Text('Rider notified — waiting for them to get in',
                        style: TextStyle(color: Colors.orange))),
                  ]),
                )
              else
                PrimaryButton(
                  label: 'I\'ve Arrived at Pickup',
                  icon: Icons.location_on,
                  color: Colors.orange,
                  loading: provider.loading,
                  onPressed: () async {
                    await ApiService.updateTripStatus(trip.id, 'driver_arrived');
                    if (!context.mounted) return;
                    setState(() => _notified = true);
                    await context.read<TripProvider>().loadDriverActiveTrip();
                  },
                ),
            ],

            if (trip.status == 'driver_arrived') ...[
              if (_started)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary),
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Expanded(child: Text('Journey started!',
                        style: TextStyle(color: AppTheme.primary))),
                  ]),
                )
              else
                PrimaryButton(
                  label: 'Start Journey',
                  icon: Icons.play_arrow,
                  color: AppTheme.primary,
                  loading: provider.loading,
                  onPressed: () async {
                    await ApiService.updateTripStatus(trip.id, 'ongoing');
                    if (!context.mounted) return;
                    setState(() => _started = true);
                    await context.read<TripProvider>().loadDriverActiveTrip();
                  },
                ),
            ],

            if (trip.status == 'ongoing')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(children: [
                  Icon(Icons.hourglass_top, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(child: Text('Waiting for rider to confirm arrival and pay...',
                      style: TextStyle(color: Colors.orange))),
                ]),
              ),

            if (trip.status == 'completed')
              _PendingPaymentCard(tripId: trip.id),
          ],
        ),
      ),
    );
  }
}

class _PendingPaymentCard extends StatefulWidget {
  final int tripId;
  const _PendingPaymentCard({required this.tripId});

  @override
  State<_PendingPaymentCard> createState() => _PendingPaymentCardState();
}

class _PendingPaymentCardState extends State<_PendingPaymentCard> {
  Map<String, dynamic>? _wallet;
  bool _loading = true;
  bool _confirming = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final wallet = await ApiService.getDriverWallet();
      if (mounted) setState(() { _wallet = wallet; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmPayment(int paymentId) async {
    setState(() => _confirming = true);
    try {
      await ApiService.confirmPayment(paymentId);
      if (!mounted) return;
      final invoice = await ApiService.getInvoice(widget.tripId);
      if (!mounted) return;
      context.read<TripProvider>().clearActiveTrip();
      Navigator.pushNamed(context, '/driver/receipt', arguments: {'invoice': invoice});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to confirm payment'),
            backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final pending = _wallet?['pending_payments'] as List? ?? [];
    final tripPending = pending.where((p) => p['trip_id'] == widget.tripId).toList();

    if (tripPending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange),
        ),
        child: const Row(children: [
          Icon(Icons.hourglass_top, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(child: Text('Waiting for rider to pay...',
              style: TextStyle(color: Colors.orange))),
        ]),
      );
    }

    final payment = tripPending.first;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.success),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.payments, color: AppTheme.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Payment: ${payment['amount']} RWF via ${payment['method'].toString().toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          const Text('Check your phone/wallet then confirm:',
              style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Confirm Payment Received',
            icon: Icons.check_circle,
            color: AppTheme.success,
            loading: _confirming,
            onPressed: () => _confirmPayment(payment['id']),
          ),
        ],
      ),
    );
  }
}

class _AvailableTripsTab extends StatefulWidget {
  const _AvailableTripsTab();

  @override
  State<_AvailableTripsTab> createState() => _AvailableTripsTabState();
}

class _AvailableTripsTabState extends State<_AvailableTripsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadAvailableTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    if (provider.loading && provider.availableTrips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final trips = provider.availableTrips;
    if (trips.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.loadAvailableTrips,
        child: ListView(children: const [
          SizedBox(height: 120),
          Center(child: Column(children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text('No trips available', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
            SizedBox(height: 4),
            Text('Pull to refresh', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ])),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: provider.loadAvailableTrips,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: trips.length,
        itemBuilder: (ctx, i) => _AvailableTripCard(trip: trips[i]),
      ),
    );
  }
}

class _AvailableTripCard extends StatelessWidget {
  final Trip trip;
  const _AvailableTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TripProvider>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('Trip #${trip.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              if (trip.fare != null)
                Text('${trip.fare!.toStringAsFixed(0)} RWF',
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        color: AppTheme.success, fontSize: 16)),
            ]),
            const SizedBox(height: 10),
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
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Accept Trip',
              icon: Icons.check,
              loading: provider.loading,
              onPressed: () async {
                final ok = await provider.acceptTrip(trip.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Trip accepted!' : provider.error ?? 'Failed'),
                    backgroundColor: ok ? AppTheme.success : AppTheme.danger,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletTab extends StatefulWidget {
  const _WalletTab();

  @override
  State<_WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<_WalletTab> {
  Map<String, dynamic>? _wallet;
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _load();
        context.read<TripProvider>().loadDriverActiveTrip();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final w = await ApiService.getDriverWallet();
      if (mounted) setState(() { _wallet = w; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _statusLabel(String status) {
  switch (status) {
    case 'accepted': return 'Driver on the way';
    case 'driver_arrived': return 'Driver arrived at pickup';
    case 'ongoing': return 'Journey in progress';
    case 'completed': return 'Waiting for payment';
    case 'paid': return 'Completed ✓';
    default: return status;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'accepted': return AppTheme.primary;
    case 'driver_arrived': return Colors.orange;
    case 'ongoing': return AppTheme.primary;
    case 'completed': return Colors.orange;
    case 'paid': return AppTheme.success;
    default: return AppTheme.textMuted;
  }
}

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _wallet == null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppTheme.danger)),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ));
    }

    final pending = _wallet?['pending_payments'] as List? ?? [];
    final provider = context.watch<TripProvider>();
    final activeTrip = provider.activeTrip;
    final completedTrips = provider.completedTrips;
    final netEarnings = (_wallet?['net_earnings'] as num?)?.toStringAsFixed(0) ?? '0';

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Active trip card ─────────────────────────
            if (activeTrip != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('Trip #${activeTrip.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(activeTrip.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _statusColor(activeTrip.status)),
                          ),
                          child: Text(
                            _statusLabel(activeTrip.status),
                            style: TextStyle(
                              color: _statusColor(activeTrip.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.my_location, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(activeTrip.pickupLocation,
                            style: const TextStyle(fontSize: 13))),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on, size: 14, color: AppTheme.danger),
                        const SizedBox(width: 6),
                        Expanded(child: Text(activeTrip.destination,
                            style: const TextStyle(fontSize: 13))),
                      ]),
                      if (activeTrip.startTime != null) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.access_time, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Expanded(child: Text(
                            activeTrip.endTime != null
                                ? 'Started: ${activeTrip.startTime} — Ended: ${activeTrip.endTime} (${activeTrip.duration})'
                                : 'Started: ${activeTrip.startTime}',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          )),
                        ]),
                      ],
                      if (activeTrip.fare != null) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.payments, size: 14, color: AppTheme.success),
                          const SizedBox(width: 6),
                          Text('Fare: ${activeTrip.fare!.toStringAsFixed(0)} RWF',
                              style: const TextStyle(fontWeight: FontWeight.bold,
                                  color: AppTheme.success)),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Pending payment confirmation ─────────────
            if (pending.isNotEmpty) ...[
              ...pending.map((p) => Card(
                color: AppTheme.success.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.payments, color: AppTheme.success),
                        const SizedBox(width: 8),
                        Text('Trip #${p['trip_id']} — ${p['amount']} RWF',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Text('Pending',
                              style: TextStyle(color: Colors.orange, fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('${p['method'].toString().toUpperCase()} — awaiting confirmation',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 20),
            ],

            // ── Wallet balance ───────────────────────────
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
              child: Column(children: [
                const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 6),
                Text('$netEarnings RWF',
                    style: const TextStyle(color: Colors.white, fontSize: 36,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('After 15% commission',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: _StatCard(
                label: 'Trips Done',
                value: '${_wallet?['total_trips'] ?? 0}',
                icon: Icons.directions_car,
                color: AppTheme.primary,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Commission',
                value: '${(_wallet?['commission'] as num?)?.toStringAsFixed(0) ?? 0} RWF',
                icon: Icons.percent,
                color: Colors.orange,
              )),
            ]),

            // ── Completed trips history ──────────────────
            if (completedTrips.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Trip History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...completedTrips.map((trip) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                        const SizedBox(width: 8),
                        Text('Trip #${trip.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (trip.fare != null)
                          Text('${trip.fare!.toStringAsFixed(0)} RWF',
                              style: const TextStyle(fontWeight: FontWeight.bold,
                                  color: AppTheme.success)),
                      ]),
                      const SizedBox(height: 6),
                      Text('${trip.pickupLocation} → ${trip.destination}',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      if (trip.startTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          trip.endTime != null
                              ? '${trip.startTime} — ${trip.endTime} (${trip.duration})'
                              : 'Started: ${trip.startTime}',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final invoice = await ApiService.getInvoice(trip.id);
                            if (!context.mounted) return;
                            Navigator.pushNamed(context, '/driver/receipt',
                                arguments: {'invoice': invoice});
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to load receipt'),
                                  backgroundColor: AppTheme.danger),
                            );
                          }
                        },
                        icon: const Icon(Icons.receipt, size: 16),
                        label: const Text('View Receipt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}