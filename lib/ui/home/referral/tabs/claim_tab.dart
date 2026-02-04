import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/app_config.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/session_manager.dart';
import '../../../../core/utils/format_util.dart';

class ClaimTab extends StatefulWidget {
  const ClaimTab({super.key});

  @override
  State<ClaimTab> createState() => _ClaimTabState();
}

class _ClaimTabState extends State<ClaimTab> {
  final ApiService _apiService = ApiService(Dio());

  bool _isLoading = true;
  bool _isClaimingPoin = false;
  bool _isClaimingSaldo = false;

  // Summary data
  int _totalPoin = 0;
  int _batasPoin = 0;
  int _totalKomisi = 0;
  int _jumlahDownline = 0;
  int _batasDownline = 0;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() => _isLoading = true);
    try {
      final token = await SessionManager.getToken();
      if (token == null) return;

      final response = await _apiService.getReferralSummary(token);
      debugPrint('[ClaimTab] Summary response: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (mounted) {
          setState(() {
            _totalPoin = (data['total_poin'] ?? 0).toInt();
            _batasPoin = (data['batas_poin'] ?? 0).toInt();
            _totalKomisi = (data['total_komisi'] ?? 0).toInt();
            _jumlahDownline = (data['jumlah_downline'] ?? 0).toInt();
            _batasDownline = (data['batas_downline'] ?? 0).toInt();
          });
        }
      }
    } catch (e) {
      debugPrint('[ClaimTab] Error fetching summary: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _claimPoin() async {
    if (_totalPoin < _batasPoin) {
      _showSnackBar(
        'Poin belum mencapai batas minimum $_batasPoin',
        isError: true,
      );
      return;
    }

    setState(() => _isClaimingPoin = true);
    try {
      final token = await SessionManager.getToken();
      if (token == null) return;

      // Backend akan menggunakan batas_poin sebagai jumlah yang diklaim
      final response = await _apiService.claimReferralPoin(token, _batasPoin);
      debugPrint('[ClaimTab] Claim poin response: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final status = response.data['status'];
        final message = response.data['message'] ?? '';

        if (status == 'success') {
          _showSnackBar(
            message.isNotEmpty ? message : 'Poin berhasil diklaim!',
          );
          await _fetchSummary(); // Refresh data
        } else {
          _showSnackBar(
            message.isNotEmpty ? message : 'Gagal klaim poin',
            isError: true,
          );
        }
      }
    } catch (e) {
      debugPrint('[ClaimTab] Error claiming poin: $e');
      _showSnackBar('Terjadi kesalahan. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _isClaimingPoin = false);
    }
  }

  Future<void> _claimSaldo() async {
    if (_jumlahDownline < _batasDownline) {
      _showSnackBar(
        'Belum mencapai target $_batasDownline downline',
        isError: true,
      );
      return;
    }
    if (_totalKomisi <= 0) {
      _showSnackBar('Tidak ada saldo komisi yang bisa diklaim', isError: true);
      return;
    }

    setState(() => _isClaimingSaldo = true);
    try {
      final token = await SessionManager.getToken();
      if (token == null) return;

      final response = await _apiService.claimReferralSaldo(token);
      debugPrint('[ClaimTab] Claim saldo response: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final status = response.data['status'];
        final message = response.data['message'] ?? '';

        if (status == 'success') {
          _showSnackBar(
            message.isNotEmpty ? message : 'Saldo berhasil diklaim!',
          );
          await _fetchSummary(); // Refresh data
        } else {
          _showSnackBar(
            message.isNotEmpty ? message : 'Gagal klaim saldo',
            isError: true,
          );
        }
      } else {
        final message = response.data?['message'] ?? 'Gagal klaim saldo';
        _showSnackBar(message, isError: true);
      }
    } catch (e) {
      debugPrint('[ClaimTab] Error claiming saldo: $e');
      _showSnackBar('Terjadi kesalahan. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _isClaimingSaldo = false);
    }
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
        onRefresh: _fetchSummary,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              _buildHeader(primaryColor),
              const SizedBox(height: 20),

              // Poin Card with Progress
              _buildPoinCard(primaryColor),
              const SizedBox(height: 16),

              // Downline Card with Progress
              _buildDownlineCard(primaryColor),
              const SizedBox(height: 16),

              // Komisi/Saldo Card
              _buildKomisiCard(primaryColor),
              const SizedBox(height: 24),

              // Claim Buttons
              _buildClaimButtons(primaryColor),
              const SizedBox(height: 20),

              // Info Section
              _buildInfoSection(primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
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
                  "Klaim Reward",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Tukarkan poin & saldo kamu!",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoinCard(Color primaryColor) {
    final progress = _batasPoin > 0
        ? (_totalPoin / _batasPoin).clamp(0.0, 1.0)
        : 0.0;
    final isComplete = _totalPoin >= _batasPoin && _batasPoin > 0;

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
                child: const Icon(
                  Icons.stars_rounded,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Total Poin",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        "Siap Klaim",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$_totalPoin",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "/ $_batasPoin poin",
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressBar(progress, Colors.amber),
          const SizedBox(height: 8),
          Text(
            "Kumpulkan $_batasPoin poin untuk bisa diklaim",
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDownlineCard(Color primaryColor) {
    final progress = _batasDownline > 0
        ? (_jumlahDownline / _batasDownline).clamp(0.0, 1.0)
        : 0.0;

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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Jumlah Downline",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$_jumlahDownline",
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "/ $_batasDownline user",
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressBar(progress, Colors.blue),
          const SizedBox(height: 8),
          Text(
            "Target: Ajak $_batasDownline teman bergabung",
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildKomisiCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
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
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Total Komisi",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            FormatUtil.formatRupiah(_totalKomisi.toString()),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Saldo dari komisi referral bisa langsung diklaim",
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress, Color color) {
    return Container(
      height: 10,
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
                    colors: [color, color.withOpacity(0.7)],
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

  Widget _buildClaimButtons(Color primaryColor) {
    // Poin bisa diklaim jika totalPoin >= batasPoin
    final canClaimPoin = _totalPoin >= _batasPoin && _batasPoin > 0;
    // Saldo bisa diklaim jika jumlahDownline >= batasDownline DAN totalKomisi > 0
    final canClaimSaldo =
        _jumlahDownline >= _batasDownline &&
        _batasDownline > 0 &&
        _totalKomisi > 0;

    return Row(
      children: [
        // Claim Poin Button
        Expanded(
          child: ElevatedButton(
            onPressed: (_isClaimingPoin || !canClaimPoin) ? null : _claimPoin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 3,
            ),
            child: _isClaimingPoin
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Klaim Poin",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 12),
        // Claim Saldo Button
        Expanded(
          child: ElevatedButton(
            onPressed: (_isClaimingSaldo || !canClaimSaldo)
                ? null
                : _claimSaldo,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 3,
            ),
            child: _isClaimingSaldo
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Klaim Saldo",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
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
                "Informasi",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            "Poin bisa diklaim setelah mencapai batas minimum",
            primaryColor,
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            "Saldo komisi langsung masuk ke saldo utama",
            primaryColor,
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            "Ajak lebih banyak teman untuk reward lebih besar",
            primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text, Color primaryColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }
}
