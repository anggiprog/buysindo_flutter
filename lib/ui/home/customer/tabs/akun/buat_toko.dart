import 'package:flutter/material.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../core/network/session_manager.dart';
import '../../../../../core/app_config.dart';

class BuatTokoPage extends StatefulWidget {
  const BuatTokoPage({Key? key}) : super(key: key);

  @override
  State<BuatTokoPage> createState() => _BuatTokoPageState();
}

class _BuatTokoPageState extends State<BuatTokoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaTokoController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _initNamaToko();
    _fetchToko();
  }

  Future<void> _initNamaToko() async {
    final namaToko = await ApiService.instance.getNamaTokoFromPrefs();
    if (namaToko != null && namaToko.isNotEmpty) {
      _namaTokoController.text = namaToko;
      setState(() {});
    }
  }

  Future<void> _fetchToko() async {
    setState(() {
      _loading = true;
    });
    final token = await SessionManager.getToken();
    try {
      final response = await ApiService.instance.getUserStore(token!);
      if (response.data['status'] == 'success' &&
          response.data['data'] != null) {
        _namaTokoController.text = response.data['data']['nama_toko'] ?? '';
      }
    } catch (e) {
      // ignore error, just show empty
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    final token = await SessionManager.getToken();
    try {
      final response = await ApiService.instance.simpanToko(
        token!,
        _namaTokoController.text,
      );
      if (response.data['status'] == 'success') {
        // Ambil nama_toko terbaru dari SharedPreferences
        final namaToko = await ApiService.instance.getNamaTokoFromPrefs();
        if (namaToko != null) {
          _namaTokoController.text = namaToko;
        }
        setState(() {
          _successMessage =
              response.data['message'] ?? 'Toko berhasil disimpan!';
        });
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? 'Gagal menyimpan toko.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      });
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Toko'),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              color: primaryColor,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Buat Toko',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _namaTokoController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nama Toko',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(
                            Icons.store,
                            color: Colors.white,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          fillColor: Colors.white10,
                          filled: true,
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Nama toko wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.yellowAccent),
                        ),
                      if (_successMessage != null)
                        Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue,
                                  ),
                                )
                              : Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: primaryColor,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nama toko yang Anda buat akan digunakan dan ditampilkan di halaman struk atau halaman lainnya.',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
