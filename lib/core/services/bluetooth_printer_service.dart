import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Simple Bluetooth Printer Service using Android Native Code
/// This avoids dependency conflicts with Bluetooth printer packages
class BluetoothPrinterService {
  static final BluetoothPrinterService _instance =
      BluetoothPrinterService._internal();

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
  }) {
    final statusText = status == 'SUKSES' ? 'BERHASIL' : 'GAGAL';
    final divider = '================================';

    return '''

BUYSINDO
$divider
TRANSAKSI $statusText
$tanggalTransaksi

$divider
INFORMASI
Ref ID: $refId

DETAIL PRODUK
Produk: $productName
Nomor: $nomorHp

PEMBAYARAN
Harga: $price
Total: $totalPrice

$divider
Terima kasih telah bertransaksi


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
