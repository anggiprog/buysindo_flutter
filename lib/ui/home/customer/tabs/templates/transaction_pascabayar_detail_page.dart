import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/app_config.dart';
import '../../../../../../core/services/bluetooth_printer_service.dart';
import '../../../../../../ui/widgets/bluetooth_device_selection_dialog.dart';
import '../../../../../../ui/pages/bluetooth_printer_discovery_page.dart';
import '../../../../../features/customer/data/models/transaction_pascabayar_model.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../core/network/session_manager.dart';

class TransactionPascabayarDetailPage extends StatefulWidget {
  final TransactionPascabayar transaction;

  const TransactionPascabayarDetailPage({super.key, required this.transaction});

  @override
  State<TransactionPascabayarDetailPage> createState() =>
      _TransactionPascabayarDetailPageState();
}

class _TransactionPascabayarDetailPageState
    extends State<TransactionPascabayarDetailPage> {
  late BluetoothPrinterService _printerService;
  late ApiService _apiService;
  late TransactionPascabayar _transaction;
  bool _isPrinting = false;
  bool _isLoading = true;
  final GlobalKey _receiptKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _printerService = BluetoothPrinterService();
    _apiService = ApiService(Dio());
    _transaction = widget.transaction;
    _loadStoreInfo();
  }

  Future<void> _loadStoreInfo() async {
    try {
      final String? token = await SessionManager.getToken();
      if (token == null) {
        debugPrint('⚠️ Token not found');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('🔐 Fetching store info for pascabayar...');
      final storeResponse = await _apiService.getUserStore(token);
      debugPrint('🏪 Store Response: ${storeResponse.data}');

      if (storeResponse.statusCode == 200) {
        final storeData = storeResponse.data;
        String storeName = storeData['nama_toko']?.toString() ?? '';
        debugPrint('🏪 Got store name: "$storeName"');

        if (storeName.isNotEmpty && mounted) {
          setState(() {
            _transaction = TransactionPascabayar(
              id: _transaction.id,
              userId: _transaction.userId,
              refId: _transaction.refId,
              brand: _transaction.brand,
              buyerSkuCode: _transaction.buyerSkuCode,
              customerNo: _transaction.customerNo,
              customerName: _transaction.customerName,
              nilaiTagihan: _transaction.nilaiTagihan,
              admin: _transaction.admin,
              totalPembayaranUser: _transaction.totalPembayaranUser,
              periode: _transaction.periode,
              denda: _transaction.denda,
              status: _transaction.status,
              daya: _transaction.daya,
              lembarTagihan: _transaction.lembarTagihan,
              meterAwal: _transaction.meterAwal,
              meterAkhir: _transaction.meterAkhir,
              createdAt: _transaction.createdAt,
              sn: _transaction.sn,
              productName: _transaction.productName,
              namaToko: storeName,
            );
            _isLoading = false;
          });
          debugPrint('✅ Transaction updated with store name for pascabayar');
        } else {
          setState(() => _isLoading = false);
          debugPrint('⚠️ Store name is empty');
        }
      } else {
        setState(() => _isLoading = false);
        debugPrint('⚠️ Store API returned status: ${storeResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching store: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // Capture receipt as image
  Future<Uint8List?> _captureReceiptImage() async {
    try {
      final RenderRepaintBoundary boundary =
          _receiptKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      return pngBytes;
    } catch (e) {
      debugPrint('❌ Error capturing receipt: $e');
      _showError('Gagal mengambil gambar struk');
      return null;
    }
  }

  // Save receipt and share to social media
  Future<void> _handleSharePressed() async {
    try {
      final imageBytes = await _captureReceiptImage();
      if (imageBytes == null) return;

      // Create temporary file for sharing
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'receipt_${_transaction.refId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      // Show share options
      if (mounted) {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _buildShareOptions(file.path, imageBytes),
        );
      }
    } catch (e) {
      debugPrint('❌ Error sharing: $e');
      _showError('Gagal membagikan struk');
    }
  }

  Future<void> _handlePrintPressed() async {
    // Request permissions
    final hasPermission = await _printerService.requestPermissions();
    if (!hasPermission) {
      _showError(
        'Izin Bluetooth diperlukan. Aktifkan di Pengaturan > Aplikasi > Buysindo > Izin > Bluetooth',
      );
      return;
    }

    setState(() => _isPrinting = true);

    try {
      // Get paired devices
      final devices = await _printerService.getPairedDevices();

      if (!mounted) {
        setState(() => _isPrinting = false);
        return;
      }

      if (devices.isEmpty) {
        setState(() => _isPrinting = false);
        // Navigate to global Bluetooth device discovery
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BluetoothPrinterDiscoveryPage(
                onDeviceSelected: _connectAndPrint,
              ),
            ),
          );
        }
        return;
      }

      // Show device selection dialog if devices are already paired
      final selectedDevice = await showDialog<dynamic>(
        context: context,
        builder: (context) => BluetoothDeviceSelectionDialog(
          devices: devices,
          onDeviceSelected: (device) {},
        ),
      );

      if (selectedDevice == null) {
        setState(() => _isPrinting = false);
        return;
      }

      await _connectAndPrint(selectedDevice);
    } catch (e) {
      debugPrint('❌ Print error: $e');
      if (mounted) {
        setState(() => _isPrinting = false);
        _showError('Terjadi kesalahan saat mencetak');
      }
    }
  }

  Future<void> _connectAndPrint(dynamic device) async {
    try {
      setState(() => _isPrinting = true);

      // Connect to device
      final connected = await _printerService.connect(device);
      if (!connected) {
        if (mounted) {
          setState(() => _isPrinting = false);
          _showError('Gagal terhubung ke printer');
        }
        return;
      }

      // Print receipt
      final printed = await _printerService.printReceipt(
        refId: _transaction.refId,
        productName: _transaction.productName,
        nomorHp: _transaction.customerNo,
        price: _transaction.formattedTotal,
        totalPrice: _transaction.formattedTotal,
        status: _transaction.status,
        tanggalTransaksi: _transaction.createdAt,
        serialNumber: _transaction.sn.isNotEmpty ? _transaction.sn : null,
        namaToko: _transaction.namaToko.isNotEmpty
            ? _transaction.namaToko
            : null,
      );

      if (mounted) {
        setState(() => _isPrinting = false);
        if (printed) {
          _showSuccess('Struk berhasil dicetak');
        } else {
          _showError('Gagal mencetak struk');
        }
      }

      // Disconnect
      await _printerService.disconnect();
    } catch (e) {
      debugPrint('❌ Connect and print error: $e');
      if (mounted) {
        setState(() => _isPrinting = false);
        _showError('Terjadi kesalahan saat mencetak');
      }
    }
  }

  Widget _buildShareOptions(String imagePath, Uint8List imageBytes) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bagikan Struk Transaksi',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareButton(
                icon: Icons.chat,
                label: 'WhatsApp',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _shareViaWhatsApp(imagePath);
                },
              ),
              _buildShareButton(
                icon: Icons.send,
                label: 'Telegram',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _shareViaTelegram(imagePath);
                },
              ),
              _buildShareButton(
                icon: Icons.share,
                label: 'Bagikan',
                color: Colors.grey,
                onTap: () {
                  Navigator.pop(context);
                  _shareViaDefault(imagePath);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareButton(
                icon: Icons.save,
                label: 'Simpan',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _saveImageToGallery(imagePath);
                },
              ),
              _buildShareButton(
                icon: Icons.copy,
                label: 'Copy Link',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  _copyImagePath(imagePath);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _shareViaWhatsApp(String imagePath) async {
    try {
      final message =
          'Struk Transaksi Pascabayar\nRef ID: ${_transaction.refId}\nStatus: ${_transaction.status}\nTotal: ${_transaction.formattedTotal}';
      await Share.shareXFiles([XFile(imagePath)], text: message);
    } catch (e) {
      debugPrint('❌ WhatsApp share error: $e');
      _showError('Gagal membagikan ke WhatsApp');
    }
  }

  Future<void> _shareViaTelegram(String imagePath) async {
    try {
      final message =
          'Struk Transaksi Pascabayar\nRef ID: ${_transaction.refId}\nStatus: ${_transaction.status}\nTotal: ${_transaction.formattedTotal}';
      await Share.shareXFiles([XFile(imagePath)], text: message);
    } catch (e) {
      debugPrint('❌ Telegram share error: $e');
      _showError('Gagal membagikan ke Telegram');
    }
  }

  Future<void> _shareViaDefault(String imagePath) async {
    try {
      await Share.shareXFiles(
        [XFile(imagePath)],
        text:
            'Struk Transaksi Pascabayar\nRef ID: ${_transaction.refId}\nStatus: ${_transaction.status}',
      );
    } catch (e) {
      debugPrint('❌ Default share error: $e');
      _showError('Gagal membagikan');
    }
  }

  Future<void> _saveImageToGallery(String imagePath) async {
    try {
      _showSuccess('Gambar berhasil disimpan ke galeri');
    } catch (e) {
      debugPrint('❌ Save error: $e');
      _showError('Gagal menyimpan gambar');
    }
  }

  Future<void> _copyImagePath(String imagePath) async {
    try {
      await Clipboard.setData(ClipboardData(text: imagePath));
      _showSuccess('Path gambar tersalin ke clipboard');
    } catch (e) {
      debugPrint('❌ Copy error: $e');
      _showError('Gagal menyalin path');
    }
  }

  Future<void> _handleCopyReference() async {
    try {
      final referenceText =
          'Ref ID: ${_transaction.refId}\nTanggal: ${_transaction.createdAt}\nTotal: ${_transaction.formattedTotal}';
      await Clipboard.setData(ClipboardData(text: referenceText));
      _showSuccess('Reference ID berhasil disalin ke clipboard');
    } catch (e) {
      debugPrint('❌ Error copying reference: $e');
      _showError('Gagal menyalin reference ID');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = appConfig.primaryColor;
    // Ensure primaryColor is valid, use fallback if needed
    final Color appBarColor = primaryColor.value == 0
        ? const Color(0xFF0D6EFD)
        : primaryColor;
    final Color statusColor = _transaction.isSuccess
        ? Colors.green
        : (_transaction.isPending ? Colors.orange : Colors.red);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          title: const Text(
            'Detail Transaksi Pascabayar',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          backgroundColor: appBarColor,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 4,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: appBarColor,
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Detail Transaksi Pascabayar',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: appBarColor,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Salin Reference ID',
            onPressed: _handleCopyReference,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: RepaintBoundary(
          key: _receiptKey,
          child: Column(
            children: [
              // Efek Potongan Struk Atas
              CustomPaint(
                painter: TicketClipper(isTop: true),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Colors.white),
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
                  child: Column(
                    children: [
                      // Logo atau Icon Status
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor.withOpacity(0.1),
                        ),
                        child: Icon(
                          _transaction.isSuccess
                              ? Icons.check_circle
                              : (_transaction.isPending
                                    ? Icons.access_time
                                    : Icons.cancel),
                          color: statusColor,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _transaction.status.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _transaction.createdAt,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      const Divider(thickness: 1, height: 1),
                    ],
                  ),
                ),
              ),

              // Isi Struk (Tengah)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _receiptSection('INFORMASI TOKO', [
                      _receiptRow('Nama Toko', _transaction.namaToko),
                    ]),
                    _receiptSection('INFORMASI', [
                      _receiptRow(
                        'Ref ID',
                        _transaction.refId,
                        isCopyable: true,
                      ),
                      _receiptRow('Pelanggan', _transaction.customerName),
                      _receiptRow(
                        'No. Pelanggan',
                        _transaction.customerNo,
                        isCopyable: true,
                      ),
                    ]),
                    _receiptSection('DETAIL PRODUK', [
                      _receiptRow('Produk', _transaction.productName),
                      _receiptRow('Brand', _transaction.brand),
                      _receiptRow('SKU Code', _transaction.buyerSkuCode),
                      if (_transaction.daya != null)
                        _receiptRow('Daya', '${_transaction.daya} VA'),
                      if (_transaction.lembarTagihan != null)
                        _receiptRow(
                          'Lembar Tagihan',
                          '${_transaction.lembarTagihan}',
                        ),
                    ]),
                    _receiptSection('TAGIHAN', [
                      _receiptRow('Periode', _transaction.formattedPeriode),
                      _receiptRow(
                        'Nilai Tagihan',
                        _transaction.formattedNilaiTagihan,
                      ),
                      _receiptRow(
                        'Admin',
                        _transaction.formattedAdmin,
                        color: Colors.orange,
                      ),
                      _receiptRow(
                        'Denda',
                        _transaction.formattedDenda,
                        color: Colors.red,
                      ),
                    ]),
                    _receiptSection('PEMBAYARAN', [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: DottedLine(),
                      ),
                      _receiptRow(
                        'TOTAL',
                        _transaction.formattedTotal,
                        isBold: true,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ]),
                    _receiptSection('STRUK', [
                      _receiptRow(
                        'Serial Number',
                        _transaction.sn,
                        isSn: true,
                        isCopyable: true,
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Efek Potongan Struk Bawah
              CustomPaint(
                painter: TicketClipper(isTop: false),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Colors.white),
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
                  child: Column(
                    children: [
                      Text(
                        "Terima kasih telah bertransaksi",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Share and Print Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _handleSharePressed,
                            icon: const Icon(Icons.share),
                            label: const Text('Bagikan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isPrinting ? null : _handlePrintPressed,
                            icon: const Icon(Icons.print_rounded),
                            label: const Text('Cetak'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home),
            label: const Text('Beranda'),
            style: ElevatedButton.styleFrom(
              backgroundColor: appConfig.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _receiptRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 13,
    Color? color,
    bool isSn = false,
    bool isCopyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(width: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                      fontSize: fontSize,
                      fontFamily: isSn
                          ? 'Courier'
                          : null, // Gunakan font monospace jika ada untuk SN
                      color: color ?? Colors.black87,
                    ),
                  ),
                ),
                if (isCopyable)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$label tersalin'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Icon(
                        Icons.copy,
                        size: 14,
                        color: appConfig.primaryColor,
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
}

// Painter untuk membuat efek zigzag potongan kertas
class TicketClipper extends CustomPainter {
  final bool isTop;
  TicketClipper({required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    Path path = Path();

    if (isTop) {
      path.moveTo(0, 10);
      double x = 0;
      double y = 10;
      double increment = size.width / 20;

      while (x < size.width) {
        x += increment;
        y = (y == 10) ? 0 : 10;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height - 10);
      double x = size.width;
      double y = size.height - 10;
      double increment = size.width / 20;

      while (x > 0) {
        x -= increment;
        y = (y == size.height - 10) ? size.height : size.height - 10;
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Widget Garis Putus-putus (Dotted Line)
class DottedLine extends StatelessWidget {
  const DottedLine({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            (constraints.constrainWidth() / 8).floor(),
            (index) => SizedBox(
              width: 4,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey[300]),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Bluetooth Device Discovery Page
class _BluetoothDeviceDiscoveryPage extends StatefulWidget {
  final BluetoothPrinterService printerService;
  final Function(dynamic) onDeviceSelected;

  const _BluetoothDeviceDiscoveryPage({
    required this.printerService,
    required this.onDeviceSelected,
  });

  @override
  State<_BluetoothDeviceDiscoveryPage> createState() =>
      _BluetoothDeviceDiscoveryPageState();
}

class _BluetoothDeviceDiscoveryPageState
    extends State<_BluetoothDeviceDiscoveryPage> {
  List<dynamic> _discoveredDevices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    setState(() => _isScanning = true);
    try {
      // Get available devices (scan for new devices)
      // This uses the platform channel to get a fresh list
      final devices = await widget.printerService.getPairedDevices();
      if (mounted) {
        setState(() {
          _discoveredDevices = devices;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal melakukan pemindaian: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Printer Bluetooth'),
        backgroundColor: appConfig.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: appConfig.primaryColor,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: _isScanning
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(appConfig.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  const Text('Mencari printer Bluetooth...'),
                ],
              ),
            )
          : _discoveredDevices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bluetooth_disabled,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text('Tidak ada printer ditemukan'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _startDiscovery,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appConfig.primaryColor,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _discoveredDevices.length,
              itemBuilder: (context, index) {
                final device = _discoveredDevices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(device.toString()),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onDeviceSelected(device);
                    },
                  ),
                );
              },
            ),
    );
  }
}
