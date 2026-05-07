import 'dart:convert';
import 'package:crypto/crypto.dart';

class SignatureService {
  /// Generate headers dengan HMAC-SHA256 signature untuk API requests
  ///
  /// Required parameters:
  /// - body: Map berisi request body yang akan di-sign
  /// - apiKey: API key dari admin user
  /// - secret: API secret untuk hashing
  ///
  /// Returns Map dengan headers yang sudah di-sign:
  /// - X-API-KEY: API key
  /// - X-SIGNATURE: HMAC-SHA256 signature dari payload
  /// - X-TIMESTAMP: Unix timestamp (seconds)
  /// - Content-Type: application/json
  /// - Accept: application/json
  static Map<String, String> generateHeaders({
    required Map<String, dynamic> body,
    required String apiKey,
    required String secret,
  }) {
    // Ambil timestamp saat ini (dalam seconds, bukan milliseconds)
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 🔥 WAJIB: Sort body keys agar sama dengan server
    final sortedEntries = body.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final sortedBody = Map.fromEntries(sortedEntries);

    // Buat JSON string dari body yang sudah di-sort
    final jsonBody = jsonEncode(sortedBody);

    // Buat payload: timestamp.jsonBody
    final payload = '$timestamp.$jsonBody';

    // Generate HMAC-SHA256 signature
    final hmac = Hmac(sha256, utf8.encode(secret));
    final signature = hmac.convert(utf8.encode(payload)).toString();

    return {
      'X-API-KEY': apiKey,
      'X-SIGNATURE': signature,
      'X-TIMESTAMP': timestamp.toString(),
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}
