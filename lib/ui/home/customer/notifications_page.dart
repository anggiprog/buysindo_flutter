import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
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
    try {
      _tabController = TabController(length: 3, vsync: this);
    } catch (e) {
      debugPrint('❌ Error creating TabController: $e');
      _tabController = TabController(length: 3, vsync: this);
    }
    _loadNotifications();
  }

  @override
  void dispose() {
    try {
      _tabController.dispose();
    } catch (e) {
      debugPrint('⚠️ Error disposing TabController: $e');
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      // Set status bar color to app primary color
      final color = appConfig.primaryColor;
      // Validate color - use fallback if invalid
      final validColor = color.value == 0 ? const Color(0xFF0D6EFD) : color;
      final brightness = validColor.computeLuminance() > 0.5
          ? Brightness.dark
          : Brightness.light;
      services.SystemChrome.setSystemUIOverlayStyle(
        services.SystemUiOverlayStyle(
          statusBarColor: validColor,
          statusBarIconBrightness: brightness,
        ),
      );
      debugPrint('✅ Status bar color set');
    } catch (e) {
      debugPrint('⚠️ Error setting status bar color: $e');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final token = await SessionManager.getToken();
      if (token == null) {
        debugPrint('⚠️ No token available for loading notifications');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      debugPrint('📲 Loading notifications...');
      final response = await _apiService.getUserNotifications(token);

      if (!mounted) return;

      debugPrint('📲 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('📲 API Response Data Type: ${data.runtimeType}');

        if (data is Map &&
            data['status'] == 'success' &&
            data['data'] != null) {
          final List raw = data['data'];
          try {
            final List<NotificationModel> list = raw
                .map(
                  (e) =>
                      NotificationModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList();
            if (mounted) {
              setState(() {
                _items = list;
                _isLoading = false;
                _selectedIds.clear();
              });
              debugPrint('✅ Notifications loaded: ${list.length} items');
            }
          } catch (e) {
            debugPrint('❌ Error parsing notification list: $e');
            if (mounted) setState(() => _isLoading = false);
          }
        } else if (data is List) {
          // fallback jika endpoint return array langsung
          final List raw = data;
          try {
            final list = raw
                .map(
                  (e) =>
                      NotificationModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList();
            if (mounted) {
              setState(() {
                _items = list;
                _isLoading = false;
                _selectedIds.clear();
              });
              debugPrint(
                '✅ Notifications loaded (array fallback): ${list.length} items',
              );
            }
          } catch (e) {
            debugPrint('❌ Error parsing notification array: $e');
            if (mounted) setState(() => _isLoading = false);
          }
        } else {
          debugPrint('⚠️ Unexpected data format from API: $data');
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        debugPrint('❌ Failed to load notifications: ${response.statusCode}');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<NotificationModel> get _all => _items;
  List<NotificationModel> get _read => _items.where((i) => i.isRead).toList();
  List<NotificationModel> get _unread =>
      _items.where((i) => !i.isRead).toList();

  Future<void> _toggleSelect(int id, bool selected) async {
    setState(() {
      if (selected)
        _selectedIds.add(id);
      else
        _selectedIds.remove(id);
    });
  }

  // Mark a single notification as read (used when tapping an item)
  Future<void> _markAsRead(NotificationModel item) async {
    final token = await SessionManager.getToken();
    if (token == null) return;
    try {
      final resp = await _apiService.markNotificationAsRead(
        id: item.id,
        token: token,
      );
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

  Widget _buildList(List<NotificationModel> list) {
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 200,
            child: Center(child: Text('Belum ada notifikasi')),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            onTap: () async {
              if (!item.isRead) await _markAsRead(item);
              // show detail
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(item.judul),
                  content: Text(item.message),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: (v) => _toggleSelect(item.id, v ?? false),
                  ),
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
                                  fontWeight: item.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            if (!item.isRead)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Baru',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
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

  Color _getValidAppBarColor() {
    final primaryColor = appConfig.primaryColor;
    if (primaryColor.value == 0 ||
        primaryColor.value == 0xFFFFFFFF ||
        primaryColor.alpha < 200) {
      return const Color(0xFF0D6EFD);
    }
    if (primaryColor.computeLuminance() >= 0.9) {
      return const Color(0xFF0D6EFD);
    }
    return primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    try {
      if (_isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final Color appBarColor = _getValidAppBarColor();

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: appBarColor,
          foregroundColor: appConfig.textColor,
          elevation: 4,
          centerTitle: false,
          title: Text(
            appConfig.appName,
            style: TextStyle(color: appConfig.textColor),
          ),
          iconTheme: IconThemeData(color: appConfig.textColor),
          systemOverlayStyle: services.SystemUiOverlayStyle(
            statusBarColor: appBarColor,
            statusBarBrightness: appBarColor.computeLuminance() > 0.5
                ? Brightness.light
                : Brightness.dark,
            statusBarIconBrightness: appBarColor.computeLuminance() > 0.5
                ? Brightness.dark
                : Brightness.light,
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: appConfig.textColor,
            labelColor: appConfig.textColor,
            unselectedLabelColor: appConfig.textColor.withOpacity(0.7),
            tabs: const [
              Tab(text: 'Semua'),
              Tab(text: 'Dibaca'),
              Tab(text: 'Belum'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
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
    } catch (e) {
      debugPrint('❌ Error building NotificationsPage: $e');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifikasi'),
          backgroundColor: appConfig.primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Terjadi kesalahan'),
              const SizedBox(height: 8),
              Text('$e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadNotifications();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
