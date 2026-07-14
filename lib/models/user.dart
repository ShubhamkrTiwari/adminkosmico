class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool isAdmin;
  final String accountStatus;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.isAdmin,
    required this.accountStatus,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      phone: json['phoneNumber'], // Updated to match your API
      isAdmin: json['isAdmin'] ?? false,
      accountStatus: json['isBlocked'] == true ? 'blocked' : 'active', // Map isBlocked to accountStatus
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'isAdmin': isAdmin,
      'accountStatus': accountStatus,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
