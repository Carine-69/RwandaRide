import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final invoice = args['invoice'] as Map<String, dynamic>;
    final paymentMethod = args['payment_method'] as String;
    final fare = invoice['fare'] != null ? (invoice['fare'] as num).toDouble() : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.success,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 56),
                  SizedBox(height: 12),
                  Text(
                    'Payment Successful!',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Thank you for riding with RwandaRide',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: 20),
                    _ReceiptRow(label: 'Receipt No.', value: invoice['invoice_number'] ?? 'N/A'),
                    _ReceiptRow(label: 'Date', value: invoice['date'] ?? 'N/A'),
                    _ReceiptRow(label: 'Rider', value: invoice['rider_name'] ?? 'N/A'),
                    if (invoice['driver'] != null) ...[
                      _ReceiptRow(label: 'Driver', value: invoice['driver']['name']),
                      _ReceiptRow(label: 'Vehicle', value: invoice['driver']['vehicle_type'].toString().toUpperCase()),
                      _ReceiptRow(label: 'Plate', value: invoice['driver']['vehicle_plate']),
                    ],
                    const Divider(height: 20),
                    _ReceiptRow(label: 'From', value: invoice['pickup_location'] ?? 'N/A'),
                    _ReceiptRow(label: 'To', value: invoice['destination'] ?? 'N/A'),
                    if (invoice['distance_km'] != null)
                      _ReceiptRow(label: 'Distance', value: '${(invoice['distance_km'] as num).toStringAsFixed(2)} km'),
                    const Divider(height: 20),
                    _ReceiptRow(
                      label: 'Payment',
                      value: paymentMethod == 'cash'
                          ? 'Cash'
                          : paymentMethod == 'mtn_mobile'
                              ? 'MTN Mobile Money'
                              : 'Airtel Money',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        Text(
                          fare > 0
                              ? '${fare.toStringAsFixed(0)} RWF'
                              : 'Cash — negotiated',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.success),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/rider/home', (_) => false),
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}