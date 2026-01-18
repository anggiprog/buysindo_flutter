# DetailPulsaPage Transaction Flow - Dokumentasi

## 📋 Ringkasan Fitur

Implementasi logika lengkap untuk proses transaksi prabayar dengan validasi saldo, PIN management, dan proses transaksi backend.

---

## 🔄 Flow Proses Transaksi

### 1. **Initial Load**
- Page pertama kali load, fetch saldo user via API
- Cek apakah saldo cukup untuk membeli produk
- Button berubah tergantung status saldo:
  - ✅ **Saldo Cukup** → "BAYAR SEKARANG" (hijau/primary)
  - ❌ **Saldo Kurang** → "TOPUP SALDO" (orange)

### 2. **Jika Saldo Tidak Cukup**
```
User Klik "TOPUP SALDO" → Show TopupModal (dari bawah)
User melakukan top up → Reload saldo
```

### 3. **Jika Saldo Cukup**
```
User Klik "BAYAR SEKARANG" 
    ↓
Cek Status PIN (API: /api/pin/check-status)
    ↓
    ├─ PIN Belum Ada → Arahkan ke PinPage (buat PIN baru)
    │                  ↓
    │                  After PIN Created → Show PIN Validation Dialog
    │
    └─ PIN Sudah Ada → Show PIN Validation Dialog
                        ↓
                        User masukkan PIN
                        ↓
                        Validasi PIN (API: /api/pin/validate)
                        ↓
                        ├─ PIN Valid → Proses Transaksi
                        └─ PIN Salah → Show Error & Ask Again
```

### 4. **Proses Transaksi**
```
POST /api/proses-trx-prabayar
{
    "pin": "123456",
    "category": "Pulsa",
    "sku": "TELKOMSEL50K",
    "nama_produk": "Telkomsel 50.000",
    "no_handphone": "08123456789",
    "diskon": 250,
    "total": 50100
}
    ↓
    ├─ Success → Show Success Dialog dengan ID Transaksi & Reference Code
    └─ Error → Show Error Message
```

---

## 📁 File-File Baru & Perubahan

### File Baru:
1. **lib/features/customer/data/models/transaction_response_model.dart**
   - Model untuk response transaksi, PIN status, dan validasi PIN
   - Classes: `TransactionResponse`, `PinStatusResponse`, `PinValidationResponse`, `SaldoResponse`

2. **lib/ui/home/pin.dart** ✨ (LENGKAP)
   - Page untuk membuat PIN baru
   - Validasi PIN 6 digit
   - Requirement checker (real-time)
   - Success notification & redirect

3. **lib/ui/widgets/pin_validation_dialog.dart** ✨ (BARU)
   - Dialog untuk validasi PIN saat checkout
   - Input PIN dengan visibility toggle
   - Error handling & retry

### File yang Dimodifikasi:
1. **lib/core/network/api_service.dart**
   - ✅ `checkPinStatus(token)` - Cek status PIN user
   - ✅ `validatePin(pin, token)` - Validasi PIN
   - ✅ `savePinData(pin, token)` - Simpan PIN baru
   - ✅ `processPrabayarTransaction(...)` - Proses transaksi

2. **lib/ui/home/customer/tabs/templates/detail_pulsa_page.dart**
   - ✅ Update dari StatelessWidget → StatefulWidget
   - ✅ Load saldo user saat page load
   - ✅ Check PIN & proses transaksi lengkap
   - ✅ Alert saldo tidak cukup
   - ✅ TopUp modal integration
   - ✅ Success dialog dengan transaction details

---

## 🎯 API Endpoints yang Digunakan

### Backend Endpoints:
```
1. GET  /api/saldo
   - Ambil saldo user
   - Header: Authorization: Bearer $token

2. GET  /api/pin/check-status
   - Cek status PIN (active/inactive)
   - Header: Authorization: Bearer $token
   - Response: { "status": "active" | "inactive" }

3. GET  /api/pin/validate
   - Validasi PIN yang dimasukkan
   - Query Param: pin=123456
   - Header: Authorization: Bearer $token
   - Response: { "status": "success|error", "message": "..." }

4. POST /api/pin/store
   - Simpan PIN baru
   - Body: { "pin": "123456" }
   - Header: Authorization: Bearer $token
   - Response: { "message": "PIN berhasil disimpan atau diperbarui" }

5. POST /api/proses-trx-prabayar
   - Proses transaksi prabayar
   - Body: {
       "pin": "123456",
       "category": "Pulsa",
       "sku": "TELKOMSEL50K",
       "nama_produk": "Telkomsel 50.000",
       "no_handphone": "08123456789",
       "diskon": 250,
       "total": 50100
     }
   - Header: Authorization: Bearer $token
   - Response: { 
       "status": true,
       "message": "Transaksi berhasil",
       "transaction_id": "TRX123456",
       "reference_code": "REF123456"
     }
```

---

## 🛡️ Security Features

1. **PIN Validation**
   - PIN di-hash di backend (bcrypt)
   - PIN tidak pernah disimpan di plain text
   - Setiap transaksi memerlukan PIN yang valid

2. **Token-based Auth**
   - Semua API request memerlukan Bearer Token
   - Token divalidasi di backend

3. **Saldo Validation**
   - Cek saldo sebelum transaksi
   - Prevent insufficient balance checkout

---

## 🧪 Testing Checklist

- [ ] Load page dengan saldo cukup → "BAYAR SEKARANG" button active
- [ ] Load page dengan saldo kurang → "TOPUP SALDO" button active
- [ ] Klik "TOPUP SALDO" → TopupModal muncul
- [ ] Klik "BAYAR SEKARANG" tanpa PIN → Navigate ke PinPage
- [ ] Buat PIN 6 digit → Success notification & back to checkout
- [ ] Klik "BAYAR SEKARANG" dengan PIN ada → PIN validation dialog
- [ ] Masukkan PIN salah → Error message
- [ ] Masukkan PIN benar → Proses transaksi
- [ ] Transaksi success → Show success dialog dengan transaction ID
- [ ] Transaksi gagal → Show error message

---

## 📝 Notes

- Semua response handling sudah include error handling
- Loading state sudah diimplementasikan
- SnackBar untuk feedback user
- Dialog untuk critical confirmations
- Real-time validation untuk PIN input

**Status: ✅ SELESAI & SIAP TESTING**
