import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../features/customer/data/models/transaction_mutasi_model.dart';
import '../../../../../core/app_config.dart';
import '../../../../../core/services/bluetooth_printer_service.dart';
import '../../../../../ui/widgets/bluetooth_device_selection_dialog.dart';

class TransactionMutasiDetailPage extends StatefulWidget {
  final TransactionMutasi transaction;

  const TransactionMutasiDetailPage({Key? key, required this.transaction})
    : super(key: key);

  @override
  State<TransactionMutasiDetailPage> createState() =>
      _TransactionMutasiDetailPageState();
}

class _TransactionMutasiDetailPageState
    extends State<TransactionMutasiDetailPage> {
  late TransactionMutasi transaction;
  late BluetoothPrinterService _printerService;

  @override
  void initState() {
    super.initState();
    transaction = widget.transaction;
    _printerService = BluetoothPrinterService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _getValidAppBarColor(),
        title: const Text(
          'Detail Mutasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.white,
        elevation: 4,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: _getValidAppBarColor(),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Card dengan status
            _buildStatusCard(),
            const SizedBox(height: 20),

            // Main Details Card
            _buildDetailsCard(),
            const SizedBox(height: 20),

            // Saldo Info Card
            _buildSaldoCard(),
            const SizedBox(height: 20),

            // Fee Details Card
            _buildFeeCard(),
            const SizedBox(height: 80), // Add space for bottom bar
          ],
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
            onPressed: _handlePrint,
            icon: const Icon(Icons.print),
            label: const Text('Cetak'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
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

  Widget _buildStatusCard() {
    final isDebit = transaction.isDebit;
    final statusColor = isDebit ? Colors.red : Colors.green;

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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDebit ? Icons.arrow_downward : Icons.arrow_upward,
              color: statusColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            transaction.formattedJumlah,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isDebit ? 'Pengeluaran' : 'Pemasukan',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              transaction.keterangan,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          _buildDetailRow('ID Transaksi', transaction.trxId, isMono: true),
          const Divider(height: 16),
          _buildDetailRow('Tanggal', transaction.createdAt),
          const Divider(height: 16),
          _buildDetailRow('Username', transaction.username),
          const Divider(height: 16),
          _buildDetailRow('Nama Toko', transaction.namaToko ?? '-'),
          const Divider(height: 16),
          _buildDetailRow('Keterangan', transaction.keterangan),
        ],
      ),
    );
  }

  Widget _buildSaldoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            'Ringkasan Saldo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildSaldoRow(
            'Saldo Awal',
            transaction.formattedSaldoAwal,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.grey[200]),
          const SizedBox(height: 12),
          _buildSaldoRow(
            'Perubahan',
            transaction.formattedJumlah,
            transaction.isDebit ? Colors.red : Colors.green,
          ),
          const SizedBox(height: 12),
          Container(height: 2, color: Colors.grey[300]),
          const SizedBox(height: 12),
          _buildSaldoRow(
            'Saldo Akhir',
            transaction.formattedSaldoAkhir,
            Colors.green,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            'Detail Biaya',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildFeeRow('Markup Admin', transaction.formattedMarkupAdmin),
          const SizedBox(height: 12),
          _buildFeeRow('Admin Fee', transaction.formattedAdminFee),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.grey[200]),
          const SizedBox(height: 12),
          _buildFeeRow(
            'Total Biaya',
            'Rp ${(transaction.markupAdmin + transaction.adminFee).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMono = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              fontFamily: isMono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaldoRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getValidAppBarColor() {
    final primaryColor = appConfig.primaryColor;
    // Check for invalid values: 0, white, or transparent
    if (primaryColor.value == 0 ||
        primaryColor.value == 0xFFFFFFFF || // Not white
        primaryColor.alpha < 200) {
      // Not too transparent
      return const Color(0xFF0D6EFD);
    }
    // Ensure color has sufficient brightness for contrast
    if (primaryColor.computeLuminance() >= 0.9) {
      return const Color(0xFF0D6EFD);
    }
    return primaryColor;
  }

  void _handlePrint() {
    _handlePrintPressed();
  }

  Future<void> _handleCopyReference() async {
    try {
      final referenceText =
          'Trx ID: ${transaction.trxId}\nTanggal: ${transaction.createdAt}\nJumlah: ${transaction.formattedJumlah}';
      await Clipboard.setData(ClipboardData(text: referenceText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reference ID berhasil disalin ke clipboard'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error copying reference: $e');
      _showError('Gagal menyalin reference ID');
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

    try {
      // Get paired devices
      final devices = await _printerService.getPairedDevices();

      if (!mounted) return;

      if (devices.isEmpty) {
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
        return;
      }

      // Connect to device
      final connected = await _printerService.connect(selectedDevice);
      if (!connected) {
        if (mounted) {
          _showError('Gagal terhubung ke printer');
        }
        return;
      }

      // Print receipt dengan format mutasi
      final printed = await _printerService.printMutasiReceipt(
        trxId: transaction.trxId,
        username: transaction.username,
        jumlah: transaction.formattedJumlah,
        isDebit: transaction.isDebit,
        saldoAwal: transaction.formattedSaldoAwal,
        saldoAkhir: transaction.formattedSaldoAkhir,
        keterangan: transaction.keterangan,
        createdAt: transaction.createdAt,
        namaToko: transaction.namaToko?.isNotEmpty ?? false
            ? transaction.namaToko
            : null,
        markupAdmin: transaction.formattedMarkupAdmin,
        adminFee: transaction.formattedAdminFee,
      );

      if (mounted) {
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
        _showError('Terjadi kesalahan saat mencetak: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
