// 🔐 Buysindo Transaction Client - Hybrid HMAC Security
// lib/services/buysindo_transaction_client.dart

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';

class BuysindoTransactionClient {
  final String baseUrl;
  final String? userToken; // JWT token untuk user mode
  final String? adminApiKey; // API Key untuk admin mode
  final String? adminApiSecret; // API Secret untuk admin mode
  final String? adminId; // Admin ID untuk admin mode

  BuysindoTransactionClient({
    required this.baseUrl,
    this.userToken,
    this.adminApiKey,
    this.adminApiSecret,
    this.adminId,
  });

  /// 📱 USER MODE TRANSACTION (Simple & Safe)
  /// Gunakan ini untuk regular users dari mobile app
  Future<Map<String, dynamic>> userProcessTransaction({
    required String pin,
    required String category,
    required String sku,
    required String namaProduk,
    required String noHandphone,
    required int diskon,
    required int total,
    int? markupMember,
    int? hargaJualMember,
  }) async {
    if (userToken == null) {
      throw Exception('User token not provided');
    }

    try {
      final payload = {
        'pin': pin,
        'category': category,
        'sku': sku,
        'nama_produk': namaProduk,
        'no_handphone': noHandphone,
        'diskon': diskon,
        'total': total,
        if (markupMember != null) 'markup_member': markupMember,
        if (hargaJualMember != null) 'harga_jual_member': hargaJualMember,
      };

      // Optional: Gunakan nonce untuk extra security
      final nonce = const Uuid().v4();

      final response = await http.post(
        Uri.parse('$baseUrl/api/transaksi/prabayar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
          'X-Nonce': nonce, // Optional untuk replay attack prevention
        },
        body: jsonEncode(payload),
      );

      return _handleResponse(response, 'USER');
    } catch (e) {
      print('❌ USER MODE ERROR: $e');
      rethrow;
    }
  }

  /// 🔥 ADMIN MODE TRANSACTION (HMAC Protected)
  /// Gunakan ini untuk admin panel atau server-to-server integration
  Future<Map<String, dynamic>> adminProcessTransaction({
    required String userId,
    required String pin,
    required String category,
    required String sku,
    required String namaProduk,
    required String noHandphone,
    required int diskon,
    required int total,
    int? markupMember,
    int? hargaJualMember,
  }) async {
    if (adminApiKey == null || adminApiSecret == null || adminId == null) {
      throw Exception('Admin credentials not provided');
    }

    try {
      // 1️⃣ Build payload
      final payload = {
        'user_id': userId,
        'pin': pin,
        'category': category,
        'sku': sku,
        'nama_produk': namaProduk,
        'no_handphone': noHandphone,
        'diskon': diskon,
        'total': total,
        if (markupMember != null) 'markup_member': markupMember,
        if (hargaJualMember != null) 'harga_jual_member': hargaJualMember,
      };

      // 2️⃣ Sort keys untuk consistency
      final sortedKeys = payload.keys.toList()..sort();
      final sortedPayload = <String, dynamic>{};
      for (var key in sortedKeys) {
        sortedPayload[key] = payload[key];
      }

      // 3️⃣ JSON encode (no escape slashes)
      final jsonBody = jsonEncode(sortedPayload);

      // 4️⃣ Generate timestamp (current time in seconds)
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 5️⃣ Generate HMAC signature
      // Format: TIMESTAMP.JSONBODY
      final payloadForSign = '$timestamp.$jsonBody';
      final signature = Hmac(
        sha256,
        utf8.encode(adminApiSecret!),
      ).convert(utf8.encode(payloadForSign)).toString();

      // 6️⃣ Generate nonce untuk anti-replay
      final nonce = const Uuid().v4();

      print('🔍 ADMIN MODE DEBUG:');
      print('Payload: $jsonBody');
      print('Signature Payload: $payloadForSign');
      print('Generated Signature: $signature');

      // 7️⃣ Send request with HMAC headers
      final response = await http.post(
        Uri.parse('$baseUrl/api/transaksi/prabayar'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': adminApiKey!,
          'X-SIGNATURE': signature,
          'X-TIMESTAMP': timestamp.toString(),
          'X-ADMIN-ID': adminId!,
          'X-Nonce': nonce,
        },
        body: jsonBody,
      );

      return _handleResponse(response, 'ADMIN');
    } catch (e) {
      print('❌ ADMIN MODE ERROR: $e');
      rethrow;
    }
  }

