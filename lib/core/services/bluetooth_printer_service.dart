import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Simple Bluetooth Printer Service using Android Native Code
/// This avoids dependency conflicts with Bluetooth printer packages
class BluetoothPrinterService {
  static final BluetoothPrinterService _instance =
      BluetoothPrinterService._internal();

  // Updated MethodChannel to match Android package name com.buysindo.app
  static const platform = MethodChannel('com.buysindo.app/printer');

  factory BluetoothPrinterService() {
    return _instance;
  }

  BluetoothPrinterService._internal();

  /// Request Bluetooth permissions
  Future<bool> requestPermissions() async {
    try {
      debugPrint('🔵 Bluetooth Permissions requested');

      // For Android 12+, we need BLUETOOTH_CONNECT (critical)
      // BLUETOOTH_SCAN is for discovering devices
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();

      debugPrint('📋 Requested statuses: $statuses');

      // Check if at least the critical permission (BLUETOOTH_CONNECT) is granted
      final hasBluetoothConnect =
          statuses[Permission.bluetoothConnect]?.isGranted ?? false;
      final hasBluetoothScan =
          statuses[Permission.bluetoothScan]?.isGranted ?? false;

      // We need at least one of these permissions to proceed
      final hasPermission = hasBluetoothConnect || hasBluetoothScan;

      debugPrint(
        '${hasPermission ? '✅' : '⚠️'} BLUETOOTH_CONNECT: $hasBluetoothConnect, BLUETOOTH_SCAN: $hasBluetoothScan',
      );

      // If permissions are denied, show a helpful message
      if (!hasPermission) {
        debugPrint(
          '❌ Critical Bluetooth permissions are denied. Please grant permissions in settings.',
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Get list of paired Bluetooth devices
  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      debugPrint('🔍 Getting paired devices...');

      final List<dynamic> result =
          await platform.invokeMethod<List<dynamic>>('getPairedDevices') ?? [];

      final devices = result
          .map((device) => BluetoothDevice.fromMap(device as Map))
          .toList();

      debugPrint('📱 Found ${devices.length} paired devices');
      for (var device in devices) {
        debugPrint('  - ${device.name} (${device.address})');
      }

      return devices;
    } catch (e) {
      debugPrint('❌ Error getting paired devices: $e');
      return [];
    }
  }

  /// Connect to a specific device
  Future<bool> connect(BluetoothDevice device) async {
    try {
      debugPrint('🔗 Connecting to ${device.name} (${device.address})...');

      final bool result =
          await platform.invokeMethod<bool>('connectDevice', {
            'address': device.address,
            'name': device.name,
          }) ??
          false;

      if (result) {
        debugPrint('✅ Connected to ${device.name}');
      } else {
        debugPrint('❌ Failed to connect to ${device.name}');
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error connecting: $e');
      return false;
    }
  }

  /// Disconnect from printer
  Future<void> disconnect() async {
    try {
      await platform.invokeMethod<void>('disconnect');
      debugPrint('✅ Disconnected from printer');
    } catch (e) {
      debugPrint('❌ Error disconnecting: $e');
    }
  }

  /// Check if connected to a printer
  Future<bool> isConnected() async {
    try {
      final bool result =
          await platform.invokeMethod<bool>('isConnected') ?? false;
      debugPrint('${result ? '✅' : '❌'} Connected: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error checking connection: $e');
      return false;
    }
  }

  /// Print receipt
  Future<bool> printReceipt({
    required String refId,
    required String productName,
    required String nomorHp,
    required String price,
    required String totalPrice,
    required String tanggalTransaksi,
    required String status,
    String? serialNumber,
    String? namaToko,
    String? customerName,
    String? brand,
    String? periode,
    String? nilaiTagihan,
    String? admin,
    String? denda,
    String? daya,
    String? lembarTagihan,
    String? meterAwal,
    String? meterAkhir,
  }) async {
    try {
      final connected = await isConnected();
      if (!connected) {
        debugPrint('❌ Not connected to printer');
        return false;
      }

      debugPrint('🖨️ Starting print...');

      // Build receipt data
      final receiptData = _generateReceiptText(
        refId: refId,
        productName: productName,
        nomorHp: nomorHp,
        price: price,
        totalPrice: totalPrice,
        tanggalTransaksi: tanggalTransaksi,
        status: status,
        serialNumber: serialNumber,
        namaToko: namaToko,
        customerName: customerName,
        brand: brand,
        periode: periode,
        nilaiTagihan: nilaiTagihan,
        admin: admin,
        denda: denda,
        daya: daya,
        lembarTagihan: lembarTagihan,
        meterAwal: meterAwal,
        meterAkhir: meterAkhir,
      );

      final bool result =
          await platform.invokeMethod<bool>('printReceipt', {
            'content': receiptData,
          }) ??
          false;

      if (result) {
        debugPrint('✅ Print completed');
      } else {
        debugPrint('❌ Print failed');
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error printing: $e');
      return false;
    }
  }

  /// Generate receipt text for thermal printer
  String _generateReceiptText({
    required String refId,
    required String productName,
    required String nomorHp,
    required String price,
    required String totalPrice,
    required String tanggalTransaksi,
    required String status,
    String? serialNumber,
    String? namaToko,
    String? customerName,
    String? brand,
    String? periode,
    String? nilaiTagihan,
    String? admin,
    String? denda,
    String? daya,
    String? lembarTagihan,
    String? meterAwal,
    String? meterAkhir,
  }) {
    final statusText = status.toUpperCase() == 'SUKSES'
        ? 'BERHASIL'
        : status.toUpperCase();
    final divider = '================================';
    final storeName = namaToko != null && namaToko.isNotEmpty
        ? namaToko
        : 'BUYSINDO';

    // Build detailed receipt
    final buffer = StringBuffer();

    buffer.writeln();
    buffer.writeln(storeName);
    buffer.writeln(divider);
    buffer.writeln('TRANSAKSI PASCABAYAR - $statusText');
    buffer.writeln(tanggalTransaksi);
    buffer.writeln();

    // Informasi Toko
    buffer.writeln(divider);
    buffer.writeln('INFORMASI TOKO');
    buffer.writeln('Nama Toko: $storeName');
    buffer.writeln();

    // Informasi Transaksi
    buffer.writeln(divider);
    buffer.writeln('INFORMASI TRANSAKSI');
    buffer.writeln('Ref ID: $refId');
    if (customerName != null && customerName.isNotEmpty) {
      buffer.writeln('Pelanggan: $customerName');
    }
    if (nomorHp.isNotEmpty) {
      buffer.writeln('No. Pelanggan: $nomorHp');
    }
    buffer.writeln();

    // Detail Produk
    buffer.writeln(divider);
    buffer.writeln('DETAIL PRODUK');
    buffer.writeln('Produk: $productName');
    if (brand != null && brand.isNotEmpty) {
      buffer.writeln('Brand: $brand');
    }
    if (daya != null && daya.isNotEmpty) {
      buffer.writeln('Daya: $daya');
    }
    if (lembarTagihan != null && lembarTagihan.isNotEmpty) {
      buffer.writeln('Lembar Tagihan: $lembarTagihan');
    }
    buffer.writeln();

    // Tagihan
    buffer.writeln(divider);
    buffer.writeln('DETAIL TAGIHAN');
    if (periode != null && periode.isNotEmpty) {
      buffer.writeln('Periode: $periode');
    }
    if (nilaiTagihan != null && nilaiTagihan.isNotEmpty) {
      buffer.writeln('Nilai Tagihan: $nilaiTagihan');
    }
    if (admin != null && admin.isNotEmpty) {
      buffer.writeln('Biaya Admin: $admin');
    }
    if (denda != null && denda.isNotEmpty) {
      buffer.writeln('Denda: $denda');
    }
    if (meterAwal != null && meterAwal.isNotEmpty) {
      buffer.writeln('Meter Awal: $meterAwal');
    }
    if (meterAkhir != null && meterAkhir.isNotEmpty) {
      buffer.writeln('Meter Akhir: $meterAkhir');
    }
    buffer.writeln();

    // Pembayaran
    buffer.writeln(divider);
    buffer.writeln('RINGKASAN PEMBAYARAN');
    buffer.writeln('Harga: $price');
    buffer.writeln('Total Pembayaran: $totalPrice');
    buffer.writeln();

    // Serial Number
    if (serialNumber != null && serialNumber.isNotEmpty) {
      buffer.writeln(divider);
      buffer.writeln('STRUK');
      buffer.writeln('Serial Number: $serialNumber');
      buffer.writeln();
    }

    buffer.writeln(divider);
    buffer.writeln('Terima kasih telah bertransaksi');
    buffer.writeln('dengan kami!');
    buffer.writeln();

    return buffer.toString();
  }

  /// Print Mutasi (Saldo Balance Log) receipt
  Future<bool> printMutasiReceipt({
    required String trxId,
    required String username,
    required String jumlah,
    required bool isDebit,
    required String saldoAwal,
    required String saldoAkhir,
    required String keterangan,
    required String createdAt,
    required String markupAdmin,
    required String adminFee,
    String? namaToko,
  }) async {
    try {
      debugPrint('🖨️ Starting print mutasi...');

      final receiptData = _generateMutasiReceiptText(
        trxId: trxId,
        username: username,
        jumlah: jumlah,
        isDebit: isDebit,
        saldoAwal: saldoAwal,
        saldoAkhir: saldoAkhir,
        keterangan: keterangan,
        createdAt: createdAt,
        markupAdmin: markupAdmin,
        adminFee: adminFee,
        namaToko: namaToko,
      );

      final bool result =
          await platform.invokeMethod<bool>('printReceipt', {
            'content': receiptData,
          }) ??
          false;

      if (result) {
        debugPrint('✅ Mutasi print completed');
      } else {
        debugPrint('❌ Mutasi print failed');
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error printing mutasi: $e');
      return false;
    }
  }

  /// Generate Mutasi receipt text for thermal printer
  String _generateMutasiReceiptText({
    required String trxId,
    required String username,
    required String jumlah,
    required bool isDebit,
    required String saldoAwal,
    required String saldoAkhir,
    required String keterangan,
    required String createdAt,
    required String markupAdmin,
    required String adminFee,
    String? namaToko,
  }) {
    final tipeTransaksi = isDebit ? 'PENGELUARAN' : 'PEMASUKAN';
    final storeName = namaToko != null && namaToko.isNotEmpty
        ? namaToko
        : 'BUYSINDO';
    final divider = '================================';

    return '''

$storeName - MUTASI SALDO
$divider

TRX ID: $trxId
Tanggal: $createdAt
Username: $username

$divider
TIPE TRANSAKSI
$tipeTransaksi
Keterangan: $keterangan

JUMLAH TRANSAKSI
$jumlah

$divider
RINGKASAN SALDO
Saldo Awal: $saldoAwal
Perubahan: $jumlah
Saldo Akhir: $saldoAkhir

$divider
DETAIL BIAYA
Markup Admin: $markupAdmin
Admin Fee: $adminFee

$divider
Terima kasih!


''';
  }
}

/// Bluetooth Device Model
class BluetoothDevice {
  final String name;
  final String address;
  final int? type;
  final bool? bonded;

  BluetoothDevice({
    required this.name,
    required this.address,
    this.type,
    this.bonded,
  });

  factory BluetoothDevice.fromMap(Map<dynamic, dynamic> map) {
    return BluetoothDevice(
      name: map['name'] ?? 'Unknown',
      address: map['address'] ?? '',
      type: map['type'],
      bonded: map['bonded'],
    );
  }

  @override
  String toString() => 'BluetoothDevice($name, $address)';
}
