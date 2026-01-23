import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
        elevation: 0,
        title: const Text('Top Up Otomatis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card,
              size: 64,
              color: widget.primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Top Up Otomatis (Coming Soon)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Amount: Rp ${widget.amount}',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali ke Top Up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
