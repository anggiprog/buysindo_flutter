# Implementasi Detail - Transaction System

## 📦 File Structure

```
lib/
├── core/
│   └── network/
│       └── api_service.dart (✏️ UPDATED)
│           └── Endpoints baru untuk PIN & Transaction
│
├── features/
│   └── customer/
│       └── data/
│           └── models/
│               ├── product_prabayar_model.dart (existing)
│               └── transaction_response_model.dart (✨ NEW)
│
├── ui/
│   ├── widgets/
│   │   └── pin_validation_dialog.dart (✨ NEW)
│   │
│   ├── home/
│   │   ├── pin.dart (✏️ UPDATED - COMPLETED)
│   │   ├── topup_modal.dart (existing)
│   │   │
│   │   └── customer/
│   │       └── tabs/
│   │           └── templates/
│   │               ├── detail_pulsa_page.dart (✏️ COMPLETELY REWRITTEN)
│   │               └── prabayar/
│   │                   └── pulsa.dart (existing)
```

---

## 🔧 Implementasi Detail

### 1. transaction_response_model.dart
**Tujuan:** Handle semua response dari backend transaksi-related

**Classes:**
- `TransactionResponse` → Response dari proses transaksi
- `PinStatusResponse` → Response status PIN user
- `PinValidationResponse` → Response validasi PIN
- `SaldoResponse` → Response saldo user

**Key Methods:**
```dart
// Parsing JSON dari backend
factory TransactionResponse.fromJson(Map<String, dynamic> json)
bool get isValid  // PinValidationResponse

// Check PIN ada/belum
bool get hasPin  // PinStatusResponse
```

---

### 2. api_service.dart - Endpoint Baru

**PIN Endpoints:**
```dart
Future<Response> checkPinStatus(String token)
Future<Response> validatePin(String pin, String token)
Future<Response> savePinData(String pin, String token)
```

**Transaction Endpoint:**
```dart
Future<Response> processPrabayarTransaction({
  required String pin,
  required String category,
  required String sku,
  required String productName,
  required String phoneNumber,
  required int discount,
  required int total,
  required String token,
})
```

---

### 3. pin.dart - PIN Creation Page

**Fitur:**
- ✅ Input PIN 6 digit
- ✅ Confirm PIN validation
- ✅ Real-time requirement checker
- ✅ Visibility toggle untuk PIN
- ✅ Save ke backend dengan API
- ✅ Success notification & redirect
- ✅ Error handling lengkap

**Key State:**
```dart
_pinController: TextEditingController
_confirmPinController: TextEditingController
_obscurePin: bool
_obscureConfirmPin: bool
_isLoading: bool
_errorMessage: String?
```

**Flow:**
1. User input PIN
2. Validasi requirement (min 6 digit, match confirm)
3. Klik BUAT PIN
4. API POST /api/pin/store
5. Success → Pop dengan result: true
6. Error → Show error message

---

### 4. pin_validation_dialog.dart - PIN Dialog

**Fitur:**
- ✅ Dialog modal untuk PIN verification
- ✅ Pin input dengan visibility toggle
- ✅ Error message inline
- ✅ Cancel & Submit buttons
- ✅ 6 digit PIN only

**Callback:**
```dart
onPinSubmitted(String pin)  // When user tap Lanjutkan
onCancel()                   // When user tap Batal
```

---

### 5. detail_pulsa_page.dart - COMPLETELY REWRITTEN

**Status:** StatefulWidget (untuk state management)

**Key State Variables:**
```dart
_userSaldo: int              // Saldo user
_isLoadingSaldo: bool        // Loading indicator saat fetch saldo
_isSaldoCukup: bool          // Flag saldo cukup/tidak
_isProcessing: bool          // Flag saat proses transaksi
```

**Main Methods:**

#### `_loadSaldo()`
- Fetch saldo user saat page init
- Update `_isSaldoCukup` status
- Error handling

