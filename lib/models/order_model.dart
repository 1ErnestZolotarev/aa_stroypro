class ServiceOrder {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhone;
  final String title;
  final String description;
  final int budget;
  final String city;
  final String type; // 'offer' или 'request'
  final List<String> keywords;
  final DateTime createdAt;
  final String status; // active, in_work, completed

  ServiceOrder({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhone,
    required this.title,
    required this.description,
    required this.budget,
    required this.city,
    required this.type,
    required this.keywords,
    required this.createdAt,
    this.status = "active",
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorPhone': authorPhone,
        'title': title,
        'description': description,
        'budget': budget,
        'city': city,
        'type': type,
        'keywords': keywords,
        'createdAt': createdAt.toIso8601String(),
    'status': status,
      };

  factory ServiceOrder.fromMap(String id, Map<String, dynamic> map) =>
      ServiceOrder(
        id: id,
        authorId: map['authorId'] ?? '',
        authorName: map['authorName'] ?? '',
        authorPhone: map['authorPhone'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        budget: (map['budget'] ?? 0).toInt(),
        city: map['city'] ?? '',
        type: map['type'] ?? 'request',
        keywords: List<String>.from(map['keywords'] ?? []),
        createdAt: DateTime.parse(map['createdAt']),
      );
}
