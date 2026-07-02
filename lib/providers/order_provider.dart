import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  List<ServiceOrder> _orders = [];
  bool _isLoading = false;

  List<ServiceOrder> get orders => _orders;
  bool get isLoading => _isLoading;

  Stream<List<ServiceOrder>> getOrdersStream({
    List<String>? cities,
    String? searchWord,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) {
    return _firestore.getOrdersStream(
      cities: cities,
      searchWord: searchWord,
      startAfter: startAfter,
      limit: limit,
    );
  }

  Future<void> addOrder(ServiceOrder order) async {
    await _firestore.addOrder(order);
    notifyListeners();
  }

  Future<void> updateOrder(ServiceOrder order) async {
    await _firestore.updateOrder(order);
    notifyListeners();
  }

  Future<void> deleteOrder(String orderId) async {
    await _firestore.deleteOrder(orderId);
    notifyListeners();
  }
}
