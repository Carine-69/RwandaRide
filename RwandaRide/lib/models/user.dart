class User {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String role;
  final String createdAt;

  User({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      role: json['role'],
      createdAt: json['created_at'] ?? '',
    );
  }
}