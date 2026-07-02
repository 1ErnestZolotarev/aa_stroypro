class Chat {
  final String id;
  final List<String> participants;
  final String? orderId;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  Chat({
    required this.id,
    required this.participants,
    this.orderId,
    this.lastMessage,
    this.lastMessageTime,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'participants': participants,
        'orderId': orderId,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime?.toIso8601String(),
      };

  factory Chat.fromMap(String id, Map<String, dynamic> m) => Chat(
        id: id,
        participants: (m['participants'] as List?)?.map((e) => e.toString()).toList() ?? [],
        orderId: m['orderId'],
        lastMessage: m['lastMessage'],
        lastMessageTime: m['lastMessageTime'] != null ? DateTime.parse(m['lastMessageTime']) : null,
      );
}
