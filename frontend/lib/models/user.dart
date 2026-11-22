class User {
  final int id;
  final String name;
  final String email;
  final String role; // 'admin' atau 'takmir'
  final bool isActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'admin',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_active': isActive ? 1 : 0,
    };
  }

  bool get isTakmir => role == 'takmir';
  bool get isAdmin => role == 'admin';
}
