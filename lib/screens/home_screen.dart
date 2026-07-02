import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  List<ServiceOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _updateLastSeen();
  }

  Future<void> _updateLastSeen() async {
    final auth = context.read<OurAuth.AuthProvider>();
    await auth.updateLastSeen();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final provider = context.read<OrderProvider>();
    final stream = provider.getOrdersStream(
      cities: _selectedCities.isEmpty ? null : _selectedCities,
      searchWord: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
    final list = await stream.first;
    setState(() {
      _orders = list;
      _isLoading = false;
    });
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
                    onSubmitted: (_) => _loadOrders(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _loadOrders(),
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
              _loadOrders();
            },
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? const Center(child: Text('Нет заказов'))
                    : ListView.builder(
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
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
