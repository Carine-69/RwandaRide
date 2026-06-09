import 'package:flutter/material.dart';
import '../../config/theme.dart';

class DriverReceiptScreen extends StatelessWidget {
  const DriverReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final invoice = args['invoice'] as Map<String, dynamic>;
    final fare = invoice['fare'] != null ? (invoice['fare'] as num).toDouble() : 0.0;
    final commission = fare * 0.15;
    final netEarnings = fare - commission;

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Receipt')),
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
                    'Payment Received!',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Trip completed successfully',
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
                    const Text('Trip Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: 20),
                    _ReceiptRow(label: 'Receipt No.', value: invoice['invoice_number'] ?? 'N/A'),
                    _ReceiptRow(label: 'Date', value: invoice['date'] ?? 'N/A'),
                    _ReceiptRow(label: 'Rider', value: invoice['rider_name'] ?? 'N/A'),
                    const Divider(height: 20),
                    _ReceiptRow(label: 'From', value: invoice['pickup_location'] ?? 'N/A'),
                    _ReceiptRow(label: 'To', value: invoice['destination'] ?? 'N/A'),
                    if (invoice['distance_km'] != null)
                      _ReceiptRow(label: 'Distance', value: '${(invoice['distance_km'] as num).toStringAsFixed(2)} km'),
                    const Divider(height: 20),
                    if (fare > 0) ...[
                      _ReceiptRow(label: 'Gross Fare', value: '${fare.toStringAsFixed(0)} RWF'),
                      _ReceiptRow(label: 'Commission (15%)', value: '- ${commission.toStringAsFixed(0)} RWF'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Your Earnings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          Text(
                            '${netEarnings.toStringAsFixed(0)} RWF',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.success),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(child: Text(
                            'Fare was negotiated directly — no calculated amount.',
                            style: TextStyle(color: Colors.orange),
                          )),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/driver/home', (_) => false),
              icon: const Icon(Icons.home),
              label: const Text('Back to Dashboard'),
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
            width: 100,
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