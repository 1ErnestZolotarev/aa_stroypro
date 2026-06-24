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

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _sc = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String? _selectedCity, _searchWord; String _typeFilter = "all";
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isNearby = true;

  @override
  void initState() {
    super.initState();
    _sc.addListener(_onScroll);
    _searchCtrl.addListener(() { final q = _searchCtrl.text; setState(() { _suggestions = SearchService.getSuggestions(q); _showSuggestions = q.isNotEmpty && _suggestions.isNotEmpty; }); });
    _searchFocus.addListener(() { if (!_searchFocus.hasFocus) setState(() => _showSuggestions = false); });
  }

  void _initCity() { final u = context.read<AuthProvider>().user; if (u?.city != null && u!.city.isNotEmpty) { _selectedCity = u.city; _isNearby = true; } _applyFilters(); }
  void _onScroll() { if (_sc.position.pixels >= _sc.position.maxScrollExtent - 200) context.read<OrderProvider>().fetchOrders(city: _selectedCity, searchWord: _searchWord, typeFilter: _typeFilter); }
  void _applyFilters() { context.read<OrderProvider>().fetchOrders(city: _selectedCity, searchWord: _searchWord, typeFilter: _typeFilter, initialLoad: true); }
  void _resetToHome() { final u = context.read<AuthProvider>().user; setState(() { _searchCtrl.clear(); _searchWord = null; _selectedCity = u?.city; _typeFilter = 'all'; _isNearby = true; _showSuggestions = false; }); _applyFilters(); }
  void _toggleNearby() { setState(() { if (_isNearby) { _selectedCity = null; _isNearby = false; } else { final u = context.read<AuthProvider>().user; _selectedCity = u?.city; _isNearby = true; } }); _applyFilters(); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OrderProvider>();
    final u = context.read<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: GestureDetector(onTap: _resetToHome, child: const Text('ААСтройПро')), actions: [
        IconButton(icon: Icon(_isNearby ? Icons.near_me : Icons.near_me_disabled, color: _isNearby ? Colors.green : null), tooltip: _isNearby ? 'Рядом: ${u?.city ?? ""}' : 'Все города', onPressed: _toggleNearby),
        IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _showCityPicker()),
        IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
      ]),
      body: Column(children: [
        if (u?.city != null) Container(padding: const EdgeInsets.symmetric(horizontal:16,vertical:4), color: _isNearby ? Colors.green.shade50 : Colors.grey.shade100, child: Row(children: [Icon(_isNearby ? Icons.location_on : Icons.location_off, size:16, color: _isNearby ? Colors.green : Colors.grey), const SizedBox(width:6), Text(_isNearby ? 'Рядом: ${u!.city}' : 'Все города', style: TextStyle(fontSize:13, color: _isNearby ? Colors.green.shade700 : Colors.grey))])),
        Padding(padding: const EdgeInsets.symmetric(horizontal:16,vertical:8), child: Column(children: [
          TextField(controller: _searchCtrl, focusNode: _searchFocus, decoration: InputDecoration(hintText: 'Поиск по работам...', prefixIcon: const Icon(Icons.search), suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _searchWord = null; _showSuggestions = false; _applyFilters(); }) : null), onSubmitted: (v) { _searchWord = v.trim().isNotEmpty ? v.trim() : null; _showSuggestions = false; _applyFilters(); }),
          if (_showSuggestions) Container(margin: const EdgeInsets.only(top:4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]), constraints: const BoxConstraints(maxHeight:200), child: ListView.builder(shrinkWrap: true, itemCount: _suggestions.length, itemBuilder: (_,i) => ListTile(dense: true, leading: const Icon(Icons.search, size:18, color: Colors.grey), title: Text(_suggestions[i]), onTap: () { _searchCtrl.text = _suggestions[i]; _searchWord = _suggestions[i]; _showSuggestions = false; _applyFilters(); }))),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal:16,vertical:4), child: SegmentedButton<String>(segments: const [ButtonSegment(value:'all',label:Text('Все')),ButtonSegment(value:'request',label:Text('Заказы')),ButtonSegment(value:'offer',label:Text('Предложения'))], selected: {_typeFilter}, onSelectionChanged: (s) { setState(() => _typeFilter = s.first); _applyFilters(); })),
        Expanded(child: p.orders.isEmpty && !p.loading ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.inbox, size:64, color:Colors.grey), const SizedBox(height:16), Text(_selectedCity!=null?'Нет заказов в городе $_selectedCity':'Нет объявлений', style: const TextStyle(color:Colors.grey))])) : ListView.builder(controller: _sc, itemCount: p.orders.length+(p.hasMore?1:0), itemBuilder: (_,i) { if (i==p.orders.length) return const Center(child: CircularProgressIndicator()); final o = p.orders[i]; return OrderCard(order: o, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o)))); })),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: () => Navigator.pushNamed(context, '/create_order'), child: const Icon(Icons.add)),
    );
  }

  void _showCityPicker() { showModalBottomSheet(context: context, builder: (_) => CityPicker(selectedCity: _selectedCity, onChanged: (city) { setState(() { _selectedCity = city; _isNearby = false; }); Navigator.pop(context); _applyFilters(); })); }
}

class ChatsListScreen extends StatelessWidget {
  final String userId;
  const ChatsListScreen({super.key, required this.userId});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Чаты')), body: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: userId).orderBy('lastMessageTime', descending: true).snapshots(), builder: (_,s) {
    if (s.connectionState==ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
    if (!s.hasData||s.data!.docs.isEmpty) return const Center(child: Text('Нет чатов'));
    return ListView.builder(itemCount: s.data!.docs.length, itemBuilder: (_,i) { final d = s.data!.docs[i].data() as Map<String, dynamic>; return ListTile(leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: const Icon(Icons.chat, color: Colors.orange)), title: Text(d['lastMessage'] as String? ?? 'Новый чат'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: s.data!.docs[i].id)))); });
  }));
}
