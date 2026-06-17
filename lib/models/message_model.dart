class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Message.fromMap(String id, Map<String, dynamic> map) => Message(
        id: id,
        senderId: map['senderId'],
        text: map['text'],
        timestamp: DateTime.parse(map['timestamp']),
      );
}
