import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SessionManager {
  static const String _tokenKey = 'access_token';

  // Menyimpan token setelah login berhasil
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    // 🔴 LOG: Tampilkan token yang disimpan
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('✅ TOKEN DISIMPAN');
    debugPrint('Token: $token');
    debugPrint('Panjang Token: ${token.length}');
    debugPrint('Waktu: ${DateTime.now()}');
    debugPrint('═══════════════════════════════════════════════════');
  }

  // Mengambil token saat aplikasi dibuka
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    // 🔴 LOG: Tampilkan token saat diambil
    if (token != null && token.isNotEmpty) {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('🔑 TOKEN DIAMBIL');
      debugPrint('Token: $token');
      debugPrint('Panjang Token: ${token.length}');
      debugPrint('Status: ✅ Ada');
      debugPrint('═══════════════════════════════════════════════════');
    } else {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('❌ TOKEN TIDAK DITEMUKAN');
      debugPrint('Status: Token kosong atau tidak tersimpan');
      debugPrint('═══════════════════════════════════════════════════');
    }

    return token;
  }

  // Menghapus token (Logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenBefore = prefs.getString(_tokenKey);

    await prefs.remove(_tokenKey);

    // 🔴 LOG: Konfirmasi token dihapus
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('🔴 TOKEN DIHAPUS (LOGOUT)');
    if (tokenBefore != null) {
      debugPrint('Token sebelumnya: $tokenBefore');
    }
    debugPrint('Status: ✅ Cleared');
    debugPrint('Waktu: ${DateTime.now()}');
    debugPrint('═══════════════════════════════════════════════════');
  }

  // 🆕 Bonus: Cek status token tanpa mengambilnya
  static Future<bool> isTokenExist() async {
    final prefs = await SharedPreferences.getInstance();
    final exists = prefs.containsKey(_tokenKey);
    debugPrint('🔍 CEK TOKEN: ${exists ? "✅ Ada" : "❌ Tidak ada"}');
    return exists;
  }
}
