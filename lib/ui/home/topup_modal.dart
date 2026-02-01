import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_service.dart';
import '../../core/network/session_manager.dart';
import './topup/topup_manual.dart';
import './topup/topup_otomatis.dart';

class TopupModal extends StatefulWidget {
  final Color primaryColor;
  final ApiService apiService;

  const TopupModal({
    super.key,
    required this.primaryColor,
    required this.apiService,
  });

  @override
  State<TopupModal> createState() => _TopupModalState();
}

class _TopupModalState extends State<TopupModal> {
  final TextEditingController _nominalController = TextEditingController();
  String? _selectedMethod;
  bool _isLoading = false;
  int? _minimalTopup;
  String? _rekeningStatus;
  String? _paymentMerchant;
  int? _paymentStatus;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<int> _quickNominals = [50000, 100000, 200000, 500000, 1000000];

  @override
  void initState() {
    super.initState();
    _fetchTopupData();
  }

  @override
  void dispose() {
    _nominalController.dispose();
    super.dispose();
  }

  Future<void> _fetchTopupData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final token = await SessionManager.getToken();
      if (token == null) throw Exception('Token not found');

      // Fetch minimal topup
      final minimalResponse = await widget.apiService.getMinimalTopup(
        null,
        token,
      );
      _minimalTopup = minimalResponse.minimalTopup;

      // Fetch rekening status
      final rekeningResponse = await widget.apiService.getRekeningStatus(token);
      _rekeningStatus = rekeningResponse.data?.status;

      // Fetch payment status
      final paymentResponse = await widget.apiService.getStatusPayment(token);
      _paymentMerchant = paymentResponse.merchant;
      _paymentStatus = paymentResponse.status;

