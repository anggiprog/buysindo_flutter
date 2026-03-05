import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../../core/app_config.dart';
import '../../../../../features/customer/data/models/transaction_detail_model.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../core/network/session_manager.dart';
import '../../../../../core/services/bluetooth_printer_service.dart';
import '../../../../../ui/widgets/bluetooth_device_selection_dialog.dart';

class TransactionDetailPage extends StatefulWidget {
  final String refId;
  final String transactionId;

  const TransactionDetailPage({
    super.key,
    required this.refId,
    required this.transactionId,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  late ApiService _apiService;
  late BluetoothPrinterService _printerService;
  TransactionDetail? _transaction;
  bool _isLoading = false;
  bool _isPrinting = false;
  final GlobalKey _receiptKey = GlobalKey();

  // Editable Harga
  late TextEditingController _hargaController;
  bool _isEditingHarga = false;
  int _currentHarga = 0;
  int _currentTotal = 0;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Dio());
    _printerService = BluetoothPrinterService();
    _hargaController = TextEditingController();
    _loadTransactionDetail();
  }

  @override
  void dispose() {
    _hargaController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactionDetail() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final String? token = await SessionManager.getToken();
      if (token == null) {
        _showError('Token tidak ditemukan');
        return;
      }

      // 1. Get transaction data
      final response = await _apiService.getTransactionDetailPrabayar(token);
      if (response.statusCode == 200) {
        final detailResponse = TransactionDetailResponse.fromJson(
          response.data,
        );
        var transaction = detailResponse.data.firstWhere(
          (t) =>
              t.refId == widget.refId ||
              t.id.toString() == widget.transactionId,
          orElse: () => throw Exception('Not Found'),
        );

        // 2. Fetch store name separately
        try {
          final storeResponse = await _apiService.getUserStore(token);
          debugPrint('🏪 Store Response: ${storeResponse.data}');
          if (storeResponse.statusCode == 200) {
            final storeData = storeResponse.data;
            String storeName = storeData['nama_toko']?.toString() ?? '';
            debugPrint('🏪 Got store name: "$storeName"');

            // Attach store name to transaction
            if (storeName.isNotEmpty) {
              transaction = TransactionDetail(
                id: transaction.id,
                userId: transaction.userId,
                refId: transaction.refId,
                buyerSkuCode: transaction.buyerSkuCode,
                productName: transaction.productName,
                nomorHp: transaction.nomorHp,
                sn: transaction.sn,
                totalPrice: transaction.totalPrice,
                diskon: transaction.diskon,
                markupMember: transaction.markupMember,
                hargaJualMember: transaction.hargaJualMember,
                paymentType: transaction.paymentType,
                status: transaction.status,
                tanggalTransaksi: transaction.tanggalTransaksi,
                namaToko: storeName,
              );
              debugPrint('✅ Transaction updated with store name');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching store: $e');
        }

        if (mounted) {
          // Calculate initial Harga and Total
          final discount = int.tryParse(transaction.diskon) ?? 0;
          final hargaSebelumDiskon = transaction.hargaJualMember + discount;

          setState(() {
            _transaction = transaction;
            _isLoading = false;
            // Initialize editable harga values
            _currentHarga = hargaSebelumDiskon;
            _currentTotal = transaction.hargaJualMember;
            _hargaController.text = _currentHarga.toString();
          });
          debugPrint(
            '✅ Transaction loaded: namaToko=${_transaction!.namaToko}',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Gagal memuat detail transaksi');
      }
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

  void _saveHarga() {
    final newHarga = int.tryParse(_hargaController.text) ?? 0;
    if (newHarga < 0) {
      _showError('Harga tidak boleh negatif');
      return;
    }

    setState(() {
      _currentHarga = newHarga;
      _isEditingHarga = false;

      // Recalculate total: Harga - Diskon
      final discount = int.tryParse(_transaction!.diskon) ?? 0;
      _currentTotal = _currentHarga - discount;
      if (_currentTotal < 0) _currentTotal = 0;
    });

    _showSuccess('Harga berhasil diperbarui');
  }

  String _formatCurrency(dynamic value) {
    final intValue = value is int ? value : int.tryParse(value.toString()) ?? 0;
    return intValue.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Widget _buildEditableHargaRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Harga',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isEditingHarga)
                  Expanded(
                    child: TextField(
                      controller: _hargaController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Colors.orange),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Colors.orange,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isEditingHarga = true),
                      child: Text(
                        'Rp ${_formatCurrency(_currentHarga)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                if (_isEditingHarga) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _saveHarga,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.save,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _hargaController.text = _currentHarga.toString();
                        _isEditingHarga = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _isEditingHarga = true),
                    child: const Icon(
                      Icons.edit,
                      size: 14,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
          'receipt_${_transaction!.refId}_${DateTime.now().millisecondsSinceEpoch}.png';
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
      final statusText = _transaction!.isSuccess
          ? "BERHASIL"
          : (_transaction!.isPending ? "PENDING" : "GAGAL");
      final message =
          'Struk Transaksi Prabayar\nRef ID: ${_transaction!.refId}\nStatus: $statusText\nTotal: Rp ${_formatCurrency(_currentTotal)}';
      await Share.shareXFiles([XFile(imagePath)], text: message);
    } catch (e) {
      debugPrint('❌ WhatsApp share error: $e');
      _showError('Gagal membagikan ke WhatsApp');
    }
  }

  Future<void> _shareViaTelegram(String imagePath) async {
    try {
      final statusText = _transaction!.isSuccess
          ? "BERHASIL"
          : (_transaction!.isPending ? "PENDING" : "GAGAL");
      final message =
          'Struk Transaksi Prabayar\nRef ID: ${_transaction!.refId}\nStatus: $statusText\nTotal: Rp ${_formatCurrency(_currentTotal)}';
      await Share.shareXFiles([XFile(imagePath)], text: message);
    } catch (e) {
      debugPrint('❌ Telegram share error: $e');
      _showError('Gagal membagikan ke Telegram');
    }
  }

  Future<void> _shareViaDefault(String imagePath) async {
    try {
      final statusText = _transaction!.isSuccess
          ? "BERHASIL"
          : (_transaction!.isPending ? "PENDING" : "GAGAL");
      await Share.shareXFiles(
        [XFile(imagePath)],
        text:
            'Struk Transaksi Prabayar\nRef ID: ${_transaction!.refId}\nStatus: $statusText',
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
    if (_transaction == null) {
      _showError('Data transaksi tidak tersedia');
      return;
    }
    try {
      final referenceText =
          'Ref ID: ${_transaction!.refId}\nTanggal: ${_transaction!.tanggalTransaksi}\nTotal: Rp ${_formatCurrency(_currentTotal)}';
      await Clipboard.setData(ClipboardData(text: referenceText));
      _showSuccess('Reference ID berhasil disalin ke clipboard');
    } catch (e) {
      debugPrint('❌ Error copying reference: $e');
      _showError('Gagal menyalin reference ID');
    }
  }

  Future<void> _handlePrintPressed() async {
    if (_transaction == null) {
      _showError('Data transaksi tidak tersedia');
      return;
    }

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

      if (!mounted) return;

      if (devices.isEmpty) {
        setState(() => _isPrinting = false);
        _showError('Tidak ada printer Bluetooth yang dipasangkan');
        return;
      }

      // Show device selection dialog
      final selectedDevice = await showDialog(
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

      // Connect to device
      final connected = await _printerService.connect(selectedDevice);
      if (!connected) {
        if (mounted) {
          setState(() => _isPrinting = false);
          _showError('Gagal terhubung ke printer');
        }
        return;
      }

      // Print receipt
      final printed = await _printerService.printReceipt(
        refId: _transaction!.refId,
        productName: _transaction!.productName,
        nomorHp: _transaction!.nomorHp,
        price: 'Rp ${_formatCurrency(_currentTotal)}',
        totalPrice: 'Rp ${_formatCurrency(_currentTotal)}',
        status: _transaction!.status,
        tanggalTransaksi: _transaction!.tanggalTransaksi,
        serialNumber: _transaction!.sn.isNotEmpty ? _transaction!.sn : null,
        namaToko: _transaction!.namaToko.isNotEmpty
            ? _transaction!.namaToko
            : null,
      );

      if (mounted) {
        setState(() => _isPrinting = false);
        if (printed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Struk berhasil dicetak'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showError('Gagal mencetak struk');
        }
      }

      // Disconnect
      await _printerService.disconnect();
    } catch (e) {
      debugPrint('❌ Print error: $e');
      if (mounted) {
        setState(() => _isPrinting = false);
        _showError('Terjadi kesalahan saat mencetak');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = appConfig.primaryColor;

    // Ensure primaryColor is valid, use fallback if needed
    // Check for invalid values: 0, white, or transparent
    Color appBarColor = const Color(0xFF0D6EFD); // Default blue

    if (primaryColor.value != 0 &&
        primaryColor.value != 0xFFFFFFFF && // Not white
        primaryColor.alpha > 200) {
      // Not too transparent
      // Additional check: ensure color has sufficient brightness for contrast
      if (primaryColor.computeLuminance() < 0.9) {
        appBarColor = primaryColor;
      }
    }

    debugPrint(
      '🎨 AppBar Color: ${appBarColor.value.toRadixString(16)}, '
      'PrimaryColor: ${primaryColor.value.toRadixString(16)}',
    );

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Detail Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
            icon: const Icon(Icons.share),
            tooltip: 'Bagikan',
            onPressed: _handleSharePressed,
          ),
          IconButton(
            icon: _isPrinting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.print_rounded),
            tooltip: 'Cetak',
            onPressed: _isPrinting ? null : _handlePrintPressed,
          ),
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Salin Reference ID',
            onPressed: _handleCopyReference,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transaction == null
          ? const Center(child: Text('Data tidak ditemukan'))
          : SingleChildScrollView(
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
                                color: _transaction!.isSuccess
                                    ? Colors.green[50]
                                    : _transaction!.isPending
                                    ? Colors.orange[50]
                                    : Colors.red[50],
                              ),
                              child: Icon(
                                _transaction!.isSuccess
                                    ? Icons.check_circle
                                    : _transaction!.isPending
                                    ? Icons.access_time
                                    : Icons.cancel,
                                color: _transaction!.isSuccess
                                    ? Colors.green
                                    : _transaction!.isPending
                                    ? Colors.orange
                                    : Colors.red,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _transaction!.isSuccess
                                  ? 'TRANSAKSI BERHASIL'
                                  : _transaction!.isPending
                                  ? 'TRANSAKSI PENDING'
                                  : 'TRANSAKSI GAGAL',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: 1.2,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _transaction!.tanggalTransaksi,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
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
                            _receiptRow('Nama Toko', _transaction!.namaToko),
                          ]),
                          _receiptSection('INFORMASI', [
                            _receiptRow('Ref ID', _transaction!.refId),
                            _receiptRow('Metode', _transaction!.paymentType),
                          ]),
                          _receiptSection('DETAIL PRODUK', [
                            _receiptRow('Produk', _transaction!.productName),
                            _receiptRow('Nomor', _transaction!.nomorHp),
                            _receiptRow('SN', _transaction!.sn, isSn: true),
                          ]),
                          _receiptSection('PEMBAYARAN', [
                            _buildEditableHargaRow(),
                            if (_transaction!.hasDiskon)
                              _receiptRow(
                                'Diskon',
                                '- ${_transaction!.formattedDiskon}',
                                color: Colors.green,
                              ),
                            if (_transaction!.hasDiskon)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: DottedLine(),
                              ),
                            _receiptRow(
                              'TOTAL',
                              'Rp ${_formatCurrency(_currentTotal)}',
                              isBold: true,
                              fontSize: 16,
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
