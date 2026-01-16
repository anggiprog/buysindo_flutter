import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TopupModal extends StatefulWidget {
  final Color primaryColor;
  const TopupModal({super.key, required this.primaryColor});

  @override
  State<TopupModal> createState() => _TopupModalState();
}

class _TopupModalState extends State<TopupModal> {
  String _topupNominal = '';
  final currencyFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<int> _quickNominals = [
    10000,
    20000,
    50000,
    100000,
    200000,
    500000,
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Isi Saldo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nominal Top Up',
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _topupNominal = v),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nominal Cepat',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quickNominals
                  .map(
                    (n) => InkWell(
                      onTap: () => setState(() => _topupNominal = n.toString()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _topupNominal == n.toString()
                                ? widget.primaryColor
                                : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: _topupNominal == n.toString()
                              ? widget.primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: Text(
                          NumberFormat.decimalPattern('id').format(n),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Lanjutkan Pembayaran',
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
    );
  }
}
