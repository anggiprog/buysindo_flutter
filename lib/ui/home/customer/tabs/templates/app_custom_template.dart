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
      debugPrint('[AppCustomTemplate] Token: $token');
      // Ganti ke getCustomHtmlPage agar dapat HTML langsung
      final subdomain = appConfig.subdomain;
      final html = await ApiService.instance.getCustomHtmlPage(
        token: token ?? '',
        subdomain: subdomain,
      );
      debugPrint('[AppCustomTemplate] HTML from backend:\n$html');
      if (html != null && html.isNotEmpty) {
        // Inject CSS untuk hide scrollbar
        final htmlWithNoScrollbar = html.replaceFirst(
          '<head>',
          '''<head><style>body::-webkit-scrollbar { display: none; } html::-webkit-scrollbar { display: none; }</style>''',
        );
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
                onNavigationRequest: (NavigationRequest request) {
                  final url = request.url;
                  // Semua link dari backend
                  final linkPatterns = {
                    'act/beranda': '/home',
                    'act/info': '/info',
                    'act/transaksi': '/transaksi',
                    'act/chat': '/chat',
                    'act/akun': '/akun',
                    'act/cs': '/cs',
                    'act/referral': '/referral',
                    'act/topup': '/topup',
                    'act/histori-topup': '/histori_topup',
                    'act/poin': '/poin',
                    'act/privacy-policy': '/privacy_policy',
                    'act/toko': '/toko',
                    'act/password': '/password',
                    'act/pin': '/pin',
                    'act/tentang-kami': '/tentang_kami',
                    'act/logout': '/logout',
                  };
                  // Cek link statis
                  for (final entry in linkPatterns.entries) {
                    if (url.contains(entry.key)) {
                      debugPrint(
                        '[AppCustomTemplate] Intercepted URL: $url, route: ${entry.value}',
                      );
                      Navigator.of(context).pushNamed(entry.value);
                      return NavigationDecision.prevent;
                    }
                  }
                  // Cek link dinamis prabayar/pascabayar
                  final prabayarPattern = RegExp(
                    r'/act/prabayar/([a-zA-Z0-9_]+)',
                  );
                  final pascabayarPattern = RegExp(
                    r'/act/pascabayar/([a-zA-Z0-9_]+)',
                  );
                  final prabayarMatch = prabayarPattern.firstMatch(url);
                  final pascabayarMatch = pascabayarPattern.firstMatch(url);
                  if (prabayarMatch != null) {
                    final slug = prabayarMatch.group(1);
                    final route = '/prabayar/$slug';
                    debugPrint(
                      '[AppCustomTemplate] Intercepted URL: $url, route: $route',
                    );
                    Navigator.of(context).pushNamed(route);
                    return NavigationDecision.prevent;
                  }
                  if (pascabayarMatch != null) {
                    final slug = pascabayarMatch.group(1);
                    final route = '/pascabayar/$slug';
                    debugPrint(
                      '[AppCustomTemplate] Intercepted URL: $url, route: $route',
                    );
                    Navigator.of(context).pushNamed(route);
                    return NavigationDecision.prevent;
                  }
                  return NavigationDecision.navigate;
                },
              ),
            )
            ..loadHtmlString(htmlWithNoScrollbar);
          _errorMessage = null;
        });
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

  Future<bool> _onWillPop() async {
    if (_controller != null && await _controller!.canGoBack()) {
      await _controller!.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(backgroundColor: Colors.white, body: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: appConfig.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image_outlined,
                color: Colors.grey,
                size: 60,
              ),
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
                child: const Text(
                  "Coba Lagi",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: _controller != null
          ? WebViewWidget(controller: _controller!)
          : Container(),
    );
  }
}