  /// ✅ Handle HTTP Response
  Map<String, dynamic> _handleResponse(http.Response response, String mode) {
    print('📡 [$mode MODE] Status Code: ${response.statusCode}');
    print('📡 [$mode MODE] Response: ${response.body}');

    try {
      final result = jsonDecode(response.body);

      switch (response.statusCode) {
        case 200:
        case 201:
          if (result['status'] == true) {
            print('✅ [$mode MODE] Transaction successful');
            return result;
          } else {
            throw TransactionException(
              message: result['message'] ?? 'Transaction failed',
              code: 'TRANSACTION_FAILED',
            );
          }

        case 401:
          throw TransactionException(
            message: 'Unauthorized - Invalid token or signature',
            code: 'UNAUTHORIZED',
          );

        case 403:
          throw TransactionException(
            message: result['message'] ?? 'Forbidden - Invalid credentials',
            code: 'FORBIDDEN',
          );

        case 422:
          throw TransactionException(
            message:
                result['message'] ?? 'Validation error - Check price or data',
            code: 'VALIDATION_ERROR',
          );

        case 429:
          throw TransactionException(
            message: 'Too many requests - Transaction in progress',
            code: 'RATE_LIMIT',
          );

        case 500:
          throw TransactionException(
            message: 'Server error - Please try again later',
            code: 'SERVER_ERROR',
          );

        default:
          throw TransactionException(
            message: 'Unexpected error: ${response.statusCode}',
            code: 'UNKNOWN_ERROR',
          );
      }
    } catch (e) {
      if (e is TransactionException) rethrow;
      throw TransactionException(
        message: 'Failed to parse response: $e',
        code: 'PARSE_ERROR',
      );
    }
  }
}

/// 🚨 Custom Exception untuk Transaction
class TransactionException implements Exception {
  final String message;
  final String code;

  TransactionException({required this.message, required this.code});

  @override
  String toString() => 'TransactionException: $code - $message';
}

// ============================================================
// 📱 USAGE EXAMPLES
// ============================================================

class TransactionExamples {
  // ✅ USER MODE EXAMPLE
  Future<void> exampleUserMode() async {
    final client = BuysindoTransactionClient(
      baseUrl: 'https://api.buysindo.com',
      userToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...', // JWT dari login
    );

    try {
      final result = await client.userProcessTransaction(
        pin: '123456',
        category: 'pulsa',
        sku: 'TELKOMSEL10K',
        namaProduk: 'Pulsa Telkomsel 10rb',
        noHandphone: '082123456789',
        diskon: 0,
        total: 10000, // Harga sudah dikalkulasi dari backend
        markupMember: 0,
        hargaJualMember: 10000,
      );

      print('✅ Transaksi berhasil!');
      print('Data: ${result['data']}');
    } on TransactionException catch (e) {
      print('❌ Transaksi gagal: ${e.message}');
    }
  }

  // 🔥 ADMIN MODE EXAMPLE
  Future<void> exampleAdminMode() async {
    final client = BuysindoTransactionClient(
      baseUrl: 'https://api.buysindo.com',
      adminApiKey: 'admin_api_key_xxx',
      adminApiSecret: 'admin_api_secret_yyy',
      adminId: '1',
    );

    try {
      final result = await client.adminProcessTransaction(
        userId: '456', // User yang akan di-proses transaksinya
        pin: '123456',
        category: 'pulsa',
        sku: 'TELKOMSEL10K',
        namaProduk: 'Pulsa Telkomsel 10rb',
        noHandphone: '082123456789',
        diskon: 0,
        total: 10000,
        markupMember: 0,
        hargaJualMember: 10000,
      );

      print('✅ Admin transaction successful!');
      print('Data: ${result['data']}');
    } on TransactionException catch (e) {
      print('❌ Admin transaction failed: ${e.message}');
      print('Code: ${e.code}');
    }
  }

  // 📊 DIFFERENCE BETWEEN MODES
  void explainModes() {
    print('''
🎯 USER MODE vs ADMIN MODE

👤 USER MODE (Mobile App):
- Menggunakan JWT Token dari login
- Aman untuk regular users
- Tidak perlu HMAC complexity
- Token tidak akan di-reverse engineer

🔥 ADMIN MODE (Server-to-Server):
- Menggunakan HMAC-SHA256 signature
- Aman untuk admin panel integration
- Signature di-generate setiap request
- Timestamp-based untuk prevent replay
- Nonce-based untuk double-check

✅ SECURITY FEATURES (Both modes):
- Replay attack prevention ✅
- Server-side price validation ✅
- Race condition prevention ✅
- Double transaction detection ✅
- Comprehensive audit logging ✅
- IP & User-Agent tracking ✅
    ''');
  }
}
