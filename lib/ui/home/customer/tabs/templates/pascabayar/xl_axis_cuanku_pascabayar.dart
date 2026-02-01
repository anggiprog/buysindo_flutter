import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../../../../core/app_config.dart';
import '../../../../../../core/network/session_manager.dart';
import '../../../../../../core/network/api_service.dart';
import 'package:dio/dio.dart';
import 'detail_cek_tagihan.dart';

class XlAxisCuankuPascabayarPage extends StatefulWidget {
  const XlAxisCuankuPascabayarPage({super.key});

  @override
  State<XlAxisCuankuPascabayarPage> createState() =>
      _XlAxisCuankuPascabayarPageState();
}

class _XlAxisCuankuPascabayarPageState
    extends State<XlAxisCuankuPascabayarPage> {
  final TextEditingController _customerIdController = TextEditingController();

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

  Future<void> _pickContact() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      _showSnackbar('Izin akses kontak diperlukan', Colors.orange);
      return;
    }
    try {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null && contact.phones.isNotEmpty) {
        final phoneNumber = contact.phones.first.number.replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );
        setState(() {
          _customerIdController.text = phoneNumber;
        });
      } else {
        _showSnackbar('Kontak tidak memiliki nomor telepon', Colors.orange);
      }
    } catch (e) {
      _showSnackbar('Gagal membuka kontak: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _cekTagihan() async {
    if (_customerIdController.text.isEmpty) {
      _showSnackbar('Masukkan nomor pelanggan XL Axis Cuanku', Colors.orange);
      return;
    }
    // Ambil token dan adminUserId dari SessionManager
    final token = await SessionManager.getToken();
    final adminUserId = await SessionManager.getAdminUserId() ?? 0;
    if (token == null || token.isEmpty) {
      _showSnackbar('Token tidak ditemukan, silakan login ulang.', Colors.red);
      return;
    }
    try {
      // Fetch produk pascabayar dari backend
      final apiService = ApiService(Dio());
      final response = await apiService.getPascabayarProducts(token);
      if (response.statusCode == 200 && response.data != null) {
        final products = response.data['products'] as List<dynamic>?;
        if (products == null || products.isEmpty) {
          _showSnackbar('Produk XL Axis Cuanku tidak ditemukan.', Colors.red);
          return;
        }
        // Cari produk XL Axis Cuanku (brand == 'XL Axis Cuanku')
        final xlProduct = products.firstWhere(
          (p) => (p['brand']?.toString().toLowerCase() == 'xl axis cuanku'),
          orElse: () => null,
        );
        if (xlProduct == null) {
          _showSnackbar(
            'Produk XL Axis Cuanku tidak tersedia untuk akun Anda.',
            Colors.red,
          );
          return;
        }
        if (!mounted) return;
        await CekTagihanPascabayar.showCekTagihan(
          context: context,
          productName: xlProduct['product_name'] ?? 'XL Axis Cuanku Pascabayar',
          brand: xlProduct['brand'] ?? 'XL Axis Cuanku',
          buyerSkuCode: xlProduct['buyer_sku_code'] ?? '',
          adminUserId: adminUserId,
          cachedCustomerNo: _customerIdController.text,
        );
      } else {
        _showSnackbar('Gagal mengambil produk XL Axis Cuanku.', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Terjadi kesalahan: ${e.toString()}', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text(
          'XL Axis Cuanku Pascabayar',
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                      Icons.bolt,
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
                          'XL Axis Cuanku Pascabayar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bayar tagihan XL Axis Cuanku Anda',
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
            ),
            const SizedBox(height: 24),
            const Text(
              'ID Pelanggan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customerIdController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 13,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Contoh: 08123456789',
                      hintStyle: TextStyle(
                        color: Colors.grey,
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
                IconButton(
                  onPressed: _pickContact,
                  icon: Icon(Icons.contacts, color: primaryColor, size: 28),
                  tooltip: 'Pilih dari kontak',
                  splashRadius: 24,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cekTagihan,
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
      ),
    );
  }
}
