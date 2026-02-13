import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/session_manager.dart';
import './topup_ipaymu.dart';
import './topup_tripay.dart';

class TopupOtomatis extends StatefulWidget {
  final int amount;
  final Color primaryColor;
  final ApiService apiService;

  const TopupOtomatis({
    super.key,
    required this.amount,
    required this.primaryColor,
    required this.apiService,
  });

  @override
  State<TopupOtomatis> createState() => _TopupOtomatisState();
}

class _TopupOtomatisState extends State<TopupOtomatis> {
  String? _merchant;

  @override
  void initState() {
    super.initState();
    _checkMerchantAndRedirect();
  }

  Future<void> _checkMerchantAndRedirect() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) throw Exception('Token not found');

      // Ambil merchant dari API
      final paymentResponse = await widget.apiService.getStatusPayment(token);
      _merchant = paymentResponse.merchant;

      if (!mounted) return;

      // Redirect berdasarkan merchant
      if (_merchant == 'Ipaymu') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TopupIpaymu(
              amount: widget.amount,
              primaryColor: widget.primaryColor,
              apiService: widget.apiService,
            ),
          ),
        );
      } else if (_merchant == 'Tripay') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TopupTripay(
              amount: widget.amount,
              primaryColor: widget.primaryColor,
              apiService: widget.apiService,
            ),
          ),
        );
      } else {
        // Default ke Ipaymu jika merchant tidak dikenali
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TopupIpaymu(
              amount: widget.amount,
              primaryColor: widget.primaryColor,
              apiService: widget.apiService,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
        elevation: 0,
        title: const Text('Top Up Otomatis'),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
