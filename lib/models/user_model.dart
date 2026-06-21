class AppUser {
  final String uid;
  final String name;
  final String phone;
  final String city;
  final String role;
  final String? avatarUrl;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.phone,
    required this.city,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'phone': phone,
        'city': city,
        'role': role,
        'avatarUrl': avatarUrl ?? '',
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        uid: map['uid'] ?? '',
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
        city: map['city'] ?? '',
        role: map['role'] ?? 'customer',
        avatarUrl: map['avatarUrl'] is String ? map['avatarUrl'] : null,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
      );
}
