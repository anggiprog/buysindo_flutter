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

class BpjsKesehatanPage extends StatefulWidget {
  const BpjsKesehatanPage({super.key});

  @override
  State<BpjsKesehatanPage> createState() => _BpjsKesehatanPageState();
}

class _BpjsKesehatanPageState extends State<BpjsKesehatanPage> {
  final TextEditingController _customerIdController = TextEditingController();

  late ApiService _apiService;

  // Products Data
  List<ProductPascabayar> _products = [];
  ProductPascabayar? _selectedProduct;

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

  // Load pascabayar products from API
  Future<void> _loadProducts() async {
    print('🔄 [BPJS] _loadProducts called');

    try {
      final token = await SessionManager.getToken();
      print('🔑 [BPJS] Token: ${token?.substring(0, 20)}...');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      print('🌐 [BPJS] Calling getPascabayarProducts...');
      final response = await _apiService.getPascabayarProducts(token);

      print('📥 [BPJS] Response status: ${response.statusCode}');
      print('📥 [BPJS] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final productResponse = ProductPascabayarResponse.fromJson(
          response.data,
        );

        print('📦 [BPJS] Total products: ${productResponse.products.length}');

        // Filter hanya produk BPJS KESEHATAN
        final bpjsProducts = productResponse.products
            .where(
              (p) =>
                  p.brand.toUpperCase().contains('BPJS') &&
                  p.brand.toUpperCase().contains('KESEHATAN'),
            )
            .toList();

        print('📦 [BPJS] BPJS products after filter: ${bpjsProducts.length}');
        if (bpjsProducts.isNotEmpty) {
          print('📦 [BPJS] First product: ${bpjsProducts.first.productName}');
          print('📦 [BPJS] First product brand: ${bpjsProducts.first.brand}');
        }

        if (mounted) {
          setState(() {
            _products = bpjsProducts;
            // Auto select first product if available
            if (_products.isNotEmpty) {
              _selectedProduct = _products.first;
              print(
                '✅ [BPJS] Auto-selected product: ${_selectedProduct!.productName}',
              );
            } else {
              print('⚠️ [BPJS] No BPJS products found');
            }
          });
          print('✅ [BPJS] Products loaded successfully');
        }
      } else {
        print('❌ [BPJS] Response status not 200: ${response.statusCode}');
        throw Exception('Gagal mengambil data produk');
      }
    } catch (e) {
      print('❌ [BPJS] Error loading products: $e');
      print('❌ [BPJS] Error type: ${e.runtimeType}');
      if (mounted) {
        _showSnackbar('Error loading products: ${e.toString()}', Colors.red);
      }
    }
  }

  // Cek Tagihan menggunakan widget global
  Future<void> _checkBill() async {
    print('🔍 [BPJS] _checkBill called');
    print('🔍 [BPJS] Selected Product: $_selectedProduct');
    print('🔍 [BPJS] Customer ID: ${_customerIdController.text}');

    if (_selectedProduct == null) {
      print('⚠️ [BPJS] No product selected');
      _showSnackbar('Pilih produk terlebih dahulu', Colors.orange);
      return;
    }

    if (_customerIdController.text.isEmpty) {
      print('⚠️ [BPJS] Customer ID is empty');
      _showSnackbar('Masukkan nomor VA BPJS terlebih dahulu', Colors.orange);
      return;
    }

    try {
      // Get admin ID from AppConfig
      final adminUserId = int.parse(appConfig.adminId);

      print('📝 [BPJS] Admin User ID (from AppConfig): $adminUserId');
      print('📝 [BPJS] Product Name: ${_selectedProduct!.productName}');
      print('📝 [BPJS] Brand: ${_selectedProduct!.brand}');
      print('📝 [BPJS] Buyer SKU Code: ${_selectedProduct!.buyerSkuCode}');

      // Show bottom sheet cek tagihan
      print('🚀 [BPJS] Showing CekTagihan bottom sheet...');
      final billData = await CekTagihanPascabayar.showCekTagihan(
        context: context,
        productName: _selectedProduct!.productName,
        brand: _selectedProduct!.brand,
        buyerSkuCode: _selectedProduct!.buyerSkuCode,
        adminUserId: adminUserId,
        cachedCustomerNo: _customerIdController.text,
      );

      print('📥 [BPJS] Bill Data Response: $billData');

      // Bottom sheet ditutup, tidak perlu action lagi di sini
      if (billData != null) {
        print('✅ [BPJS] Bill data received from bottom sheet');
      } else {
        print('ℹ️ [BPJS] User cancelled the bill check');
      }
    } catch (e) {
      print('❌ [BPJS] Error in _checkBill: $e');
      print('❌ [BPJS] Error type: ${e.runtimeType}');
      if (mounted) {
        _showSnackbar('Error: ${e.toString()}', Colors.red);
      }
    }
  }

  // Show Snackbar
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
      // Request camera permission - will show system dialog automatically
      final status = await Permission.camera.request();

      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin kamera diperlukan untuk scan barcode'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (status.isPermanentlyDenied) {
        if (mounted) {
          // Show dialog to open settings
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Izin Kamera Diperlukan'),
              content: const Text(
                'Aplikasi memerlukan akses kamera untuk scan barcode. '
                'Silakan aktifkan izin kamera di pengaturan aplikasi.',
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

      // Permission granted, proceed with scanning
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const _BarcodeScannerScreen()),
      );

      if (result != null && result.isNotEmpty && mounted) {
        setState(() {
          _customerIdController.text = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nomor VA BPJS: $result'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning: ${e.message ?? e.code}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka scanner: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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
          'BPJS Kesehatan',
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProducts();
        },
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeaderCard(primaryColor),
              _buildCustomerIdInput(primaryColor),
            ],
          ),
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
            child: const Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BPJS Kesehatan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bayar iuran BPJS Kesehatan',
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
                    'Nomor Virtual Account',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Masukkan nomor VA BPJS Kesehatan',
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
                  maxLength: 16,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 8888001234567890',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
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
                      borderSide: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1.5,
                      ),
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

