class Trip {
  final int id;
  final int riderId;
  final int? driverId;
  final String pickupLocation;
  final String destination;
  final double? fare;
  final String status;
  final String createdAt;

  Trip({
    required this.id,
    required this.riderId,
    this.driverId,
    required this.pickupLocation,
    required this.destination,
    this.fare,
    required this.status,
    required this.createdAt,
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
    );
  }

  String get statusLabel {
    switch (status) {
      case 'requested':
        return 'Searching for driver';
      case 'accepted':
        return 'Driver on the way';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get canCancel => status == 'requested' || status == 'accepted';
  bool get isCompleted => status == 'completed';
  bool get isActive => status == 'requested' || status == 'accepted';
}
