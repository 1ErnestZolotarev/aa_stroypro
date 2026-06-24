class AppUser {
  final String uid, name, phone, city, role;
  final String? avatarUrl;
  final bool isPro;
  final int ordersLimit;
  final bool isBanned;
  final String? bannedReason;
  final DateTime createdAt;
  final double rating;
  final int totalRatings;
  final int quickResponses;
  final int completedOrders;
  final int thanks;
  final int noShows;
  final int complaints;
  final List<String> favorites; // ID избранных заказов
  final DateTime? lastSeen; // Когда был онлайн

  AppUser({
    required this.uid, required this.name, required this.phone,
    required this.city, required this.role, this.avatarUrl,
    this.isPro=false, this.ordersLimit=10, this.isBanned=false,
    this.bannedReason, required this.createdAt,
    this.rating = 0, this.totalRatings = 0,
    this.quickResponses = 0, this.completedOrders = 0,
    this.thanks = 0, this.noShows = 0, this.complaints = 0,
    this.favorites = const [],
    this.lastSeen,
  });

  bool get isOnline => lastSeen != null && DateTime.now().difference(lastSeen!).inMinutes < 5;

  Map<String, dynamic> toMap() => {
    'uid': uid, 'name': name, 'phone': phone, 'city': city,
    'role': role, 'avatarUrl': avatarUrl ?? '', 'isPro': isPro,
    'ordersLimit': ordersLimit, 'isBanned': isBanned,
    'bannedReason': bannedReason ?? '', 'createdAt': createdAt.toIso8601String(),
    'rating': rating, 'totalRatings': totalRatings,
    'quickResponses': quickResponses, 'completedOrders': completedOrders,
    'thanks': thanks, 'noShows': noShows, 'complaints': complaints,
    'favorites': favorites,
    'lastSeen': lastSeen?.toIso8601String() ?? '',
  };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
    uid: m['uid'] ?? '', name: m['name'] ?? '', phone: m['phone'] ?? '',
    city: m['city'] ?? '', role: m['role'] ?? 'customer',
    avatarUrl: m['avatarUrl'] is String ? m['avatarUrl'] : null,
    isPro: m['isPro'] ?? false, ordersLimit: m['ordersLimit'] ?? 10,
    isBanned: m['isBanned'] ?? false, bannedReason: m['bannedReason'],
    createdAt: m['createdAt'] != null ? DateTime.parse(m['createdAt']) : DateTime.now(),
    rating: (m['rating'] ?? 0).toDouble(), totalRatings: m['totalRatings'] ?? 0,
    quickResponses: m['quickResponses'] ?? 0, completedOrders: m['completedOrders'] ?? 0,
    thanks: m['thanks'] ?? 0, noShows: m['noShows'] ?? 0, complaints: m['complaints'] ?? 0,
    favorites: List<String>.from(m[favorites] ?? []),
    lastSeen: m['lastSeen'] != null && m['lastSeen'].toString().isNotEmpty ? DateTime.parse(m['lastSeen']) : null,
  );
}
