import 'package:flutter/foundation.dart';

class TransactionResponse {
  final bool status;
  final String message;
  final String? transactionId;
  final String? referenceCode;

  TransactionResponse({
    required this.status,
    required this.message,
    this.transactionId,
    this.referenceCode,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('\n🔍 TransactionResponse.fromJson - Received JSON:');
    debugPrint('   JSON keys: ${json.keys.toList()}');
    debugPrint('   Full JSON: $json');

    // Extract data dari nested 'data' object jika ada
    final Map<String, dynamic> dataObject = (json['data'] is Map)
        ? json['data'] as Map<String, dynamic>
        : json;

    debugPrint('   Data object keys: ${dataObject.keys.toList()}');

    // Try multiple field names untuk transaction ID
    final String? txId =
        dataObject['transaction_id'] ??
        dataObject['transactionId'] ??
        dataObject['id']?.toString();

    // Try multiple field names untuk reference code
    final String? refCode =
        dataObject['reference_code'] ??
        dataObject['referenceCode'] ??
        dataObject['ref_id'];

    debugPrint('   ✅ Extracted - txId: $txId, refCode: $refCode');

    return TransactionResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      transactionId: txId,
      referenceCode: refCode,
    );
  }
}

class PinStatusResponse {
  final String status;

  PinStatusResponse({required this.status});

  factory PinStatusResponse.fromJson(Map<String, dynamic> json) {
    return PinStatusResponse(status: json['status'] ?? 'inactive');
  }

  bool get hasPin => status == 'active';
}

class PinValidationResponse {
  final String status;
  final String message;

  PinValidationResponse({required this.status, required this.message});

  factory PinValidationResponse.fromJson(Map<String, dynamic> json) {
    return PinValidationResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? '',
    );
  }

  bool get isValid => status == 'success';
}

class SaldoResponse {
  final bool status;
  final int saldo;

  SaldoResponse({required this.status, required this.saldo});

  factory SaldoResponse.fromJson(Map<String, dynamic> json) {
    // Handle saldo yang mungkin datang sebagai String atau int
    int parsedSaldo = 0;
    final saldoValue = json['saldo'];

    if (saldoValue is String) {
      parsedSaldo = int.tryParse(saldoValue) ?? 0;
    } else if (saldoValue is int) {
      parsedSaldo = saldoValue;
    } else if (saldoValue is double) {
      parsedSaldo = saldoValue.toInt();
    }

    return SaldoResponse(status: json['status'] ?? false, saldo: parsedSaldo);
  }
}
