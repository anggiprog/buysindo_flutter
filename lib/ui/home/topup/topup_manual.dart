import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../../core/network/api_service.dart';
import '../../../core/network/session_manager.dart';
import '../../../core/app_config.dart';
import '../../../features/topup/models/topup_response_models.dart';
import 'topup_konfirmasi.dart';

class TopupManual extends StatefulWidget {
  final int amount;
  final Color primaryColor;
  final ApiService apiService;

  const TopupManual({
    super.key,
    required this.amount,
    required this.primaryColor,
    required this.apiService,
  });

  @override
  State<TopupManual> createState() => _TopupManualState();
}

class _TopupManualState extends State<TopupManual> {
  late int _uniqueCode;
  late int _totalAmount;
  int? _adminFee;
  bool _isLoading = true;
  List<BankAccount> _bankAccounts = [];
  BankAccount? _selectedBank;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _uniqueCode = 0; // Initialize with default value
    _totalAmount = widget.amount; // Initialize with default value
    _generateUniqueCode();
    _fetchAdminFeeAndBankAccounts();
  }

  void _generateUniqueCode() {
    // Generate 3-digit random code (100-999)
    _uniqueCode = 100 + Random().nextInt(900);
  }

  Future<void> _fetchAdminFeeAndBankAccounts() async {
    try {
      print(
        '🔍 [TOPUP] ===== FETCHING ADMIN FEE AND BANK ACCOUNTS START =====',
      );
      print('🔍 [TOPUP] Time: ${DateTime.now()}');
      print('🔍 [TOPUP] Widget mounted: $mounted');

      // Get token from SessionManager
      final token = await SessionManager.getToken();
      if (token == null) {
        print('⚠️ [TOPUP] Token is null, using defaults');
        if (mounted) {
          setState(() {
            _adminFee = 0;
            _totalAmount = widget.amount;
            _bankAccounts = [];
            _isLoading = false;
          });
        }
        return;
      }
      print('🔍 [TOPUP] Token retrieved: ${token.substring(0, 20)}...');

      // Fetch admin fee
      print('🔍 [TOPUP] Fetching admin fee...');
      final adminFeeResponse = await widget.apiService.getAdminFee(token);
      final adminFeeValue = adminFeeResponse.biayaAdminManual ?? 0;
      // Add unique code to total amount (e.g., if amount is 100000, admin fee is 2000, code is 452, total becomes 102452)
      final totalValue = widget.amount + adminFeeValue + _uniqueCode;
      print('🔍 [TOPUP] Admin fee received: $adminFeeValue');
      print('🔍 [TOPUP] Unique code: $_uniqueCode');
      print('🔍 [TOPUP] Total with unique code: $totalValue');

      // Fetch bank accounts
      print('🔍 [TOPUP] Fetching bank accounts...');
      final bankAccountsResponse = await widget.apiService.getBankAccounts(
        token,
      );
      final bankAccounts = bankAccountsResponse.data ?? [];
      print(
        '🔍 [TOPUP] Bank accounts received: ${bankAccounts.length} accounts',
      );

      print('🔍 [TOPUP] ===== API RESPONSES RECEIVED =====');
      print('🔍 [TOPUP] Admin Fee: $adminFeeValue');
      print('🔍 [TOPUP] Total: $totalValue');
      print('🔍 [TOPUP] Bank Accounts Count: ${bankAccounts.length}');

      if (mounted) {
        print('🔍 [TOPUP] Widget mounted, calling setState');
        setState(() {
          _adminFee = adminFeeValue;
          _totalAmount = totalValue;
          _bankAccounts = bankAccounts;
          _isLoading = false;
          print('🔍 [TOPUP] ===== SETSTATE COMPLETE =====');
          print('🔍 [TOPUP] _bankAccounts.length: ${_bankAccounts.length}');
        });
      } else {
        print('❌ [TOPUP] Widget not mounted!');
      }
    } catch (e, stackTrace) {
      print('❌ [TOPUP] ===== ERROR IN _fetchAdminFeeAndBankAccounts =====');
      print('❌ [TOPUP] Error type: ${e.runtimeType}');
      print('❌ [TOPUP] Error message: $e');
      print('❌ [TOPUP] StackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
        setState(() => _isLoading = false);
      }
    }
    print('🔍 [TOPUP] ===== FETCHING END =====\n');
  }

  String get _nominalWithCode {
    // Format: amount (in thousands).code (e.g., Rp 50.452 for 50000.452)
    final amountInThousands = widget.amount ~/ 1000;
    return 'Rp $amountInThousands.$_uniqueCode';
  }

  String get _totalWithCode {
    // Format: total amount (in thousands).code
    final totalInThousands = _totalAmount ~/ 1000;
    return 'Rp $totalInThousands.$_uniqueCode';
  }

  void _copyToClipboard() {
    // Copy total transfer to clipboard without Rp prefix and spaces
    final textToCopy = _totalWithCode.replaceAll('Rp ', '').trim();
    print('🔍 Copying total transfer to clipboard: $textToCopy');
    print('🔍 Full total: $_totalWithCode');

    Clipboard.setData(ClipboardData(text: textToCopy))
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Total transfer disalin ke clipboard'),
              backgroundColor: widget.primaryColor,
              duration: const Duration(seconds: 2),
            ),
          );
        })
        .catchError((e) {
          print('❌ ERROR copying to clipboard: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyalin ke clipboard'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      minWidth: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Information card
                Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Top Up',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Nominal Top Up (with unique code)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Nominal Top Up',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _nominalWithCode,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Biaya Admin
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Biaya Admin',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  final displayValue = _adminFee != null
                                      ? currencyFormatter.format(_adminFee!)
                                      : 'Rp 0';
                                  print(
                                    '🔍 [UI] Biaya Admin display value: $displayValue (_adminFee=$_adminFee)',
                                  );
                                  return Text(
                                    displayValue,
                                    style: TextStyle(
                                      color: Colors.orange[900],
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        // Total Transfer
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Transfer (dengan kode unik)',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _totalWithCode,
                                    style: TextStyle(
                                      color: Colors.blue[900],
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    '(${currencyFormatter.format(_totalAmount)})',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Copy button with info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kode unik sudah ditambahkan ke nominal di atas',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _copyToClipboard,
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Salin Nominal Transfer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bank details card - Dynamic
                Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Transfer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: widget.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_bankAccounts.isEmpty)
                          const Center(
                            child: Text('Tidak ada rekening tersedia'),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _bankAccounts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final bank = _bankAccounts[index];
                              return _BankDetailCard(
                                bank: bank,
                                primaryColor: widget.primaryColor,
                                selectedBank: _selectedBank,
                                onSelected: (selectedBank) {
                                  setState(() {
                                    _selectedBank = selectedBank;
                                  });
                                  print(
                                    '✅ [TOPUP] Bank selected: ${selectedBank.namaBank}',
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Instructions card
                Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Instruksi Pembayaran',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.blue[900],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '1. Transfer ke rekening bank berikut dengan nominal yang tertera di atas\n\n'
                          '2. Gunakan nominal dengan kode unik di belakang untuk kemudahan identifikasi\n\n'
                          '3. Pastikan nominal transfer sesuai dengan yang ditampilkan\n\n'
                          '4. Saldo akan masuk dalam 5-10 menit setelah transfer dikonfirmasi',
                          style: TextStyle(
                            color: Colors.blue[900],
                            height: 1.6,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // CTA buttons
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
                    onPressed: () async {
                      print('🔍 [TOPUP] Saya Sudah Transfer button pressed');
                      print('🔍 [TOPUP] Total Amount: $_totalAmount');
                      print(
                        '🔍 [TOPUP] Selected Bank: ${_selectedBank?.namaBank}',
                      );

                      if (_selectedBank == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pilih bank terlebih dahulu'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        // 1. Get user token
                        final userToken = await SessionManager.getToken();
                        if (userToken == null || userToken.isEmpty) {
                          throw Exception('Token tidak ditemukan');
                        }

                        print(
                          '🔍 [TOPUP] User Token: ${userToken.substring(0, 20)}...',
                        );

                        // 2. Call topUpSaldo API to create transaction in database
                        print('🔍 [TOPUP] Calling topUpSaldo API...');
                        final topupResult = await widget.apiService.topUpSaldo(
                          amount: _totalAmount.toString(),
                          bankName: _selectedBank!.namaBank ?? '',
                          nomorRekening: _selectedBank!.nomorRekening ?? '',
                          namaRekening: _selectedBank!.atasNamaRekening ?? '',
                          userToken: userToken,
                          adminUserId: AppConfig().adminId,
                        );

                        print(
                          '🔍 [TOPUP] API Response Status: ${topupResult.response.status}',
                        );
                        print(
                          '🔍 [TOPUP] Message: ${topupResult.response.message}',
                        );
                        print(
                          '🔍 [TOPUP] Generated Transaction ID: ${topupResult.generatedTrxId}',
                        );

                        // Check if transaction creation was successful
                        if (topupResult.response.status != true) {
                          throw Exception(
                            topupResult.response.message ??
                                'Gagal membuat topup',
                          );
                        }

                        // 3. Use the client-generated transaction number (backend accepted it)
                        final nomorTransaksi = topupResult.generatedTrxId;
                        print('✅ [TOPUP] Transaction created successfully!');
                        print('✅ [TOPUP] No. Transaksi: $nomorTransaksi');
                        print('✅ [TOPUP] Navigating to confirmation page...');

                        if (!mounted) return;

                        // 4. Navigate to TopupKonfirmasi with nomorTransaksi from server
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TopupKonfirmasi(
                              nomorTransaksi: nomorTransaksi,
                              totalAmount: _totalAmount,
                              primaryColor: widget.primaryColor,
                              apiService: widget.apiService,
                            ),
                          ),
                        );
                      } catch (e) {
                        print('❌ [TOPUP] Error: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal membuat topup: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Saya Sudah Transfer',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: widget.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Kembali',
                      style: TextStyle(
                        color: widget.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BankDetailCard extends StatelessWidget {
  final BankAccount bank;
  final Color primaryColor;
  final Function(BankAccount)? onSelected;
  final BankAccount? selectedBank;

  const _BankDetailCard({
    required this.bank,
    required this.primaryColor,
    this.onSelected,
    this.selectedBank,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    print('🔍 [BANK] Copying to clipboard: $label = $text');
    Clipboard.setData(ClipboardData(text: text))
        .then((_) {
          print('✅ [BANK] Successfully copied: $label');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label disalin ke clipboard'),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 2),
            ),
          );
        })
        .catchError((e) {
          print('❌ ERROR copying to clipboard: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyalin ke clipboard'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  void _showLogoPreview(BuildContext context, String logoUrl, String bankName) {
    print('🔍 [BANK] Opening logo preview: $logoUrl');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      height: 400,
                      errorBuilder: (_, __, ___) => Container(
                        height: 400,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      bankName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedBank?.id == bank.id;

    print('🔍 [BANK] Building card for: ${bank.namaBank} (ID: ${bank.id})');
    print('🔍 [BANK] Logo URL: ${bank.logoBank}');
    print('🔍 [BANK] Account: ${bank.nomorRekening}');
    print('🔍 [BANK] Is Selected: $isSelected');

    return GestureDetector(
      onTap: () {
        print('🔍 [BANK] Bank selected: ${bank.namaBank}');
        onSelected?.call(bank);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[300]!,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bank Name with Logo + Selection Indicator
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (bank.logoBank != null && bank.logoBank!.isNotEmpty)
                        GestureDetector(
                          onTap: () => _showLogoPreview(
                            context,
                            bank.logoBank!,
                            bank.namaBank ?? 'Bank',
                          ),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                              border: Border.all(color: primaryColor, width: 2),
                            ),
                            child: Stack(
                              children: [
                                Image.network(
                                  bank.logoBank!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.account_balance,
                                    color: primaryColor,
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            border: Border.all(color: primaryColor, width: 2),
                          ),
                          child: Icon(
                            Icons.account_balance,
                            color: primaryColor,
                            size: 30,
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bank.namaBank ?? 'Bank',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap logo untuk preview',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection Indicator
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // Atas Nama
            _BankDetailRow(
              label: 'Atas Nama',
              value: bank.atasNamaRekening ?? '',
              textColor: primaryColor,
              isCopyable: true,
              onCopy: () => _copyToClipboard(
                context,
                bank.atasNamaRekening ?? '',
                'Atas nama',
              ),
            ),
            const SizedBox(height: 10),
            // Nomor Rekening
            _BankDetailRow(
              label: 'No. Rekening',
              value: bank.nomorRekening ?? '',
              textColor: primaryColor,
              isCopyable: true,
              onCopy: () => _copyToClipboard(
                context,
                bank.nomorRekening ?? '',
                'Nomor rekening',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final bool isCopyable;
  final VoidCallback? onCopy;

  const _BankDetailRow({
    required this.label,
    required this.value,
    required this.textColor,
    this.isCopyable = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.black, // Changed to black
              ),
            ),
            if (isCopyable) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onCopy,
                child: const Icon(Icons.copy, size: 16, color: Colors.grey),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
