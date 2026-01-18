import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/app_config.dart';
import '../../../../../features/customer/data/models/transaction_response_model.dart';
import '../../../../../features/customer/data/models/transaction_detail_model.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../core/network/session_manager.dart';
import 'transaction_detail_page.dart';

class TransactionSuccessPage extends StatefulWidget {
  final String productName;
  final String phoneNumber;
  final int totalPrice;
  final TransactionResponse transaction;

  const TransactionSuccessPage({
    super.key,
    required this.productName,
    required this.phoneNumber,
    required this.totalPrice,
    required this.transaction,
  });

  @override
  State<TransactionSuccessPage> createState() => _TransactionSuccessPageState();
}

class _TransactionSuccessPageState extends State<TransactionSuccessPage> {
  late ApiService _apiService;
  bool _isVerifying = true;
  String? _verificationError;
  TransactionDetail? _transactionDetail;
  int _retryCount = 0;
  final int _maxRetries = 15; // Max 15 attempts (~30 seconds)

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Dio());
    _startPolling();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _startPolling() async {
    if (!mounted) return;

    // Initial delay sebelum check pertama
    await Future.delayed(const Duration(seconds: 1));

    while (mounted && _retryCount < _maxRetries) {
      try {
        final String? token = await SessionManager.getToken();

        if (token == null) {
          if (mounted) {
            setState(() {
              _isVerifying = false;
              _verificationError = 'Token tidak ditemukan';
            });
          }
          break;
        }

        // Fetch transaction detail
        final response = await _apiService.getTransactionDetailPrabayar(token);

        if (response.statusCode == 200) {
          final detailResponse = TransactionDetailResponse.fromJson(
            response.data,
          );

          if (detailResponse.data.isNotEmpty) {
            // Find transaction by refId or ID
            TransactionDetail? transaction;
            try {
              transaction = detailResponse.data.firstWhere((t) {
                final refIdMatch = t.refId == widget.transaction.referenceCode;
                final idMatch =
                    t.id.toString() == widget.transaction.transactionId;
                return refIdMatch || idMatch;
              });
            } catch (e) {
              transaction = null;
            }

            if (transaction != null) {
              if (mounted) {
                setState(() {
                  _transactionDetail = transaction;
                });
              }

              // ✅ Check if status is final (SUKSES or GAGAL)
              if (transaction.status == 'SUKSES' ||
                  transaction.status == 'GAGAL') {
                if (mounted) {
                  setState(() {
                    _isVerifying = false;
                  });
                }
                return; // Stop polling
              } else if (transaction.status == 'PENDING') {
                // Still pending, continue polling
                _retryCount++;

                if (mounted && _retryCount < _maxRetries) {
                  await Future.delayed(const Duration(seconds: 2));
                  continue;
                } else if (mounted) {
                  // Max retries reached
                  setState(() {
                    _isVerifying = false;
                    _verificationError =
                        'Transaksi masih diproses (timeout setelah 30 detik)';
                  });
                  return;
                }
              }
            } else {
              // Transaction not found yet
              _retryCount++;

              if (mounted && _retryCount < _maxRetries) {
                await Future.delayed(const Duration(seconds: 2));
                continue;
              } else if (mounted) {
                // Max retries reached
                setState(() {
                  _isVerifying = false;
                  _verificationError =
                      'Transaksi tidak ditemukan setelah beberapa kali coba';
                });
                return;
              }
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _isVerifying = false;
              _verificationError =
                  'Gagal memverifikasi transaksi (${response.statusCode})';
            });
          }
          break;
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isVerifying = false;
            _verificationError = 'Error: $e';
          });
        }
        break;
      }
    }

    // Max retries reached and still PENDING
    if (mounted && _retryCount >= _maxRetries) {
      setState(() {
        _isVerifying = false;
        if (_transactionDetail == null) {
          _verificationError =
              'Transaksi tidak ditemukan setelah beberapa kali coba';
        } else if (_transactionDetail!.status == 'PENDING') {
          _verificationError =
              'Transaksi masih PENDING (${_transactionDetail!.status})';
        }
      });
    }
  }

  Future<void> _retryVerify() async {
    setState(() {
      _isVerifying = true;
      _verificationError = null;
      _transactionDetail = null;
      _retryCount = 0;
    });
    _startPolling();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = appConfig.primaryColor;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: _isVerifying
            ? _buildVerifyingState(primaryColor)
            : _verificationError != null
            ? _buildErrorState(primaryColor)
            : _buildSuccessState(primaryColor),
      ),
    );
  }

  Widget _buildVerifyingState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated checkmark
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(primaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Memproses Transaksi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reload status dari database...',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          if (_transactionDetail != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Status: ${_transactionDetail!.status}',
                style: TextStyle(
                  fontSize: 12,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 32),
          // Status steps
          _buildStatusStep('Transaksi dikirim', true),
          const SizedBox(height: 12),
          _buildStatusStep('Reload status', _transactionDetail != null),
          const SizedBox(height: 12),
          _buildStatusStep(
            'Selesai',
            _transactionDetail != null &&
                (_transactionDetail!.status == 'SUKSES' ||
                    _transactionDetail!.status == 'GAGAL'),
          ),
          const SizedBox(height: 16),
          Text(
            'Attempt: ${_retryCount + 1}/$_maxRetries',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(String label, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: completed ? Colors.green : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: completed ? Colors.green : Colors.grey[600],
              fontWeight: completed ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color primaryColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(Icons.error_outline, color: Colors.red, size: 50),
        ),
        const SizedBox(height: 24),
        const Text(
          'Verifikasi Gagal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _verificationError ?? 'Terjadi kesalahan saat verifikasi',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        if (_transactionDetail != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Status: ${_transactionDetail!.status}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _retryVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  side: BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Kembali', style: TextStyle(color: primaryColor)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(Color primaryColor) {
    final isSuccess = _transactionDetail?.status == 'SUKSES';

    return ListView(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isSuccess
                ? Colors.green.withOpacity(0.05)
                : Colors.red.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: isSuccess
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isSuccess
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  isSuccess
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSuccess ? 'Transaksi Berhasil!' : 'Transaksi Gagal!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSuccess
                    ? 'Status: SUKSES - Transaksi berhasil diproses'
                    : 'Status: GAGAL - Transaksi gagal diproses',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Transaction Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'Status Transaksi',
                      _transactionDetail?.status ?? 'UNKNOWN',
                      isBold: true,
                      valueColor: _transactionDetail?.status == 'SUKSES'
                          ? Colors.green
                          : _transactionDetail?.status == 'GAGAL'
                          ? Colors.red
                          : Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'ID Transaksi',
                      widget.transaction.transactionId ?? '-',
                      copyable: true,
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Kode Referensi',
                      widget.transaction.referenceCode ?? '-',
                      copyable: true,
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _buildInfoRow('Produk', widget.productName),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _buildInfoRow('Nomor Tujuan', widget.phoneNumber),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Total Bayar',
                      'Rp ${widget.totalPrice}',
                      isBold: true,
                      valueColor: primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(45),
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Selesai',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_transactionDetail != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionDetailPage(
                                refId: widget.transaction.referenceCode ?? '',
                                transactionId:
                                    widget.transaction.transactionId ?? '',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size.fromHeight(45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Lihat Detail',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    bool copyable = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Flexible(
          child: GestureDetector(
            onLongPress: copyable
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$label disalin: $value'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                : null,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
