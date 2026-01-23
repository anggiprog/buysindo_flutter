import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/network/api_service.dart';
import '../../../core/network/session_manager.dart';
import '../../../models/topup_history_models.dart';
import '../../../core/app_config.dart';
import 'topup_konfirmasi.dart';
import 'topup_otomatis.dart';

class TopupHistoryScreen extends StatefulWidget {
  const TopupHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TopupHistoryScreen> createState() => _TopupHistoryScreenState();
}

class _TopupHistoryScreenState extends State<TopupHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _apiService = ApiService(Dio());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: appConfig.primaryColor,
        foregroundColor: appConfig.textColor,
        title: const Text(
          'Histori Topup',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: appConfig.textColor,
          labelColor: appConfig.textColor,
          unselectedLabelColor: appConfig.textColor.withOpacity(0.6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          tabs: const [
            Tab(text: 'Manual'),
            Tab(text: 'Otomatis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ManualHistoryTab(apiService: _apiService),
          _OtomatisHistoryTab(apiService: _apiService),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB HISTORI MANUAL
// ============================================================================

class _ManualHistoryTab extends StatefulWidget {
  final ApiService apiService;

  const _ManualHistoryTab({required this.apiService});

  @override
  State<_ManualHistoryTab> createState() => _ManualHistoryTabState();
}

class _ManualHistoryTabState extends State<_ManualHistoryTab>
    with AutomaticKeepAliveClientMixin {
  List<TopupManualHistory> _history = [];
  bool _isLoading = false;
  String? _errorMessage;
  static const String _cacheKey = 'topup_manual_history_cache';
  static const String _cacheTimeKey = 'topup_manual_history_cache_time';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool forceRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Cek cache terlebih dahulu
      if (!forceRefresh) {
        final cachedData = prefs.getString(_cacheKey);
        final cacheTime = prefs.getInt(_cacheTimeKey);

        if (cachedData != null && cacheTime != null) {
          final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
          // Cache valid untuk 5 menit
          if (cacheAge < 300000) {
            try {
              final List<dynamic> jsonList = json.decode(cachedData);
              final cachedHistory = jsonList
                  .map((json) => TopupManualHistory.fromJson(json))
                  .toList();

              if (mounted) {
                setState(() {
                  _history = cachedHistory;
                  _isLoading = false;
                });
              }

              // Tetap coba fetch data baru di background
              _fetchFromApi(prefs);
              return;
            } catch (e) {
              // Jika cache corrupt, lanjut ke API
              print('Cache parsing error: $e');
            }
          }
        }
      }

      // Fetch dari API
      await _fetchFromApi(prefs);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat histori: ${_getErrorMessage(e)}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchFromApi(SharedPreferences prefs) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Token tidak ditemukan';
            _isLoading = false;
          });
        }
        return;
      }

      final response = await widget.apiService
          .getTopupManualHistory(token)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Koneksi timeout. Silakan coba lagi.');
            },
          );

      if (mounted) {
        setState(() {
          _history = response.data;
          _isLoading = false;
        });
      }

      // Simpan ke cache
      try {
        final jsonList = response.data
            .map(
              (h) => {
                'trx_id': h.trxId,
                'topup': h.topup,
                'tanggal': h.tanggal,
                'status': h.status,
                'nama_bank': h.namaBank,
                'nama_rekening': h.namaRekening,
                'nomor_rekening': h.nomorRekening,
                'batas_waktu': h.batasWaktu,
                'bukti_transfer': h.buktiTransfer,
              },
            )
            .toList();

        await prefs.setString(_cacheKey, json.encode(jsonList));
        await prefs.setInt(
          _cacheTimeKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      } catch (e) {
        print('Failed to cache data: $e');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat histori: ${_getErrorMessage(e)}';
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Koneksi timeout. Periksa internet Anda.';
        case DioExceptionType.connectionError:
          return 'Tidak ada koneksi internet.';
        case DioExceptionType.badResponse:
          return 'Server error. Coba lagi nanti.';
        default:
          return 'Terjadi kesalahan jaringan.';
      }
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading && _history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadHistory(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada histori topup manual',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadHistory(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          return _ManualHistoryCard(
            history: _history[index],
            onRefresh: () => _loadHistory(forceRefresh: true),
          );
        },
      ),
    );
  }
}

class _ManualHistoryCard extends StatelessWidget {
  final TopupManualHistory history;
  final VoidCallback onRefresh;

