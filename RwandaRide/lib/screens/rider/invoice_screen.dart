import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../models/trip.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  Map<String, dynamic>? _invoice;
  bool _loading = true;
  bool _paying = false;
  bool _paid = false;
  String _paymentMethod = 'cash';
  Trip? _trip;

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
      if (_trip != null) _fetchInvoice();
    }
  }

  Future<void> _fetchInvoice() async {
    try {
      final invoice = await ApiService.getInvoice(_trip!.id);
      if (mounted) setState(() { _invoice = invoice; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmPayment() async {
    if (_invoice == null || _trip == null) return;
    setState(() => _paying = true);
    try {
      final fare = _invoice!['fare'];
      await ApiService.createPayment(
        tripId: _trip!.id,
        amount: fare != null ? (fare as num).toDouble() : 0,
        method: _paymentMethod,
      );
      if (!mounted) return;
      setState(() => _paid = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment confirmed! Waiting for driver to verify...'),
          backgroundColor: AppTheme.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _goToReceipt() {
    Navigator.pushReplacementNamed(context, '/receipt', arguments: {
      'invoice': _invoice,
      'payment_method': _paymentMethod,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _invoice == null
              ? const Center(child: Text('Failed to load invoice'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Invoice header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_long, color: Colors.white, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              _invoice!['invoice_number'],
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _invoice!['date'],
                              style: TextStyle(color: Colors.white.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Trip details
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Trip Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Divider(height: 20),
                              _InvoiceRow(label: 'Rider', value: _invoice!['rider_name'] ?? 'N/A'),
                              if (_invoice!['driver'] != null) ...[
                                _InvoiceRow(label: 'Driver', value: _invoice!['driver']['name']),
                                _InvoiceRow(label: 'Vehicle', value: _invoice!['driver']['vehicle_type'].toString().toUpperCase()),
                                _InvoiceRow(label: 'Plate', value: _invoice!['driver']['vehicle_plate']),
                              ],
                              const Divider(height: 20),
                              _InvoiceRow(label: 'From', value: _invoice!['pickup_location'] ?? 'N/A'),
                              _InvoiceRow(label: 'To', value: _invoice!['destination'] ?? 'N/A'),
                              if (_invoice!['distance_km'] != null)
                                _InvoiceRow(
                                  label: 'Distance',
                                  value: '${(_invoice!['distance_km'] as num).toStringAsFixed(2)} km',
                                ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  const Text('Total Fare', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const Spacer(),
                                  Text(
                                    _invoice!['fare'] != null
                                        ? '${(_invoice!['fare'] as num).toStringAsFixed(0)} RWF'
                                        : 'Negotiate with driver',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: _invoice!['fare'] != null ? 22 : 16,
                                      color: _invoice!['fare'] != null ? AppTheme.primary : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Payment method selection
                      if (!_paid) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 8),
                                ..._paymentMethods.map((m) => RadioListTile<String>(
                                      value: m,
                                      groupValue: _paymentMethod,
                                      onChanged: (v) => setState(() => _paymentMethod = v!),
                                      title: Text(_paymentLabels[m]!),
                                      activeColor: AppTheme.primary,
                                      contentPadding: EdgeInsets.zero,
                                    )),

                                // MTN MoMo instructions
                                if (_paymentMethod == 'mtn_mobile' && _invoice!['driver'] != null) ...[
                                  const Divider(),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.yellow.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.yellow.shade700),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(children: [
                                          Icon(Icons.phone_android, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text('Step 1 — Dial this code on your phone:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ]),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _invoice!['fare'] != null
                                                ? '*182*8*${_invoice!['driver']['phone']}*${(_invoice!['fare'] as num).toStringAsFixed(0)}#'
                                                : '*182*8*${_invoice!['driver']['phone']}*AMOUNT#',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Driver MTN number: ${_invoice!['driver']['phone']}',
                                            style: const TextStyle(color: AppTheme.textMuted)),
                                        const SizedBox(height: 8),
                                        const Row(children: [
                                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                                          SizedBox(width: 6),
                                          Text('Step 2 — Enter your PIN to confirm', style: TextStyle(fontWeight: FontWeight.w600)),
                                        ]),
                                        const SizedBox(height: 4),
                                        const Row(children: [
                                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                                          SizedBox(width: 6),
                                          Text('Step 3 — Tap "I Have Paid" below', style: TextStyle(fontWeight: FontWeight.w600)),
                                        ]),
                                      ],
                                    ),
                                  ),
                                ],

                                // Airtel Money instructions
                                if (_paymentMethod == 'airtel_money' && _invoice!['driver'] != null) ...[
                                  const Divider(),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red.shade300),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(children: [
                                          Icon(Icons.phone_android, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Step 1 — Dial this code on your phone:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ]),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _invoice!['fare'] != null
                                                ? '*182*1*${_invoice!['driver']['phone']}*${(_invoice!['fare'] as num).toStringAsFixed(0)}#'
                                                : '*182*1*${_invoice!['driver']['phone']}*AMOUNT#',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.danger),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Driver Airtel number: ${_invoice!['driver']['phone']}',
                                            style: const TextStyle(color: AppTheme.textMuted)),
                                        const SizedBox(height: 8),
                                        const Row(children: [
                                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                                          SizedBox(width: 6),
                                          Text('Step 2 — Enter your PIN to confirm', style: TextStyle(fontWeight: FontWeight.w600)),
                                        ]),
                                        const SizedBox(height: 4),
                                        const Row(children: [
                                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                                          SizedBox(width: 6),
                                          Text('Step 3 — Tap "I Have Paid" below', style: TextStyle(fontWeight: FontWeight.w600)),
                                        ]),
                                      ],
                                    ),
                                  ),
                                ],

                                // Cash instructions
                                if (_paymentMethod == 'cash') ...[
                                  const Divider(),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green.shade300),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(children: [
                                          Icon(Icons.payments, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Cash Payment Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ]),
                                        const SizedBox(height: 8),
                                        Text(
                                          _invoice!['fare'] != null
                                              ? 'Hand ${(_invoice!['fare'] as num).toStringAsFixed(0)} RWF cash directly to your driver'
                                              : 'Hand the agreed amount in cash to your driver',
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text('Then tap "I Have Paid" below',
                                            style: TextStyle(color: AppTheme.textMuted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        PrimaryButton(
                          label: _paymentMethod == 'cash'
                              ? 'I Have Paid — Cash'
                              : 'I Have Paid — ${_paymentLabels[_paymentMethod]}',
                          icon: Icons.check_circle,
                          color: AppTheme.success,
                          loading: _paying,
                          onPressed: _confirmPayment,
                        ),
                      ],

                      // After paying — waiting for driver confirmation
                      if (_paid) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.success),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.hourglass_top, color: AppTheme.success, size: 40),
                              SizedBox(height: 8),
                              Text(
                                'Payment Submitted!',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.success),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Waiting for driver to confirm payment received...',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _goToReceipt,
                          icon: const Icon(Icons.receipt),
                          label: const Text('View Receipt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            minimumSize: const Size(double.infinity, 52),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final String label;
  final String value;
  const _InvoiceRow({required this.label, required this.value});

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