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
      _tabController = TabController(length: 3, vsync: this);
    }
    _loadNotifications();
  }

  @override
  void dispose() {
    try {
      _tabController.dispose();
    } catch (e) {
      // Ignore disposal errors
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final color = appConfig.primaryColor;
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
    } catch (e) {
      // Ignore status bar color errors
    }
  }

  Future<void> _loadNotifications() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final token = await SessionManager.getToken();
      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await _apiService.getUserNotifications(token);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = response.data;

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
            }
          } catch (e) {
            if (mounted) setState(() => _isLoading = false);
          }
        } else if (data is List) {
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
            }
          } catch (e) {
            if (mounted) setState(() => _isLoading = false);
          }
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      // Handle network errors gracefully
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      if (resp.statusCode == 200 && mounted) {
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
      }
    } catch (e) {
      // Silently fail - marking as read is not critical
    }
  }

  // Delete notifications (selected or all)
  Future<void> _deleteNotifications() async {
    final token = await SessionManager.getToken();
    if (token == null) return;

    final bool hasSelection = _selectedIds.isNotEmpty;
    final String title = hasSelection
        ? 'Hapus ${_selectedIds.length} Notifikasi?'
        : 'Hapus Semua Notifikasi?';
    final String message = hasSelection
        ? 'Notifikasi yang dipilih akan dihapus secara permanen.'
        : 'Semua notifikasi akan dihapus secara permanen.';

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (hasSelection) {
        // Delete selected notifications
        int successCount = 0;
        int failCount = 0;
        final List<int> failedIds = [];
        final List<int> selectedList = _selectedIds.toList();

        for (final id in selectedList) {
          try {
            print('\n📤 Attempting to delete notification ID: $id');
            final response = await _apiService.deleteNotification(
              id: id,
              token: token,
            );

            print('📥 Response status: ${response.statusCode}');
            print('📥 Response data: ${response.data}');
            print('📥 Response headers: ${response.headers}');

            // Check if response indicates success
            bool isSuccess = false;

            if (response.statusCode == 200 || response.statusCode == 201) {
              isSuccess = true;
            } else if (response.data is Map) {
              final data = response.data as Map;
              // Check for success in response body
              if (data['success'] == true ||
                  data['status'] == 'success' ||
                  data['message'] == 'Notification deleted successfully') {
                isSuccess = true;
              }
            }

            if (isSuccess) {
              print('✅ Notification $id deleted successfully');
              successCount++;
            } else {
              print('❌ Notification $id delete returned unexpected response');
              failCount++;
              failedIds.add(id);
            }
          } catch (e) {
            print('❌ Error deleting notification $id: $e');
            failCount++;
            failedIds.add(id);
          }
        }

        if (mounted) {
          // Hapus notifikasi yang berhasil dihapus dari UI
          setState(() {
            _items.removeWhere(
              (item) =>
                  _selectedIds.contains(item.id) &&
                  !failedIds.contains(item.id),
            );
            _selectedIds.clear();
          });

          // Tampilkan hasil dengan detail
          String feedbackMessage;
          Color feedbackColor;

          if (failCount == 0) {
            feedbackMessage = 'Semua notifikasi berhasil dihapus';
            feedbackColor = Colors.green;
          } else if (successCount == 0) {
            feedbackMessage = 'Gagal menghapus semua notifikasi';
            feedbackColor = Colors.red;
          } else {
            feedbackMessage =
                '$successCount berhasil, $failCount gagal dihapus';
            feedbackColor = Colors.orange;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(feedbackMessage),
              backgroundColor: feedbackColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Delete all notifications via single endpoint
        try {
          print('\n📤 Attempting to delete ALL notifications');
          final response = await _apiService.deleteAllUserNotifications(token);

          print('📥 Response status: ${response.statusCode}');
          print('📥 Response data: ${response.data}');
          print('📥 Response headers: ${response.headers}');

          bool isSuccess = false;

          if (response.statusCode == 200 || response.statusCode == 201) {
            isSuccess = true;
          } else if (response.data is Map) {
            final data = response.data as Map;
            if (data['success'] == true ||
                data['status'] == 'success' ||
                data['message'] == 'All notifications deleted successfully') {
              isSuccess = true;
            }
          }

          if (mounted) {
            if (isSuccess) {
              // Clear all items from UI
              setState(() {
                _items.clear();
                _selectedIds.clear();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Semua notifikasi berhasil dihapus'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gagal menghapus semua notifikasi'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        } catch (e) {
          print('❌ Error deleting all notifications: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal menghapus semua notifikasi'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal menghapus notifikasi. Periksa koneksi internet Anda.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildList(List<NotificationModel> list) {
    if (list.isEmpty) {
      return Container(
        color: const Color(0xFFFFFFFF),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 200,
              child: Center(child: Text('Belum ada notifikasi')),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFFFFFFF),
      child: ListView.separated(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
      ),
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
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final Color appBarColor = _getValidAppBarColor();

      return Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          backgroundColor: appBarColor,
          foregroundColor: appConfig.textColor,
          elevation: 4,
          centerTitle: false,
          title: Text(
            "Notifikasi",
            style: TextStyle(
              color: appConfig.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: IconThemeData(color: appConfig.textColor),
          actions: [
            if (_items.isNotEmpty)
              IconButton(
                icon: Icon(Icons.delete_outline, color: appConfig.textColor),
                tooltip: _selectedIds.isEmpty
                    ? 'Hapus Semua'
                    : 'Hapus ${_selectedIds.length} Terpilih',
                onPressed: _deleteNotifications,
              ),
          ],
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
        body: Container(
          color: const Color(0xFFFFFFFF),
          child: TabBarView(
            controller: _tabController,
            children: [
              Container(
                color: const Color(0xFFFFFFFF),
                child: RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: appConfig.primaryColor,
                  backgroundColor: Colors.white,
                  child: _buildList(_all),
                ),
              ),
              Container(
                color: const Color(0xFFFFFFFF),
                child: RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: appConfig.primaryColor,
                  backgroundColor: Colors.white,
                  child: _buildList(_read),
                ),
              ),
              Container(
                color: const Color(0xFFFFFFFF),
                child: RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: appConfig.primaryColor,
                  backgroundColor: Colors.white,
                  child: _buildList(_unread),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
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
