class User {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String role;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    required this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String,
      createdAt: json['created_at'] as String?,
    );
  }

  bool get isDriver => role == 'driver';
  bool get isRider => role == 'rider';
}