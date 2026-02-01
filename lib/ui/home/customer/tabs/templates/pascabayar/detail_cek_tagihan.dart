import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../core/app_config.dart';
import '../../../../../../core/network/api_service.dart';
import '../../../../../../core/network/session_manager.dart';
import '../../../../../widgets/pin_validation_dialog.dart';
import '../../../../topup_modal.dart';
import '../../../../../../features/customer/data/models/transaction_pascabayar_model.dart';
import '../transaction_pascabayar_detail_page.dart';

/// Widget global untuk cek tagihan pascabayar
/// Dapat digunakan untuk PLN, BPJS, Telkom, dll
class CekTagihanPascabayar {
  /// Show bottom sheet untuk cek tagihan
  static Future<Map<String, dynamic>?> showCekTagihan({
    required BuildContext context,
    required String productName,
    required String brand,
    required String buyerSkuCode,
    required int adminUserId,
    String? cachedCustomerNo,
    int? amount,
  }) async {
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CekTagihanBottomSheet(
        productName: productName,
        brand: brand,
        buyerSkuCode: buyerSkuCode,
        adminUserId: adminUserId,
        cachedCustomerNo: cachedCustomerNo,
        amount: amount,
      ),
    );
  }
}

class _CekTagihanBottomSheet extends StatefulWidget {
  final String productName;
  final String brand;
  final String buyerSkuCode;
  final int adminUserId;
  final String? cachedCustomerNo;
  final int? amount;

  const _CekTagihanBottomSheet({
    required this.productName,
    required this.brand,
    required this.buyerSkuCode,
    required this.adminUserId,
    this.cachedCustomerNo,
    this.amount,
  });

  @override
  State<_CekTagihanBottomSheet> createState() => _CekTagihanBottomSheetState();
}

