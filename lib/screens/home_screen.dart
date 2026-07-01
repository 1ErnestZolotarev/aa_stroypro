import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart' as OurAuth;
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
  List<String> _selectedCities = [];
  String? _searchWord;
  String _typeFilter = 'all';
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isNearby = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _sc.addListener(_onScroll);
    _searchCtrl.addListener(() { final q = _searchCtrl.text; setState(() { _suggestions = SearchService.getSuggestions(q); _showSuggestions = q.isNotEmpty && _suggestions.isNotEmpty; }); });
    _searchFocus.addListener(() { if (!_searchFocus.hasFocus) setState(() => _showSuggestions = false); });
    _loadSavedCities();
    _listenChats();
  }

  Future<void> _loadSavedCities() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCities = prefs.getStringList('selectedCities') ?? [];
    if (savedCities.isNotEmpty) {
      setState(() => _selectedCities = savedCities);
    } else {
      final u = context.read<OurAuth.AuthProvider>().user;
      if (u?.city != null) {
        setState(() => _selectedCities = [u!.city]);
      }
    }
    _applyFilters();
  }

  Future<void> _saveCities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selectedCities', _selectedCities);
  }

  void _listenChats() {
    final u = context.read<OurAuth.AuthProvider>().user;
    if (u == null) return;
    FirebaseFirestore.instance.collection('chats')
      .where('participants', arrayContains: u.phone)
      .snapshots()
      .listen((s) {
        int count = 0;
        for (var doc in s.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final lastMessageTime = data['lastMessageTime'] as String?;
          final lastReadBy = data['lastReadBy'] as Map<String, dynamic>?;
          final myLastRead = lastReadBy?[u.phone] as String?;
          if (lastMessageTime != null && (myLastRead == null || lastMessageTime.compareTo(myLastRead) > 0)) {
            count++;
          }
        }
        if (mounted) setState(() => _unreadCount = count);
      });
  }

  void _onScroll() { if (_sc.position.pixels >= _sc.position.maxScrollExtent - 200) context.read<OrderProvider>().fetchOrders(cities: _selectedCities, searchWord: _searchWord, typeFilter: _typeFilter); }
  void _applyFilters() { context.read<OrderProvider>().fetchOrders(cities: _selectedCities, searchWord: _searchWord, typeFilter: _typeFilter, initialLoad: true); }
  
  void _resetToHome() {
    final u = context.read<OurAuth.AuthProvider>().user;
    setState(() {
      _searchCtrl.clear();
      _searchWord = null;
      _selectedCities = u?.city != null ? [u!.city] : [];
      _typeFilter = 'all';
      _isNearby = false;
      _showSuggestions = false;
    });
    _saveCities();
    _applyFilters();
  }

  void _toggleNearby() {
    final u = context.read<OurAuth.AuthProvider>().user;
    setState(() {
      if (_isNearby) {
        _selectedCities = [];
        _isNearby = false;
      } else {
        _selectedCities = u?.city != null ? [u!.city] : [];
        _isNearby = true;
      }
    });
    _saveCities();
    _applyFilters();
  }

  void _openChats() { final u = context.read<OurAuth.AuthProvider>().user; if (u != null) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatsListScreen(userId: u.phone))); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OrderProvider>();
    final u = context.read<OurAuth.AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: GestureDetector(onTap: _resetToHome, child: const Text('ААСтройПро')), actions: [
        IconButton(icon: const Icon(Icons.home), onPressed: _resetToHome),
        IconButton(icon: Icon(_isNearby ? Icons.near_me : Icons.near_me_disabled, color: _isNearby ? Colors.green : null), tooltip: _isNearby ? 'Мой город: ${u?.city ?? ""}' : 'Все города', onPressed: _toggleNearby),
        Stack(children: [
          IconButton(icon: const Icon(Icons.chat), onPressed: _openChats),
          if (_unreadCount > 0) Positioned(right: 6, top: 6, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), constraints: const BoxConstraints(minWidth: 18, minHeight: 18), child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center))),
        ]),
        IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _showCityPicker()),
        IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
      ]),
      body: Column(children: [
        if (_selectedCities.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: _isNearby ? Colors.green.shade50 : Colors.orange.shade50,
            child: Text(
              _isNearby ? 'Рядом: ${_selectedCities.join(", ")}' : 'Выбраны города: ${_selectedCities.join(", ")}',
              style: TextStyle(fontSize: 12, color: _isNearby ? Colors.green.shade700 : Colors.orange.shade700),
            ),
          ),
        Padding(padding: const EdgeInsets.symmetric(horizontal:16,vertical:8), child: Column(children: [
          TextField(controller: _searchCtrl, focusNode: _searchFocus, decoration: InputDecoration(hintText: 'Поиск по работам...', prefixIcon: const Icon(Icons.search), suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _searchWord = null; _showSuggestions = false; _applyFilters(); }) : null), onSubmitted: (v) { _searchWord = v.trim().isNotEmpty ? v.trim() : null; _showSuggestions = false; _applyFilters(); }),
          if (_showSuggestions) Container(margin: const EdgeInsets.only(top:4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]), constraints: const BoxConstraints(maxHeight:200), child: ListView.builder(shrinkWrap: true, itemCount: _suggestions.length, itemBuilder: (_,i) => ListTile(dense: true, leading: const Icon(Icons.search, size:18, color: Colors.grey), title: Text(_suggestions[i]), onTap: () { _searchCtrl.text = _suggestions[i]; _searchWord = _suggestions[i]; _showSuggestions = false; _applyFilters(); }))),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal:16,vertical:4), child: SegmentedButton<String>(segments: const [ButtonSegment(value:'all',label:Text('Все')),ButtonSegment(value:'request',label:Text('Заказы')),ButtonSegment(value:'offer',label:Text('Предложения'))], selected: {_typeFilter}, onSelectionChanged: (s) { setState(() => _typeFilter = s.first); _applyFilters(); })),
        Expanded(child: p.orders.isEmpty && !p.loading ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.inbox, size:64, color:Colors.grey), const SizedBox(height:16), Text(_selectedCities.isNotEmpty?'Нет заказов в выбранных городах':'Нет объявлений', style: const TextStyle(color:Colors.grey))])) : ListView.builder(controller: _sc, itemCount: p.orders.length+(p.hasMore?1:0), itemBuilder: (_,i) { if (i==p.orders.length) return const Center(child: CircularProgressIndicator()); final o = p.orders[i]; return OrderCard(order: o, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o)))); })),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: () => Navigator.pushNamed(context, '/create_order'), child: const Icon(Icons.add)),
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: CityPicker(
          selectedCities: _selectedCities,
          onChanged: (cities) {
            setState(() {
              _selectedCities = cities;
              _isNearby = false;
            });
            _saveCities();
            _applyFilters();
          },
        ),
      ),
    );
  }
}

