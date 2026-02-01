import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import '../../core/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ValueNotifier<int> _refreshNotifier = ValueNotifier<int>(0);
  Timer? _timer;
  String _loadingStatus = "Menghubungkan...";
  int? _userId;
  late Future<List<Map<String, dynamic>>> _messagesFuture;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _refreshNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _messagesFuture = _fetchChatMessages();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        setState(() {
          _messagesFuture = _fetchChatMessages();
        });
      }
    });
  }

  Future<void> _loadUserId() async {
    try {
      if (!mounted) return;
      setState(() => _loadingStatus = "Mengambil data...");

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token =
          prefs.getString('token') ?? prefs.getString('access_token');

      // 1. Coba ambil dari SharedPreferences (paling cepat)
      Object? rawId = prefs.get('user_id') ?? prefs.get('id');
      if (rawId != null) {
        if (rawId is String)
          _userId = int.tryParse(rawId);
        else if (rawId is int)
          _userId = rawId;
      }

      // 2. Jika gagal, coba fetch dari profile API dengan timeout
      if (_userId == null && token != null) {
        setState(() => _loadingStatus = "Menghubungkan ke server...");

        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 7),
            receiveTimeout: const Duration(seconds: 7),
          ),
        );

        try {
          final apiService = ApiService(dio);
          final response = await apiService.getProfile(token);
          if (response.statusCode == 200 && response.data != null) {
            final userData = response.data['user'];
            if (userData != null && userData['id'] != null) {
              _userId = int.tryParse(userData['id'].toString());
              if (_userId != null) {
                await prefs.setInt('user_id', _userId!);
              }
            }
          }
        } catch (apiError) {
          debugPrint('Error fetch profile: $apiError');
        }
      }

      if (_userId == null) {
        _userId = -1;
      }

      if (mounted) setState(() => _loadingStatus = "Siap");
    } catch (e) {
      debugPrint('Fatal error _loadUserId: $e');
      if (mounted) {
        setState(() {
          _userId = -1;
          _loadingStatus = "Gagal memuat";
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchChatMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('access_token');

      if (token == null) return <Map<String, dynamic>>[];

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final apiService = ApiService(dio);

      final List<dynamic>? responseBody = await apiService.getChatMessages(
        token,
      );

      List<Map<String, dynamic>> parsed = [];
      if (responseBody != null) {
        parsed = responseBody
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }

      // Simpan di cache
      await prefs.setString('chat_cache_temp', jsonEncode(parsed));

      return parsed;
    } catch (e) {
      debugPrint('Error fetching messages: $e');

      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('chat_cache_temp');
        if (cached != null) {
          return List<Map<String, dynamic>>.from(jsonDecode(cached));
        }
      } catch (_) {}

      return <Map<String, dynamic>>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = appConfig.primaryColor;
    const Color senderColor = Color(0xFFB3FF66);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CHAT',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            tooltip: 'Hapus Semua Chat',
            onPressed: () => _showDeleteConfirmation(),
          ),
        ],
      ),
      // PERBAIKAN: Pastikan resizeToAvoidBottomInset adalah true (default)
      resizeToAvoidBottomInset: true,
      body: _userId == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_loadingStatus),
                  const SizedBox(height: 8),
                  const Text(
                    'Mohon tunggu sejenak...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      behavior: HitTestBehavior.opaque,
                      child: ValueListenableBuilder<int>(
                        valueListenable: _refreshNotifier,
                        builder: (context, _, __) {
                          return FutureBuilder<List<Map<String, dynamic>>>(
                            future: _messagesFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return const Center(
                                  child: Text(
                                    'Gagal memuat chat. Pastikan koneksi internet stabil.',
                                  ),
                                );
                              }

                              final messages = snapshot.data ?? [];

                              if (messages.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'Belum ada percakapan.\nSilakan kirim pesan ke admin.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }

                              return ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: messages.length,
                                reverse: true,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, i) {
                                  final msg = messages[messages.length - 1 - i];

                                  final senderId = msg['sender_id'].toString();
                                  final userId = _userId?.toString();
                                  final bool isSender = senderId == userId;

                                  return _buildChatBubble(
                                    message: msg['message'] ?? '',
                                    time: msg['timestamp']?.toString() ?? '',
                                    color: isSender
                                        ? senderColor
                                        : primaryColor,
                                    isSender: isSender,
                                    textColor: isSender
                                        ? Colors.black
                                        : Colors.white,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  _buildInputArea(primaryColor),
                ],
              ),
            ),
    );
  }

  Future<void> _deleteChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('access_token');
      if (token == null) return;

      final dio = Dio();
      final apiService = ApiService(dio);
      final success = await apiService.deleteAllChat(token);

      if (success && mounted) {
        setState(() {
          _messagesFuture = _fetchChatMessages();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua chat berhasil dihapus')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting chat: $e');
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Hapus semua chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteChat();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble({
    required String message,
    required String time,
    required Color color,
    required bool isSender,
    required Color textColor,
  }) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isSender
                ? const Radius.circular(12)
                : const Radius.circular(4),
            bottomRight: isSender
                ? const Radius.circular(4)
                : const Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isSender
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.black),
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: 'Ketik pesan...',
                        hintStyle: TextStyle(color: Colors.black54),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: primaryColor,
            radius: 22,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('access_token');

      if (token == null) return;

      // Gunakan local ApiService dengan timeout
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final apiService = ApiService(dio);

      final success = await apiService.sendChatMessage(token, text);

      if (success) {
        _controller.clear();
        // Update local state and trigger refresh
        setState(() {
          _messagesFuture = _fetchChatMessages();
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }
}