  const _ManualHistoryCard({required this.history, required this.onRefresh});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sukses':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'ditolak':
      case 'gagal':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _formatCurrency(String amount) {
    try {
      final number = int.parse(amount);
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(number);
    } catch (e) {
      return amount;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nomor rekening disalin: $text'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(history.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status dan Tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    history.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  _formatDate(history.tanggal),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            const Divider(height: 24),

            // Nomor Transaksi
            Row(
              children: [
                Icon(Icons.receipt_long, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No. Transaksi',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        history.trxId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Jumlah Topup
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jumlah Topup',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        _formatCurrency(history.topup),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Bank Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2196F3).withOpacity(0.1),
                    const Color(0xFF1976D2).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2196F3), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.namaBank,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    history.namaRekening,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          history.nomorRekening,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            _copyToClipboard(context, history.nomorRekening),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2196F3).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.copy,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Batas Waktu
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Batas Waktu: ${_formatDate(history.batasWaktu)}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),

            // Button Kirim Struk (jika status pending)
            if (history.status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TopupKonfirmasiScreen(
                          trxId: history.trxId,
                          amount: double.tryParse(history.topup) ?? 0,
                        ),
                      ),
                    );
                    // Refresh jika ada perubahan
                    if (result == true) {
                      onRefresh();
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Kirim Struk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],

            // Info Bukti Transfer (jika sudah upload)
            if (history.buktiTransfer != null &&
                history.buktiTransfer!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[200]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bukti transfer telah dikirim',
                        style: TextStyle(
                          color: Colors.green[900],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB HISTORI OTOMATIS
// ============================================================================

class _OtomatisHistoryTab extends StatefulWidget {
  final ApiService apiService;

  const _OtomatisHistoryTab({required this.apiService});

  @override
  State<_OtomatisHistoryTab> createState() => _OtomatisHistoryTabState();
}

class _OtomatisHistoryTabState extends State<_OtomatisHistoryTab>
    with AutomaticKeepAliveClientMixin {
  List<TopupOtomatisHistory> _history = [];
  bool _isLoading = false;
  String? _errorMessage;
  static const String _cacheKey = 'topup_otomatis_history_cache';
  static const String _cacheTimeKey = 'topup_otomatis_history_cache_time';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool forceRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Cek cache terlebih dahulu
      if (!forceRefresh) {
        final cachedData = prefs.getString(_cacheKey);
        final cacheTime = prefs.getInt(_cacheTimeKey);

        if (cachedData != null && cacheTime != null) {
          final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
          // Cache valid untuk 5 menit
          if (cacheAge < 300000) {
            try {
              final List<dynamic> jsonList = json.decode(cachedData);
              final cachedHistory = jsonList
                  .map((json) => TopupOtomatisHistory.fromJson(json))
                  .toList();

              if (mounted) {
                setState(() {
                  _history = cachedHistory;
                  _isLoading = false;
                });
              }

              // Tetap coba fetch data baru di background
              _fetchFromApi(prefs);
              return;
            } catch (e) {
              // Jika cache corrupt, lanjut ke API
              print('Cache parsing error: $e');
            }
          }
        }
      }

      // Fetch dari API
      await _fetchFromApi(prefs);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat histori: ${_getErrorMessage(e)}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchFromApi(SharedPreferences prefs) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Token tidak ditemukan';
            _isLoading = false;
          });
        }
        return;
      }

      final response = await widget.apiService
          .getTopupOtomatisHistory(token)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Koneksi timeout. Silakan coba lagi.');
            },
          );

      if (mounted) {
        setState(() {
          _history = response.data;
          _isLoading = false;
        });
      }

      // Simpan ke cache
      try {
        final jsonList = response.data
            .map(
              (h) => {
                'trx_id': h.trxId,
                'jumlah_topup': h.jumlahTopup,
                'channel': h.channel,
                'source': h.source,
                'status': h.status,
                'created_at': h.createdAt,
              },
            )
            .toList();

        await prefs.setString(_cacheKey, json.encode(jsonList));
        await prefs.setInt(
          _cacheTimeKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      } catch (e) {
        print('Failed to cache data: $e');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat histori: ${_getErrorMessage(e)}';
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Koneksi timeout. Periksa internet Anda.';
        case DioExceptionType.connectionError:
          return 'Tidak ada koneksi internet.';
        case DioExceptionType.badResponse:
          return 'Server error. Coba lagi nanti.';
        default:
          return 'Terjadi kesalahan jaringan.';
      }
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading && _history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadHistory(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada histori topup otomatis',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadHistory(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          return _OtomatisHistoryCard(
            history: _history[index],
            onRefresh: () => _loadHistory(forceRefresh: true),
          );
        },
      ),
    );
  }
}

class _OtomatisHistoryCard extends StatelessWidget {
  final TopupOtomatisHistory history;
  final VoidCallback onRefresh;

  const _OtomatisHistoryCard({required this.history, required this.onRefresh});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sukses':
      case 'success':
      case 'berhasil':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'ditolak':
      case 'gagal':
      case 'failed':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(history.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      color: Colors.white,
      shadowColor: statusColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status dan Tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    history.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  _formatDate(history.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            const Divider(height: 24),

            // Nomor Transaksi (jika ada)
            if (history.trxId != null && history.trxId!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.receipt_long, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No. Transaksi',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          history.trxId!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Jumlah Topup
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jumlah Topup',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        _formatCurrency(history.jumlahTopup),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Channel & Source
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF9C27B0).withOpacity(0.15),
                    const Color(0xFF7B1FA2).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF9C27B0), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.payment, size: 20, color: Colors.purple[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          history.channel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Via ${history.source}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Button Bayar Sekarang (jika status pending)
            if (history.status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TopupOtomatisScreen(
                          initialAmount: history.jumlahTopup.toDouble(),
                        ),
                      ),
                    );
                    // Refresh jika ada perubahan
                    if (result == true) {
                      onRefresh();
                    }
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Bayar Sekarang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
