import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/session_manager.dart';
import '../../../../features/customer/data/models/notification_model.dart';
import '../../../../core/app_config.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late ApiService _apiService;
  bool _isLoading = true;
  List<NotificationModel> _items = [];

  // Selection
  final Set<int> _selectedIds = {};

  // Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Dio());
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await _apiService.getUserNotifications(token);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final List raw = data['data'];
          final List<NotificationModel> list = raw
              .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          if (mounted) {
            setState(() {
              _items = list;
              _isLoading = false;
              _selectedIds.clear();
            });
          }
        } else if (data is List) {
          // fallback jika endpoint return array langsung
          final List raw = data;
          final list = raw
              .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          if (mounted) setState(() {
            _items = list;
            _isLoading = false;
            _selectedIds.clear();
          });
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        debugPrint('Failed to load notifications: ${response.statusCode}');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<NotificationModel> get _all => _items;
  List<NotificationModel> get _read => _items.where((i) => i.isRead).toList();
  List<NotificationModel> get _unread => _items.where((i) => !i.isRead).toList();

  Future<void> _toggleSelect(int id, bool selected) async {
    setState(() {
      if (selected) _selectedIds.add(id); else _selectedIds.remove(id);
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final token = await SessionManager.getToken();
    if (token == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus notifikasi terpilih'),
        content: const Text('Yakin ingin menghapus notifikasi yang dipilih?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;

    // Jika semua dipilih, panggil deleteAll di backend
    if (_selectedIds.length == _items.length) {
      final resp = await _apiService.deleteAllUserNotifications(token);
      if (resp.statusCode == 200) {
        await _loadNotifications();
        return;
      }
    }

    // Backend tidak mendukung delete-by-ids -> fallback: mark as read on server for each selected, then remove locally
    for (final id in List<int>.from(_selectedIds)) {
      try {
        await _apiService.markNotificationAsRead(id: id, token: token);
      } catch (e) {
        debugPrint('Failed mark read for $id: $e');
      }
    }

    setState(() {
      _items.removeWhere((i) => _selectedIds.contains(i.id));
      _selectedIds.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifikasi dihapus secara lokal (server tidak mendukung delete-by-ids)')));
  }

  Future<void> _markSelectedAsRead() async {
    if (_selectedIds.isEmpty) return;
    final token = await SessionManager.getToken();
    if (token == null) return;

    for (final id in List<int>.from(_selectedIds)) {
      final resp = await _apiService.markNotificationAsRead(id: id, token: token);
      if (resp.statusCode == 200) {
        final idx = _items.indexWhere((e) => e.id == id);
        if (idx >= 0) {
          _items[idx] = NotificationModel(
            id: _items[idx].id,
            judul: _items[idx].judul,
            message: _items[idx].message,
            imageUrl: _items[idx].imageUrl,
            isRead: true,
            createdAt: _items[idx].createdAt,
          );
        }
      }
    }
    setState(() => _selectedIds.clear());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifikasi ditandai sebagai dibaca')));
  }

  // Mark a single notification as read (used when tapping an item)
  Future<void> _markAsRead(NotificationModel item) async {
    final token = await SessionManager.getToken();
    if (token == null) return;
    try {
      final resp = await _apiService.markNotificationAsRead(id: item.id, token: token);
      if (resp.statusCode == 200) {
        final idx = _items.indexWhere((e) => e.id == item.id);
        if (idx >= 0) {
          setState(() {
            _items[idx] = NotificationModel(
              id: _items[idx].id,
              judul: _items[idx].judul,
              message: _items[idx].message,
              imageUrl: _items[idx].imageUrl,
              isRead: true,
              createdAt: _items[idx].createdAt,
            );
          });
        }
      } else {
        debugPrint('Mark as read failed: ${resp.statusCode} ${resp.data}');
      }
    } catch (e) {
      debugPrint('Error mark as read: $e');
    }
  }

  // Delete all notifications via API with confirmation
  Future<void> _deleteAll() async {
    final token = await SessionManager.getToken();
    if (token == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus semua notifikasi'),
        content: const Text('Semua notifikasi akan dihapus. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus Semua')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final resp = await _apiService.deleteAllUserNotifications(token);
      if (resp.statusCode == 200) {
        // Hapus langsung di UI agar user tidak perlu manual refresh
        if (mounted) {
          setState(() {
            _items.clear();
            _selectedIds.clear();
            _isLoading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua notifikasi berhasil dihapus')));
        return;
      } else {
        debugPrint('Failed delete all: ${resp.statusCode} ${resp.data}');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus notifikasi')));
      }
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus notifikasi')));
    }
  }

  Widget _buildList(List<NotificationModel> list) {
    if (list.isEmpty) {
      // Return a scrollable ListView with AlwaysScrollableScrollPhysics so RefreshIndicator works
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200, child: Center(child: Text('Belum ada notifikasi'))),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final item = list[idx];
        final selected = _selectedIds.contains(item.id);
        return Card(
          elevation: 2,
          color: Colors.grey[100], // abu-abu lembut untuk tampilan buram
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            onTap: () async {
              if (!item.isRead) await _markAsRead(item);
              // show detail
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(item.judul),
                  content: Text(item.message),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(value: selected, onChanged: (v) => _toggleSelect(item.id, v ?? false)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.judul,
                                style: TextStyle(
                                  fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            if (!item.isRead)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                                child: const Text('Baru', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${item.createdAt.day.toString().padLeft(2, '0')}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.year} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // halaman background putih
      appBar: AppBar(
        backgroundColor: appConfig.primaryColor, // gunakan primary supaya teks putih terlihat
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            tooltip: 'Tandai terpilih sebagai dibaca',
            onPressed: _selectedIds.isEmpty ? null : _markSelectedAsRead,
            icon: const Icon(Icons.mark_email_read_outlined),
          ),
          IconButton(
            tooltip: 'Hapus terpilih',
            onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: 'Hapus semua',
            onPressed: _items.isEmpty ? null : _deleteAll,
            icon: const Icon(Icons.delete_forever),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [Tab(text: 'Semua'), Tab(text: 'Dibaca'), Tab(text: 'Belum')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tambahkan RefreshIndicator di setiap tab untuk swipe-to-refresh
                RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: _buildList(_all),
                ),
                RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: _buildList(_read),
                ),
                RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: _buildList(_unread),
                ),
              ],
            ),
    );
  }
}
