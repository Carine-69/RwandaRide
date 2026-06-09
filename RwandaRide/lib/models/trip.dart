class Trip {
  final int id;
  final int riderId;
  final int? driverId;
  final String pickupLocation;
  final String destination;
  final double? fare;
  final String status;
  final String createdAt;
  final String? startedAt;
  final String? completedAt;

  Trip({
    required this.id,
    required this.riderId,
    this.driverId,
    required this.pickupLocation,
    required this.destination,
    this.fare,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      riderId: json['rider_id'],
      driverId: json['driver_id'],
      pickupLocation: json['pickup_location'],
      destination: json['destination'],
      fare: json['fare'] != null ? (json['fare'] as num).toDouble() : null,
      status: json['status'],
      createdAt: json['created_at'],
      startedAt: json['started_at'],
      completedAt: json['completed_at'],
    );
  }

  String get statusLabel {
    switch (status) {
      case 'requested': return 'Searching for driver';
      case 'accepted': return 'Driver on the way';
      case 'driver_arrived': return 'Driver has arrived!';
      case 'ongoing': return 'Journey in progress';
      case 'completed': return 'Completed';
      case 'paid': return 'Paid ✓';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  String? get duration {
    if (startedAt == null || completedAt == null) return null;
    final start = DateTime.parse(startedAt!);
    final end = DateTime.parse(completedAt!);
    final diff = end.difference(start);
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes.remainder(60)}min';
    return '${diff.inMinutes}min';
  }

  String? get startTime {
    if (startedAt == null) return null;
    final dt = DateTime.parse(startedAt!);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String? get endTime {
    if (completedAt == null) return null;
    final dt = DateTime.parse(completedAt!);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool get canCancel => status == 'requested' || status == 'accepted';
  bool get isCompleted => status == 'completed' || status == 'paid';
  bool get isOngoing => status == 'ongoing';
  bool get isDriverArrived => status == 'driver_arrived';
  bool get isActive => status == 'requested' || status == 'accepted' || 
      status == 'driver_arrived' || status == 'ongoing';
  bool get isPaid => status == 'paid';
}