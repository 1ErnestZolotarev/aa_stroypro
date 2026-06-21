import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  List<ServiceOrder> _orders = [];
  DocumentSnapshot? _lastDocument;
  bool _loading = false;
  bool _hasMore = true;

  List<ServiceOrder> get orders => _orders;
  bool get loading => _loading;
  bool get hasMore => _hasMore;

  void resetPagination() {
    _orders.clear();
    _lastDocument = null;
    _hasMore = true;
  }

  Future<void> fetchOrders({
    String? city,
    String? searchWord,
    String? typeFilter,
    bool initialLoad = false,
  }) async {
    if (_loading) return;
    if (!_hasMore && !initialLoad) return;

    _loading = true;
    if (initialLoad) resetPagination();
    notifyListeners();

    try {
      Query query = FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true);

      // Применяем фильтры по одному, чтобы избежать проблем с индексами
      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }
      if (typeFilter != null && typeFilter != 'all') {
        query = query.where('type', isEqualTo: typeFilter);
      }
      
      // Поиск по ключевым словам делаем на клиенте (для простоты)
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      query = query.limit(20);

      final snapshot = await query.get();
      List<ServiceOrder> fetchedOrders = snapshot.docs
          .map((doc) => ServiceOrder.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      // Фильтрация по searchWord на клиенте
      if (searchWord != null && searchWord.isNotEmpty) {
        final searchLower = searchWord.toLowerCase();
        fetchedOrders = fetchedOrders.where((order) {
          return order.title.toLowerCase().contains(searchLower) ||
                 order.description.toLowerCase().contains(searchLower) ||
                 order.keywords.any((kw) => kw.toLowerCase().contains(searchLower));
        }).toList();
      }

      if (fetchedOrders.isNotEmpty) {
        _orders.addAll(fetchedOrders);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == 20;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Ошибка загрузки: $e');
    }

    _loading = false;
    notifyListeners();
  }
}
