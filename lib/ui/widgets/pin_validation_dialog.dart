import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/app_config.dart';

class PinValidationDialog extends StatefulWidget {
  final Function(String) onPinSubmitted;
  final VoidCallback onCancel;

  const PinValidationDialog({
    super.key,
    required this.onPinSubmitted,
    required this.onCancel,
  });

  @override
  State<PinValidationDialog> createState() => _PinValidationDialogState();
}

class _PinValidationDialogState extends State<PinValidationDialog> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _obscurePin = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_pinController.text.length == 6) {
      widget.onPinSubmitted(_pinController.text);
    } else {
      setState(() => _errorMessage = 'Masukkan 6 digit PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = appConfig.primaryColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
        ), // Batas maksimal lebar dialog
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                'Verifikasi Keamanan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Silakan masukkan PIN transaksi Anda',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // PIN Input Responsive Area
              LayoutBuilder(
                builder: (context, constraints) {
                  // Hitung ukuran kotak berdasarkan lebar tersedia (dibagi 6 kotak + spasi)
                  double spacing = 8.0;
                  double totalSpacing = spacing * 5;
                  double boxSize = (constraints.maxWidth - totalSpacing) / 6;

                  // Batasi ukuran maksimal kotak agar tidak terlalu raksasa di tablet
                  if (boxSize > 45) boxSize = 45;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Hidden TextField
                      Opacity(
                        opacity: 0,
                        child: SizedBox(
                          height: boxSize,
                          child: TextField(
                            controller: _pinController,
                            focusNode: _focusNode,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (val) {
                              setState(() => _errorMessage = null);
                              if (val.length == 6) _submit();
                            },
                          ),
                        ),
                      ),
                      // Visual Boxes
                      GestureDetector(
                        onTap: () => _focusNode.requestFocus(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            bool isFocused =
                                _pinController.text.length == index;
                            bool hasValue = _pinController.text.length > index;

                            return Container(
                              width: boxSize,
                              height:
                                  boxSize *
                                  1.2, // Sedikit lebih tinggi dari lebarnya
                              decoration: BoxDecoration(
                                color: isFocused
                                    ? Colors.white
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isFocused
                                      ? primaryColor
                                      : (hasValue
                                            ? primaryColor.withOpacity(0.5)
                                            : Colors.grey.shade300),
                                  width: isFocused ? 2 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: hasValue
                                  ? (_obscurePin
                                        ? Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                          )
                                        : Text(
                                            _pinController.text[index],
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ))
                                  : isFocused
                                  ? Container(
                                      width: 2,
                                      height: 15,
                                      color: primaryColor.withOpacity(0.3),
                                    ) // Cursor simulasi
                                  : null,
                            );
                          }),
                        ),
                      ),
                    ],
                  );
                },
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
                child: Text(
                  _obscurePin ? "Lihat PIN" : "Sembunyikan",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: widget.onCancel,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Konfirmasi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
