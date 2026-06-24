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
  String? _selectedCity, _searchWord;
  String _typeFilter = 'all';
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isNearby = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _sc.addListener(_onScroll);
    _searchCtrl.addListener(() { final q = _searchCtrl.text; setState(() { _suggestions = SearchService.getSuggestions(q); _showSuggestions = q.isNotEmpty && _suggestions.isNotEmpty; }); });
    _searchFocus.addListener(() { if (!_searchFocus.hasFocus) setState(() => _showSuggestions = false); });
    Future.microtask(() { _initCity(); _listenUnread(); });
  }

  void _initCity() { final u = context.read<AuthProvider>().user; if (u?.city != null && u!.city.isNotEmpty) { _selectedCity = u.city; _isNearby = true; } _applyFilters(); }

  void _listenUnread() {
    final u = context.read<AuthProvider>().user;
    if (u == null) return;
    FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: u.uid).snapshots().listen((s) {
      if (mounted) setState(() => _unreadCount = s.docs.length);
    });
  }

  void _onScroll() { if (_sc.position.pixels >= _sc.position.maxScrollExtent - 200) context.read<OrderProvider>().fetchOrders(city: _selectedCity, searchWord: _searchWord, typeFilter: _typeFilter); }
  void _applyFilters() { context.read<OrderProvider>().fetchOrders(city: _selectedCity, searchWord: _searchWord, typeFilter: _typeFilter, initialLoad: true); }
  void _resetToHome() { final u = context.read<AuthProvider>().user; setState(() { _searchCtrl.clear(); _searchWord = null; _selectedCity = u?.city; _typeFilter = 'all'; _isNearby = true; _showSuggestions = false; }); _applyFilters(); }
  void _toggleNearby() { setState(() { if (_isNearby) { _selectedCity = null; _isNearby = false; } else { final u = context.read<AuthProvider>().user; _selectedCity = u?.city; _isNearby = true; } }); _applyFilters(); }
  void _openChats() { final u = context.read<AuthProvider>().user; if (u != null) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatsListScreen(userId: u.uid))).then((_) => _listenUnread()); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OrderProvider>();
    final u = context.read<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: GestureDetector(onTap: _resetToHome, child: const Text('ААСтройПро')), actions: [
        IconButton(icon: const Icon(Icons.home), onPressed: _resetToHome),
        IconButton(icon: Icon(_isNearby ? Icons.near_me : Icons.near_me_disabled, color: _isNearby ? Colors.green : null), tooltip: _isNearby ? 'Рядом: ${u?.city ?? ""}' : 'Все города', onPressed: _toggleNearby),
        Stack(children: [
          IconButton(icon: const Icon(Icons.chat), onPressed: _openChats),
          if (_unreadCount > 0) Positioned(right: 6, top: 6, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), constraints: const BoxConstraints(minWidth: 18, minHeight: 18), child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center))),
        ]),
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

// Список чатов с возможностью удаления (как в Авито)
class ChatsListScreen extends StatelessWidget {
  final String userId;
  const ChatsListScreen({super.key, required this.userId});

  Future<void> _deleteChat(String chatId) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Чаты')),
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: userId).snapshots(),
      builder: (_, s) {
        if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (s.hasError) return Center(child: Text('Ошибка: ${s.error}'));
        if (!s.hasData || s.data!.docs.isEmpty) return const Center(child: Text('Нет чатов'));
        final chats = s.data!.docs;
        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (_, i) {
            final d = chats[i].data() as Map<String, dynamic>;
            return Dismissible(
              key: Key(chats[i].id),
              direction: DismissDirection.endToStart,
              background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
              confirmDismiss: (_) async => await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Удалить чат?'), content: const Text('Вся переписка будет удалена.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить', style: TextStyle(color: Colors.red)))])) ?? false,
              onDismissed: (_) => _deleteChat(chats[i].id),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: const Icon(Icons.chat, color: Colors.orange)),
                title: Text(d['lastMessage'] as String? ?? 'Новый чат'),
                subtitle: d['lastMessageTime'] != null ? Text(_fmt(d['lastMessageTime'] as String)) : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chats[i].id))),
              ),
            );
          },
        );
      },
    ),
  );

  String _fmt(String iso) { final dt = DateTime.parse(iso); return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'; }
}
