class ServiceOrder {
  final String id, authorId, authorName, authorPhone, title, description, city, type;
  final String? address;
  final int budget;
  final List<String> keywords;
  final DateTime createdAt;

  ServiceOrder({
    required this.id, required this.authorId, required this.authorName,
    required this.authorPhone, required this.title, required this.description,
    required this.budget, required this.city, this.address,
    required this.type, required this.keywords, required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'authorId': authorId, 'authorName': authorName,
    'authorPhone': authorPhone, 'title': title, 'description': description,
    'budget': budget, 'city': city, 'address': address ?? '',
    'type': type, 'keywords': keywords, 'createdAt': createdAt.toIso8601String(),
  };

  factory ServiceOrder.fromMap(String id, Map<String, dynamic> m) => ServiceOrder(
    id: id, authorId: m['authorId'] ?? '', authorName: m['authorName'] ?? '',
    authorPhone: m['authorPhone'] ?? '', title: m['title'] ?? '',
    description: m['description'] ?? '', budget: (m['budget'] ?? 0).toInt(),
    city: m['city'] ?? '', address: m['address'],
    type: m['type'] ?? 'request',
    keywords: List<String>.from(m['keywords'] ?? []),
    createdAt: DateTime.parse(m['createdAt']),
  );
}
