import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Orders ---
  Stream<List<ServiceOrder>> getOrdersStream({
    List<String>? cities,
    String? searchWord,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) {
    Query query = _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true);

    if (cities != null && cities.isNotEmpty) {
      query = query.where('city', whereIn: cities);
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

  Future<Chat?> getChat(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    if (!doc.exists) return null;
    return Chat.fromMap(doc.id, doc.data() as Map<String, dynamic>);
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
    await chatRef.set({...chat.toMap(), 'createdAt': DateTime.now().toIso8601String()});
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

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
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

  Future<void> markAsRead(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'lastReadBy.$userId': DateTime.now().toIso8601String(),
    });
  }
}
