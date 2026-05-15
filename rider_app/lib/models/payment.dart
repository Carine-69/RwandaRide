class Payment {
  final int id;
  final int tripId;
  final double amount;
  final String method;
  final String status;
  final String createdAt;

  Payment({
    required this.id,
    required this.tripId,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      tripId: json['trip_id'],
      amount: (json['amount'] as num).toDouble(),
      method: json['method'],
      status: json['status'],
      createdAt: json['created_at'],
    );
  }
}

class DriverEarnings {
  final int totalTrips;
  final double grossEarnings;
  final double commission;
  final double netEarnings;
  final String currency;

  DriverEarnings({
    required this.totalTrips,
    required this.grossEarnings,
    required this.commission,
    required this.netEarnings,
    required this.currency,
  });

  factory DriverEarnings.fromJson(Map<String, dynamic> json) {
    return DriverEarnings(
      totalTrips: json['total_trips'],
      grossEarnings: (json['gross_earnings'] as num).toDouble(),
      commission: (json['commission_15_percent'] as num).toDouble(),
      netEarnings: (json['net_earnings'] as num).toDouble(),
      currency: json['currency'],
    );
  }
}
