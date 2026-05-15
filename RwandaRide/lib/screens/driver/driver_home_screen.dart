import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../models/trip.dart';
import '../../widgets/custom_button.dart';

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
      if (_online) {
        context.read<TripProvider>().loadAvailableTrips();
      }
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
      appBar: AppBar(
        title: const Text('RwandaRide Driver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/logout', (_) => false),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _StatusTab(
            online: _online,
            toggling: _togglingStatus,
            onToggle: _toggleStatus,
          ),
          const _AvailableTripsTab(),
          const _EarningsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) {
          setState(() => _tabIndex = i);
          if (i == 1 && _online) {
            context.read<TripProvider>().loadAvailableTrips();
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.power_settings_new_outlined), selectedIcon: Icon(Icons.power_settings_new), label: 'Status'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Available'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
        ],
      ),
    );
  }
}

// ─── Status Tab ───────────────────────────────────

class _StatusTab extends StatelessWidget {
  final bool online;
  final bool toggling;
  final VoidCallback onToggle;

  const _StatusTab({required this.online, required this.toggling, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    final activeTrip = provider.activeTrip;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Online/offline status card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: online
                    ? [AppTheme.success, const Color(0xFF27AE60)]
                    : [AppTheme.textMuted, const Color(0xFF95A5A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  online ? Icons.wifi : Icons.wifi_off,
                  size: 56,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  online ? 'You are Online' : 'You are Offline',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  online ? 'Receiving trip requests' : 'Go online to receive trips',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: toggling ? null : onToggle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: online ? AppTheme.success : AppTheme.textMuted,
                    ),
                    child: toggling
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(online ? 'Go Offline' : 'Go Online',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Active trip
          if (activeTrip != null) ...[
            const Text('Current Trip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _ActiveDriverTripCard(trip: activeTrip),
          ],

          if (!online && activeTrip == null) ...[
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

class _ActiveDriverTripCard extends StatelessWidget {
  final Trip trip;
  const _ActiveDriverTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TripProvider>();

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
            PrimaryButton(
              label: 'Complete Trip',
              icon: Icons.check_circle_outline,
              color: AppTheme.success,
              loading: provider.loading,
              onPressed: () async {
                final ok = await provider.completeTrip(trip.id);
                if (!context.mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trip completed!'), backgroundColor: AppTheme.success),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Available Trips Tab ──────────────────────────

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
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Column(children: [
                Icon(Icons.search_off, size: 64, color: AppTheme.textMuted),
                SizedBox(height: 12),
                Text('No trips available', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                SizedBox(height: 4),
                Text('Pull to refresh', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ]),
            ),
          ],
        ),
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
              Expanded(
                child: Text('Trip #${trip.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              if (trip.fare != null)
                Text('${trip.fare!.toStringAsFixed(0)} RWF',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 16)),
            ]),
            const SizedBox(height: 10),
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
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Accept Trip',
              icon: Icons.check,
              loading: provider.loading,
              onPressed: () async {
                final ok = await provider.acceptTrip(trip.id);
                if (!context.mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trip accepted!'), backgroundColor: AppTheme.success),
                  );
                } else {
                  final err = provider.error ?? 'Failed to accept trip';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: AppTheme.danger),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Earnings Tab ─────────────────────────────────

class _EarningsTab extends StatefulWidget {
  const _EarningsTab();

  @override
  State<_EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<_EarningsTab> {
  dynamic _earnings;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final e = await ApiService.getMyEarnings();
      if (mounted) setState(() => _earnings = e);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
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
    if (_earnings == null) return const SizedBox();

    final e = _earnings;
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
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
                children: [
                  const Text('Net Earnings', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    '${e.netEarnings.toStringAsFixed(0)} ${e.currency}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats grid
            Row(children: [
              Expanded(child: _StatCard(label: 'Total Trips', value: '${e.totalTrips}', icon: Icons.directions_car, color: AppTheme.primary)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Gross Earnings', value: '${e.grossEarnings.toStringAsFixed(0)} RWF', icon: Icons.trending_up, color: AppTheme.success)),
            ]),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Icon(Icons.percent, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Platform commission (15%)', style: TextStyle(color: AppTheme.textMuted))),
                  Text('${e.commission.toStringAsFixed(0)} RWF',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ]),
              ),
            ),
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

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

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
