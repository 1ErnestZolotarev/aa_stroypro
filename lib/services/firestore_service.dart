import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Orders ---
  Stream<List<ServiceOrder>> getOrdersStream({
    String? city,
    String? searchWord,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) {
    Query query = _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true);

    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }
    if (searchWord != null && searchWord.isNotEmpty) {
      query = query.where('keywords', arrayContains: searchWord.toLowerCase());
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    query = query.limit(limit);

    return query.snapshots().map((snap) =>
        snap.docs.map((doc) => ServiceOrder.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList());
  }

  Future<void> addOrder(ServiceOrder order) async {
    await _firestore.collection('orders').doc(order.id).set(order.toMap());
  }

  Future<void> updateOrder(ServiceOrder order) async {
    await _firestore.collection('orders').doc(order.id).update(order.toMap());
  }

  Future<void> deleteOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).delete();
  }

  // --- Chats ---
  Stream<List<Chat>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Chat.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList());
  }

  Future<String> createOrGetChat(String userId1, String userId2,
      {String? orderId}) async {
    final existing = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId1)
        .get();
    for (var doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participants']);
      if (participants.contains(userId2)) return doc.id;
    }
    final chatRef = _firestore.collection('chats').doc();
    final chat = Chat(
      id: chatRef.id,
      participants: [userId1, userId2],
      orderId: orderId,
    );
    await chatRef.set(chat.toMap());
    return chatRef.id;
  }

  Future<void> sendMessage(String chatId, Message message) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message.text,
      'lastMessageTime': message.timestamp.toIso8601String(),
    });
  }

  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Message.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList());
  }
}