#### `_showTopupModal()`
- Show TopupModal dari bawah (showModalBottomSheet)
- After topup → Reload saldo

#### `_checkPinAndProcess()`
1. Call `checkPinStatus()` API
2. If PIN tidak ada → Navigate ke PinPage
3. If PIN ada → Show PIN validation dialog

#### `_validateAndProcessTransaction(pin, token)`
1. Call `validatePin()` API
2. If valid → Call `_processTransaction()`
3. If invalid → Show error

#### `_processTransaction(pin, token)`
1. Call `processPrabayarTransaction()` API dengan semua data
2. If success → Show success dialog
3. If error → Show error message

#### `_showSuccessDialog(transaction)`
- Show transaction details
- Button "Selesai" → Pop 3x (back to home)

---

## 🎨 UI Elements

### Alert Saldo Tidak Cukup (Conditional)
```dart
if (!_isLoadingSaldo && !_isSaldoCukup)
  Container(
    // Red alert banner
    // Show berapa kurang saldo
  )
```

### Button Logic
```dart
_isSaldoCukup ? "BAYAR SEKARANG" : "TOPUP SALDO"
_isSaldoCukup ? primaryColor : Colors.orange
```

### Loading State
- Loading indicator saat fetch saldo
- Loading indicator saat process transaksi
- Button disabled saat loading

---

## ⚠️ Error Handling

**Tipe Error:**
1. **No Token** → Show "Token tidak ditemukan"
2. **Network Error** → Show "Terjadi kesalahan"
3. **API Error** → Show message dari response
4. **PIN Validation** → Show specific PIN error (e.g., "PIN salah")
5. **Insufficient Balance** → Show alert & button "TOPUP SALDO"

**Error Display:**
- SnackBar untuk transient error
- Dialog untuk critical error
- Inline error untuk input validation

---

## 🔄 Data Flow

```
Page Load
  ↓
Load Saldo (API)
  ↓
Update UI (Button Text, Alert)
  ↓
User Action
  ├─ Saldo Kurang → Klik Topup → TopupModal
  │                            ↓
  │                         After Topup → Reload Saldo
  │
  └─ Saldo Cukup → Klik Bayar → Check PIN Status (API)
                                ↓
                              PIN Ada?
                              ├─ Tidak → PinPage (Create PIN)
                              │          ↓
                              │       After Create → Validation Dialog
                              │
                              └─ Ya → Validation Dialog
                                      ↓
                                   User Input PIN
                                      ↓
                                   Validate PIN (API)
                                      ↓
                                   Process Transaction (API)
                                      ↓
                                   Success → Success Dialog
                                      ↓
                                   Back to Home
```

---

## 📊 Backend Integration

### 1. Session Manager
```dart
SessionManager.getToken()  // Get Bearer token
```

### 2. API Calls Order
```
1. getSaldo(token)                    // Check balance
2. checkPinStatus(token)              // Check if user has PIN
3. [Optional] savePinData(pin, token) // Create new PIN
4. validatePin(pin, token)            // Validate entered PIN
5. processPrabayarTransaction(...)    // Process transaction
```

### 3. Error Response Handling
Semua API responses di-check dengan:
```dart
if (response.statusCode == 200) {
  // Parse response
} else {
  // Show error from response.data['message']
}
```

---

## ✅ Validation Checklist

- [x] PIN model & response handling
- [x] All API endpoints implemented
- [x] PIN creation page (PinPage)
- [x] PIN validation dialog
- [x] DetailPulsaPage complete rewrite
- [x] Saldo checking & alert
- [x] Error handling comprehensive
- [x] Loading states implemented
- [x] Success dialog with transaction ID
- [x] Navigation flows correct
- [x] Code compile without errors

---

## 🚀 Siap untuk Testing!

**Next Step:**
1. Run aplikasi: `flutter run`
2. Navigate ke Pulsa page
3. Select produk → Click Detail
4. Test flow: Bayar → Create/Enter PIN → Success
5. Verify transaction in backend
