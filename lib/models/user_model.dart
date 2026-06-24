class AppUser {
  final String phone; // ключ документа = номер телефона
  final String name;
  final String city;
  final String role;
  final DateTime createdAt;

  AppUser({
    required this.phone,
    required this.name,
    required this.city,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'name': name,
        'city': city,
        'role': role,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        phone: m['phone'] ?? '',
        name: m['name'] ?? '',
        city: m['city'] ?? '',
        role: m['role'] ?? 'customer',
        createdAt:
            m['createdAt'] != null ? DateTime.parse(m['createdAt']) : DateTime.now(),
      );
}