      // Set default selected method based on available options
      if (_rekeningStatus == 'active') {
        _selectedMethod = 'manual';
      } else if (_paymentStatus == 1) {
        _selectedMethod = 'auto';
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading topup data: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  int _parseNominal() {
    final text = _nominalController.text.trim();
    if (text.isEmpty) return 0;
    // Remove 'Rp ' prefix if exists
    final withoutPrefix = text.replaceFirst('Rp ', '').trim();
    final onlyDigits = withoutPrefix.replaceAll(RegExp(r'[^0-9]'), '');
    if (onlyDigits.isEmpty) return 0;
    return int.tryParse(onlyDigits) ?? 0;
  }

  void _setNominal(int value) {
    _nominalController.text = value.toString();
    setState(() {});
  }

  void _onContinueManual() async {
    final value = _parseNominal();
    // debug log removed
    // debug log removed

    // Validasi
    if (value == 0) {
      // debug log removed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan nominal top up')),
      );
      return;
    }

    // Show loading
    // debug log removed
    setState(() => _isLoading = true);

    try {
      final token = await SessionManager.getToken();
      // debug log removed
      if (token == null) throw Exception('Token not found');

      // Validate amount dengan backend
      // debug log removed
      final validationResponse = await widget.apiService.getMinimalTopup(
        value,
        token,
      );

      // debug log removed

      // Check if amount doesn't meet minimal requirement
      if (validationResponse.amountMeetsMinimal == false ||
          validationResponse.amountMeetsMinimal == null) {
        // debug log removed
        if (mounted) {
          // debug log removed

          // Dismiss loading first
          setState(() => _isLoading = false);

          // Show alert dialog instead of snackbar for better visibility
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Nominal Tidak Mencukupi'),
                content: Text(
                  'Minimal top up adalah ${currencyFormatter.format(validationResponse.minimalTopup ?? _minimalTopup ?? 50000)}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
        // debug log removed
        return;
      }

      // debug log removed
      if (mounted) setState(() => _isLoading = false);

      // Navigate ke TopupManual dengan amount
      if (mounted) {
        // debug log removed
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopupManual(
              amount: value,
              primaryColor: widget.primaryColor,
              apiService: widget.apiService,
            ),
          ),
        );
      }
    } catch (e) {
      // debug log removed
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error validasi: $e')));
        setState(() => _isLoading = false);
      }
    }
    // debug log removed
  }

  void _onContinueAuto() async {
    final value = _parseNominal();

    // Validasi
    if (value == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan nominal top up')),
      );
      return;
    }

    // Show loading
    setState(() => _isLoading = true);

    try {
      final token = await SessionManager.getToken();
      if (token == null) throw Exception('Token not found');

      // Validate amount dengan backend
      final validationResponse = await widget.apiService.getMinimalTopup(
        value,
        token,
      );

      // Check if amount doesn't meet minimal requirement
      if (validationResponse.amountMeetsMinimal == false ||
          validationResponse.amountMeetsMinimal == null) {
        if (mounted) {
          // Dismiss loading first
          setState(() => _isLoading = false);

          // Show alert dialog instead of snackbar for better visibility
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Nominal Tidak Mencukupi'),
                content: Text(
                  'Minimal top up adalah ${currencyFormatter.format(validationResponse.minimalTopup ?? _minimalTopup ?? 50000)}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
        return;
      }
      if (mounted) setState(() => _isLoading = false);

      // Navigate ke TopupOtomatis dengan amount
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopupOtomatis(
              amount: value,
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
        ).showSnackBar(SnackBar(content: Text('Error validasi: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Isi Saldo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Pilih metode dan nominal top up (min Rp20.000)',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      minWidth: 40,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Minimal topup info
              if (_minimalTopup != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    'Minimal top up: ${currencyFormatter.format(_minimalTopup!)}',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Select metode pembayaran
              if (_rekeningStatus == 'active' || _paymentStatus == 1)
                DropdownButtonFormField<String>(
                  value: _selectedMethod,
                  items: [
                    if (_rekeningStatus == 'active')
                      const DropdownMenuItem(
                        value: 'manual',
                        child: Text(
                          'Pembayaran Manual',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    if (_paymentStatus == 1)
                      const DropdownMenuItem(
                        value: 'auto',
                        child: Text(
                          'Pembayaran Otomatis',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedMethod = v);
                    }
                  },
                  isExpanded: true,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Metode Pembayaran',
                    labelStyle: const TextStyle(color: Colors.black87),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

              const SizedBox(height: 18),

              // Input nominal (berlaku untuk kedua metode)
              TextField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  labelText: 'Nominal Top Up',
                  labelStyle: const TextStyle(color: Colors.black87),
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(color: Colors.black87),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              const Text(
                'Pilih Nominal Cepat',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickNominals
                    .map(
                      (n) => InkWell(
                        onTap: () => _setNominal(n),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _nominalController.text == n.toString()
                                  ? widget.primaryColor
                                  : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: _nominalController.text == n.toString()
                                ? widget.primaryColor.withOpacity(0.12)
                                : Colors.white,
                          ),
                          child: Text(
                            NumberFormat.decimalPattern('id').format(n),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _nominalController.text == n.toString()
                                  ? widget.primaryColor
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.black54),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedMethod == null
                            ? 'Memuat informasi pembayaran...'
                            : _selectedMethod == 'manual'
                            ? 'Pembayaran manual: transfer ke rekening. Status: ${_rekeningStatus ?? 'loading'}'
                            : 'Pembayaran otomatis via ${_paymentMerchant ?? 'payment gateway'}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isLoading || _selectedMethod == null
                      ? null
                      : (_selectedMethod == 'manual'
                            ? _onContinueManual
                            : _onContinueAuto),
                  child: Text(
                    _isLoading
                        ? 'Loading...'
                        : _selectedMethod == null
                        ? 'Memuat...'
                        : (_selectedMethod == 'manual'
                              ? 'Lanjutkan Pembayaran Manual'
                              : 'Lanjutkan Pembayaran Otomatis'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
