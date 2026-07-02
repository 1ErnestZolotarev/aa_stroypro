class ServiceOrder {
  final String id;
  final String authorId;        // номер телефона (старое поле, оставлено для совместимости)
  final String? authorUid;      // uid автора (новое поле)
  final String authorName;
  final String authorPhone;
  final String title;
  final String description;
  final int budget;
  final String city;
  final String? address;
  final String type;
  final List<String> keywords;
  final DateTime createdAt;

  ServiceOrder({
    required this.id,
    required this.authorId,
    this.authorUid,
    required this.authorName,
    required this.authorPhone,
    required this.title,
    required this.description,
    required this.budget,
    required this.city,
    this.address,
    required this.type,
    required this.keywords,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'authorId': authorId,
        'authorUid': authorUid ?? '',
        'authorName': authorName,
        'authorPhone': authorPhone,
        'title': title,
        'description': description,
        'budget': budget,
        'city': city,
        'address': address ?? '',
        'type': type,
        'keywords': keywords,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ServiceOrder.fromMap(String id, Map<String, dynamic> m) => ServiceOrder(
        id: id,
        authorId: m['authorId'] ?? '',
        authorUid: m['authorUid'],
        authorName: m['authorName'] ?? '',
        authorPhone: m['authorPhone'] ?? '',
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        budget: (m['budget'] ?? 0).toInt(),
        city: m['city'] ?? '',
        address: m['address'],
        type: m['type'] ?? 'request',
        // Исправление: явное приведение к List<String> и fallback на пустой список
        keywords: (m['keywords'] as List?)?.map((e) => e.toString()).toList() ?? [],
        createdAt: m['createdAt'] != null ? DateTime.parse(m['createdAt']) : DateTime.now(),
      );
}