class ChatsListScreen extends StatelessWidget {
  final String userId;
  const ChatsListScreen({super.key, required this.userId});

  Future<void> _deleteChat(String chatId) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
  }

  Future<String> _getPartnerName(List<String> participants) async {
    final other = participants.firstWhere((id) => id != userId, orElse: () => '');
    if (other.isEmpty) return 'Неизвестно';
    final doc = await FirebaseFirestore.instance.collection('users').doc(other).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['name'] != null && data['name'].toString().isNotEmpty) {
        return data['name'];
      }
      return other;
    }
    return other;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Чаты')),
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: userId)
          .snapshots(),
      builder: (_, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s.hasError) {
          return Center(child: Text('Ошибка: ${s.error}'));
        }
        if (!s.hasData || s.data!.docs.isEmpty) {
          return const Center(child: Text('Нет чатов'));
        }

        final chats = s.data!.docs;
        // Сортировка на клиенте – новые сверху
        chats.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['lastMessageTime'] as String? ?? '';
          final bTime = (b.data() as Map<String, dynamic>)['lastMessageTime'] as String? ?? '';
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (_, i) {
            final d = chats[i].data() as Map<String, dynamic>;
            final participants = List<String>.from(d['participants'] ?? []);
            return Dismissible(
              key: Key(chats[i].id),
              direction: DismissDirection.endToStart,
              background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white)),
              confirmDismiss: (_) async =>
                  await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Удалить чат?'),
                          content: const Text('Вся переписка будет удалена.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Отмена')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Удалить', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ) ??
                  false,
              onDismissed: (_) => _deleteChat(chats[i].id),
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: const Icon(Icons.person, color: Colors.orange)),
                title: FutureBuilder<String>(
                  future: _getPartnerName(participants),
                  builder: (_, nameSnap) => Text(nameSnap.data ?? 'Загрузка...'),
                ),
                subtitle: Text(d['lastMessage'] as String? ?? '', maxLines: 1),
                trailing: d['lastMessageTime'] != null
                    ? Text(_fmt(d['lastMessageTime'] as String),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
                    : null,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ChatScreen(chatId: chats[i].id))),
              ),
            );
          },
        );
      },
    ),
  );

  String _fmt(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
