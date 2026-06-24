import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../services/search_service.dart';

class OrderProvider with ChangeNotifier {
  List<ServiceOrder> _allOrders = [];
  List<ServiceOrder> _filteredOrders = [];
  DocumentSnapshot? _lastDocument;
  bool _loading = false;
  bool _hasMore = true;

  List<ServiceOrder> get orders => _filteredOrders;
  bool get loading => _loading;
  bool get hasMore => _hasMore;

  void resetPagination() { _allOrders.clear(); _filteredOrders.clear(); _lastDocument = null; _hasMore = true; }

  Future<void> fetchOrders({String? city, String? searchWord, String? typeFilter, bool initialLoad = false}) async {
    if (_loading) return; if (!_hasMore && !initialLoad) return;
    _loading = true; if (initialLoad) resetPagination(); notifyListeners();
    try {
      Query query = FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true);

      // Пробуем фильтровать на сервере
      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }
      if (typeFilter != null && typeFilter != 'all') {
        query = query.where('type', isEqualTo: typeFilter);
      }

      if (_lastDocument != null) query = query.startAfterDocument(_lastDocument!);
      query = query.limit(50);
      final snapshot = await query.get();
      List<ServiceOrder> fetched = snapshot.docs.map((d) => ServiceOrder.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();
      if (fetched.isNotEmpty) { _allOrders.addAll(fetched); _lastDocument = snapshot.docs.last; _hasMore = snapshot.docs.length == 50; } else { _hasMore = false; }
      _applyLocalFilters(city: city, searchWord: searchWord, typeFilter: typeFilter);
    } catch (e) {
      debugPrint('Server filter error, using local filter: $e');
      // Загружаем без серверных фильтров
      try {
        Query query = FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true);
        if (_lastDocument != null) query = query.startAfterDocument(_lastDocument!);
        query = query.limit(50);
        final snapshot = await query.get();
        List<ServiceOrder> fetched = snapshot.docs.map((d) => ServiceOrder.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();
        if (fetched.isNotEmpty) { _allOrders.addAll(fetched); _lastDocument = snapshot.docs.last; _hasMore = snapshot.docs.length == 50; } else { _hasMore = false; }
        _applyLocalFilters(city: city, searchWord: searchWord, typeFilter: typeFilter);
      } catch (e2) { debugPrint('Fallback error: $e2'); }
    }
    _loading = false; notifyListeners();
  }

  void _applyLocalFilters({String? city, String? searchWord, String? typeFilter}) {
    _filteredOrders = _allOrders.where((o) {
      if (city != null && city.isNotEmpty && o.city != city) return false;
      if (typeFilter != null && typeFilter != 'all' && o.type != typeFilter) return false;
      if (searchWord != null && searchWord.isNotEmpty && !SearchService.matchesSearch(o.title, o.description, o.keywords, o.city, searchWord)) return false;
      return true;
    }).toList();
  }
}
