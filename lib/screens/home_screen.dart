import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/city_picker.dart';
import 'order_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedCity;
  String? _searchWord;
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() => context.read<OrderProvider>().fetchOrders(initialLoad: true));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<OrderProvider>().fetchOrders(
            city: _selectedCity,
            searchWord: _searchWord,
            typeFilter: _typeFilter,
          );
    }
  }

  void _applyFilters() {
    context.read<OrderProvider>().fetchOrders(
          city: _selectedCity,
          searchWord: _searchWord,
          typeFilter: _typeFilter,
          initialLoad: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<OrderProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('ААСтройПро'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Поисковая строка
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Поиск по работам...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _searchWord = null;
                          _applyFilters();
                        },
                      )
                    : null,
              ),
              onSubmitted: (val) {
                _searchWord = val.trim().isNotEmpty ? val.trim() : null;
                _applyFilters();
              },
            ),
          ),
          // Переключатель типа объявлений
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('Все')),
                ButtonSegment(value: 'request', label: Text('Заказы')),
                ButtonSegment(value: 'offer', label: Text('Предложения')),
              ],
              selected: {_typeFilter},
              onSelectionChanged: (s) {
                setState(() => _typeFilter = s.first);
                _applyFilters();
              },
            ),
          ),
          // Лента
          Expanded(
            child: orderProv.orders.isEmpty && !orderProv.loading
                ? const Center(child: Text('Нет объявлений'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        orderProv.orders.length + (orderProv.hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == orderProv.orders.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final order = orderProv.orders[i];
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create_order'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => CityPicker(
        selectedCity: _selectedCity,
        onChanged: (city) {
          _selectedCity = city;
          Navigator.pop(context);
          _applyFilters();
        },
      ),
    );
  }
}
