import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../../core/app_config.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../core/network/session_manager.dart';
import '../../../../../core/utils/format_util.dart';

class RiwayatPoinTab extends StatefulWidget {
  const RiwayatPoinTab({super.key});

  @override
  State<RiwayatPoinTab> createState() => _RiwayatPoinTabState();
}

class _RiwayatPoinTabState extends State<RiwayatPoinTab> {
  final ApiService _apiService = ApiService(Dio());

  bool _isLoading = true;
  List<Map<String, dynamic>> _riwayatList = [];

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final token = await SessionManager.getToken();
      if (token == null) return;

      final response = await _apiService.getRiwayatPoin(token);
      debugPrint('[RiwayatPoinTab] Response: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['data'] != null) {
          _riwayatList = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          _riwayatList = List<Map<String, dynamic>>.from(data);
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('[RiwayatPoinTab] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            const Text(
              "Memuat riwayat...",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_riwayatList.isEmpty) {
      return _buildEmptyState(primaryColor);
    }

    return Container(
      color: Colors.grey[50],
      child: RefreshIndicator(
        onRefresh: _fetchRiwayat,
        color: primaryColor,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _riwayatList.length + 1, // +1 for header
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildHeader(primaryColor);
            }
            final item = _riwayatList[index - 1];
            return _buildRiwayatItem(item, primaryColor);
          },
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Riwayat Poin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_riwayatList.length} transaksi",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatItem(Map<String, dynamic> item, Color primaryColor) {
    // Parse data dari API tukar_poin_member
    // Field: saldo_poin, poin, created_at
    final poin = item['poin'] ?? 0;
    final saldoPoin = item['saldo_poin'] ?? item['jumlah_saldo'] ?? 0;
    final tanggal = item['created_at'] ?? item['tanggal'] ?? '';

    final formattedDate = _formatDate(tanggal.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon - Tukar poin selalu icon swap
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tukar Poin",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "→ ${FormatUtil.formatRupiah(saldoPoin.toString())}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Poin
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "-$poin",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.stars_rounded,
                    size: 16,
                    color: Colors.amber.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                "poin",
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Belum Ada Riwayat",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Riwayat poin Anda akan muncul di sini\nsetelah melakukan transaksi",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchRiwayat,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day} ${months[date.month]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
