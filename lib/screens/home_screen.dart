import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../services/search_service.dart';
import '../services/geolocation_service.dart';
import '../widgets/order_card.dart';
import '../widgets/city_picker.dart';
import 'order_detail_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final GeolocationService _geoService = GeolocationService();
  
  String? _selectedCity;
  String? _myCity; // Город по геолокации
  String? _searchWord;
  String _typeFilter = 'all';
  int _unreadChats = 0;
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isLoadingCity = false;
  bool _isNearby = false; // Включён ли фильтр «Рядом»

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChanged);
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) setState(() => _showSuggestions = false);
    });
    Future.microtask(() {
      _detectCity();
      context.read<OrderProvider>().fetchOrders(initialLoad: true);
      _listenToChats();
    });
  }

  Future<void> _detectCity() async {
    setState(() => _isLoadingCity = true);
    final city = await _geoService.getCurrentCity();
    if (city != null && mounted) {
      setState(() {
        _myCity = city;
        _selectedCity = city;
        _isNearby = true;
      });
      _applyFilters();
    }
    setState(() => _isLoadingCity = false);
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text;
    setState(() {
      _suggestions = SearchService.getSuggestions(query);
      _showSuggestions = query.isNotEmpty && _suggestions.isNotEmpty;
    });
  }

  void _listenToChats() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) {
      if (mounted) setState(() => _unreadChats = snapshot.docs.length);
    });
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

  void _resetToHome() {
    setState(() {
      _searchCtrl.clear();
      _searchWord = null;
      _selectedCity = _myCity; // Возвращаем к городу по геолокации
      _typeFilter = 'all';
      _isNearby = _myCity != null;
      _showSuggestions = false;
    });
    _applyFilters();
  }

  void _toggleNearby() {
    setState(() {
      if (_isNearby) {
        _selectedCity = null;
        _isNearby = false;
      } else {
        _selectedCity = _myCity;
        _isNearby = true;
      }
    });
    _applyFilters();
  }

  void _showChatsList() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatsListScreen(userId: user.uid)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<OrderProvider>();
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _resetToHome,
          child: const Text('ААСтройПро'),
        ),
        actions: [
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.chat), tooltip: 'Чаты', onPressed: _showChatsList),
              if (_unreadChats > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text('$_unreadChats', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          IconButton(icon: const Icon(Icons.home), tooltip: 'На главную', onPressed: _resetToHome),
          IconButton(
            icon: Icon(_isNearby ? Icons.near_me : Icons.near_me_disabled, color: _isNearby ? Colors.green : null),
            tooltip: _isNearby ? 'Рядом со мной' : 'Показать все',
            onPressed: _toggleNearby,
          ),
          IconButton(icon: const Icon(Icons.filter_list), tooltip: 'Выбрать город', onPressed: () => _showFilterBottomSheet(context)),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Профиль',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Город и геолокация
          if (_myCity != null || _isLoadingCity)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: _isNearby ? Colors.green.shade50 : Colors.grey.shade100,
              child: Row(
                children: [
                  Icon(_isNearby ? Icons.location_on : Icons.location_off, size: 16, color: _isNearby ? Colors.green : Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    _isLoadingCity ? 'Определяем город...' : _isNearby ? 'Рядом: $_myCity' : 'Геолокация отключена',
                    style: TextStyle(fontSize: 13, color: _isNearby ? Colors.green.shade700 : Colors.grey),
                  ),
                ],
              ),
            ),
          // Поиск
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  decoration: InputDecoration(
                    hintText: 'Поиск по работам...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _searchWord = null; _showSuggestions = false; _applyFilters(); })
                        : null,
                  ),
                  onSubmitted: (val) {
                    _searchWord = val.trim().isNotEmpty ? val.trim() : null;
                    _showSuggestions = false;
                    _applyFilters();
                  },
                ),
                if (_showSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (ctx, i) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.search, size: 18, color: Colors.grey),
                        title: Text(_suggestions[i]),
                        onTap: () {
                          _searchCtrl.text = _suggestions[i];
                          _searchWord = _suggestions[i];
                          _showSuggestions = false;
                          _applyFilters();
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Фильтры
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('Все')),
                ButtonSegment(value: 'request', label: Text('Заказы')),
                ButtonSegment(value: 'offer', label: Text('Предложения')),
              ],
              selected: {_typeFilter},
              onSelectionChanged: (s) { setState(() => _typeFilter = s.first); _applyFilters(); },
            ),
          ),
          // Лента
          Expanded(
            child: orderProv.orders.isEmpty && !orderProv.loading
                ? const Center(child: Text('Нет объявлений'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: orderProv.orders.length + (orderProv.hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == orderProv.orders.length) return const Center(child: CircularProgressIndicator());
                      final order = orderProv.orders[i];
                      return OrderCard(
                        order: order,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order))),
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
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Выберите город', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          Expanded(
            child: CityPicker(
              selectedCity: _selectedCity,
              onChanged: (city) {
                _selectedCity = city;
                _isNearby = false;
                Navigator.pop(context);
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChatsListScreen extends StatelessWidget {
  final String userId;
  const ChatsListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Чаты')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: userId).orderBy('lastMessageTime', descending: true).snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Нет чатов'));
          final chats = snapshot.data!.docs;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (ctx, i) {
              final data = chats[i].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: const Icon(Icons.chat, color: Colors.orange)),
                title: Text(data['lastMessage'] as String? ?? 'Новый чат'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chats[i].id))),
              );
            },
          );
        },
      ),
    );
  }
}
