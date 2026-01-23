import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/app_config.dart';
import '../../../../../features/customer/data/models/product_prabayar_model.dart';
import '../../../../../features/customer/data/models/transaction_response_model.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../core/network/session_manager.dart';
import '../../../pin.dart';
import '../../../topup_modal.dart';
import '../../../../../../ui/widgets/pin_validation_dialog.dart';
import 'transaction_success_page.dart';

class DetailPulsaPage extends StatefulWidget {
  final ProductPrabayar product;
  final String phone;

  const DetailPulsaPage({
    super.key,
    required this.product,
    required this.phone,
  });

  @override
  State<DetailPulsaPage> createState() => _DetailPulsaPageState();
}

class _DetailPulsaPageState extends State<DetailPulsaPage> {
  late ApiService _apiService;
  int _userSaldo = 0;
  bool _isLoadingSaldo = false;
  bool _isProcessing = false;
  bool _isSaldoCukup = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Dio());
    _loadSaldo();
  }

  Future<void> _loadSaldo() async {
    if (!mounted) return;
    setState(() => _isLoadingSaldo = true);

    try {
      final String? token = await SessionManager.getToken();

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Token tidak ditemukan')),
          );
        }
        return;
      }

      final response = await _apiService.getSaldo(token);

      if (response.statusCode == 200) {
        final saldoResponse = SaldoResponse.fromJson(response.data);
        if (mounted) {
          setState(() {
            _userSaldo = saldoResponse.saldo;
            _isSaldoCukup = _userSaldo >= widget.product.totalHarga;
            _isLoadingSaldo = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saldo: $e');
      if (mounted) setState(() => _isLoadingSaldo = false);
    }
  }

  void _showTopupModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TopupModal(
        primaryColor: appConfig.primaryColor,
        apiService: _apiService,
      ),
    );
  }

  Future<void> _checkPinAndProcess() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final String? token = await SessionManager.getToken();

      if (token == null) {
        _showError('Token tidak ditemukan');
        return;
      }

      // Cek status PIN
      final pinStatusResponse = await _apiService.checkPinStatus(token);

      if (pinStatusResponse.statusCode != 200) {
        _showError('Gagal memeriksa status PIN');
        return;
      }

      final pinStatus = PinStatusResponse.fromJson(pinStatusResponse.data);

      if (!pinStatus.hasPin) {
        // PIN belum ada, arahkan ke buat PIN
        if (mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PinPage(isFromTransaction: true, onPinCreated: () {}),
            ),
          );

          // Jika PIN berhasil dibuat, lanjut proses transaksi
          if (result == true && mounted) {
            setState(() => _isProcessing = false);
            _showPinValidationDialog(token);
          } else {
            setState(() => _isProcessing = false);
          }
        }
      } else {
        // PIN sudah ada, minta PIN dari user
        if (mounted) {
          setState(() => _isProcessing = false);
          _showPinValidationDialog(token);
        }
      }
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
    }
  }

  void _showPinValidationDialog(String token) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinValidationDialog(
        onPinSubmitted: (pin) async {
          Navigator.pop(context);
          await _validateAndProcessTransaction(pin, token);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _validateAndProcessTransaction(String pin, String token) async {
    setState(() => _isProcessing = true);

    try {
      // Validasi PIN
      final pinValidationResponse = await _apiService.validatePin(pin, token);

      if (pinValidationResponse.statusCode != 200) {
        _showError('Gagal memvalidasi PIN');
        return;
      }

      final pinValidation = PinValidationResponse.fromJson(
        pinValidationResponse.data,
      );

      if (!pinValidation.isValid) {
        _showError(pinValidation.message);
        return;
      }

      // PIN valid, proses transaksi
      await _processTransaction(pin, token);
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _processTransaction(String pin, String token) async {
    try {
      final response = await _apiService.processPrabayarTransaction(
        pin: pin,
        category: widget.product.category,
        sku: widget.product.skuCode,
        productName: widget.product.productName,
        phoneNumber: widget.phone,
        discount: widget.product.produkDiskon,
        total: widget.product.totalHarga,
        token: token,
      );

      if (response.statusCode == 200) {
        final transaction = TransactionResponse.fromJson(response.data);

        if (transaction.status) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionSuccessPage(
                  productName: widget.product.productName,
                  phoneNumber: widget.phone,
                  totalPrice: widget.product.totalHarga,
                  transaction: transaction,
                ),
              ),
            );
          }
        } else {
          _showError(transaction.message);
        }
      } else {
        _showError(response.data['message'] ?? 'Gagal memproses transaksi');
      }
    } catch (e) {
      _showError('Terjadi kesalahan saat proses transaksi: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = appConfig.primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Konfirmasi Bayar",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection("Informasi Nomor", [
                  _rowInfo("Nomor Tujuan", widget.phone),
                  _rowInfo("Operator", widget.product.brand),
                ]),
                const SizedBox(height: 16),
                _buildSection("Detail Produk", [
                  _rowInfo("Nama Produk", widget.product.productName),
                  _rowInfo("Deskripsi", widget.product.description),
                  _rowInfo("SKU", widget.product.skuCode),
                ]),
                const SizedBox(height: 16),
                _buildSection("Rincian Harga", [
                  _rowInfo(
                    "Harga Produk",
                    "Rp ${widget.product.totalHarga + widget.product.produkDiskon}",
                  ),
                  if (widget.product.produkDiskon > 0)
                    _rowInfo(
                      "Diskon",
                      "- Rp ${widget.product.produkDiskon}",
                      valueColor: Colors.green,
                    ),
                  const Divider(),
                  _rowInfo(
                    "Total Bayar",
                    "Rp ${widget.product.totalHarga}",
                    isBold: true,
                    valueColor: primaryColor,
                  ),
                ]),
                const SizedBox(height: 16),
                // Saldo Section
                _buildSection("Saldo Anda", [
                  _isLoadingSaldo
                      ? const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _rowInfo(
                          "Saldo Tersedia",
                          "Rp $_userSaldo",
                          isBold: true,
                          valueColor: _isSaldoCukup ? Colors.green : Colors.red,
                        ),
                ]),
                // Alert jika saldo tidak cukup
                if (!_isLoadingSaldo && !_isSaldoCukup)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Saldo Tidak Cukup',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Anda membutuhkan Rp ${widget.product.totalHarga - _userSaldo} lagi',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _isProcessing || _isLoadingSaldo
                      ? null
                      : (_isSaldoCukup ? _checkPinAndProcess : _showTopupModal),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSaldoCukup
                        ? primaryColor
                        : Colors.orange,
                    disabledBackgroundColor: Colors.grey[300],
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          _isSaldoCukup ? "BAYAR SEKARANG" : "TOPUP SALDO",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _rowInfo(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
