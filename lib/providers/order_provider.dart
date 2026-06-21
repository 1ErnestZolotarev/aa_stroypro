import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../services/search_service.dart';

class OrderProvider with ChangeNotifier {
  List<ServiceOrder> _allOrders = []; // Все загруженные заказы
  List<ServiceOrder> _filteredOrders = []; // Отфильтрованные
  DocumentSnapshot? _lastDocument;
  bool _loading = false;
  bool _hasMore = true;

  List<ServiceOrder> get orders => _filteredOrders;
  bool get loading => _loading;
  bool get hasMore => _hasMore;

  void resetPagination() {
    _allOrders.clear();
    _filteredOrders.clear();
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

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      query = query.limit(20);

      final snapshot = await query.get();
      List<ServiceOrder> fetchedOrders = snapshot.docs
          .map((doc) => ServiceOrder.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      if (fetchedOrders.isNotEmpty) {
        _allOrders.addAll(fetchedOrders);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == 20;
      } else {
        _hasMore = false;
      }

      // Применяем локальные фильтры
      _applyLocalFilters(city: city, searchWord: searchWord, typeFilter: typeFilter);
    } catch (e) {
      debugPrint('Ошибка загрузки: $e');
    }

    _loading = false;
    notifyListeners();
  }

  void _applyLocalFilters({
    String? city,
    String? searchWord,
    String? typeFilter,
  }) {
    _filteredOrders = _allOrders.where((order) {
      // Фильтр по городу
      if (city != null && city.isNotEmpty && order.city != city) {
        return false;
      }
      // Фильтр по типу
      if (typeFilter != null && typeFilter != 'all' && order.type != typeFilter) {
        return false;
      }
      // Фильтр по поисковому слову
      if (searchWord != null && searchWord.isNotEmpty) {
        if (!SearchService.matchesSearch(
            order.title, order.description, order.keywords, searchWord)) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
