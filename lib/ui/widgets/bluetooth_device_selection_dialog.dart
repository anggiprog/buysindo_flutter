import 'package:flutter/material.dart';
import 'package:rutino_customer/core/services/bluetooth_printer_service.dart';

class BluetoothDeviceSelectionDialog extends StatefulWidget {
  final List<BluetoothDevice> devices;
  final Function(BluetoothDevice) onDeviceSelected;

  const BluetoothDeviceSelectionDialog({
    super.key,
    required this.devices,
    required this.onDeviceSelected,
  });

  @override
  State<BluetoothDeviceSelectionDialog> createState() =>
      _BluetoothDeviceSelectionDialogState();
}

class _BluetoothDeviceSelectionDialogState
    extends State<BluetoothDeviceSelectionDialog> {
  BluetoothDevice? _selectedDevice;
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.print_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  'Pilih Printer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Device List
          if (widget.devices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.bluetooth_disabled, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'Tidak ada printer yang dipasangkan',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.devices.length,
                itemBuilder: (context, index) {
                  final device = widget.devices[index];
                  final isSelected = _selectedDevice?.address == device.address;

                  return ListTile(
                    leading: const Icon(Icons.print_rounded),
                    title: Text(device.name),
                    subtitle: Text(device.address),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedDevice = device;
                      });
                    },
                  );
                },
              ),
            ),

          // Divider
          const Divider(height: 1),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                    ),
                    onPressed: _isConnecting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                    ),
                    onPressed: _selectedDevice == null || _isConnecting
                        ? null
                        : _connect,
                    child: _isConnecting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Hubungkan',
                            style: TextStyle(color: Colors.white),
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

  Future<void> _connect() async {
    if (_selectedDevice == null) return;

    setState(() => _isConnecting = true);

    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pop(context, _selectedDevice);
    }
  }
}
