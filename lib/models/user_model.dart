class AppUser {
  final String phone;
  final String name;
  final String city;
  final String role;
  final String? uid;
  final bool isAdmin;
  final DateTime? bannedUntil;   // <-- новое поле
  final DateTime createdAt;

  AppUser({
    required this.phone,
    required this.name,
    required this.city,
    required this.role,
    this.uid,
    this.isAdmin = false,
    this.bannedUntil,
    required this.createdAt,
  });

  bool get isBanned {
    if (bannedUntil == null) return false;
    return DateTime.now().isBefore(bannedUntil!);
  }

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'name': name,
        'city': city,
        'role': role,
        'uid': uid ?? '',
        'isAdmin': isAdmin,
        'bannedUntil': bannedUntil?.toIso8601String() ?? '',
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        phone: m['phone'] ?? '',
        name: m['name'] ?? '',
        city: m['city'] ?? '',
        role: m['role'] ?? 'customer',
        uid: m['uid'],
        isAdmin: m['isAdmin'] ?? false,
        bannedUntil: m['bannedUntil'] != null && m['bannedUntil'].toString().isNotEmpty
            ? DateTime.parse(m['bannedUntil'])
            : null,
        createdAt: m['createdAt'] != null
            ? DateTime.parse(m['createdAt'])
            : DateTime.now(),
      );
}
