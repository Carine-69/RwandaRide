import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await ApiService.getMe();
      if (mounted) setState(() { _profile = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Failed to load profile'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(45),
                        ),
                        child: Icon(
                          _profile!['role'] == 'driver' ? Icons.drive_eta : Icons.person,
                          size: 48,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _profile!['name'],
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _profile!['role'].toString().toUpperCase(),
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _InfoCard(
                        title: 'Personal Information',
                        items: [
                          _InfoRow(icon: Icons.phone, label: 'Phone', value: _profile!['phone'] ?? 'N/A'),
                          _InfoRow(icon: Icons.email, label: 'Email', value: _profile!['email'] ?? 'Not provided'),
                          _InfoRow(icon: Icons.calendar_today, label: 'Member since', value: _profile!['created_at']?.toString().substring(0, 10) ?? 'N/A'),
                        ],
                      ),
                      if (_profile!['driver_info'] != null) ...[
                        const SizedBox(height: 16),
                        _InfoCard(
                          title: 'Vehicle Information',
                          items: [
                            _InfoRow(icon: Icons.badge, label: 'License', value: _profile!['driver_info']['license_number']),
                            _InfoRow(icon: Icons.directions_car, label: 'Vehicle Type', value: _profile!['driver_info']['vehicle_type'].toString().toUpperCase()),
                            _InfoRow(icon: Icons.pin, label: 'Plate Number', value: _profile!['driver_info']['vehicle_plate']),
                            _InfoRow(
                              icon: Icons.circle,
                              label: 'Status',
                              value: _profile!['driver_info']['status'].toString().toUpperCase(),
                              valueColor: _profile!['driver_info']['status'] == 'online' ? AppTheme.success : AppTheme.danger,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await auth.logout();
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.danger,
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppTheme.textMuted)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.textDark)),
        ],
      ),
    );
  }
}