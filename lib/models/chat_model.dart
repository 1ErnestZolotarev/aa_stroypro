class Chat {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? orderId;
  final bool quickResponseGiven; // Был ли начислен +1 за быстрый ответ
  final bool orderCompleted;     // Подтверждено ли выполнение
  final DateTime? createdAt;

  Chat({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.orderId,
    this.quickResponseGiven = false,
    this.orderCompleted = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'participants': participants,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime?.toIso8601String(),
    'orderId': orderId,
    'quickResponseGiven': quickResponseGiven,
    'orderCompleted': orderCompleted,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Chat.fromMap(String id, Map<String, dynamic> m) => Chat(
    id: id,
    participants: List<String>.from(m['participants'] ?? []),
    lastMessage: m['lastMessage'],
    lastMessageTime: m['lastMessageTime'] != null ? DateTime.parse(m['lastMessageTime']) : null,
    orderId: m['orderId'],
    quickResponseGiven: m['quickResponseGiven'] ?? false,
    orderCompleted: m['orderCompleted'] ?? false,
    createdAt: m['createdAt'] != null ? DateTime.parse(m['createdAt']) : null,
  );
}
