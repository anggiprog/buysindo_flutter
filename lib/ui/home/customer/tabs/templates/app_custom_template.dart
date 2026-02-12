import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../../core/network/api_service.dart';

import '../../../../../core/network/session_manager.dart';
import '../../../../../core/app_config.dart';
import 'popup.dart';

class AppCustomTemplate extends StatefulWidget {
  const AppCustomTemplate({super.key});

  @override
  State<AppCustomTemplate> createState() => _AppCustomTemplateState();
}

class _AppCustomTemplateState extends State<AppCustomTemplate> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  final PopupManager _popupManager = PopupManager();

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
                  if (mounted) {
                    setState(() => _isLoading = false);
                    // Show popup after page loads
                    _checkAndShowPopup();
                  }
                },
                onWebResourceError: (error) {
                  debugPrint("WebView Error: ${error.description}");
                },
                onNavigationRequest: (NavigationRequest request) {
                  final url = request.url;
                  debugPrint('[AppCustomTemplate] 🔗 Navigation request: $url');

                  String? extractedPath;

                  // Handle custom app:// scheme
                  if (url.startsWith('app://')) {
                    extractedPath = url.replaceFirst('app://', '');
                    debugPrint(
                      '[AppCustomTemplate] 📱 Extracted from app:// scheme: "$extractedPath"',
                    );
                  }
                  // Handle HTTP URLs with /act/ pattern (e.g., http://192.168.100.7/act/prabayar/pulsa)
                  else if (url.contains('/act/')) {
                    final actPattern = RegExp(
                      r'/act/(prabayar|pascabayar)/([a-zA-Z0-9_]+)',
                    );
                    final match = actPattern.firstMatch(url);
                    if (match != null) {
                      final type = match.group(1); // prabayar or pascabayar
                      final slug = match.group(2); // pulsa, pln, etc.
                      extractedPath = '$type/$slug';
                      debugPrint(
                        '[AppCustomTemplate] 📱 Extracted from HTTP /act/ URL: "$extractedPath"',
                      );
                    }
                  }

                  // Process extracted path if exists
                  if (extractedPath != null) {
                    // Mapping custom scheme ke route Flutter
                    final linkPatterns = {
                      'beranda': '/home',
                      'info': '/info',
                      'transaksi': '/transaksi',
                      'chat': '/chat',
                      'akun': '/akun',
                      'cs': '/cs',
                      'referral': '/referral',
                      'topup': '/topup',
                      'histori-topup': '/histori_topup',
                      'poin': '/poin',
                      'privacy-policy': '/privacy_policy',
                      'toko': '/toko',
                      'password': '/password',
                      'pin': '/pin',
                      'tentang-kami': '/tentang_kami',
                      'logout': '/logout',
                    };

                    // Cek link statis
                    if (linkPatterns.containsKey(extractedPath)) {
                      final route = linkPatterns[extractedPath]!;
                      debugPrint(
                        '[AppCustomTemplate] ✅ Static route matched: $route',
                      );
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.of(context).pushNamed(route);
                      });
                      return NavigationDecision.prevent;
                    }

                    // Cek link dinamis prabayar/pascabayar
                    final prabayarPattern = RegExp(
                      r'^prabayar/([a-zA-Z0-9_]+)$',
                    );
                    final pascabayarPattern = RegExp(
                      r'^pascabayar/([a-zA-Z0-9_]+)$',
                    );

                    final prabayarMatch = prabayarPattern.firstMatch(
                      extractedPath,
                    );
                    final pascabayarMatch = pascabayarPattern.firstMatch(
                      extractedPath,
                    );

                    if (prabayarMatch != null) {
                      final slug = prabayarMatch.group(1);
                      final route = '/prabayar/$slug';
                      debugPrint(
                        '[AppCustomTemplate] ✅ Prabayar route matched: $route (slug: $slug)',
                      );
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.of(context).pushNamed(route);
                      });
                      return NavigationDecision.prevent;
                    }
                    if (pascabayarMatch != null) {
                      final slug = pascabayarMatch.group(1);
                      final route = '/pascabayar/$slug';
                      debugPrint(
                        '[AppCustomTemplate] ✅ Pascabayar route matched: $route (slug: $slug)',
                      );
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.of(context).pushNamed(route);
                      });
                      return NavigationDecision.prevent;
                    }

                    debugPrint(
                      '[AppCustomTemplate] ⚠️ No pattern matched for path: "$extractedPath"',
                    );
                  }

                  debugPrint(
                    '[AppCustomTemplate] ➡️ Allowing navigation to: $url',
                  );
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

  void _checkAndShowPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _popupManager.checkAndShowPopup(context);
      }
    });
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
