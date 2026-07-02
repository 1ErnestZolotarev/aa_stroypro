import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart' as OurAuth;
import '../widgets/order_card.dart';
import '../widgets/city_filter.dart';
import 'order_detail_screen.dart';
import 'create_order_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedCities = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  List<ServiceOrder> _orders = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _updateLastSeen();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMore();
      }
    });
  }

  Future<void> _updateLastSeen() async {
    final auth = context.read<OurAuth.AuthProvider>();
    await auth.updateLastSeen();
  }

  Future<void> _loadOrders({bool reset = true}) async {
    if (reset) {
      setState(() {
        _orders = [];
        _lastDocument = null;
        _hasMore = true;
        _isLoading = true;
      });
    }
    final provider = context.read<OrderProvider>();
    final stream = provider.getOrdersStream(
      cities: _selectedCities.isEmpty ? null : _selectedCities,
      searchWord: _searchController.text.isNotEmpty ? _searchController.text : null,
      startAfter: reset ? null : _lastDocument,
    );
    final list = await stream.first;
    setState(() {
      if (reset) {
        _orders = list;
      } else {
        _orders.addAll(list);
      }
      _lastDocument = list.isNotEmpty ? list.last.id : null;
      _hasMore = list.length >= 20;
      _isLoading = false;
    });
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;
    await _loadOrders(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Поиск...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _loadOrders(reset: true),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _loadOrders(reset: true),
                ),
              ],
            ),
          ),
          CityFilter(
            selectedCities: _selectedCities,
            onChanged: (cities) {
              setState(() {
                _selectedCities = cities;
              });
              _loadOrders(reset: true);
            },
          ),
          Expanded(
            child: _isLoading && _orders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? const Center(child: Text('Нет заказов'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _orders.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _orders.length) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final order = _orders[index];
                          return OrderCard(
                            order: order,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(order: order),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
