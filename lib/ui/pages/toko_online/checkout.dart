import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_config.dart';
import '../../../core/network/api_service.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> product;
  const CheckoutPage({Key? key, required this.product}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  /// Hitung ongkir dari kecamatan produk ke kecamatan user
  Future<void> _calculateShippingCost() async {
    if (selectedAddress == null || selectedAddress!["kecamatan_id"] == null)
      return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    // Ambil kecamatan_id asal dari produk (misal dari widget.product)
    final originKecamatanId = widget.product['lokasi']?['kecamatan_id']
        ?.toString();
    final destinationKecamatanId = selectedAddress!["kecamatan_id"]!;
    final weight =
        (widget.product['berat'] ?? 1000) as int; // default 1000 gram
    final courier = selectedExpedition.toLowerCase().contains('j&t')
        ? 'jnt'
        : 'jne'; // contoh mapping

    if (originKecamatanId == null || destinationKecamatanId.isEmpty) return;

    final ongkirData = await ApiService.instance.hitungOngkir(
      origin: originKecamatanId,
      destination: destinationKecamatanId,
      weight: weight,
      courier: courier,
      token: token,
    );
    if (ongkirData != null &&
        ongkirData['costs'] != null &&
        ongkirData['costs'] is List &&
        ongkirData['costs'].isNotEmpty) {
      final cost = ongkirData['costs'][0]['cost'][0]['value'];
      setState(() {
        shippingCost = cost is int ? cost : int.tryParse(cost.toString()) ?? 0;
      });
    }
  }

  // RajaOngkir API state
  List<Map<String, dynamic>> provinsiList = [];
  List<Map<String, dynamic>> kotaList = [];
  List<Map<String, dynamic>> kecamatanList = [];

  // Form state
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  // Tidak perlu baseUrl, gunakan ApiService

  @override
  void initState() {
    super.initState();
    _loadAddressFromPrefs();
  }

  /// Load alamat tersimpan dari SharedPreferences
  Future<void> _loadAddressFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedAddressJson = prefs.getString('user_address');
    if (savedAddressJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(savedAddressJson);
        setState(() {
          selectedAddress = Map<String, String>.from(decoded);
        });
      } catch (e) {
        // debugPrint('Error parsing address: $e');
      }
    }
  }

  /// Simpan alamat ke SharedPreferences
  Future<void> _saveAddressToPrefs(Map<String, String> addressData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_address', jsonEncode(addressData));
    setState(() {
      selectedAddress = addressData;
    });
  }

  // --- API Calls ---

  Future<List<Map<String, dynamic>>> fetchProvinsi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      debugPrint('Token kosong! User harus login ulang.');
      // Tampilkan dialog atau pesan error di UI
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda harus login ulang untuk memilih alamat!'),
          ),
        );
      }
      return [];
    }
    return await ApiService.instance.getProvinsi(token);
  }

  Future<List<Map<String, dynamic>>> fetchKota(String provinsiId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      debugPrint('Token kosong! User harus login ulang.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda harus login ulang untuk memilih alamat!'),
          ),
        );
      }
      return [];
    }
    return await ApiService.instance.getKota(provinsiId, token);
  }

  Future<List<Map<String, dynamic>>> fetchKecamatan(String kotaId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      debugPrint('Token kosong! User harus login ulang.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda harus login ulang untuk memilih alamat!'),
          ),
        );
      }
      return [];
    }
    return await ApiService.instance.getKecamatan(kotaId, token);
  }

  final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Alamat yang dipilih
  Map<String, String>? selectedAddress;
  List<Map<String, String>> addressList = [];

  String selectedExpedition = 'J&T Express';
  int shippingCost = 15000;
  String paymentMethod = 'Transfer Bank (Manual)';

  @override
  Widget build(BuildContext context) {
    double productPrice =
        (widget.product['harga_diskon'] != null &&
            widget.product['harga_diskon'] > 0)
        ? (widget.product['harga_diskon'] as num).toDouble()
        : (widget.product['harga'] as num).toDouble();

    double totalPrice = productPrice + shippingCost;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: 120,
            ), // Memberi ruang untuk fixed bottom
            child: Column(
              children: [
                _buildAddressSection(),
                _buildSectionDivider(),
                _buildProductSection(productPrice),
                _buildSectionDivider(),
                _buildShippingSection(),
                _buildSectionDivider(),
                _buildPaymentMethodSection(),
                _buildSectionDivider(),
                _buildOrderSummary(productPrice),
              ],
            ),
          ),
          _buildFixedBottom(totalPrice),
        ],
      ),
    );
  }

  // 1. Alamat Section
  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: appConfig.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Alamat Pengiriman",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedAddress != null) ...[
            Text(
              "${selectedAddress!['penerima']} | ${selectedAddress!['telepon']}",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selectedAddress!['alamat']!,
              style: const TextStyle(color: Colors.black54),
            ),
            Text(
              "${selectedAddress!['kota_kec']}, ${selectedAddress!['provinsi']}",
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _showAddressDialog,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Pilih Alamat Lain",
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Produk Section
  Widget _buildProductSection(double price) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pesanan Anda",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.product['gambar'],
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product['nama_barang'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatter.format(price),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: appConfig.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Text("x1", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Pengiriman Section
  Widget _buildShippingSection() {
    return InkWell(
      onTap: _showShippingOptions,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.blue.withOpacity(0.05),
        child: Row(
          children: [
            const Icon(
              Icons.local_shipping_outlined,
              size: 20,
              color: Colors.blue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Opsi Pengiriman",
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  Text(
                    selectedExpedition,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    "Estimasi diterima dalam 2-4 hari",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              _formatter.format(shippingCost),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // 4. Metode Pembayaran Section
  Widget _buildPaymentMethodSection() {
    return InkWell(
      onTap: _showPaymentDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 20,
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Metode Pembayaran",
                style: TextStyle(color: Colors.black87),
              ),
            ),
            Text(
              paymentMethod,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // 5. Ringkasan Biaya
  Widget _buildOrderSummary(double productPrice) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          _summaryRow("Subtotal Produk", _formatter.format(productPrice)),
          const SizedBox(height: 8),
          _summaryRow("Subtotal Pengiriman", _formatter.format(shippingCost)),
          const SizedBox(height: 12),
          const Divider(),
          _summaryRow(
            "Total Pembayaran",
            _formatter.format(productPrice + shippingCost),
            isBold: true,
          ),
        ],
      ),
    );
  }

  // 6. Fixed Bottom Bar
  Widget _buildFixedBottom(double totalPrice) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Pembayaran",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    _formatter.format(totalPrice),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: appConfig.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Proses pesanan ke Server
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appConfig.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Buat Pesanan",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets & Dialogs ---

  Widget _buildSectionDivider() =>
      Container(height: 10, color: const Color(0xFFF0F0F0));

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? Colors.black87 : Colors.black54,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isBold ? appConfig.primaryColor : Colors.black87,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  void _showAddressDialog() {
    // Reset form state saat buka dialog
    _namaController.clear();
    _teleponController.clear();
    _alamatController.clear();

    // Variabel lokal untuk dialog (StatefulBuilder)
    String? localProvinsiId, localKotaId, localKecamatanId;
    String? localProvinsiName, localKotaName, localKecamatanName;
    List<Map<String, dynamic>> localProvinsiList = [];
    List<Map<String, dynamic>> localKotaList = [];
    List<Map<String, dynamic>> localKecamatanList = [];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Load provinsi saat pertama kali dialog dibuka
            if (localProvinsiList.isEmpty) {
              fetchProvinsi().then((data) {
                setModalState(() {
                  localProvinsiList = data;
                });
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Tambah Alamat Baru",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Divider(),
                      TextField(
                        controller: _namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Penerima',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _teleponController,
                        decoration: const InputDecoration(labelText: 'Telepon'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _alamatController,
                        decoration: const InputDecoration(
                          labelText: 'Alamat Lengkap (Jalan, No Rumah, RT/RW)',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),

                      // Dropdown Provinsi
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Provinsi',
                        ),
                        value: localProvinsiId,
                        items: localProvinsiList.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'].toString(),
                            child: Text(item['name']),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          if (val != null) {
                            final selected = localProvinsiList.firstWhere(
                              (e) => e['id'].toString() == val,
                            );
                            setModalState(() {
                              localProvinsiId = val;
                              localProvinsiName = selected['name'];
                              // Reset Kota & Kecamatan
                              localKotaId = null;
                              localKotaName = null;
                              localKecamatanId = null;
                              localKecamatanName = null;
                              localKotaList = [];
                              localKecamatanList = [];
                            });

                            // Fetch Kota
                            final kotas = await fetchKota(val);
                            setModalState(() {
                              localKotaList = kotas;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),

                      // Dropdown Kota
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Kota/Kabupaten',
                        ),
                        value: localKotaId,
                        items: localKotaList.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'].toString(),
                            child: Text(item['name']),
                          );
                        }).toList(),
                        onChanged: localProvinsiId == null
                            ? null
                            : (val) async {
                                if (val != null) {
                                  final selected = localKotaList.firstWhere(
                                    (e) => e['id'].toString() == val,
                                  );
                                  setModalState(() {
                                    localKotaId = val;
                                    localKotaName = selected['name'];
                                    // Reset Kecamatan
                                    localKecamatanId = null;
                                    localKecamatanName = null;
                                    localKecamatanList = [];
                                  });

                                  // Fetch Kecamatan
                                  final kecamatans = await fetchKecamatan(val);
                                  setModalState(() {
                                    localKecamatanList = kecamatans;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 8),

                      // Dropdown Kecamatan
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Kecamatan',
                        ),
                        value: localKecamatanId,
                        items: localKecamatanList.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'].toString(),
                            child: Text(item['name']),
                          );
                        }).toList(),
                        onChanged: localKotaId == null
                            ? null
                            : (val) {
                                if (val != null) {
                                  final selected = localKecamatanList
                                      .firstWhere(
                                        (e) => e['id'].toString() == val,
                                      );
                                  setModalState(() {
                                    localKecamatanId = val;
                                    localKecamatanName = selected['name'];
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_namaController.text.isEmpty ||
                                _teleponController.text.isEmpty ||
                                _alamatController.text.isEmpty ||
                                localProvinsiId == null ||
                                localKotaId == null ||
                                localKecamatanId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Mohon lengkapi semua data"),
                                ),
                              );
                              return;
                            }

                            final newAddress = {
                              'penerima': _namaController.text,
                              'telepon': _teleponController.text,
                              'alamat': _alamatController.text,
                              'provinsi': localProvinsiName ?? '',
                              'provinsi_id': localProvinsiId ?? '',
                              'kota': localKotaName ?? '',
                              'kota_id': localKotaId ?? '',
                              'kecamatan': localKecamatanName ?? '',
                              'kecamatan_id': localKecamatanId ?? '',
                            };

                            _saveAddressToPrefs(newAddress);
                            Navigator.pop(context);
                            // Hitung ongkir setelah alamat dipilih
                            _calculateShippingCost();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appConfig.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Simpan Alamat",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showShippingOptions() {
    // Tampilkan pilihan JNE, J&T, Sicepat dsb
    // Contoh: setelah user memilih ekspedisi, panggil _calculateShippingCost
    // _calculateShippingCost();
  }

  void _showPaymentDialog() {
    // Tampilkan pilihan Transfer, COD, E-Wallet dsb
  }
}
