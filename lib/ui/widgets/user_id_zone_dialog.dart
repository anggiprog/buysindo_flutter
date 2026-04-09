import 'package:flutter/material.dart';

class UserIdZoneDialog extends StatefulWidget {
  final String productName;
  final String productBrand;
  final bool needsZoneId;
  final Function(String userId, String? zoneId) onSubmit;
  final VoidCallback onCancel;

  const UserIdZoneDialog({
    super.key,
    required this.productName,
    required this.productBrand,
    required this.needsZoneId,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<UserIdZoneDialog> createState() => _UserIdZoneDialogState();
}

class _UserIdZoneDialogState extends State<UserIdZoneDialog> {
  late TextEditingController _userIdController;
  late TextEditingController _zoneIdController;
  bool _isLoading = false;

  // Map game brands yang memerlukan Zone ID/Server ID/Character ID
  static const Map<String, String> gamesWithSecondaryId = {
    'MOBILE LEGENDS': 'Zone ID',
    'ML': 'Zone ID',
    'PUBG': 'Character ID',
    'PUBG MOBILE': 'Character ID',
    'AOV': 'Server ID',
    'ARENA OF VALOR': 'Server ID',
    'CALL OF DUTY': 'Character ID',
    'COD': 'Character ID',
    'FREE FIRE': 'Zone ID',
    'FF': 'Zone ID',
  };

  @override
  void initState() {
    super.initState();
    _userIdController = TextEditingController();
    _zoneIdController = TextEditingController();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _zoneIdController.dispose();
    super.dispose();
  }

  String _getSecondaryIdLabel() {
    final brand = widget.productBrand.toUpperCase();
    for (final entry in gamesWithSecondaryId.entries) {
      if (brand.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'Zone ID';
  }

  Future<void> _handleSubmit() async {
    final userId = _userIdController.text.trim();
    final zoneId = _zoneIdController.text.trim();

    // Validasi User ID
    if (userId.isEmpty) {
      _showError('User ID tidak boleh kosong');
      return;
    }

    // Validasi format User ID (hanya angka)
    if (!RegExp(r'^[0-9]+$').hasMatch(userId)) {
      _showError('User ID harus berupa angka');
      return;
    }

    // Zone ID bersifat optional - hanya validasi format jika ada
    if (zoneId.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(zoneId)) {
      _showError('Zone ID harus berupa angka');
      return;
    }

    setState(() => _isLoading = true);

    // Simulasi delay untuk proses validasi
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);

      // DEBUG: Lihat data yang dikirim
      // 
      // 
      // 
      // 

      widget.onSubmit(userId, widget.needsZoneId ? zoneId : null);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Masukkan Data Akun',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Untuk: ${widget.productName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onCancel();
                    },
                    child: Icon(Icons.close, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.needsZoneId
                            ? 'Masukkan User ID (wajib). ${_getSecondaryIdLabel()} opsional untuk game ini'
                            : 'Masukkan User ID akun Anda',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // User ID Field
              Text(
                'User ID',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _userIdController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Masukkan User ID',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Secondary ID Field (Zone ID / Character ID / Server ID) - conditional
              if (widget.needsZoneId) ...[
                Text(
                  '${_getSecondaryIdLabel()} (Opsional)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _zoneIdController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Masukkan ${_getSecondaryIdLabel()}',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: Colors.amber[700],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_getSecondaryIdLabel()} dapat ditemukan di pengaturan akun game Anda',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                              widget.onCancel();
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Lanjutkan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

