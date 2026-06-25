class AppUser {
  final String phone;
  final String name;
  final String city;
  final String role;
  final String? uid;        // <-- новое поле
  final DateTime createdAt;

  AppUser({
    required this.phone,
    required this.name,
    required this.city,
    required this.role,
    this.uid,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'name': name,
        'city': city,
        'role': role,
        'uid': uid ?? '',
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        phone: m['phone'] ?? '',
        name: m['name'] ?? '',
        city: m['city'] ?? '',
        role: m['role'] ?? 'customer',
        uid: m['uid'],
        createdAt: m['createdAt'] != null
            ? DateTime.parse(m['createdAt'])
            : DateTime.now(),
      );
}
