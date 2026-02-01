import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_service.dart';
import '../../core/network/session_manager.dart';
import 'chat_admin.dart';

class KontakAdminPage extends StatefulWidget {
  const KontakAdminPage({Key? key}) : super(key: key);

  @override
  State<KontakAdminPage> createState() => _KontakAdminPageState();
}

class _KontakAdminPageState extends State<KontakAdminPage> {
  Map<String, dynamic>? kontak;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchKontak();
  }

  Future<void> _fetchKontak() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final token = await SessionManager.getToken();
    final data = await ApiService.instance.getKontakAdmin(token ?? '');

    if (data == null) {
      setState(() {
        _error = 'Kontak admin tidak tersedia.';
        _loading = false;
      });
    } else {
      setState(() {
        kontak = data;
        _loading = false;
      });
    }
  }

  // Fungsi navigasi ke URL luar
  Future<void> _launch(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka aplikasi: $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Kontak Admin',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section sesuai gambar
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F0), // Warna krem muda sesuai gambar
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Gunakan Image.asset jika kamu punya gambarnya,
                // di sini saya pakai Icon besar sebagai placeholder
                const Icon(
                  Icons.support_agent,
                  size: 80,
                  color: Color.fromARGB(255, 228, 4, 4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Kontak Customer Services',
                  selectionColor: Colors.black,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jam Operasional Customer Service\nSetiap Hari ( 08.00 - 21.00 )\n(Luar jam operasional slow respon)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),

          // Grid Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9, // Menyesuaikan tinggi kotak
              children: [
                _buildGridItem(
                  image:
                      'assets/images/wa_icon.png', // Ganti dengan path asetmu
                  label: 'Whatsapp',
                  onTap: () {
                    final phone = kontak?['whatsapp'].toString().replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    _launch('https://wa.me/$phone');
                  },
                ),
                _buildGridItem(
                  image: 'assets/images/email_icon.png',
                  label: 'Email',
                  onTap: () {
                    _launch('mailto:${kontak?['email']}');
                  },
                ),
                _buildGridItem(
                  image: 'assets/images/chat_icon.png',
                  label: 'Chat APP',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatPage()),
                    );
                  },
                ),
                _buildGridItem(
                  image: 'assets/images/telegram_icon.png',
                  label: 'Telegram',
                  onTap: () {
                    final user = kontak?['telegram'].toString().replaceAll(
                      '@',
                      '',
                    );
                    _launch('https://t.me/$user');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem({
    required String image,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gunakan icon bawaan jika asset tidak ada
            Builder(
              builder: (context) {
                if (image.contains('wa')) {
                  return const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Colors.green,
                    size: 50,
                  );
                } else if (image.contains('email')) {
                  return Icon(Icons.email, color: Colors.redAccent, size: 50);
                } else if (image.contains('telegram')) {
                  return Icon(Icons.send, color: Colors.blue, size: 50);
                } else if (image.contains('chat')) {
                  return Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.deepPurple,
                    size: 50,
                  );
                } else {
                  return Image.asset(
                    image,
                    height: 60,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.image, size: 50),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error ?? 'Error'),
          ElevatedButton(
            onPressed: _fetchKontak,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