// Barcode Scanner Screen
class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
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
    final primaryColor = Theme.of(context).primaryColor;

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
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
            ),
            tooltip: 'Flash',
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
            tooltip: 'Flip',
            onPressed: () => cameraController.switchCamera(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double scanAreaSize =
              constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth * 0.7
              : constraints.maxHeight * 0.4;
          final double scanAreaLeft = (constraints.maxWidth - scanAreaSize) / 2;
          final double scanAreaTop = (constraints.maxHeight - scanAreaSize) / 2;

          return Stack(
            children: [
              // Camera preview
              Positioned.fill(
                child: MobileScanner(
                  controller: cameraController,
                  onDetect: _handleBarcode,
                ),
              ),

              // Dark overlay with transparent center
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScannerOverlayPainter(
                    scanRect: Rect.fromLTWH(
                      scanAreaLeft,
                      scanAreaTop,
                      scanAreaSize,
                      scanAreaSize,
                    ),
                  ),
                ),
              ),

              // Scanner frame and UI
              Positioned(
                left: scanAreaLeft,
                top: scanAreaTop,
                width: scanAreaSize,
                height: scanAreaSize,
                child: Stack(
                  children: [
                    ..._buildCornerBrackets(primaryColor, scanAreaSize),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Positioned(
                          top: _animationController.value * (scanAreaSize - 20),
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  primaryColor.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Instructions
              Positioned(
                left: 0,
                right: 0,
                top: scanAreaTop + scanAreaSize + 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Arahkan Kamera ke Barcode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pastikan barcode berada di dalam frame',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCornerBrackets(Color color, double scanAreaSize) {
    final double size = scanAreaSize * 0.15;
    final double thickness = 4.0;

    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(2)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(2)),
          ),
        ),
      ),

      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(topRight: Radius.circular(2)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(topRight: Radius.circular(2)),
          ),
        ),
      ),

      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(2),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(2),
            ),
          ),
        ),
      ),

      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(2),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(2),
            ),
          ),
        ),
      ),
    ];
  }
}

// Custom painter for scanner overlay
class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanRect;
  _ScannerOverlayPainter({required this.scanRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
