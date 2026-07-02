class Message {
  final String id;
  final String senderId;
  final String senderName;   // новое поле
  final String text;
  final DateTime timestamp;
  final bool edited;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.edited = false,
  });

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'edited': edited,
      };

  factory Message.fromMap(String id, Map<String, dynamic> m) => Message(
        id: id,
        senderId: m['senderId'] ?? '',
        senderName: m['senderName'] ?? m['senderId'] ?? 'Пользователь',
        text: m['text'] ?? '',
        timestamp: m['timestamp'] != null
            ? DateTime.parse(m['timestamp'])
            : DateTime.now(),
        edited: m['edited'] ?? false,
      );
}
