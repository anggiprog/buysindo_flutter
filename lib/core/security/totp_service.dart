import 'package:crypto/crypto.dart';
import 'dart:convert';

class TOTPService {
  /// Generate TOTP token yang sama dengan Laravel backend
  /// Algoritma: HMAC-SHA256(timeIndex, secretKey)
  /// Token berubah setiap N detik (default 60 detik)
  static String generateToken({
    required String secretKey,
    int timeStep = 60,
    int offsetWindows = 0,
  }) {
    // Hitung time index berdasarkan epoch time (HARUS SESUAI DENGAN BACKEND)
    int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int timeIndex = (currentTime ~/ timeStep) + offsetWindows;

    // Generate HMAC-SHA256 dengan secret key (SESUAI DENGAN BACKEND)
    // Backend PHP: hash_hmac('sha256', $timeIndex, $secret)
    // Kita perlu encode timeIndex sebagai big-endian 8 bytes (standard TOTP)
    var key = utf8.encode(secretKey);

    // Convert timeIndex ke 8 bytes big-endian (ini adalah standard TOTP RFC 6238)
    List<int> timeBytes = _longToBytes(timeIndex);

    var hmac = Hmac(sha256, key);
    var digest = hmac.convert(timeBytes);

    // Ambil 8 karakter terakhir dari hash hex dan uppercase
    String hashString = digest.toString().toUpperCase();
    return hashString.substring(hashString.length - 8);
  }

  /// Convert long (int64) to 8 bytes big-endian
  static List<int> _longToBytes(int value) {
    List<int> bytes = List<int>.filled(8, 0);
    for (int i = 7; i >= 0; i--) {
      bytes[i] = (value & 0xFF).toInt();
      value = value >> 8;
    }
    return bytes;
  }

  /// Generate current TOTP token dengan tolerance untuk clock drift
  /// Mencoba 3 windows: current, -1 step, +1 step
  static String getCurrentToken({
    required String secretKey,
    int timeStep = 60,
  }) {
    // Return current token saja (backend akan mengecek 3 windows)
    return generateToken(
      secretKey: secretKey,
      timeStep: timeStep,
      offsetWindows: 0,
    );
  }

  /// Debug: Lihat tokens untuk 3 windows waktu
  static Map<String, String> debugGetAllValidTokens({
    required String secretKey,
    int timeStep = 60,
  }) {
    return {
      'previous': generateToken(
        secretKey: secretKey,
        timeStep: timeStep,
        offsetWindows: -1,
      ),
      'current': generateToken(
        secretKey: secretKey,
        timeStep: timeStep,
        offsetWindows: 0,
      ),
      'next': generateToken(
        secretKey: secretKey,
        timeStep: timeStep,
        offsetWindows: 1,
      ),
    };
  }
}
