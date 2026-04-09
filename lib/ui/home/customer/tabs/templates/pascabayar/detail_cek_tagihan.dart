import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../core/app_config.dart';
import '../../../../../../core/network/api_service.dart';
import '../../../../../../core/network/session_manager.dart';
import '../../../../../../core/security/totp_service.dart';
import '../../../../../widgets/pin_validation_dialog.dart';
import '../../../../topup_modal.dart';
import '../../../../topup/topup_manual.dart';
import '../../../../topup/topup_otomatis.dart';
import '../../../../../../features/customer/data/models/transaction_pascabayar_model.dart';
import '../transaction_pascabayar_detail_page.dart';
import '../../transaction_history_tab.dart';

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
    int? markupMember,
    int? adminFee,
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
        markupMember: markupMember,
        adminFee: adminFee,
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
  final int? markupMember;
  final int? adminFee;

  const _CekTagihanBottomSheet({
    required this.productName,
    required this.brand,
    required this.buyerSkuCode,
    required this.adminUserId,
    this.cachedCustomerNo,
    this.amount,
    this.markupMember,
    this.adminFee,
  });

  @override
  State<_CekTagihanBottomSheet> createState() => _CekTagihanBottomSheetState();
}

class _CekTagihanBottomSheetState extends State<_CekTagihanBottomSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _customerNoController = TextEditingController();
  final ApiService _apiService = ApiService.auto(Dio());

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
    if (_customerNoController.text.isEmpty) {
      _showSnackbar('Masukkan nomor pelanggan terlebih dahulu', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _billData = null;
      _errorMessage = null;
    });

    try {
      final token = await SessionManager.getToken();
      print(
        '🔑 [CekTagihan] Token retrieved: [90m${token?.substring(0, 20)}...[0m',
      );

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      print('   - customerNo: ${_customerNoController.text.trim()}');

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
      } else if (brandUpper.contains('BPJS') &&
          brandUpper.contains('KETENAGAKERJAAN')) {
        print('   - customerNo: ${_customerNoController.text.trim()}');

        response = await _apiService.checkBpjsKetenagakerjaanBill(
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
      } else if (brandUpper.contains('INTERNET') &&
          brandUpper.contains('PASCABAYAR')) {
        response = await _apiService.checkInternetPascabayarBill(
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
      } else if (brandUpper.contains('NONTAGLIS')) {
        // PLN NONTAGLIS uses different endpoint

        response = await _apiService.checkPlnNontaglisBill(
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

      // NEW: Extract data from nested "data" object (Digiflazz format)
      final responseData = response.data;
      dynamic billResponseData = responseData;

      // Check if response has nested "data" structure (Digiflazz format)
      if (responseData is Map && responseData.containsKey('data')) {
        billResponseData = responseData['data'];
      }

      // DEBUG: Show extracted response structure
      print(
        '📥 [CekTagihan] billResponseData keys: ${(billResponseData is Map) ? billResponseData.keys.toList() : 'N/A'}',
      );
      if (billResponseData is Map) {
        print('   - Has desc: ${billResponseData.containsKey('desc')}');

        if (billResponseData['desc'] is Map) {
          final desc = billResponseData['desc'] as Map;
          print('   - desc keys: ${desc.keys.toList()}');
          print('   - Has detail: ${desc.containsKey('detail')}');
          if (desc.containsKey('detail')) {
            if (desc['detail'] is List) {
              print('   - detail length: ${(desc['detail'] as List).length}');
            }
          }
        }
      }

      // Debug PLN NONTAGLIS specific
      if (brandUpper.contains('NONTAGLIS')) {}

      if (response.statusCode == 200) {
        // PATCH: Logic sukses untuk PLN NONTAGLIS (Digiflazz format)
        if (brandUpper.contains('NONTAGLIS')) {
          final hasStatus = billResponseData.containsKey('status');
          final isStatusSuccess =
              hasStatus && billResponseData['status'] == 'Sukses';

          if (isStatusSuccess) {
            // PLN NONTAGLIS with Digiflazz format
            final descData = billResponseData['desc'] ?? {};
            final price = billResponseData['price'] ?? 0;
            final admin = billResponseData['admin'] ?? 0;
            final totalTagihan =
                billResponseData['selling_price'] ?? (price + admin);

            final billData = {
              'customer_name': billResponseData['customer_name'],
              'customer_no': billResponseData['customer_no'],
              'periode':
                  descData['tanggal_registrasi'], // Use tanggal_registrasi as periode
              'tagihan': price, // Map price to tagihan
              'admin': admin,
              'denda': 0, // No denda for NONTAGLIS
              'total_tagihan': totalTagihan,
              'lembar_tagihan': descData['lembar_tagihan'] ?? 1,
              'ref_id': billResponseData['ref_id'],
              'product_name': billResponseData['buyer_sku_code'],
              'buyer_sku_code': billResponseData['buyer_sku_code'],
              'brand': billResponseData['buyer_sku_code'],
              'biaya_lain': null,
              'alamat': null,
              'jumlah_peserta': null,
              // PLN NONTAGLIS specific fields from desc
              'transaksi_type': descData['transaksi'],
              'no_registrasi': descData['no_registrasi'],
              'tgl_registrasi': descData['tanggal_registrasi'],
              'sn': billResponseData['sn'],
            };

            await _cacheCustomerNo(_customerNoController.text.trim());

            if (mounted) {
              setState(() {
                _billData = billData;
                _isLoading = false;
              });

              _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
            }
          } else {
            throw Exception(
              billResponseData['message'] ?? 'Gagal mengambil tagihan',
            );
          }
        }
        // PATCH: Logic sukses untuk E-Money (Digiflazz format)
        else if (brandUpper.contains('E-MONEY')) {
          final hasStatus = billResponseData.containsKey('status');
          final isStatusSuccess =
              hasStatus && billResponseData['status'] == 'Sukses';

          if (isStatusSuccess) {
            // E-Money with Digiflazz format
            final price = billResponseData['price'] ?? 0;
            final admin = billResponseData['admin'] ?? 0;
            final totalTagihan =
                billResponseData['selling_price'] ?? (price + admin);

            final billData = {
              'customer_name': billResponseData['customer_name'],
              'customer_no': billResponseData['customer_no'],
              'periode': 1, // E-Money doesn't have periode
              'tagihan': price,
              'admin': admin,
              'denda': 0,
              'total_tagihan': totalTagihan,
              'lembar_tagihan':
                  billResponseData['desc']?['lembar_tagihan'] ?? 1,
              'ref_id': billResponseData['ref_id'],
              'product_name': billResponseData['buyer_sku_code'],
              'buyer_sku_code': billResponseData['buyer_sku_code'],
              'brand': billResponseData['buyer_sku_code'],
              'biaya_lain': 0,
              'alamat': null,
              'jumlah_peserta': null,
              'sn': billResponseData['sn'],
            };

            await _cacheCustomerNo(_customerNoController.text.trim());

            if (mounted) {
              setState(() {
                _billData = billData;
                _isLoading = false;
              });

              _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
            }
          } else {
            throw Exception(
              billResponseData['message'] ?? 'Gagal mengambil tagihan',
            );
          }
        } else {
          // PATCH: Logic sukses untuk HP Pascabayar, Multifinance, Internet Pascabayar, BPJS, dan PLN Pascabayar (Digiflazz format)
          final hasStatus = billResponseData.containsKey('status');
          final isStatusSuccess =
              hasStatus && billResponseData['status'] == 'Sukses';
          final isHpPascabayar = brandUpper.contains('HP');
          final isMultifinance = brandUpper.contains('MULTIFINANCE');
          final isInternetPascabayar = brandUpper.contains('INTERNET');
          final isBpjsKetenagakerjaan =
              brandUpper.contains('BPJS') &&
              brandUpper.contains('KETENAGAKERJAAN');
          final isBpjsKesehatan =
              brandUpper.contains('BPJS') &&
              !brandUpper.contains('KETENAGAKERJAAN');
          final isPLNPascabayar =
              brandUpper.contains('PLN') && !brandUpper.contains('NONTAGLIS');
          final isPdam = brandUpper.contains('PDAM');
          final isPbb = brandUpper.contains('PBB');
          final isTvPascabayar = brandUpper.contains('TV');
          final isGas = brandUpper.contains('GAS');
          final isMobileCarrier =
              brandUpper.contains('BYU') ||
              brandUpper.contains('TELKOMSEL') ||
              brandUpper.contains('INDOSAT') ||
              brandUpper.contains('TRI') ||
              brandUpper.contains('XL');
          final isHpSuccess =
              isHpPascabayar &&
              isStatusSuccess &&
              billResponseData['desc'] is Map;
          final isMobileCarrierSuccess =
              isMobileCarrier &&
              isStatusSuccess &&
              billResponseData['desc'] is Map;
          final isMultifinanceSuccess =
              isMultifinance &&
              isStatusSuccess &&
              billResponseData['desc'] is Map;
          final isInternetSuccess =
              isInternetPascabayar &&
              isStatusSuccess &&
              billResponseData['desc'] is Map &&
              (billResponseData['desc'] as Map).containsKey('detail') &&
              billResponseData['desc']['detail'] is List &&
              (billResponseData['desc']['detail'] as List).isNotEmpty;
          final isBpjsKetenagakerjaanSuccess =
              isBpjsKetenagakerjaan &&
              isStatusSuccess &&
              billResponseData['desc'] is Map;

          // NEW: Check for PLN Pascabayar with Digiflazz format (nested desc.detail)
          final isPlnPascabayarSuccess =
              isPLNPascabayar &&
              isStatusSuccess &&
              billResponseData['desc'] is Map &&
              (billResponseData['desc'] as Map).containsKey('detail') &&
              billResponseData['desc']['detail'] is List &&
              (billResponseData['desc']['detail'] as List).isNotEmpty;

          // NEW: Check for Internet Pascabayar with Digiflazz format (same as PLN)
          final isInternetPascabayarSuccess = isInternetSuccess;

          // NEW: Check for PDAM with Digiflazz format (has desc.detail like PLN & Internet)
          final isPdamSuccess =
              isPdam &&
              isStatusSuccess &&
              billResponseData['desc'] is Map &&
              (billResponseData['desc'] as Map).containsKey('detail') &&
              billResponseData['desc']['detail'] is List &&
              (billResponseData['desc']['detail'] as List).isNotEmpty;

          // NEW: Check for PBB with Digiflazz format (has desc but no detail array)
          final isPbbSuccess =
              isPbb && isStatusSuccess && billResponseData['desc'] is Map;

          // NEW: Check for TV Pascabayar with Digiflazz format (has desc.detail array)
          final isTvSuccess =
              isTvPascabayar &&
              isStatusSuccess &&
              billResponseData['desc'] is Map &&
              (billResponseData['desc'] as Map).containsKey('detail') &&
              billResponseData['desc']['detail'] is List &&
              (billResponseData['desc']['detail'] as List).isNotEmpty;

          // NEW: Check for GAS with Digiflazz format (has desc.detail array with meter readings)
          final isGasSuccess =
              isGas &&
              isStatusSuccess &&
              billResponseData['desc'] is Map &&
              (billResponseData['desc'] as Map).containsKey('detail') &&
              billResponseData['desc']['detail'] is List &&
              (billResponseData['desc']['detail'] as List).isNotEmpty;

          // DEBUG: PDAM validation checks
          if (isPdam) {
            if (billResponseData['desc'] is Map) {
              final desc = billResponseData['desc'] as Map;
              print(
                '   - desc.containsKey(detail): ${desc.containsKey('detail')}',
              );

              if (desc['detail'] is List) {
                print(
                  '   - desc[detail].isNotEmpty: ${(desc['detail'] as List).isNotEmpty}',
                );
              }
            }
          }

          // DEBUG: Mobile Carrier validation checks
          if (isMobileCarrier) {}

          // Debug validation flags

          // DEBUG: Check Internet response structure
          if (isInternetPascabayar) {
            print('   - desc exists: ${billResponseData.containsKey('desc')}');

            if (billResponseData['desc'] != null) {
              final desc = billResponseData['desc'];
              print('   - desc has detail: ${desc.containsKey('detail')}');

              print(
                '   - detail length: ${(desc['detail'] as List?)?.length ?? 0}',
              );
            }
          }

          if (isStatusSuccess ||
              isHpSuccess ||
              isMobileCarrierSuccess ||
              isMultifinanceSuccess ||
              isInternetSuccess ||
              isBpjsKetenagakerjaanSuccess ||
              isPlnPascabayarSuccess ||
              isPdamSuccess ||
              isPbbSuccess ||
              isTvSuccess ||
              isGasSuccess) {
            print(
              '✅ [CekTagihan] Status is success (Digiflazz format), building bill data...',
            );

            // NEW: Handle PLN Pascabayar with multiple periods in detail array
            if (isPlnPascabayarSuccess) {
              final descData = billResponseData['desc'];
              final details = descData['detail'] as List<dynamic>? ?? [];

              if (details.isNotEmpty) {
                // SUM all periods' nilai_tagihan and denda
                int totalNilaiTagihan = 0;
                int totalDenda = 0;

                for (var detail in details) {
                  final nilai =
                      int.tryParse(detail['nilai_tagihan'].toString()) ?? 0;
                  final dnd = int.tryParse(detail['denda'].toString()) ?? 0;
                  totalNilaiTagihan += nilai;
                  totalDenda += dnd;
                }

                // Get admin from top-level response (already includes all periods)
                final adminFromApi = billResponseData['admin'] ?? 0;

                // Calculate total_tagihan = sum of all values + admin
                final totalTagihan =
                    totalNilaiTagihan + adminFromApi + totalDenda;

                final billData = {
                  'customer_name': billResponseData['customer_name'],
                  'customer_no': billResponseData['customer_no'],
                  'periode': details.isNotEmpty ? details[0]['periode'] : '',
                  'tagihan': totalNilaiTagihan,
                  'admin': adminFromApi,
                  'denda': totalDenda,
                  'total_tagihan': totalTagihan,
                  'lembar_tagihan': descData['lembar_tagihan'] ?? 1,
                  'ref_id': billResponseData['ref_id'],
                  'product_name': billResponseData['buyer_sku_code'],
                  'buyer_sku_code': billResponseData['buyer_sku_code'],
                  'brand': billResponseData['buyer_sku_code'],
                  'biaya_lain': null,
                  'alamat': null,
                  'jumlah_peserta': null,
                  // NEW: Add detail for all periods
                  'details': details,
                  'tarif': descData['tarif'],
                  'daya': descData['daya'],
                };

                await _cacheCustomerNo(_customerNoController.text.trim());

                if (mounted) {
                  setState(() {
                    _billData = billData;
                    _isLoading = false;
                  });

                  _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
                }
              } else {
                throw Exception('Detail tagihan tidak ditemukan');
              }
            } else if (isInternetPascabayarSuccess) {
              // NEW: Handle Internet Pascabayar with Digiflazz format (same as PLN)

              final descData = billResponseData['desc'];
              final details = descData['detail'] as List<dynamic>? ?? [];

              if (details.isNotEmpty) {
                // SUM all periods' nilai_tagihan and denda
                int totalNilaiTagihan = 0;
                int totalDenda = 0;

                for (var detail in details) {
                  final nilai =
                      int.tryParse(detail['nilai_tagihan'].toString()) ?? 0;
                  final dnd = int.tryParse(detail['denda'].toString()) ?? 0;
                  totalNilaiTagihan += nilai;
                  totalDenda += dnd;
                }

                // Get admin from top-level response
                final adminFromApi = billResponseData['admin'] ?? 0;

                // Calculate total_tagihan = sum of all values + admin
                final totalTagihan =
                    totalNilaiTagihan + adminFromApi + totalDenda;

                final billData = {
                  'customer_name': billResponseData['customer_name'],
                  'customer_no': billResponseData['customer_no'],
                  'periode': details.isNotEmpty ? details[0]['periode'] : '',
                  'tagihan': totalNilaiTagihan,
                  'admin': adminFromApi,
                  'denda': totalDenda,
                  'total_tagihan': totalTagihan,
                  'lembar_tagihan': descData['lembar_tagihan'] ?? 1,
                  'ref_id': billResponseData['ref_id'],
                  'product_name': billResponseData['buyer_sku_code'],
                  'buyer_sku_code': billResponseData['buyer_sku_code'],
                  'brand': billResponseData['buyer_sku_code'],
                  'biaya_lain': null,
                  'alamat': null,
                  'jumlah_peserta': null,
                  // Add detail for all periods
                  'details': details,
                };

                await _cacheCustomerNo(_customerNoController.text.trim());

                if (mounted) {
                  setState(() {
                    _billData = billData;
                    _isLoading = false;
                  });

                  _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
                }
              } else {
                throw Exception('Detail tagihan tidak ditemukan');
              }
            } else if (isPdamSuccess) {
              // NEW: Handle PDAM with Digiflazz format (same as PLN & Internet)

              final descData = billResponseData['desc'];
              final details = descData['detail'] as List<dynamic>? ?? [];

              print('📋 [PDAM] descData keys: ${descData.keys.toList()}');

              // DEBUG: Print detail array structure
              print(
                '📋 [PDAM] Detail array keys from first item: ${details.isNotEmpty ? (details[0] as Map).keys.toList() : 'EMPTY'}',
              );

              // DEBUG: Print detail array structure
              print(
                '📋 [PDAM] Detail array keys from first item: ${details.isNotEmpty ? (details[0] as Map).keys.toList() : 'EMPTY'}',
              );

              if (details.isNotEmpty) {
                // SUM all periods' nilai_tagihan, denda, and biaya_lain
                int totalNilaiTagihan = 0;
                int totalDenda = 0;
                int totalBiayaLain = 0;

                for (var detail in details) {
                  final nilai =
                      int.tryParse(detail['nilai_tagihan'].toString()) ?? 0;
                  final dnd = int.tryParse(detail['denda'].toString()) ?? 0;
                  final biaya =
                      int.tryParse(detail['biaya_lain'].toString()) ?? 0;
                  totalNilaiTagihan += nilai;
                  totalDenda += dnd;
                  totalBiayaLain += biaya;

                  // DEBUG: Log each detail item processing
                  print(
                    '📋 [PDAM] Detail item: ${(detail as Map).keys.toList()}',
                  );
                  print(
                    '   [Period ${detail['periode']}] nilai: $nilai, denda: $dnd, biaya_lain: $biaya (raw: ${detail['biaya_lain']})',
                  );
                }

                // Get admin from top-level response
                final adminFromApi = billResponseData['admin'] ?? 0;

                // Calculate total_tagihan = sum of all values + admin
                final totalTagihan =
                    totalNilaiTagihan +
                    adminFromApi +
                    totalDenda +
                    totalBiayaLain;

                final billData = {
                  'customer_name': billResponseData['customer_name'],
                  'customer_no': billResponseData['customer_no'],
                  'periode': details.isNotEmpty ? details[0]['periode'] : '',
                  'tagihan': totalNilaiTagihan,
                  'admin': adminFromApi,
                  'denda': totalDenda,
                  'total_tagihan': totalTagihan,
                  'lembar_tagihan': descData['lembar_tagihan'] ?? 1,
                  'ref_id': billResponseData['ref_id'],
                  'product_name': billResponseData['buyer_sku_code'],
                  'buyer_sku_code': billResponseData['buyer_sku_code'],
                  'brand': billResponseData['buyer_sku_code'],
                  'biaya_lain': totalBiayaLain,
                  'alamat': descData['alamat'] ?? null,
                  'jumlah_peserta': null,
                  // Add detail for all periods and additional PDAM fields
                  'details': details,
                  'tarif': descData['tarif'] ?? null,
                  'jatuh_tempo': descData['jatuh_tempo'] ?? null,
                };

                await _cacheCustomerNo(_customerNoController.text.trim());

                if (mounted) {
                  setState(() {
                    _billData = billData;
                    _isLoading = false;
                  });

                  _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
                }
              } else {
                throw Exception('Detail tagihan tidak ditemukan');
              }
            } else if (isPbbSuccess) {
              // NEW: Handle PBB with Digiflazz format (no detail array, single period)

              final descData = billResponseData['desc'];

              final billData = {
                'customer_name': billResponseData['customer_name'],
                'customer_no': billResponseData['customer_no'],
                'periode': descData['tahun_pajak'] ?? '',
                'tagihan': billResponseData['price'],
                'admin': billResponseData['admin'],
                'denda': 0,
                'total_tagihan': billResponseData['selling_price'],
                'lembar_tagihan': descData['lembar_tagihan'] ?? 1,
                'ref_id': billResponseData['ref_id'],
                'product_name': billResponseData['buyer_sku_code'],
                'buyer_sku_code': billResponseData['buyer_sku_code'],
                'brand': billResponseData['buyer_sku_code'],
                'biaya_lain': 0,
                // PBB-specific fields
                'alamat': descData['alamat'] ?? null,
                'kelurahan': descData['kelurahan'] ?? null,
                'kecamatan': descData['kecamatan'] ?? null,
                'kab_kota': descData['kab_kota'] ?? null,
                'luas_tanah': descData['luas_tanah'] ?? null,
                'luas_gedung': descData['luas_gedung'] ?? null,
                'jumlah_peserta': null,
              };

              await _cacheCustomerNo(_customerNoController.text.trim());

              if (mounted) {
                setState(() {
                  _billData = billData;
                  _isLoading = false;
                });

                _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
              }
            } else if (isTvSuccess) {
              // NEW: Handle TV Pascabayar with Digiflazz format

              final descData = billResponseData['desc'];
              final details = descData['detail'] as List<dynamic>? ?? [];

              // Extract TV-specific fields from first detail
              final periode = details.isNotEmpty
                  ? details[0]['periode'] ?? ''
                  : '';
              final nilaiTagihan = details.isNotEmpty
                  ? int.tryParse(details[0]['nilai_tagihan'].toString()) ?? 0
                  : 0;

              final billData = {
                'customer_name': billResponseData['customer_name'],
                'customer_no': billResponseData['customer_no'],
                'periode': periode,
                'tagihan': nilaiTagihan,
                'admin': billResponseData['admin'],
                'denda': 0,
                'total_tagihan': billResponseData['selling_price'],
                'lembar_tagihan': descData['lembar_tagihan'] ?? 1,
                'ref_id': billResponseData['ref_id'],
                'product_name': billResponseData['buyer_sku_code'],
                'buyer_sku_code': billResponseData['buyer_sku_code'],
                'brand': billResponseData['buyer_sku_code'],
                'biaya_lain': 0,
                'alamat': null,
                'jumlah_peserta': null,
                'details': details,
              };

              await _cacheCustomerNo(_customerNoController.text.trim());

              if (mounted) {
                setState(() {
                  _billData = billData;
                  _isLoading = false;
                });

                _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
              }
            } else if (isGasSuccess) {
              // NEW: Handle GAS with Digiflazz format (has desc.detail array with meter readings)

              final descData = billResponseData['desc'];
              final details = descData['detail'] as List<dynamic>? ?? [];

              // Extract GAS-specific fields from all details (sum meter usage if multiple)
              int totalUsage = 0;
              for (var detail in details) {
                final usage = int.tryParse(detail['usage'].toString()) ?? 0;
                totalUsage += usage;
              }

              final periode = details.isNotEmpty
                  ? details[0]['periode'] ?? ''
                  : '';
              final meterAwal = details.isNotEmpty
                  ? details[0]['meter_awal'] ?? ''
                  : '';
              final meterAkhir = details.isNotEmpty
                  ? details[0]['meter_akhir'] ?? ''
                  : '';

              final billData = {
                'customer_name': billResponseData['customer_name'],
                'customer_no': billResponseData['customer_no'],
                'periode': periode,
                'tagihan': billResponseData['price'],
                'admin': billResponseData['admin'],
                'denda': 0,
                'total_tagihan': billResponseData['selling_price'],
                'lembar_tagihan': descData['lembar_tagihan'] ?? 1,
                'ref_id': billResponseData['ref_id'],
                'product_name': billResponseData['buyer_sku_code'],
                'buyer_sku_code': billResponseData['buyer_sku_code'],
                'brand': billResponseData['buyer_sku_code'],
                'biaya_lain': 0,
                'alamat': descData['alamat'] ?? null,
                'jumlah_peserta': null,
                // GAS-specific fields
                'meter_awal': meterAwal,
                'meter_akhir': meterAkhir,
                'usage': totalUsage,
                'details': details,
              };

              await _cacheCustomerNo(_customerNoController.text.trim());

              if (mounted) {
                setState(() {
                  _billData = billData;
                  _isLoading = false;
                });

                _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
              }
            } else if (isBpjsKetenagakerjaanSuccess) {
              // NEW: Handle BPJS Ketenagakerjaan with Digiflazz format

              final descData = billResponseData['desc'] as Map;

              // Extract BPJS-specific fields from desc
              final jht = (int.tryParse(descData['jht'].toString()) ?? 0);
              final jkk = (int.tryParse(descData['jkk'].toString()) ?? 0);
              final jkm = (int.tryParse(descData['jkm'].toString()) ?? 0);
              final jpk = (int.tryParse(descData['jpk'].toString()) ?? 0);
              final jpn = (int.tryParse(descData['jpn'].toString()) ?? 0);

              final billData = {
                'customer_name': billResponseData['customer_name'],
                'customer_no': billResponseData['customer_no'],
                'periode': descData['kode_divisi'] ?? '-',
                'tagihan': billResponseData['price'],
                'admin': billResponseData['admin'],
                'denda': 0,
                'total_tagihan': billResponseData['selling_price'],
                'lembar_tagihan': descData['lembar_tagihan'] ?? 1,
                'ref_id': billResponseData['ref_id'],
                'product_name': billResponseData['buyer_sku_code'],
                'buyer_sku_code': billResponseData['buyer_sku_code'],
                'brand': billResponseData['buyer_sku_code'],
                'biaya_lain': 0,
                'alamat': null,
                'jumlah_peserta': null,
                // BPJS Ketenagakerjaan-specific fields
                'kode_iuran': descData['kode_iuran'] ?? '-',
                'jht': jht,
                'jkk': jkk,
                'jkm': jkm,
                'jpk': jpk,
                'jpn': jpn,
                'npp': descData['npp'] ?? '-',
                'kode_program': descData['kode_program'] ?? '-',
                'kantor_cabang': descData['kantor_cabang'] ?? '-',
                'tgl_efektif': descData['tgl_efektif'] ?? '-',
                'tgl_expired': descData['tgl_expired'] ?? '-',
              };

              await _cacheCustomerNo(_customerNoController.text.trim());

              if (mounted) {
                setState(() {
                  _billData = billData;
                  _isLoading = false;
                });

                _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
              }
            } else if (isBpjsKesehatan &&
                billResponseData['desc'] is Map &&
                (billResponseData['desc'] as Map).containsKey('detail') &&
                billResponseData['desc']['detail'] is List &&
                (billResponseData['desc']['detail'] as List).isNotEmpty) {
              // NEW: Handle BPJS Kesehatan with Digiflazz format

              final descData = billResponseData['desc'] as Map;
              final detailArray = descData['detail'] as List;
              final periode = detailArray.isNotEmpty
                  ? detailArray[0]['periode'] ?? ''
                  : '';

              final billData = {
                'customer_name': billResponseData['customer_name'],
                'customer_no': billResponseData['customer_no'],
                'periode': periode,
                'tagihan': billResponseData['price'],
                'admin': billResponseData['admin'],
                'denda': 0,
                'total_tagihan':
                    billResponseData['price'] +
                    billResponseData['admin'], // price + admin
                'lembar_tagihan': descData['lembar_tagihan'] ?? 1,
                'ref_id': billResponseData['ref_id'],
                'product_name': billResponseData['buyer_sku_code'],
                'buyer_sku_code': billResponseData['buyer_sku_code'],
                'brand': billResponseData['buyer_sku_code'],
                'biaya_lain': 0,
                'alamat': descData['alamat'] ?? null,
                'jumlah_peserta': descData['jumlah_peserta'] ?? null,
                'details': detailArray,
              };

              await _cacheCustomerNo(_customerNoController.text.trim());

              if (mounted) {
                setState(() {
                  _billData = billData;
                  _isLoading = false;
                });

                _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
              }
            } else if (isMobileCarrierSuccess) {
              // NEW: Handle Mobile Carriers (BYU, Telkomsel, Indosat, Tri, XL) with Digiflazz format

              final billData = {
                'customer_name': billResponseData['customer_name'],
                'customer_no': billResponseData['customer_no'],
                'periode': '1',
                'tagihan': billResponseData['price'],
                'admin': billResponseData['admin'],
                'denda': 0,
                'total_tagihan': billResponseData['selling_price'],
                'lembar_tagihan':
                    billResponseData['desc']['lembar_tagihan'] ?? 1,
                'ref_id': billResponseData['ref_id'],
                'product_name': billResponseData['buyer_sku_code'],
                'buyer_sku_code': billResponseData['buyer_sku_code'],
                'brand': billResponseData['buyer_sku_code'],
                'biaya_lain': 0,
                'alamat': null,
                'jumlah_peserta': null,
              };

              await _cacheCustomerNo(_customerNoController.text.trim());

              if (mounted) {
                setState(() {
                  _billData = billData;
                  _isLoading = false;
                });

                _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
              }
            } else if (isHpSuccess) {
              // NEW: Handle HP Pascabayar with Digiflazz format

              final billData = {
                'customer_name': billResponseData['customer_name'],
                'customer_no': billResponseData['customer_no'],
                'periode': '1',
                'tagihan': billResponseData['price'],
                'admin': billResponseData['admin'],
                'denda': 0,
                'total_tagihan':
                    billResponseData['price'] +
                    billResponseData['admin'], // price + admin
                'lembar_tagihan':
                    billResponseData['desc']['lembar_tagihan'] ?? 1,
                'ref_id': billResponseData['ref_id'],
                'product_name': billResponseData['buyer_sku_code'],
                'buyer_sku_code': billResponseData['buyer_sku_code'],
                'brand': billResponseData['buyer_sku_code'],
                'biaya_lain': 0,
                'alamat': null,
                'jumlah_peserta': null,
              };

              await _cacheCustomerNo(_customerNoController.text.trim());

              if (mounted) {
                setState(() {
                  _billData = billData;
                  _isLoading = false;
                });

                _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
              }
            } else if (isMultifinanceSuccess) {
              // NEW: Handle Multifinance with Digiflazz format

              final descData = billResponseData['desc'];
              final details = descData['detail'] as List<dynamic>? ?? [];

              // Extract multifinance-specific fields
              final itemName = descData['item_name'] ?? '';
              final noRangka = descData['no_rangka'] ?? '';
              final noPol = descData['no_pol'] ?? '';
              final tenor = descData['tenor'] ?? '';
              final buyerLastSaldo = billResponseData['buyer_last_saldo'] ?? 0;

              // Calculate total denda and biaya_lain from detail
              int totalDenda = 0;
              int totalBiayaLain = 0;

              for (var detail in details) {
                final dnd = int.tryParse(detail['denda'].toString()) ?? 0;
                final biaya =
                    int.tryParse(detail['biaya_lain'].toString()) ?? 0;
                totalDenda += dnd;
                totalBiayaLain += biaya;
              }

              final billData = {
                'customer_name': billResponseData['customer_name'],
                'customer_no': billResponseData['customer_no'],
                'periode': details.isNotEmpty
                    ? details[0]['periode'] ?? '001'
                    : '001',
                'tagihan': billResponseData['price'],
                'admin': billResponseData['admin'],
                'denda': totalDenda,
                'total_tagihan':
                    billResponseData['price'] +
                    billResponseData['admin'] +
                    totalDenda +
                    totalBiayaLain, // price + admin + denda + biaya_lain
                'lembar_tagihan': descData['lembar_tagihan'] ?? 1,
                'ref_id': billResponseData['ref_id'],
                'product_name': billResponseData['buyer_sku_code'],
                'buyer_sku_code': billResponseData['buyer_sku_code'],
                'brand': billResponseData['buyer_sku_code'],
                'biaya_lain': totalBiayaLain,
                'alamat': null,
                'jumlah_peserta': null,
                // Multifinance-specific fields
                'item_name': itemName,
                'no_rangka': noRangka,
                'no_pol': noPol,
                'tenor': tenor,
                'buyer_last_saldo': buyerLastSaldo,
                'details': details,
              };

              await _cacheCustomerNo(_customerNoController.text.trim());

              if (mounted) {
                setState(() {
                  _billData = billData;
                  _isLoading = false;
                });

                _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
              }
            } else {
              // OLD: Handle non-PLN/Internet/PDAM/HP/Multifinance Pascabayar responses (flat structure)
              final billData = {
                'customer_name': billResponseData['customer_name'],
                'customer_no': billResponseData['customer_no'],
                'periode': billResponseData['periode'],
                'tagihan': billResponseData['tagihan'],
                'admin': billResponseData['admin'],
                'denda': billResponseData['denda'] ?? 0,
                'total_tagihan': billResponseData['total_tagihan'],
                'lembar_tagihan': billResponseData['lembar_tagihan'] ?? 1,
                'ref_id': billResponseData['ref_id'],
                'product_name': billResponseData['product_name'],
                'buyer_sku_code': billResponseData['buyer_sku_code'],
                'brand': billResponseData['brand'],
                'biaya_lain': billResponseData['biaya_lain'],
                'alamat': billResponseData['alamat'],
                'jumlah_peserta': billResponseData['jumlah_peserta'],
              };

              // Cache customer number
              await _cacheCustomerNo(_customerNoController.text.trim());

              if (mounted) {
                setState(() {
                  _billData = billData;
                  _isLoading = false;
                });

                _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
              }
            }
          } else {
            throw Exception(
              billResponseData['message'] ?? 'Gagal mengambil tagihan',
            );
          }
        }
      } else {
        throw Exception('Gagal mengambil tagihan');
      }
    } catch (e) {
      String userMessage = 'Gagal mengambil tagihan. Silakan coba lagi.';
      String debugMessage = '';

      if (e is DioException) {
        debugMessage = 'DioException: ${e.type} - ${e.message}';

        final statusCode = e.response?.statusCode;

        if (e.type == DioExceptionType.connectionTimeout) {
          userMessage = 'Koneksi timeout. Silakan coba lagi.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          userMessage = 'Server tidak merespons. Silakan coba lagi.';
        } else if (e.type == DioExceptionType.sendTimeout) {
          userMessage = 'Pengiriman data timeout. Silakan coba lagi.';
        } else if (statusCode == 404) {
          userMessage = 'Pelanggan tidak ditemukan (404).';
        } else if (statusCode == 400) {
          // Try to get detailed message from response
          if (e.response?.data is Map) {
            final responseData = e.response!.data as Map<dynamic, dynamic>;
            if (responseData['message'] != null) {
              userMessage = responseData['message'].toString();
            } else if (responseData['error'] != null) {
              userMessage = responseData['error'].toString();
            } else {
              userMessage = 'Bad request (400). Silakan periksa data.';
            }
          } else {
            userMessage = 'Bad request (400). Silakan periksa data.';
          }
        } else if (statusCode == 401) {
          userMessage = 'Token tidak valid. Silakan login kembali.';
        } else if (statusCode == 403) {
          userMessage = 'Akses ditolak (403).';
        } else if (statusCode == 500) {
          userMessage =
              'Server sedang bermasalah (500). Silakan coba beberapa saat lagi.';
        } else if (statusCode == null) {
          // Network error, no status code
          userMessage =
              'Gagal terkoneksi ke server. Silakan cek koneksi internet Anda.';
        } else {
          // Try to extract message from response
          if (e.response?.data is Map) {
            final responseData = e.response!.data as Map<dynamic, dynamic>;
            if (responseData['message'] != null) {
              userMessage = responseData['message'].toString();
            } else if (responseData['data'] is Map) {
              final dataMap = responseData['data'] as Map<dynamic, dynamic>;
              if (dataMap['message'] != null) {
                userMessage = dataMap['message'].toString();
              }
            }
          }
          userMessage = 'Error $statusCode: $userMessage';
        }
      } else if (e is Exception) {
        debugMessage = 'Exception: ${e.toString()}';
        userMessage = e.toString().replaceAll('Exception: ', '');
      }

      if (debugMessage.isNotEmpty) {}

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
      if (mounted) {
        setState(() => _isLoadingSaldo = false);
      }
    }
  }

  Future<void> _processPayment() async {
    if (_billData == null) return;

    // Cek saldo cukup atau tidak (gunakan total asli, markup hanya untuk tampilan)
    final totalTagihan = _billData?['total_tagihan'] ?? 0;
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
            await _submitTransaction(pin);
          } catch (e) {
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
    if (_billData == null) {
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

      print('   - PIN: ${pin.substring(0, 2)}****');
      print(
        '   - Total Tagihan (display): Rp ${_formatCurrency((_billData?['total_tagihan'] ?? 0) + (widget.markupMember ?? 0))}',
      );
      print(
        '   - Total Tagihan (potong saldo): Rp ${_formatCurrency(_billData?['total_tagihan'] ?? 0)}',
      );

      print('   - Markup Member (keuntungan): ${widget.markupMember ?? 0}');

      // Generate TOTP token for pascabayar security
      final adminToken = TOTPService.getCurrentToken(
        secretKey: 'Anggiprog@241288123_2026',
        timeStep: 60,
      );

      final response = await _apiService.processPascabayarTransaction(
        adminUserId: widget.adminUserId,
        pin: pin,
        refId: _billData?['ref_id'] ?? '',
        brand: _billData?['brand'] ?? widget.brand,
        customerNo: _billData?['customer_no'] ?? '',
        customerName: _billData?['customer_name'] ?? '',
        tagihan: _billData?['tagihan'] ?? 0,
        admin: _billData?['admin'] ?? 0,
        denda: _billData?['denda'] ?? 0,
        totalTagihan: _billData?['total_tagihan'] ?? 0,
        productName: _billData?['product_name'] ?? '',
        buyerSkuCode: _billData?['buyer_sku_code'] ?? '',
        token: token,
        adminToken: adminToken,
        markupMember: widget.markupMember,
      );

      if (mounted) {
        setState(() => _isProcessingPayment = false);

        if (response.statusCode == 200) {
          final responseData = response.data;

          // Close loading dialog
          Navigator.pop(context);

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
                  Flexible(child: Text('Transaksi Berhasil')),
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
                    // Trigger refresh di transaction history
                    TransactionHistoryTab.clearPascabayarCache();
                    TransactionHistoryTab.triggerRefresh();

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
                    // Trigger refresh di transaction history
                    TransactionHistoryTab.clearPascabayarCache();
                    TransactionHistoryTab.triggerRefresh();

                    Navigator.pop(ctx); // Close success dialog
                    Navigator.pop(context); // Close bottom sheet

                    // Buat objek TransactionPascabayar dari response
                    final transaction = TransactionPascabayar(
                      id: 0, // ID akan di-update dari database nanti
                      userId: widget.adminUserId,
                      refId:
                          responseData['ref_id'] ?? _billData?['ref_id'] ?? '',
                      brand: _billData?['brand'] ?? '',
                      buyerSkuCode: _billData?['buyer_sku_code'] ?? '',
                      customerNo: _billData?['customer_no'] ?? '',
                      customerName: _billData?['customer_name'] ?? '',
                      nilaiTagihan: _billData?['tagihan']?.toString() ?? '0',
                      admin:
                          ((_billData?['admin'] ?? 0) +
                                  (widget.markupMember ?? 0))
                              .toString(),
                      totalPembayaranUser:
                          ((_billData?['total_tagihan'] ?? 0) +
                                  (widget.markupMember ?? 0))
                              .toString(),
                      periode: (_billData?['periode'] ?? '').toString(),
                      denda: _billData?['denda']?.toString() ?? '0',
                      status: responseData['status'] ?? 'Sukses',
                      daya: null,
                      lembarTagihan: _billData?['lembar_tagihan'] ?? 1,
                      meterAwal: null,
                      meterAkhir: null,
                      createdAt: DateTime.now().toString(),
                      sn: responseData['data']?['sn'] ?? '-',
                      productName: _billData?['product_name'] ?? '',
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
      if (e is DioException) {}

      if (mounted) {
        // Close loading dialog first
        Navigator.pop(context);

        setState(() => _isProcessingPayment = false);

        String errorMessage = e.toString().replaceAll('Exception: ', '');
        if (e is DioException && e.response?.data != null) {
          errorMessage = e.response?.data['message'] ?? errorMessage;
        }

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
                        _billData?['ref_id'] ?? '-',
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
                  value: (_billData?['customer_name'] ?? '-').toString(),
                  primaryColor: primaryColor,
                ),
                const Divider(height: 16, thickness: 0.5),
                _buildCompactInfoRow(
                  icon: Icons.badge,
                  label: 'ID Pelanggan',
                  value: (_billData?['customer_no'] ?? '-').toString(),
                  primaryColor: primaryColor,
                ),
                const Divider(height: 16, thickness: 0.5),
                _buildCompactInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Periode',
                  value: (_billData?['periode']?.toString() ?? '-'),
                  primaryColor: primaryColor,
                ),
                const Divider(height: 16, thickness: 0.5),
                _buildCompactInfoRow(
                  icon: Icons.receipt,
                  label: 'Lembar',
                  value: (_billData?['lembar_tagihan'] ?? 1).toString(),
                  primaryColor: primaryColor,
                ),

                // Multifinance-specific fields
                if (widget.brand.toUpperCase().contains('MULTIFINANCE')) ...[
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.directions_car,
                    label: 'Kendaraan',
                    value: (_billData?['item_name'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.vpn_key,
                    label: 'No. Rangka',
                    value: (_billData?['no_rangka'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.numbers,
                    label: 'No. Polisi',
                    value: (_billData?['no_pol'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Tenor',
                    value: (_billData?['tenor'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactAmountRow(
                    label: 'Saldo Terakhir',
                    amount: _billData?['buyer_last_saldo'] ?? 0,
                  ),
                ],

                // PBB-specific fields
                if (widget.brand.toUpperCase().contains('PBB')) ...[
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.location_on,
                    label: 'Alamat',
                    value: (_billData?['alamat'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.map,
                    label: 'Kelurahan',
                    value: (_billData?['kelurahan'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.domain,
                    label: 'Kecamatan',
                    value: (_billData?['kecamatan'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.location_city,
                    label: 'Kab/Kota',
                    value: (_billData?['kab_kota'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.aspect_ratio,
                    label: 'Luas Tanah',
                    value: (_billData?['luas_tanah'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.business,
                    label: 'Luas Gedung',
                    value: (_billData?['luas_gedung'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                ],

                // GAS-specific fields
                if (widget.brand.toUpperCase().contains('GAS')) ...[
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.location_on,
                    label: 'Alamat',
                    value: (_billData?['alamat'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.speed,
                    label: 'Meter Awal',
                    value: (_billData?['meter_awal'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.speed,
                    label: 'Meter Akhir',
                    value: (_billData?['meter_akhir'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.show_chart,
                    label: 'Penggunaan (m³)',
                    value: (_billData?['usage'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                ],

                // PLN NONTAGLIS-specific fields
                if (widget.brand.toUpperCase().contains('NONTAGLIS')) ...[
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.receipt_long,
                    label: 'Tipe Transaksi',
                    value: (_billData?['transaksi_type'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.confirmation_number,
                    label: 'Nomor Registrasi',
                    value: (_billData?['no_registrasi'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Tanggal Registrasi',
                    value: (_billData?['tgl_registrasi'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                ],

                // BPJS Ketenagakerjaan-specific fields
                if (widget.brand.toUpperCase().contains('KETENAGAKERJAAN')) ...[
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactAmountRow(
                    label: 'JHT (Jaminan Hari Tua)',
                    amount: _billData?['jht'] ?? 0,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactAmountRow(
                    label: 'JKK (Jaminan Kecelakaan Kerja)',
                    amount: _billData?['jkk'] ?? 0,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactAmountRow(
                    label: 'JKM (Jaminan Kematian)',
                    amount: _billData?['jkm'] ?? 0,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.confirmation_number,
                    label: 'Kode Iuran',
                    value: (_billData?['kode_iuran'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.receipt,
                    label: 'NPP',
                    value: (_billData?['npp'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.business,
                    label: 'Kantor Cabang',
                    value: (_billData?['kantor_cabang'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Tgl Efektif',
                    value: (_billData?['tgl_efektif'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildCompactInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Tgl Expired',
                    value: (_billData?['tgl_expired'] ?? '-').toString(),
                    primaryColor: primaryColor,
                  ),
                ],

                const SizedBox(height: 12),
                Container(height: 1, color: Colors.grey[300]),
                const SizedBox(height: 12),

                // Financial Details (Compact)
                _buildCompactAmountRow(
                  label: (widget.brand.toUpperCase().contains('E-MONEY'))
                      ? 'Nominal'
                      : 'Tagihan',
                  amount: _billData?['tagihan'] ?? 0,
                ),
                const SizedBox(height: 8),
                _buildCompactAmountRow(
                  label: 'Admin',
                  amount:
                      (_billData?['admin'] ?? 0) + (widget.markupMember ?? 0),
                ),
                const SizedBox(height: 8),
                _buildCompactAmountRow(
                  label: 'Denda',
                  amount: _billData?['denda'] ?? 0,
                  isDenda: true,
                ),
                const SizedBox(height: 8),
                if (_billData?['biaya_lain'] != null)
                  _buildCompactAmountRow(
                    label: 'Biaya Lain',
                    amount: _billData?['biaya_lain'] ?? 0,
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
                        'Rp ${_formatCurrency((_billData?['total_tagihan'] ?? 0) + (widget.markupMember ?? 0))}',
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
    // Cek saldo: gunakan total asli (yang dipotong dari saldo)
    // Markup member hanya untuk tampilan, tidak dipotong dari saldo
    final totalTagihanPotong = _billData?['total_tagihan'] ?? 0;
    final isSaldoCukup = _saldo >= totalTagihanPotong;

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
                  onTap: () async {
                    // Close bottom sheet dan buka topup modal
                    Navigator.pop(context);
                    final result = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => TopupModal(
                        primaryColor: appConfig.primaryColor,
                        apiService: _apiService,
                      ),
                    );
                    // Handle navigation based on result
                    if (result is Map &&
                        result['action'] != null &&
                        context.mounted) {
                      if (result['action'] == 'navigate_manual') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TopupManual(
                              amount: result['amount'],
                              primaryColor: appConfig.primaryColor,
                              apiService: _apiService,
                            ),
                          ),
                        );
                      } else if (result['action'] == 'navigate_auto') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TopupOtomatis(
                              amount: result['amount'],
                              primaryColor: appConfig.primaryColor,
                              apiService: _apiService,
                            ),
                          ),
                        );
                      }
                    }
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
                : () async {
                    // Close bottom sheet dan buka topup modal
                    Navigator.pop(context);
                    final result = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => TopupModal(
                        primaryColor: appConfig.primaryColor,
                        apiService: _apiService,
                      ),
                    );
                    // Handle navigation based on result
                    if (result is Map &&
                        result['action'] != null &&
                        context.mounted) {
                      if (result['action'] == 'navigate_manual') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TopupManual(
                              amount: result['amount'],
                              primaryColor: appConfig.primaryColor,
                              apiService: _apiService,
                            ),
                          ),
                        );
                      } else if (result['action'] == 'navigate_auto') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TopupOtomatis(
                              amount: result['amount'],
                              primaryColor: appConfig.primaryColor,
                              apiService: _apiService,
                            ),
                          ),
                        );
                      }
                    }
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
