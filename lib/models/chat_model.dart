class Chat {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? orderId;

  Chat({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.orderId,
  });

  Map<String, dynamic> toMap() => {
        'participants': participants,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime?.toIso8601String(),
        'orderId': orderId,
      };

  factory Chat.fromMap(String id, Map<String, dynamic> map) => Chat(
        id: id,
        participants: List<String>.from(map['participants']),
        lastMessage: map['lastMessage'],
        lastMessageTime: map['lastMessageTime'] != null
            ? DateTime.parse(map['lastMessageTime'])
            : null,
        orderId: map['orderId'],
      );
}
