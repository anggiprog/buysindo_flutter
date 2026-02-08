import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../core/network/session_manager.dart';
import '../../../../../core/app_config.dart'; 

class AppCustomTemplate extends StatefulWidget {
  const AppCustomTemplate({super.key});

  @override
  State<AppCustomTemplate> createState() => _AppCustomTemplateState();
}

class _AppCustomTemplateState extends State<AppCustomTemplate> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTemplateFromApi();
  }

  Future<void> _loadTemplateFromApi() async {
    try {
      final token = await SessionManager.getToken();

      // MENGGUNAKAN fungsi spesifik yang sudah ada di ApiService kamu
      final data = await ApiService.instance.getCustomTemplatePreview(token);

      if (data != null) {
        // Sesuai logika di api_service: return data as Map<String, dynamic>
        if (data['success'] == true || data['status'] == 'success') {
          final String? webUrl = data['url'];
          
          if (webUrl != null && webUrl.isNotEmpty) {
            setState(() {
              _controller = WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..setBackgroundColor(Colors.white)
                ..setNavigationDelegate(
                  NavigationDelegate(
                    onPageFinished: (String url) {
                      if (mounted) setState(() => _isLoading = false);
                    },
                    onWebResourceError: (error) {
                      debugPrint("WebView Error: ${error.description}");
                    },
                  ),
                )
                ..loadRequest(Uri.parse(webUrl));
              
              _errorMessage = null;
            });
          } else {
            _handleError("URL Template tidak ditemukan dalam respon.");
          }
        } else {
          _handleError(data['message'] ?? "Gagal mengambil data template.");
        }
      } else {
        _handleError("Gagal terhubung ke server atau data kosong.");
      }
    } catch (e) {
      debugPrint("❌ Error AppCustomTemplate: $e");
      _handleError("Terjadi kesalahan sistem.");
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: appConfig.primaryColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 60),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadTemplateFromApi();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appConfig.primaryColor,
                ),
                child: const Text("Coba Lagi", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: () async {
        await _loadTemplateFromApi();
      },
      child: ListView(
        // physics AlwaysScrollable agar RefreshIndicator tetap bisa ditarik meski konten sedikit
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 
                    MediaQuery.of(context).padding.top,
            child: WebViewWidget(controller: _controller!),
          ),
        ],
      ),
    );
  }
}