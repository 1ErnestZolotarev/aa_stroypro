import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../services/search_service.dart';
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
  final ScrollController _sc = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String? _selectedCity, _searchWord;
  String _typeFilter = 'all';
  int? _budgetFrom, _budgetTo;
  int _unreadChats = 0;
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isNearby = true; // По умолчанию показываем свой город

  @override
  void initState() {
    super.initState();
    _sc.addListener(_onScroll);
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text;
      setState(() {
        _suggestions = SearchService.getSuggestions(q);
        _showSuggestions = q.isNotEmpty && _suggestions.isNotEmpty;
      });
    });
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) setState(() => _showSuggestions = false);
    });
    Future.microtask(() {
      _initCity();
      _listenChats();
    });
  }

  void _initCity() {
    final u = context.read<AuthProvider>().user;
    if (u?.city != null && u!.city.isNotEmpty) {
      _selectedCity = u.city;
      _isNearby = true;
    }
    _applyFilters();
  }

  void _listenChats() {
    final u = context.read<AuthProvider>().user;
    if (u == null) return;
    FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: u.uid)
        .snapshots()
        .listen((s) {
      if (mounted) setState(() => _unreadChats = s.docs.length);
    });
  }

  void _onScroll() {
    if (_sc.position.pixels >= _sc.position.maxScrollExtent - 200) {
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
    final u = context.read<AuthProvider>().user;
    setState(() {
      _searchCtrl.clear();
      _searchWord = null;
      _selectedCity = u?.city;
      _typeFilter = 'all';
      _isNearby = true;
      _showSuggestions = false;
    });
    _applyFilters();
  }

  void _toggleNearby() {
    setState(() {
      if (_isNearby) {
        // Выключаем — показываем все города
        _selectedCity = null;
        _isNearby = false;
      } else {
        // Включаем — показываем свой город
        final u = context.read<AuthProvider>().user;
        _selectedCity = u?.city;
        _isNearby = true;
      }
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OrderProvider>();
    final u = context.read<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _resetToHome,
          child: const Text('ААСтройПро'),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.chat),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ChatsListScreen(userId: u!.uid))),
              ),
              if (_unreadChats > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10)),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text('$_unreadChats',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          IconButton(icon: const Icon(Icons.home), onPressed: _resetToHome),
          // Иконка геолокации
          IconButton(
            icon: Icon(
              _isNearby ? Icons.near_me : Icons.near_me_disabled,
              color: _isNearby ? Colors.green : null,
            ),
            tooltip: _isNearby ? 'Рядом: ${u?.city ?? ""}' : 'Все города',
            onPressed: _toggleNearby,
          ),
          IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showCityPicker()),
          IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()))),
        ],
      ),
      body: Column(
        children: [
          // Статус геолокации
          if (u?.city != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: _isNearby ? Colors.green.shade50 : Colors.grey.shade100,
              child: Row(
                children: [
                  Icon(
                    _isNearby ? Icons.location_on : Icons.location_off,
                    size: 16,
                    color: _isNearby ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isNearby ? 'Рядом: ${u!.city}' : 'Все города',
                    style: TextStyle(
                      fontSize: 13,
                      color: _isNearby ? Colors.green.shade700 : Colors.grey,
                    ),
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
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _searchWord = null;
                              _showSuggestions = false;
                              _applyFilters();
                            })
                        : null,
                  ),
                  onSubmitted: (val) {
                    _searchWord =
                        val.trim().isNotEmpty ? val.trim() : null;
                    _showSuggestions = false;
                    _applyFilters();
                  },
                ),
                if (_showSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8)
                        ]),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.search,
                            size: 18, color: Colors.grey),
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