class _CekTagihanBottomSheetState extends State<_CekTagihanBottomSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _customerNoController = TextEditingController();
  final ApiService _apiService = ApiService(Dio());

  bool _isLoading = false;
  bool _isLoadingSaldo = false;
  bool _isProcessingPayment = false;
  Map<String, dynamic>? _billData;
  String? _errorMessage;
  num _saldo = 0;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Pre-fill customer number jika ada dari cache
    if (widget.cachedCustomerNo != null) {
      _customerNoController.text = widget.cachedCustomerNo!;
    }

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Start animation
    _animationController.forward();

    // Load saldo
    _loadSaldo();

    // AUTO CEK TAGIHAN jika customer number sudah ada
    if (widget.cachedCustomerNo != null &&
        widget.cachedCustomerNo!.isNotEmpty) {
      // Delay sedikit untuk animasi selesai
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _checkBill();
        }
      });
    }
  }

  @override
  void dispose() {
    _customerNoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBill() async {
    print('🔍 [CekTagihan] _checkBill called');
    print('🔍 [CekTagihan] Customer No: ${_customerNoController.text}');

    if (_customerNoController.text.isEmpty) {
      print('⚠️ [CekTagihan] Customer number is empty');
      _showSnackbar('Masukkan nomor pelanggan terlebih dahulu', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _billData = null;
      _errorMessage = null;
    });

    print('🔄 [CekTagihan] Loading state set to true');

    try {
      final token = await SessionManager.getToken();
      print(
        '🔑 [CekTagihan] Token retrieved: [90m${token?.substring(0, 20)}...[0m',
      );

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      print('📤 [CekTagihan] Sending request with:');
      print('   - adminUserId: ${widget.adminUserId}');
      print('   - customerNo: ${_customerNoController.text.trim()}');
      print('   - productName: ${widget.productName}');
      print('   - brand: ${widget.brand}');
      print('   - buyerSkuCode: ${widget.buyerSkuCode}');
      print('   - amount: ${widget.amount}');

      Response response;
      final brandUpper = widget.brand.toUpperCase();
      if (brandUpper.contains('E-MONEY')) {
        // E-Money: gunakan endpoint khusus dan kirim amount
        response = await _apiService.checkEmoneyBill(
          adminUserId: widget.adminUserId,
          customerNo: _customerNoController.text.trim(),
          productName: widget.productName,
          brand: widget.brand,
          buyerSkuCode: widget.buyerSkuCode,
          amount: widget.amount ?? 0,
          token: token,
        );
      } else if (brandUpper.contains('BYU') || brandUpper.contains('BY.U')) {
        response = await _apiService.checkByuBill(
          adminUserId: widget.adminUserId,
          customerNo: _customerNoController.text.trim(),
          productName: widget.productName,
          brand: widget.brand,
          buyerSkuCode: widget.buyerSkuCode,
          token: token,
        );
      } else if (brandUpper.contains('INDOSAT ONLY4U')) {
        response = await _apiService.checkIndosatOnly4uBill(
          adminUserId: widget.adminUserId,
          customerNo: _customerNoController.text.trim(),
          productName: widget.productName,
          brand: widget.brand,
          buyerSkuCode: widget.buyerSkuCode,
          token: token,
        );
      } else if (brandUpper.contains('XL AXIS CUANKU')) {
        response = await _apiService.checkXlAxisCuankuBill(
          adminUserId: widget.adminUserId,
          customerNo: _customerNoController.text.trim(),
          productName: widget.productName,
          brand: widget.brand,
          buyerSkuCode: widget.buyerSkuCode,
          token: token,
        );
      } else if (brandUpper.contains('BPJS')) {
        response = await _apiService.checkBpjsBill(
          adminUserId: widget.adminUserId,
          customerNo: _customerNoController.text.trim(),
          productName: widget.productName,
          brand: widget.brand,
          buyerSkuCode: widget.buyerSkuCode,
          token: token,
        );
      } else if (brandUpper.contains('HP')) {
        response = await _apiService.checkHpPascabayarBill(
          adminUserId: widget.adminUserId,
          customerNo: _customerNoController.text.trim(),
          productName: widget.productName,
          brand: widget.brand,
          buyerSkuCode: widget.buyerSkuCode,
          token: token,
        );
      } else if (brandUpper.contains('MULTIFINANCE')) {
        response = await _apiService.checkMultifinanceBill(
          adminUserId: widget.adminUserId,
          customerNo: _customerNoController.text.trim(),
          productName: widget.productName,
          brand: widget.brand,
          buyerSkuCode: widget.buyerSkuCode,
          token: token,
        );
      } else if (brandUpper.contains('PBB')) {
        response = await _apiService.checkPbbBill(
          adminUserId: widget.adminUserId,
          customerNo: _customerNoController.text.trim(),
          productName: widget.productName,
          brand: widget.brand,
          buyerSkuCode: widget.buyerSkuCode,
          token: token,
        );
      } else if (brandUpper.contains('TV') &&
          brandUpper.contains('PASCABAYAR')) {
        response = await _apiService.checkTvPascabayarBill(
          adminUserId: widget.adminUserId,
          customerNo: _customerNoController.text.trim(),
          productName: widget.productName,
          brand: widget.brand,
          buyerSkuCode: widget.buyerSkuCode,
          token: token,
        );
      } else if (brandUpper.contains('GAS')) {
        response = await _apiService.checkGasPascabayarBill(
          adminUserId: widget.adminUserId,
          customerNo: _customerNoController.text.trim(),
          productName: widget.productName,
          brand: widget.brand,
          buyerSkuCode: widget.buyerSkuCode,
          token: token,
        );
      } else {
        response = await _apiService.checkPascabayarBill(
          adminUserId: widget.adminUserId,
          customerNo: _customerNoController.text.trim(),
          productName: widget.productName,
          brand: widget.brand,
          buyerSkuCode: widget.buyerSkuCode,
          token: token,
        );
      }

      print('📥 [CekTagihan] Response received');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // PATCH: Logic sukses untuk E-Money
        if (brandUpper.contains('E-MONEY')) {
          // Parsing sesuai hasil Postman
          final billData = {
            'customer_name': responseData['customer_name'],
            'customer_no': responseData['customer_no'],
            'periode': responseData['periode'],
            'tagihan': responseData['tagihan'],
            'admin': responseData['admin'],
            'denda': responseData['denda'] ?? 0,
            'total_tagihan': responseData['total_tagihan'],
            'lembar_tagihan': responseData['lembar_tagihan'] ?? 1,
            'ref_id': responseData['ref_id'],
            'product_name': responseData['product_name'],
            'buyer_sku_code': responseData['buyer_sku_code'],
            'brand': responseData['brand'],
            'biaya_lain': responseData['biaya_lain'],
            'alamat': responseData['alamat'],
            'jumlah_peserta': responseData['jumlah_peserta'],
          };
          print('📋 [CekTagihan] Bill Data created: $billData');
          await _cacheCustomerNo(_customerNoController.text.trim());
          if (mounted) {
            setState(() {
              _billData = billData;
              _isLoading = false;
            });
            print('✅ [CekTagihan] Bill data set in state');
            _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
          }
        } else {
          // PATCH: Logic sukses untuk HP Pascabayar dan Multifinance
          final hasStatus = responseData.containsKey('status');
          final isStatusSuccess =
              hasStatus && responseData['status'] == 'success';
          final isHpPascabayar = brandUpper.contains('HP');
          final isMultifinance = brandUpper.contains('MULTIFINANCE');
          final isHpSuccess =
              isHpPascabayar &&
              !hasStatus &&
              responseData['tagihan'] != null &&
              responseData['total_tagihan'] != null;
          final isMultifinanceSuccess =
              isMultifinance &&
              !hasStatus &&
              responseData['tagihan'] != null &&
              responseData['total_tagihan'] != null;

          if (isStatusSuccess || isHpSuccess || isMultifinanceSuccess) {
            print(
              '✅ [CekTagihan] Status is success (status field/HP/Multifinance logic), building bill data...',
            );

            final billData = {
              'customer_name': responseData['customer_name'],
              'customer_no': responseData['customer_no'],
              'periode': responseData['periode'],
              'tagihan': responseData['tagihan'],
              'admin': responseData['admin'],
              'denda': responseData['denda'] ?? 0,
              'total_tagihan': responseData['total_tagihan'],
              'lembar_tagihan': responseData['lembar_tagihan'] ?? 1,
              'ref_id': responseData['ref_id'],
              'product_name': responseData['product_name'],
              'buyer_sku_code': responseData['buyer_sku_code'],
              'brand': responseData['brand'],
              'biaya_lain': responseData['biaya_lain'],
              'alamat': responseData['alamat'],
              'jumlah_peserta': responseData['jumlah_peserta'],
            };

            print('📋 [CekTagihan] Bill Data created: $billData');

            // Cache customer number
            await _cacheCustomerNo(_customerNoController.text.trim());

            if (mounted) {
              setState(() {
                _billData = billData;
                _isLoading = false;
              });

              print('✅ [CekTagihan] Bill data set in state');
              _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
            }
          } else {
            print('❌ [CekTagihan] Status is not success');
            throw Exception(
              responseData['message'] ?? 'Gagal mengambil tagihan',
            );
          }
        }
      } else {
        print('❌ [CekTagihan] Status code is not 200: ${response.statusCode}');
        throw Exception('Gagal mengambil tagihan');
      }
    } catch (e) {
      print('❌ [CekTagihan] Error occurred: $e');
      print('❌ [CekTagihan] Error type: ${e.runtimeType}');
      String userMessage = 'Gagal mengambil tagihan. Silakan coba lagi.';
      if (e is DioException) {
        // Jika status code 500, tampilkan pesan user-friendly
        final statusCode = e.response?.statusCode;
        if (statusCode == 500) {
          userMessage =
              'Server sedang bermasalah (500). Silakan coba beberapa saat lagi.';
        } else if (e.response?.data is Map &&
            e.response?.data['message'] != null) {
          userMessage = e.response?.data['message'];
        }
      } else if (e is Exception) {
        userMessage = e.toString().replaceAll('Exception: ', '');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = userMessage;
        });
        _showSnackbar(userMessage, Colors.red);
      }
    }
  }

  Future<void> _cacheCustomerNo(String customerNo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_customer_no_${widget.brand}', customerNo);
    } catch (e) {
      // Ignore cache errors
    }
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadSaldo() async {
    if (!mounted) return;
    setState(() => _isLoadingSaldo = true);

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await _apiService.getSaldo(token);
      print('💰 [Saldo] Response: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        // Parse saldo - API bisa return string atau number
        final saldoValue = data['saldo'];
        if (mounted) {
          setState(() {
            if (saldoValue is String) {
              _saldo = num.tryParse(saldoValue) ?? 0;
            } else if (saldoValue is num) {
              _saldo = saldoValue;
            } else {
              _saldo = 0;
            }
            _isLoadingSaldo = false;
          });
          print(
            '✅ [Saldo] Loaded: Rp ${_formatCurrency(_saldo)} (raw: $saldoValue)',
          );
        }
      }
    } catch (e) {
      print('❌ [Saldo] Error: $e');
      if (mounted) {
        setState(() => _isLoadingSaldo = false);
      }
    }
  }

  Future<void> _processPayment() async {
    if (_billData == null) return;

    // Cek saldo cukup atau tidak
    final totalTagihan = _billData!['total_tagihan'] ?? 0;
    if (_saldo < totalTagihan) {
      _showSnackbar('Saldo tidak mencukupi', Colors.red);
      return;
    }

    // Show PIN validation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinValidationDialog(
        onPinSubmitted: (pin) async {
          print('🔐 [PIN] PIN received: ${pin.length} digits');
          Navigator.pop(context); // Close PIN dialog

          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => WillPopScope(
              onWillPop: () async => false,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: appConfig.primaryColor),
                      const SizedBox(height: 16),
                      const Text(
                        'Memproses Pembayaran...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mohon tunggu',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          try {
            print('🔄 [Payment] Calling _submitTransaction...');
            await _submitTransaction(pin);
            print('✅ [Payment] _submitTransaction completed');
          } catch (e) {
            print('❌ [Payment] Uncaught error in _submitTransaction: $e');
            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 28),
                      SizedBox(width: 12),
                      Text('Error Tidak Terduga'),
                    ],
                  ),
                  content: Text('Terjadi kesalahan: ${e.toString()}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            }
          }
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _submitTransaction(String pin) async {
    print('🔍 [Payment] _submitTransaction called');
    print('🔍 [Payment] _billData is null? ${_billData == null}');

    if (_billData == null) {
      print('❌ [Payment] Missing bill data!');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Text('Error'),
              ],
            ),
            content: Text('Data tagihan tidak ditemukan'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      print('🚀 [Payment] Processing transaction...');
      print('   - PIN: ${pin.substring(0, 2)}****');
      print('   - Total: Rp ${_formatCurrency(_billData!['total_tagihan'])}');
      print('   - Ref ID: ${_billData!['ref_id']}');
      print('   - Admin User ID: ${widget.adminUserId}');
      print('   - Customer No: ${_billData!['customer_no']}');
      print('   - Brand: ${_billData!['brand']}');

      print('📤 [Payment] Sending API request...');
      final response = await _apiService.processPascabayarTransaction(
        adminUserId: widget.adminUserId,
        pin: pin,
        refId: _billData!['ref_id'] ?? '',
        brand: _billData!['brand'] ?? widget.brand,
        customerNo: _billData!['customer_no'] ?? '',
        customerName: _billData!['customer_name'] ?? '',
        tagihan: _billData!['tagihan'] ?? 0,
        admin: _billData!['admin'] ?? 0,
        denda: _billData!['denda'] ?? 0,
        totalTagihan: _billData!['total_tagihan'] ?? 0,
        productName: _billData!['product_name'] ?? '',
        buyerSkuCode: _billData!['buyer_sku_code'] ?? '',
        token: token,
      );

      print('📥 [Payment] Response received!');
      print('📥 [Payment] Status Code: ${response.statusCode}');
      print('📥 [Payment] Response Data: ${response.data}');

      if (mounted) {
        setState(() => _isProcessingPayment = false);

        if (response.statusCode == 200) {
          final responseData = response.data;

          // Close loading dialog
          Navigator.pop(context);

          print('✅ [Payment] Transaction successful');

          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text('Transaksi Berhasil'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    responseData['message'] ?? 'Pembayaran sedang diproses',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  if (responseData['data'] != null) ...[
                    Text(
                      'SN: ${responseData['data']['sn'] ?? '-'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sisa Saldo: Rp ${_formatCurrency(responseData['data']['saldo'] ?? 0)}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close success dialog
                    Navigator.pop(
                      context,
                      _billData,
                    ); // Close bottom sheet with result
                  },
                  child: const Text('Tutup'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx); // Close success dialog
                    Navigator.pop(context); // Close bottom sheet

                    // Buat objek TransactionPascabayar dari response
                    final transaction = TransactionPascabayar(
                      id: 0, // ID akan di-update dari database nanti
                      userId: widget.adminUserId,
                      refId:
                          responseData['ref_id'] ?? _billData!['ref_id'] ?? '',
                      brand: _billData!['brand'] ?? '',
                      buyerSkuCode: _billData!['buyer_sku_code'] ?? '',
                      customerNo: _billData!['customer_no'] ?? '',
                      customerName: _billData!['customer_name'] ?? '',
                      nilaiTagihan: _billData!['tagihan']?.toString() ?? '0',
                      admin: _billData!['admin']?.toString() ?? '0',
                      totalPembayaranUser:
                          _billData!['total_tagihan']?.toString() ?? '0',
                      periode: _billData!['periode'] ?? '',
                      denda: _billData!['denda']?.toString() ?? '0',
                      status: responseData['status'] ?? 'Sukses',
                      daya: null,
                      lembarTagihan: _billData!['lembar_tagihan'] ?? 1,
                      meterAwal: null,
                      meterAkhir: null,
                      createdAt: DateTime.now().toString(),
                      sn: responseData['data']?['sn'] ?? '-',
                      productName: _billData!['product_name'] ?? '',
                      namaToko: '',
                    );

                    // Navigate ke detail page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionPascabayarDetailPage(
                          transaction: transaction,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.receipt_long),
                  label: const Text('Lihat Detail'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appConfig.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        } else {
          throw Exception(response.data['message'] ?? 'Transaksi gagal');
        }
      }
    } catch (e) {
      print('❌ [Payment] Error caught!');
      print('❌ [Payment] Error type: ${e.runtimeType}');
      print('❌ [Payment] Error: $e');

      if (e is DioException) {
        print('❌ [Payment] DioException details:');
        print('   - Type: ${e.type}');
        print('   - Message: ${e.message}');
        print('   - Response Status: ${e.response?.statusCode}');
        print('   - Response Data: ${e.response?.data}');
      }

      if (mounted) {
        // Close loading dialog first
        Navigator.pop(context);

        setState(() => _isProcessingPayment = false);

        String errorMessage = e.toString().replaceAll('Exception: ', '');
        if (e is DioException && e.response?.data != null) {
          errorMessage = e.response?.data['message'] ?? errorMessage;
          print('❌ [Payment] Extracted error message: $errorMessage');
        }

        print('❌ [Payment] Error message: $errorMessage');

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Text('Transaksi Gagal'),
              ],
            ),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  String _formatCurrency(dynamic value) {
    final intValue = value is int ? value : int.tryParse(value.toString()) ?? 0;
    return intValue.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _getIconForBrand() {
    final brandLower = widget.brand.toLowerCase();
    if (brandLower.contains('pln')) return '⚡';
    if (brandLower.contains('bpjs')) return '🏥';
    if (brandLower.contains('telkom')) return '📞';
    if (brandLower.contains('pdam')) return '💧';
    return '📄';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
            ),
            child: Transform.translate(
              offset: Offset(0, mediaQuery.size.height * _slideAnimation.value),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      _getIconForBrand(),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.brand.toUpperCase().contains('E-MONEY')
                              ? 'Detail Transaksi E-Money'
                              : 'Cek Tagihan ${widget.productName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.brand,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPadding + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Loading Indicator (ditampilkan saat sedang cek tagihan)
                    if (_isLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: primaryColor),
                              const SizedBox(height: 16),
                              Text(
                                'Mengecek tagihan...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ID: ${_customerNoController.text}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Error Message (jika ada error)
                    if (_errorMessage != null && !_isLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Gagal Mengecek Tagihan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ID Pelanggan: ${_customerNoController.text}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _checkBill,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Coba Lagi'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Tutup'),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Bill Details (jika tagihan sudah ditemukan)
                    if (_billData != null && !_isLoading) ...[
                      _buildBillDetails(primaryColor),
                      const SizedBox(height: 16),
                      _buildConfirmButton(primaryColor),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillDetails(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Detail Tagihan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Success',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Ref ID
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ref ID',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _billData!['ref_id'] ?? '-',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Detail Information (Compact)
                _buildCompactInfoRow(
                  icon: Icons.person,
                  label: 'Nama',
                  value: (_billData!['customer_name'] ?? '-').toString(),
                  primaryColor: primaryColor,
                ),
                const Divider(height: 16, thickness: 0.5),
                _buildCompactInfoRow(
                  icon: Icons.badge,
                  label: 'ID Pelanggan',
                  value: (_billData!['customer_no'] ?? '-').toString(),
                  primaryColor: primaryColor,
                ),
                const Divider(height: 16, thickness: 0.5),
                _buildCompactInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Periode',
                  value: (_billData!['periode'] ?? '-').toString(),
                  primaryColor: primaryColor,
                ),
                const Divider(height: 16, thickness: 0.5),
                _buildCompactInfoRow(
                  icon: Icons.receipt,
                  label: 'Lembar',
                  value: (_billData!['lembar_tagihan'] ?? 1).toString(),
                  primaryColor: primaryColor,
                ),

                const SizedBox(height: 12),
                Container(height: 1, color: Colors.grey[300]),
                const SizedBox(height: 12),

                // Financial Details (Compact)
                _buildCompactAmountRow(
                  label: (widget.brand.toUpperCase().contains('E-MONEY'))
                      ? 'Nominal'
                      : 'Tagihan',
                  amount: _billData!['tagihan'] ?? 0,
                ),
                const SizedBox(height: 8),
                _buildCompactAmountRow(
                  label: 'Admin',
                  amount: _billData!['admin'] ?? 0,
                ),
                const SizedBox(height: 8),
                _buildCompactAmountRow(
                  label: 'Denda',
                  amount: _billData!['denda'] ?? 0,
                  isDenda: true,
                ),
                const SizedBox(height: 8),
                if (_billData!['biaya_lain'] != null)
                  _buildCompactAmountRow(
                    label: 'Biaya Lain',
                    amount: _billData!['biaya_lain'] ?? 0,
                  ),

                const SizedBox(height: 12),
                Container(height: 1, color: primaryColor.withOpacity(0.3)),
                const SizedBox(height: 12),

                // Total (Prominent)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Tagihan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Rp ${_formatCurrency(_billData!['total_tagihan'] ?? 0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color primaryColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryColor.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactAmountRow({
    required String label,
    required dynamic amount,
    bool isDenda = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDenda ? Colors.red[700] : Colors.grey[700],
          ),
        ),
        Text(
          'Rp ${_formatCurrency(amount)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDenda ? Colors.red[700] : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(Color primaryColor) {
    final totalTagihan = _billData?['total_tagihan'] ?? 0;
    final isSaldoCukup = _saldo >= totalTagihan;

    return Column(
      children: [
        // Info Saldo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isLoadingSaldo
                ? Colors.grey[100]
                : isSaldoCukup
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isLoadingSaldo
                  ? Colors.grey[300]!
                  : isSaldoCukup
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isLoadingSaldo
                    ? Icons.hourglass_empty
                    : isSaldoCukup
                    ? Icons.check_circle
                    : Icons.warning,
                color: _isLoadingSaldo
                    ? Colors.grey[600]
                    : isSaldoCukup
                    ? Colors.green
                    : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Anda',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _isLoadingSaldo
                        ? Text(
                            'Memuat...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          )
                        : Text(
                            'Rp ${_formatCurrency(_saldo)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSaldoCukup
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                  ],
                ),
              ),
              if (!_isLoadingSaldo && !isSaldoCukup)
                InkWell(
                  onTap: () {
                    // Close bottom sheet dan buka topup modal
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => TopupModal(
                        primaryColor: appConfig.primaryColor,
                        apiService: _apiService,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Topup',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Payment Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoadingSaldo
                ? null
                : isSaldoCukup
                ? (_isProcessingPayment ? null : _processPayment)
                : () {
                    // Close bottom sheet dan buka topup modal
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => TopupModal(
                        primaryColor: appConfig.primaryColor,
                        apiService: _apiService,
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSaldoCukup ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: _isProcessingPayment
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSaldoCukup ? Icons.lock_outline : Icons.add_card,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isSaldoCukup
                            ? 'Lanjut ke Pembayaran'
                            : 'Topup Sekarang',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
