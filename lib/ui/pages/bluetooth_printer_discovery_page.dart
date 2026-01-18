import 'package:flutter/material.dart';
import '../../core/app_config.dart';
import '../../core/services/bluetooth_printer_service.dart';

/// Global Bluetooth Printer Discovery Page
/// Dapat digunakan dari berbagai halaman (Prabayar, Pascabayar, dll)
class BluetoothPrinterDiscoveryPage extends StatefulWidget {
  final Function(dynamic) onDeviceSelected;

  const BluetoothPrinterDiscoveryPage({
    super.key,
    required this.onDeviceSelected,
  });

  @override
  State<BluetoothPrinterDiscoveryPage> createState() =>
      _BluetoothPrinterDiscoveryPageState();
}

class _BluetoothPrinterDiscoveryPageState
    extends State<BluetoothPrinterDiscoveryPage> {
  late BluetoothPrinterService _printerService;
  List<dynamic> _discoveredDevices = [];
  bool _isScanning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _printerService = BluetoothPrinterService();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _discoveredDevices = [];
    });

    try {
      debugPrint('🔍 Starting Bluetooth device discovery...');
      debugPrint('🔧 BluetoothPrinterService: $_printerService');

      // Request permissions if needed
      final hasPermission = await _printerService.requestPermissions();
      debugPrint('✅ Permissions granted: $hasPermission');

      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _errorMessage = 'Izin Bluetooth diperlukan untuk mencari device';
          });
        }
        return;
      }

      // Get paired devices
      debugPrint('📱 Fetching paired devices...');
      final devices = await _printerService.getPairedDevices();

      debugPrint('📊 Devices retrieved: ${devices.length} device(s)');
      for (int i = 0; i < devices.length; i++) {
        debugPrint('  Device $i: $devices[$i]');
      }

      if (mounted) {
        setState(() {
          _discoveredDevices = devices;
          _isScanning = false;
          debugPrint('✅ Found ${devices.length} devices');
          if (devices.isEmpty) {
            _errorMessage =
                'Tidak ada printer Bluetooth yang terpasang.\n\nJika printer Anda sudah dipasangkan, coba:\n1. Nyalakan ulang Bluetooth\n2. Periksa izin Bluetooth di Pengaturan\n3. Hubungkan manual dari Pengaturan Bluetooth';
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Discovery error: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: ${e.toString()}');

      if (mounted) {
        setState(() {
          _isScanning = false;
          _errorMessage =
              'Gagal melakukan pemindaian:\n$e\n\nCara mengatasi:\n1. Pastikan Bluetooth HP aktif\n2. Pastikan printer Bluetooth aktif\n3. Coba hubungkan dari Pengaturan terlebih dahulu\n4. Tutup dan buka aplikasi kembali';
        });
      }
    }
  }

  void _selectDevice(dynamic device) {
    debugPrint('✅ Device selected: $device');
    Navigator.pop(context);
    widget.onDeviceSelected(device);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = appConfig.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cari Printer Bluetooth',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: _isScanning
          ? _buildScanningState(primaryColor)
          : _errorMessage != null
          ? _buildErrorState(primaryColor)
          : _discoveredDevices.isEmpty
          ? _buildEmptyState(primaryColor)
          : _buildDeviceListState(),
    );
  }

  Widget _buildScanningState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(primaryColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          const Text(
            'Mencari printer Bluetooth...',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pastikan printer Bluetooth dalam jangkauan',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color primaryColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Terjadi Kesalahan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Kesalahan tidak diketahui',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            // Debug Error Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔍 INFORMASI DEBUG:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pesan Error:\n${_errorMessage ?? "Tidak ada pesan"}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '💡 SOLUSI:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '1. Periksa logcat/console untuk detail error\n'
                    '2. Pastikan native Bluetooth service sudah diimplementasikan\n'
                    '3. Cek AndroidManifest.xml permissions\n'
                    '4. Restart device Anda',
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _startDiscovery,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Printer Ditemukan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pastikan printer Bluetooth sudah dipasangkan dengan perangkat ini',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            // Debug Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔧 DEBUG INFO:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Devices ditemukan: ${_discoveredDevices.length}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  if (_discoveredDevices.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Daftar Perangkat:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ..._discoveredDevices.asMap().entries.map((entry) {
                          final index = entry.key;
                          final device = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$index. $device',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    '📋 Tips:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '1. Nyalakan Bluetooth di perangkat Anda\n'
                    '2. Nyalakan printer Bluetooth\n'
                    '3. Hubungkan printer dari Pengaturan Bluetooth terlebih dahulu\n'
                    '4. Kembali ke layar ini dan klik "Coba Lagi"',
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _startDiscovery,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceListState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _discoveredDevices.length,
      itemBuilder: (context, index) {
        final device = _discoveredDevices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          child: ListTile(
            leading: Icon(Icons.print, color: appConfig.primaryColor),
            title: Text(
              device.toString(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _selectDevice(device),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
        );
      },
    );
  }
}
