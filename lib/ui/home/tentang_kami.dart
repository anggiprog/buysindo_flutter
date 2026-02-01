import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../core/app_config.dart';
import '../../core/network/api_service.dart';
import '../../core/network/session_manager.dart';

class TentangKamiPage extends StatefulWidget {
  const TentangKamiPage({super.key});

  @override
  State<TentangKamiPage> createState() => _TentangKamiPageState();
}

class _TentangKamiPageState extends State<TentangKamiPage> {
  late Future<Map<String, dynamic>> _tentangFuture;
  final ApiService _apiService = ApiService(Dio());

  @override
  void initState() {
    super.initState();
    _tentangFuture = _fetchTentangKami();
  }

  Future<Map<String, dynamic>> _fetchTentangKami() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) throw Exception("Sesi berakhir");

      final response = await _apiService.getTentangKami(token);
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      } else {
        throw Exception("Gagal memuat data");
      }
    } catch (e) {
      debugPrint("Error Fetch Tentang Kami: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(primaryColor),
          SliverToBoxAdapter(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _tentangFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return _buildErrorWidget();
                } else if (!snapshot.hasData ||
                    snapshot.data!['tentang'] == null) {
                  return const Center(child: Text("Data tidak ditemukan"));
                }

                final content = snapshot.data!['tentang'];

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildContentCard(content),
                      const SizedBox(height: 20),
                      _buildFooter(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Color primaryColor) {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          "Tentang Kami",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                ),
              ),
            ),
            // Decorative shapes
            Positioned(
              right: -50,
              top: -50,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child:
                        appConfig.logoUrl != null &&
                            appConfig.logoUrl!.isNotEmpty
                        ? Image.network(
                            appConfig.logoUrl!,
                            height: 70,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  'assets/images/logo.png',
                                  height: 70,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.business,
                                        size: 70,
                                        color: Colors.blue,
                                      ),
                                ),
                          )
                        : Image.asset(
                            'assets/images/logo.png',
                            height: 70,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.business,
                                  size: 70,
                                  color: Colors.blue,
                                ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  appConfig.appName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildContentCard(String htmlContent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: HtmlWidget(
        htmlContent,
        textStyle: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
          height: 1.5,
        ),
        customStylesBuilder: (element) {
          if (element.localName == 'h3') {
            return {'font-weight': 'bold', 'color': '#333333'};
          }
          return null;
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text("Gagal memuat data"),
            TextButton(
              onPressed: () {
                setState(() {
                  _tentangFuture = _fetchTentangKami();
                });
              },
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            "Versi Aplikasi 1.0.0",
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
