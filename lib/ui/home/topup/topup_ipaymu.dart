import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/session_manager.dart';

class TopupIpaymu extends StatefulWidget {
  final int amount;
  final Color primaryColor;
  final ApiService apiService;

  const TopupIpaymu({
    super.key,
    required this.amount,
    required this.primaryColor,
    required this.apiService,
  });

  @override
  State<TopupIpaymu> createState() => _TopupIpaymuState();
}

class _TopupIpaymuState extends State<TopupIpaymu> {
  bool _isLoading = true;
  String? _paymentUrl;
  String? _errorMessage;
  late WebViewController _webViewController;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) throw Exception('Token not found');

      // Get user info to retrieve admin_user_id
      final userResponse = await widget.apiService.getUserInfo(token);
      final adminUserId = userResponse['admin_user_id'];

      if (adminUserId == null) {
        throw Exception(
          'Admin user ID tidak ditemukan. Silakan hubungi administrator.',
        );
      }

      // Create payment transaction
      final response = await widget.apiService.createIpaymuTopup(
        token: token,
        adminUserId: adminUserId is int
            ? adminUserId
            : int.parse(adminUserId.toString()),
        amount: widget.amount,
      );

      // Validate response has URL
      final paymentUrl = response['url'] as String?;
      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw Exception(
          'URL pembayaran tidak ditemukan. Silakan coba lagi atau hubungi administrator.',
        );
      }

      if (mounted) {
        setState(() {
          _paymentUrl = paymentUrl;
          _isLoading = false;
        });

        // Initialize WebView controller
        _webViewController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                // Check if user returned from payment
                if (url.contains('payresult')) {
                  if (url.contains('status=berhasil')) {
                    _showSuccessDialog();
                  } else if (url.contains('status=cancel')) {
                    _showCancelDialog();
                  }
                }
              },
              onPageFinished: (String url) {
                // Page loaded
              },
              onWebResourceError: (WebResourceError error) {
                if (mounted) {
                  setState(() {
                    _errorMessage =
                        'Error loading payment page: ${error.description}';
                  });
                }
              },
            ),
          )
          ..loadRequest(Uri.parse(_paymentUrl!));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pembayaran Berhasil'),
        content: const Text(
          'Top up Anda sedang diproses. Saldo akan bertambah setelah pembayaran dikonfirmasi.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pembayaran Dibatalkan'),
        content: const Text('Anda membatalkan proses pembayaran.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
        elevation: 0,
        title: const Text('Pembayaran Topup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: widget.primaryColor),
                  const SizedBox(height: 20),
                  const Text('Memproses pembayaran...'),
                  const SizedBox(height: 10),
                  Text(
                    'Nominal: ${currencyFormatter.format(widget.amount)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Kembali'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _paymentUrl != null && _paymentUrl!.isNotEmpty
          ? WebViewWidget(controller: _webViewController)
          : const Center(child: Text('Tidak ada URL pembayaran')),
    );
  }
}
