import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/session_manager.dart';

class TopupTripay extends StatefulWidget {
  final int amount;
  final Color primaryColor;
  final ApiService apiService;

  const TopupTripay({
    super.key,
    required this.amount,
    required this.primaryColor,
    required this.apiService,
  });

  @override
  State<TopupTripay> createState() => _TopupTripayState();
}

class _TopupTripayState extends State<TopupTripay> {
  bool _isLoadingChannels = true;
  bool _isCreatingTransaction = false;
  List<dynamic> _paymentChannels = [];
  Map<String, dynamic>? _selectedChannel;
  String? _errorMessage;
  Map<String, dynamic>? _transactionData;
  Timer? _paymentStatusTimer;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadPaymentChannels();
  }

  @override
  void dispose() {
    _paymentStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPaymentChannels() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await widget.apiService.getTripayChannels(
        token: token,
        amount: widget.amount,
      );

      if (mounted) {
        setState(() {
          _paymentChannels = response['data'] ?? [];
          _isLoadingChannels = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoadingChannels = false;
        });
      }
    }
  }

  Future<void> _createTransaction() async {
    if (_selectedChannel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih metode pembayaran terlebih dahulu'),
        ),
      );
      return;
    }

    setState(() => _isCreatingTransaction = true);

    try {
      final token = await SessionManager.getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await widget.apiService.createTripayTransaction(
        token: token,
        method: _selectedChannel!['code'],
        amount: widget.amount,
      );

      if (mounted && response['success'] == true) {
        setState(() {
          _transactionData = response['data'];
          _isCreatingTransaction = false;
        });

        debugPrint('✅ Transaction created successfully');
        debugPrint('📋 Reference: ${_transactionData!['reference']}');
        debugPrint('💰 Amount: ${_transactionData!['amount']}');

        // Start polling untuk check status pembayaran
        _startPaymentStatusPolling();
      } else {
        throw Exception(response['message'] ?? 'Gagal membuat transaksi');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingTransaction = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label berhasil disalin')));
  }

  void _startPaymentStatusPolling() {
    debugPrint('🔄 Starting payment status polling...');
    // Check status setiap 5 detik
    _paymentStatusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      debugPrint('⏰ Polling check at ${DateTime.now()}');
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_transactionData == null) {
      debugPrint('⚠️ Transaction data is null');
      return;
    }

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        debugPrint('⚠️ Token is null');
        return;
      }

      final reference = _transactionData!['reference'] ?? '';
      if (reference.isEmpty) {
        debugPrint('⚠️ Reference is empty');
        return;
      }

      debugPrint('🔍 Checking payment status for: $reference');

      final response = await widget.apiService.checkTripayPaymentStatus(
        token: token,
        reference: reference,
      );

      debugPrint('📥 Response: $response');

      if (response['success'] == true && response['data'] != null) {
        final status = response['data']['status'];
        debugPrint('📊 Current status: $status');

        if (status == 'PAID' && mounted) {
          debugPrint('✅ Payment PAID! Showing dialog...');
          // Stop polling
          _paymentStatusTimer?.cancel();

          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Pembayaran Berhasil!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Saldo Anda telah ditambahkan',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );

          // Auto close dialog dan redirect setelah 2 detik
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              // Close dialog
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }

              // Pop halaman topup_tripay (kembali ke home)
              // topup_otomatis sudah di-replace, jadi cukup 1x pop
              Future.microtask(() {
                if (mounted && Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              });
            }
          });
        }
      } else {
        debugPrint('⚠️ Response success=false or data is null');
      }
    } catch (e) {
      // Silent error, akan retry di polling berikutnya
      debugPrint('❌ Error checking payment status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
        elevation: 0,
        title: const Text('Pembayaran Tripay'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _transactionData != null
          ? _buildPaymentInstructions()
          : _buildChannelSelection(),
      bottomNavigationBar:
          _transactionData == null &&
              !_isLoadingChannels &&
              _errorMessage == null
          ? _buildBottomButton()
          : null,
    );
  }

  Widget _buildChannelSelection() {
    if (_isLoadingChannels) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: widget.primaryColor),
            const SizedBox(height: 20),
            const Text('Memuat metode pembayaran...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                const Text(
                  'Nominal Top Up',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormatter.format(widget.amount),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pilih Metode Pembayaran',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._paymentChannels.map((channel) {
            final isSelected = _selectedChannel?['code'] == channel['code'];
            final totalFee =
                (channel['total_fee']?['customer'] as num?)?.toDouble() ?? 0;
            final totalAmount = widget.amount + totalFee;

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isSelected ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? widget.primaryColor : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () => setState(() => _selectedChannel = channel),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (channel['icon_url'] != null)
                        Image.network(
                          channel['icon_url'],
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.payment, size: 40),
                        )
                      else
                        const Icon(Icons.payment, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channel['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Biaya: ${currencyFormatter.format(totalFee)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Total: ${currencyFormatter.format(totalAmount)}',
                              style: TextStyle(
                                color: widget.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: widget.primaryColor),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isCreatingTransaction || _selectedChannel == null
                ? null
                : _createTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: _isCreatingTransaction
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Lanjutkan Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    final reference = _transactionData!['reference'] ?? '';
    final paymentName = _transactionData!['payment_name'] ?? '';
    final amount = (_transactionData!['amount'] as num?)?.toInt() ?? 0;
    final fee = (_transactionData!['total_fee'] as num?)?.toInt() ?? 0;
    final totalAmount = amount + fee;
    final paymentCode = _transactionData!['pay_code'] ?? '';
    final qrUrl = _transactionData!['qr_url'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Polling indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Menunggu pembayaran...',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Transaksi Berhasil Dibuat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Referensi: $reference',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoCard('Metode Pembayaran', paymentName),
          _buildInfoCard(
            'Total Pembayaran',
            currencyFormatter.format(totalAmount),
            highlight: true,
          ),
          if (paymentCode.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Kode Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 31, 30, 30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      paymentCode,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        _copyToClipboard(paymentCode, 'Kode pembayaran'),
                    icon: const Icon(Icons.copy),
                    color: widget.primaryColor,
                  ),
                ],
              ),
            ),
          ],
          if (qrUrl != null) ...[
            const SizedBox(height: 16),
            const Text(
              'QR Code',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Image.network(
                  qrUrl,
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error, size: 200),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Penting!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Selesaikan pembayaran sebelum batas waktu\n'
                  '• Pastikan jumlah yang dibayar sesuai\n'
                  '• Simpan bukti pembayaran\n'
                  '• Saldo akan otomatis masuk setelah pembayaran berhasil',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                // Cancel timer sebelum keluar
                _paymentStatusTimer?.cancel();

                // Pop kembali ke home (topup_otomatis sudah di-replace)
                if (mounted && Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.check),
              label: const Text(
                'Selesai',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, {bool highlight = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: highlight
            ? widget.primaryColor.withOpacity(0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? widget.primaryColor : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 20 : 16,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              color: highlight ? widget.primaryColor : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
