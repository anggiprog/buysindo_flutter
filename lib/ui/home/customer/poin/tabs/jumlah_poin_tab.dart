import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../../core/app_config.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../core/network/session_manager.dart';
import '../../../../../core/utils/format_util.dart';

class JumlahPoinTab extends StatefulWidget {
  const JumlahPoinTab({super.key});

  @override
  State<JumlahPoinTab> createState() => _JumlahPoinTabState();
}

class _JumlahPoinTabState extends State<JumlahPoinTab> {
  final ApiService _apiService = ApiService(Dio());

  bool _isLoading = true;
  bool _isClaiming = false;

  // Data poin
  int _totalPoin = 0;
  int _jumlahPoin = 0; // minimum poin untuk tukar
  int _jumlahSaldo = 0; // saldo yang didapat
  int _adminUserId = 0; // admin_user_id untuk tukar poin

  @override
  void initState() {
    super.initState();
    _fetchPoinData();
  }

  Future<void> _fetchPoinData() async {
    setState(() => _isLoading = true);
    try {
      // Get admin_user_id from session
      final adminUserId = await SessionManager.getAdminUserId();
      _adminUserId = adminUserId ?? 0;
      final token = await SessionManager.getToken();
      if (token == null) return;

      final response = await _apiService.getPoinSummary(token);
      debugPrint('[JumlahPoinTab] Response: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (mounted) {
          setState(() {
            _totalPoin = (data['total_poin'] ?? 0).toInt();
            _jumlahPoin = (data['jumlah_poin'] ?? 0).toInt();
            // jumlah_saldo bisa string atau int
            final saldoValue = data['jumlah_saldo'];
            if (saldoValue is String) {
              _jumlahSaldo = int.tryParse(saldoValue) ?? 0;
            } else {
              _jumlahSaldo = (saldoValue ?? 0).toInt();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[JumlahPoinTab] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _tukarPoin() async {
    if (_totalPoin < _jumlahPoin) {
      _showSnackBar(
        'Poin tidak mencukupi. Butuh $_jumlahPoin poin untuk tukar.',
        isError: true,
      );
      return;
    }

    // Konfirmasi dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: appConfig.primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Konfirmasi Tukar',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apakah Anda yakin ingin menukar poin?',
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildConfirmRow('Poin ditukar', '$_jumlahPoin poin'),
                  const SizedBox(height: 8),
                  _buildConfirmRow(
                    'Saldo didapat',
                    FormatUtil.formatRupiah(_jumlahSaldo.toString()),
                  ),
                  const Divider(color: Colors.amber),
                  _buildConfirmRow(
                    'Sisa poin',
                    '${_totalPoin - _jumlahPoin} poin',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: appConfig.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ya, Tukar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isClaiming = true);
    try {
      final token = await SessionManager.getToken();
      if (token == null) return;

      final response = await _apiService.claimPoinToSaldo(
        token,
        _jumlahPoin,
        _jumlahSaldo,
        _adminUserId,
      );
      debugPrint('[JumlahPoinTab] Claim response: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final message = response.data['message'] ?? '';

        if (message.toLowerCase().contains('berhasil')) {
          _showSnackBar(
            message.isNotEmpty
                ? message
                : 'Poin berhasil ditukar dengan saldo!',
          );
          await _fetchPoinData(); // Refresh data
        } else {
          _showSnackBar(
            message.isNotEmpty ? message : 'Gagal menukar poin',
            isError: true,
          );
        }
      }
    } catch (e) {
      debugPrint('[JumlahPoinTab] Error claiming: $e');
      _showSnackBar('Terjadi kesalahan. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  Widget _buildConfirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
            const Text("Memuat data...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Container(
      color: Colors.grey[50],
      child: RefreshIndicator(
        onRefresh: _fetchPoinData,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header Card
              _buildHeaderCard(primaryColor),
              const SizedBox(height: 20),

              // Total Poin Card
              _buildTotalPoinCard(primaryColor),
              const SizedBox(height: 16),

              // Progress Card
              _buildProgressCard(primaryColor),
              const SizedBox(height: 16),

              // Reward Card
              _buildRewardCard(primaryColor),
              const SizedBox(height: 24),

              // Tukar Button
              _buildTukarButton(primaryColor),
              const SizedBox(height: 20),

              // Info Section
              _buildInfoSection(primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amber.shade600, Colors.orange.shade500],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tukar Poin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Kumpulkan poin & tukar dengan saldo!",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPoinCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Total Poin Anda",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 36),
              const SizedBox(width: 8),
              Text(
                FormatUtil.formatNumber(_totalPoin.toString()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  " poin",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(Color primaryColor) {
    final progress = _jumlahPoin > 0
        ? (_totalPoin / _jumlahPoin).clamp(0.0, 1.0)
        : 0.0;
    final isComplete = _totalPoin >= _jumlahPoin && _jumlahPoin > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: Colors.amber.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Progress Tukar Poin",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Tercapai!",
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FormatUtil.formatNumber(_totalPoin.toString()),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isComplete ? Colors.green : Colors.amber.shade700,
                    ),
                  ),
                  const Text(
                    "poin terkumpul",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${(progress * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isComplete ? Colors.green : Colors.grey.shade700,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    FormatUtil.formatNumber(_jumlahPoin.toString()),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const Text(
                    "poin dibutuhkan",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(progress, Colors.amber),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isComplete ? Colors.green.shade50 : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isComplete
                      ? Icons.celebration_rounded
                      : Icons.info_outline_rounded,
                  color: isComplete
                      ? Colors.green.shade600
                      : Colors.amber.shade700,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isComplete
                        ? "Selamat! Poin Anda sudah cukup untuk ditukar dengan saldo."
                        : "Kumpulkan ${_jumlahPoin - _totalPoin} poin lagi untuk menukar dengan saldo.",
                    style: TextStyle(
                      fontSize: 12,
                      color: isComplete
                          ? Colors.green.shade700
                          : Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress, Color color) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: double.infinity,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: progress >= 1.0
                        ? [Colors.green, Colors.green.shade400]
                        : [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(Color primaryColor) {
    final canClaim = _totalPoin >= _jumlahPoin && _jumlahPoin > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: canClaim
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.grey.shade400, Colors.grey.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (canClaim ? Colors.green : Colors.grey).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Hadiah Saldo",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (canClaim)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_open, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "Tersedia",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: Colors.white70, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "Terkunci",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            FormatUtil.formatRupiah(_jumlahSaldo.toString()),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            canClaim
                ? "Tukar $_jumlahPoin poin untuk mendapatkan saldo ini!"
                : "Kumpulkan $_jumlahPoin poin untuk membuka hadiah ini",
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTukarButton(Color primaryColor) {
    final canClaim = _totalPoin >= _jumlahPoin && _jumlahPoin > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isClaiming || !canClaim) ? null : _tukarPoin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade600,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canClaim ? 5 : 0,
        ),
        child: _isClaiming
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    canClaim ? Icons.swap_horiz_rounded : Icons.lock_rounded,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    canClaim
                        ? "Tukar $_jumlahPoin Poin → ${FormatUtil.formatRupiah(_jumlahSaldo.toString())}"
                        : "Poin Belum Mencukupi",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoSection(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                "Cara Mendapatkan Poin",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            "Lakukan transaksi",
            "Setiap transaksi berhasil akan mendapat poin",
          ),
          _buildInfoItem(
            "Kumpulkan poin",
            "Minimal $_jumlahPoin poin untuk ditukar",
          ),
          _buildInfoItem(
            "Tukar dengan saldo",
            "Dapatkan ${FormatUtil.formatRupiah(_jumlahSaldo.toString())} saldo",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.amber.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
