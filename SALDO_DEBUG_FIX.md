# 🔧 Saldo Checking Fix - Debug Guide

## 🐛 Masalah

Saldo user 660.000 tetapi sistem mengatakan "Saldo Tidak Cukup"

## ✅ Solusi

### 1. Fix di SaldoResponse Model
```dart
// BEFORE: Hanya handle int
saldo: json['saldo'] ?? 0

// AFTER: Handle String, int, dan double
if (saldoValue is String) {
  parsedSaldo = int.tryParse(saldoValue) ?? 0;
} else if (saldoValue is int) {
  parsedSaldo = saldoValue;
} else if (saldoValue is double) {
  parsedSaldo = saldoValue.toInt();
}
```

**Mengapa:** API mungkin mengembalikan saldo sebagai String atau Double, bukan Integer.

### 2. Debug Logging di DetailPulsaPage
```dart
debugPrint('═══════════════════════════════════════════');
debugPrint('💰 SALDO CHECK');
debugPrint('Saldo User: $_userSaldo');
debugPrint('Total Bayar: ${widget.product.totalHarga}');
debugPrint('Saldo Cukup: $_isSaldoCukup');
debugPrint('═══════════════════════════════════════════');
```

**Fungsi:** Tampilkan di console saat page load untuk debug.

## 🧪 Testing

1. **Run aplikasi:**
   ```bash
   flutter clean
   flutter run
   ```

2. **Buka console untuk melihat output:**
   - Lihat debug info dengan format:
   ```
   ═══════════════════════════════════════════
   💰 SALDO CHECK
   Saldo User: 660000
   Total Bayar: 50100
   Saldo Cukup: true
   ═══════════════════════════════════════════
   ```

3. **Verifikasi:**
   - Jika `Saldo User >= Total Bayar` → "BAYAR SEKARANG" button harus green
   - Jika `Saldo User < Total Bayar` → "TOPUP SALDO" button harus orange

## 🎯 Possible Causes

| Penyebab | Solusi |
|----------|--------|
| API return saldo as String | ✅ Fixed dengan parsing |
| API return saldo as Double | ✅ Fixed dengan toInt() |
| Wrong JSON key (bukan "saldo") | Cek di backend |
| Saldo 0 dari awal | Cek di database |

## 📊 Logika Pengecekan

```dart
// Logika di _loadSaldo()
_isSaldoCukup = _userSaldo >= widget.product.totalHarga;

// Button UI
_isSaldoCukup ? "BAYAR SEKARANG" : "TOPUP SALDO"
```

## 🚀 Sekarang

- Coba test di emulator/device
- Lihat output console
- Verifikasi saldo parsing correct
- Jika masih tidak cukup, cek response dari API `/api/saldo`

---

**File Modified:**
- `transaction_response_model.dart` - SaldoResponse parsing fix
- `detail_pulsa_page.dart` - Debug logging added
