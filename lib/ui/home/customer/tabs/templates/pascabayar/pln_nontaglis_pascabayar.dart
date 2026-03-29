import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../../../core/app_config.dart';
import '../../../../../../core/network/api_service.dart';
import '../../../../../../core/network/session_manager.dart';
import '../../../../../../features/customer/data/models/product_pascabayar_model.dart';
import 'detail_cek_tagihan.dart';

class PlnNontaglisPascabayarPage extends StatefulWidget {
  const PlnNontaglisPascabayarPage({super.key});

  @override
  State<PlnNontaglisPascabayarPage> createState() =>
      _PlnNontaglisPascabayarPageState();
}

class _PlnNontaglisPascabayarPageState
    extends State<PlnNontaglisPascabayarPage> {
  final TextEditingController _customerIdController = TextEditingController();
  late ApiService _apiService;

  // Products Data
  List<ProductPascabayar> _products = [];
  ProductPascabayar? _selectedProduct;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Dio());
    _loadProducts();
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    print('🔄 [PLN NONTAGLIS] _loadProducts called');

    setState(() => _isLoading = true);

    try {
      final token = await SessionManager.getToken();
      print('🔑 [PLN NONTAGLIS] Token: ${token?.substring(0, 20)}...');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      print('🌐 [PLN NONTAGLIS] Calling getPascabayarProducts...');
      final response = await _apiService.getPascabayarProducts(token);

      print('📥 [PLN NONTAGLIS] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final productResponse = ProductPascabayarResponse.fromJson(
          response.data,
        );

        print(
          '📦 [PLN NONTAGLIS] Total products: ${productResponse.products.length}',
        );

        // Print semua brand yang tersedia untuk debugging
        print('📦 [PLN NONTAGLIS] Available brands:');
        for (var p in productResponse.products) {
          if (p.brand.toUpperCase().contains('PLN NONTAGLIS')) {
            print('   - ${p.brand} (${p.buyerSkuCode})');
          }
        }

        // Filter hanya produk PLN NONTAGLIS (case insensitive, handle variations)
        // Match: PLN NONTAGLIS, PLN Nontaglis, plnnontaglis, etc.
        final nontaglisProducts = productResponse.products.where((p) {
          final brandUpper = p.brand.toUpperCase().replaceAll(' ', '');
          final skuUpper = p.buyerSkuCode.toUpperCase();
          return brandUpper.contains('PLNNONTAGLIS') ||
              brandUpper.contains('PLN NONTAGLIS') &&
                  brandUpper.contains('NONTAGLIS') ||
              skuUpper.contains('PLNNONTAGLIS');
        }).toList();

        print(
          '📦 [PLN NONTAGLIS] Products after filter: ${nontaglisProducts.length}',
        );

        if (nontaglisProducts.isNotEmpty) {
          print(
            '📦 [PLN NONTAGLIS] First product: ${nontaglisProducts.first.productName}',
          );
          print(
            '📦 [PLN NONTAGLIS] First product brand: ${nontaglisProducts.first.brand}',
          );
          print(
            '📦 [PLN NONTAGLIS] buyerSkuCode: ${nontaglisProducts.first.buyerSkuCode}',
          );
          print(
            '📦 [PLN NONTAGLIS] markupMember: ${nontaglisProducts.first.markupMember}',
          );
          print(
            '📦 [PLN NONTAGLIS] adminFee: ${nontaglisProducts.first.adminFee}',
          );
        }

        if (mounted) {
          setState(() {
            _products = nontaglisProducts;
            _isLoading = false;
            // Auto select first product if available
            if (_products.isNotEmpty) {
              _selectedProduct = _products.first;
              print(
                '✅ [PLN NONTAGLIS] Auto-selected product: ${_selectedProduct!.productName}',
              );
            } else {
              print(
                '⚠️ [PLN NONTAGLIS] No PLN NONTAGLIS products found in API',
              );
              // Fallback: use hardcoded product if API doesn't return PLN NONTAGLIS
              _selectedProduct = ProductPascabayar(
                productName: 'PLN Nontaglis',
                buyerSkuCode: 'plnnontaglist',
                admin: '0',
                commission: '0',
                category: 'Pascabayar',
                brand: 'PLN NONTAGLIS',
                sellerName: 'Digiflazz',
                price: '0',
                adminFee: '0',
                markupAdmin: '0',
                produkDiskon: '0',
                totalHarga: '0',
                markupMember: 1500,
                hargaJualMember: 0,
                buyerProductStatus: true,
                sellerProductStatus: true,
                desc: 'PLN Nontaglis',
              );
              print('⚠️ [PLN NONTAGLIS] Using fallback product');
            }
          });
          print('✅ [PLN NONTAGLIS] Products loaded successfully');
        }
      } else {
        print(
          '❌ [PLN NONTAGLIS] Response status not 200: ${response.statusCode}',
        );
        throw Exception('Gagal mengambil data produk');
      }
    } catch (e) {
      print('❌ [PLN NONTAGLIS] Error loading products: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackbar('Error: ${e.toString()}', Colors.red);
      }
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

  Future<void> _scanBarcode() async {
    try {
      final status = await Permission.camera.request();
      if (status.isDenied) {
        if (mounted) {
          _showSnackbar(
            'Izin kamera diperlukan untuk scan barcode',
            Colors.orange,
          );
        }
        return;
      }
      if (status.isPermanentlyDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Izin Kamera Diperlukan'),
              content: const Text(
                'Aplikasi memerlukan akses kamera untuk scan barcode. Silakan aktifkan izin kamera di pengaturan aplikasi.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: const Text('Buka Pengaturan'),
                ),
              ],
            ),
          );
        }
        return;
      }
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const _BarcodeScannerScreen()),
      );
      if (result != null && result.isNotEmpty && mounted) {
        setState(() {
          _customerIdController.text = result;
        });
        _showSnackbar('ID Pelanggan: $result', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Gagal membuka scanner: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _checkBill() async {
    print('🔍 [PLN NONTAGLIS] _checkBill called');
    print('🔍 [PLN NONTAGLIS] Selected Product: $_selectedProduct');
    print('🔍 [PLN NONTAGLIS] Customer ID: ${_customerIdController.text}');

    if (_selectedProduct == null) {
      print('⚠️ [PLN NONTAGLIS] No product selected');
      _showSnackbar('Produk PLN NONTAGLIS tidak ditemukan', Colors.orange);
      return;
    }
    if (_customerIdController.text.isEmpty) {
      print('⚠️ [PLN NONTAGLIS] Customer ID is empty');
      _showSnackbar('Masukkan ID pelanggan terlebih dahulu', Colors.orange);
      return;
    }
    try {
      final adminUserId = int.parse(appConfig.adminUserId);

      print('🚀 [PLN NONTAGLIS] Showing CekTagihan bottom sheet...');
      print(
        '📝 [PLN NONTAGLIS] Markup Member: ${_selectedProduct!.markupMember}',
      );
      print('📝 [PLN NONTAGLIS] Admin Fee: ${_selectedProduct!.adminFee}');

      final billData = await CekTagihanPascabayar.showCekTagihan(
        context: context,
        productName: _selectedProduct!.productName,
        brand: _selectedProduct!.brand,
        buyerSkuCode: _selectedProduct!.buyerSkuCode,
        adminUserId: adminUserId,
        cachedCustomerNo: _customerIdController.text,
        markupMember: _selectedProduct!.markupMember,
        adminFee: int.tryParse(_selectedProduct!.adminFee) ?? 0,
      );
      if (billData != null) {
        // Success
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Error: ${e.toString()}', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text(
          'PLN NONTAGLIS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderCard(primaryColor),
                  _buildCustomerIdInput(primaryColor),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLN NONTAGLIS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bayar tagihan PLN NONTAGLIS Anda',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerIdInput(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, primaryColor.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
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
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.badge, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID Pelanggan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Masukkan nomor pelanggan PLN NONTAGLIS',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customerIdController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 13,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 530000000001',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.normal,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primaryColor, width: 2.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _scanBarcode,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkBill,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: const Text(
                'Cek Tagihan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen();
  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final String? code = barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) {
      _isProcessing = true;
      Navigator.pop(context, code);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ...existing code...
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Scan Barcode',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: _handleBarcode,
      ),
    );
  }
}
