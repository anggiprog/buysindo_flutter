import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/session_manager.dart';

class TopupKonfirmasi extends StatefulWidget {
  final String nomorTransaksi;
  final int totalAmount;
  final Color primaryColor;
  final ApiService apiService;

  const TopupKonfirmasi({
    super.key,
    required this.nomorTransaksi,
    required this.totalAmount,
    required this.primaryColor,
    required this.apiService,
  });

  @override
  State<TopupKonfirmasi> createState() => _TopupKonfirmasiState();
}

class _TopupKonfirmasiState extends State<TopupKonfirmasi> {
  File? _selectedImageFile; // For mobile
  List<int>? _selectedImageBytes; // For web - stores image bytes
  String? _selectedImageFileName; // Store filename for both platforms
  bool _isUploading = false;
  final ImagePicker _imagePicker = ImagePicker();

  final currencyFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Future<void> _pickImageFromCamera() async {
    try {
      print('🔍 [CONFIRM] Opening camera to capture proof...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        print('✅ [CONFIRM] Image captured: ${image.path}');
        print('🔍 [CONFIRM] Image name: ${image.name}');

        // Read as bytes for both web and mobile
        final imageBytes = await image.readAsBytes();
        print('✅ [CONFIRM] Image bytes loaded: ${imageBytes.length} bytes');

        if (mounted) {
          setState(() {
            _selectedImageBytes = imageBytes;
            _selectedImageFileName = image.name;
            // Also save file path for mobile
            if (!kIsWeb) {
              _selectedImageFile = File(image.path);
            }
          });
          print('✅ [CONFIRM] Image preview updated');
        }
      } else {
        print('⚠️ [CONFIRM] No image selected from camera');
      }
    } catch (e, stackTrace) {
      print('❌ [CONFIRM] Camera error: $e');
      print('❌ [CONFIRM] StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka kamera: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      print('🔍 [CONFIRM] Opening gallery to select proof...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        print('✅ [CONFIRM] Image selected: ${image.path}');
        print('🔍 [CONFIRM] Image name: ${image.name}');

        // Read as bytes for both web and mobile
        final imageBytes = await image.readAsBytes();
        print('✅ [CONFIRM] Image bytes loaded: ${imageBytes.length} bytes');

        if (mounted) {
          setState(() {
            _selectedImageBytes = imageBytes;
            _selectedImageFileName = image.name;
            // Also save file path for mobile
            if (!kIsWeb) {
              _selectedImageFile = File(image.path);
            }
          });
          print('✅ [CONFIRM] Image preview updated');
        }
      } else {
        print('⚠️ [CONFIRM] No image selected from gallery');
      }
    } catch (e, stackTrace) {
      print('❌ [CONFIRM] Gallery error: $e');
      print('❌ [CONFIRM] StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka galeri: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _uploadProof() async {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih foto bukti terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isUploading = true);

      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      print('🔍 [CONFIRM] Starting upload process...');
      print('🔍 [CONFIRM] No. Transaksi: ${widget.nomorTransaksi}');
      print('🔍 [CONFIRM] Image size: ${_selectedImageBytes!.length} bytes');

      final response = await widget.apiService.uploadPaymentProof(
        nomorTransaksi: widget.nomorTransaksi,
        photoPath: _selectedImageFile?.path,
        photoBytes: _selectedImageBytes,
        photoFileName: _selectedImageFileName,
        userToken: token,
      );

      print('✅ [CONFIRM] Upload response status: ${response.statusCode}');
      print('✅ [CONFIRM] Response data: ${response.data}');

      // Validate response
      bool isSuccess = false;
      if (response.statusCode == 200) {
        // Check if response indicates success
        if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          final status = data['status'];
          // Accept: true, "true", 1, "success"
          isSuccess =
              status == true ||
              status == 'true' ||
              status == 1 ||
              status == 'success';

          print('✅ [CONFIRM] Response status field: $status');
          print('✅ [CONFIRM] Is success: $isSuccess');
        } else {
          isSuccess = true; // Assume success if 200
        }
      }

      if (!isSuccess) {
        throw Exception(
          'Upload failed: Server returned error or invalid response',
        );
      }

      if (mounted) {
        setState(() => _isUploading = false);

        // Show success dialog with white background
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Berhasil',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Bukti transfer berhasil diunggah.\n\n'
              'Saldo Anda akan diproses dalam beberapa menit. \n\n'
              'Silahkan hubungi customer service jika ada kendala.',
              style: TextStyle(color: Colors.black87, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to topup_manual
                  Navigator.of(context).pop(); // Go back to home
                },
                style: TextButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Kembali ke Beranda',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ [CONFIRM] Upload error: $e');
      if (mounted) {
        setState(() => _isUploading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah bukti: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
        title: const Text(
          'Konfirmasi Pembayaran',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Info Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Transaksi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Badge: Dari Database
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green[300]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Nomor transaksi dari database',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nomor Transaksi:',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        Text(
                          widget.nomorTransaksi,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Transfer:',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        Text(
                          currencyFormatter.format(widget.totalAmount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Instructions
              Text(
                'Upload Bukti Transfer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ambil foto atau pilih dari galeri bukti transfer Anda untuk verifikasi',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Image Preview or Placeholder
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child:
                    _selectedImageBytes != null &&
                        _selectedImageBytes!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          Uint8List.fromList(_selectedImageBytes!),
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                                if (frame == null) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: widget.primaryColor,
                                    ),
                                  );
                                }
                                return child;
                              },
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ [CONFIRM] Image display error: $error');
                            print('❌ [CONFIRM] StackTrace: $stackTrace');
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    size: 60,
                                    color: Colors.red[300],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('Gagal menampilkan gambar'),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Error: ${error.toString()}',
                                    style: const TextStyle(fontSize: 10),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada foto',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ambil atau pilih foto bukti transfer',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Action Buttons for Image Selection
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Ambil Foto'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: widget.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isUploading ? null : _pickImageFromCamera,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Pilih dari Galeri'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: widget.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isUploading ? null : _pickImageFromGallery,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Upload Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: _isUploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                    _isUploading ? 'Mengunggah...' : 'Unggah Bukti Transfer',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isUploading ? null : _uploadProof,
                ),
              ),
              const SizedBox(height: 12),

              // Info Box
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Informasi Penting',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Pastikan bukti transfer jelas dan terbaca\n'
                      '• Tampilkan nomor rekening tujuan di bukti\n'
                      '• Foto harus menunjukkan jumlah transfer\n'
                      '• Saldo akan diverifikasi dalam 5-10 menit',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
