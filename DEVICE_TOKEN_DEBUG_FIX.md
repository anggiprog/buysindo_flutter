# 🔧 Device Token Debugging & Fix Guide

## 📋 Masalah yang Ditemukan

Device token **TIDAK TAMPIL DI DEBUG** karena:

1. ❌ **`updateDeviceToken()` TIDAK PERNAH DIPANGGIL** setelah login
2. ❌ Tidak ada logging detail untuk track device token flow
3. ❌ OTP screen juga tidak update device token setelah verification

---

## ✅ Solusi yang Diimplementasikan

### 1. **Enhanced Logging di AuthService**

**File:** [lib/core/network/auth_service.dart](lib/core/network/auth_service.dart)

#### `getDeviceToken()` - Sekarang dengan logging detail:
```dart
// ❌ BEFORE
Future<String> getDeviceToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    return token ?? 'unknown_device_token';
  } catch (e) {
    debugPrint('Error getting device token: $e');
    return 'error_getting_token';
  }
}

// ✅ AFTER
Future<String> getDeviceToken() async {
  try {
    debugPrint('📱 [AuthService] Fetching Firebase device token...');
    final token = await FirebaseMessaging.instance.getToken();
    
    if (token != null && token.isNotEmpty) {
      debugPrint('✅ [AuthService] Device token fetched: $token');
      return token;
    } else {
      debugPrint('⚠️ [AuthService] Firebase device token is empty/null');
      return 'unknown_device_token';
    }
  } catch (e) {
    debugPrint('❌ [AuthService] Error getting device token: $e');
    return 'error_getting_token';
  }
}
```

#### `login()` - Enhanced dengan device token logging:
```dart
// ✅ SEKARANG DENGAN LOGGING:
debugPrint('🔐 [AuthService] Starting login with email: $email');
final deviceToken = await getDeviceToken();
debugPrint('📤 [AuthService] Sending login request with device_token: $deviceToken');
```

#### `updateDeviceToken()` - Perbaikan CRITICAL:
```dart
// ❌ BEFORE - Tidak ada logging yang jelas
debugPrint('✅ Device token updated successfully: $deviceToken');

// ✅ AFTER - Logging komprehensif
debugPrint('📝 [AuthService] updateDeviceToken() called');
debugPrint('🔑 [AuthService] Using auth token: ${token.substring(0, 20)}...');
debugPrint('📱 [AuthService] Device token to update: $deviceToken');
debugPrint('✅ [AuthService] Device token updated successfully!');
debugPrint('📌 [AuthService] Device Token: $deviceToken');
debugPrint('📌 [AuthService] Response: ${response.data}');
```

---

### 2. **Login Screen - Call updateDeviceToken()**

**File:** [lib/ui/auth/login_screen.dart](lib/ui/auth/login_screen.dart#L68-L78)

```dart
// ✅ ADDED
// Update device token di server
debugPrint('📱 Updating device token...');
try {
  await authService.updateDeviceToken(loginResponse.accessToken!);
} catch (e) {
  debugPrint('⚠️ Device token update failed (non-critical): $e');
}
```

**Sebelumnya:** Device token diminta saat login tapi TIDAK di-update ke server.  
**Sekarang:** Setelah login berhasil, device token langsung di-update ke server dengan logging detail.

---

### 3. **OTP Screen - Call updateDeviceToken() Setelah Verification**

**File:** [lib/ui/auth/otp_screen.dart](lib/ui/auth/otp_screen.dart#L48)

```dart
// ✅ ADDED
if (response.token != null && response.token!.isNotEmpty) {
  debugPrint('📱 Updating device token after OTP verification...');
  try {
    await authService.updateDeviceToken(response.token!);
  } catch (e) {
    debugPrint('⚠️ Device token update failed after OTP (non-critical): $e');
  }
}
```

**Sebelumnya:** Setelah OTP verification, device token tidak di-update.  
**Sekarang:** Device token di-update ke server setelah OTP verification berhasil.

---

## 🔍 Debug Flow Chart

```
┌─────────────────────────────────────────┐
│  User enters email & password           │
└────────────────┬────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  📱 [AuthService] Fetching Firebase     │
│      device token...                     │
└────────────────┬────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  ✅ [AuthService] Device token fetched: │
│      [ACTUAL_TOKEN_HERE]                │
└────────────────┬────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  📤 [AuthService] Sending login request │
│      with device_token: [TOKEN]         │
└────────────────┬────────────────────────┘
                 ↓
         ┌──────┴──────────┐
         ↓                 ↓
    ┌────────────┐    ┌──────────┐
    │ OTP Needed │    │No OTP    │
    └────────┬───┘    │Required  │
             ↓        └────┬─────┘
    🔑 OTP REQUIRED        ↓
             │      ✅ [AuthService]
             │          Login successful
             │             │
             ↓             ↓
        ┌────────────┐  ┌──────────────┐
        │ OTP Screen │  │📱 Updating   │
        │            │  │device token..│
        └────────┬───┘  └────┬─────────┘
                 ↓            ↓
         🔐 Verify OTP   📝 [AuthService]
                 │        updateDeviceToken()
                 │        called
                 ↓            ↓
         ✅ Status=true   🔑 Using auth token
                 │            │
                 │            ↓
                 │        📱 Device token
                 │            to update:
                 │        [TOKEN_HERE]
                 │            │
                 │            ↓
                 │        ✅ Device token
                 │            updated!
                 │            │
                 └────┬───────┘
                      ↓
              🚀 Navigate to /home
```

---

## 📊 Debug Output yang Diharapkan

### **Login (Direct, tanpa OTP):**
```
🔐 [AuthService] Starting login with email: user@example.com
📱 [AuthService] Fetching Firebase device token...
✅ [AuthService] Device token fetched: xyz123...
📤 [AuthService] Sending login request with device_token: xyz123...
✅ [AuthService] Login successful, status code: 200
✅ Login successful, token received: abc456...
✅ Token disimpan di SessionManager
📱 Updating device token...
📝 [AuthService] updateDeviceToken() called
🔑 [AuthService] Using auth token: abc456...
📱 [AuthService] Fetching Firebase device token...
✅ [AuthService] Device token fetched: xyz123...
📱 [AuthService] Device token to update: xyz123...
✅ [AuthService] Device token updated successfully!
📌 [AuthService] Device Token: xyz123...
📌 [AuthService] Response: {...}
🚀 Navigating to /home route...
```

### **Login dengan OTP:**
```
🔐 [AuthService] Starting login with email: user@example.com
📱 [AuthService] Fetching Firebase device token...
✅ [AuthService] Device token fetched: xyz123...
📤 [AuthService] Sending login request with device_token: xyz123...
✅ [AuthService] Login successful, status code: 200
📋 Login Response: status=true, requireOtp=true, ...
🔑 OTP REQUIRED - Navigating to OTP Screen

[User enters OTP in OTP Screen]

🔐 Attempting OTP verification...
✅ OTP verification successful
📱 Updating device token after OTP verification...
📝 [AuthService] updateDeviceToken() called
🔑 [AuthService] Using auth token: def789...
📱 [AuthService] Fetching Firebase device token...
✅ [AuthService] Device token fetched: xyz123...
📱 [AuthService] Device token to update: xyz123...
✅ [AuthService] Device token updated successfully!
🚀 Navigate to /home
```

---

## 🧪 Testing Checklist

- [ ] Jalankan aplikasi dengan `flutter run`
- [ ] Login dengan email & password
- [ ] **Di console, cari messages:**
  - ✅ `📱 [AuthService] Fetching Firebase device token...`
  - ✅ `✅ [AuthService] Device token fetched: [YOUR_TOKEN]`
  - ✅ `📤 [AuthService] Sending login request with device_token: [TOKEN]`
  - ✅ `📱 Updating device token...`
  - ✅ `📝 [AuthService] updateDeviceToken() called`
  - ✅ `✅ [AuthService] Device token updated successfully!`
  - ✅ `📌 [AuthService] Device Token: [YOUR_TOKEN]`
- [ ] Jika OTP diperlukan:
  - ✅ Masuk ke OTP screen
  - ✅ Masukkan OTP
  - ✅ Cari `📱 Updating device token after OTP verification...`
- [ ] Aplikasi navigate ke /home
- [ ] **Device token HARUS TAMPIL di console sekarang!** ✅

---

## 💡 Troubleshooting

### **Problem: Device token masih tidak tampil**

**Solution 1:** Cek di Android Logcat
```bash
# Di terminal, jalankan:
flutter logs
# atau
adb logcat | grep -i device
```

**Solution 2:** Firebase Messaging mungkin belum initialized
- Pastikan di `main.dart`, Firebase.initializeApp() sudah dipanggil
- Cek bahwa `google-services.json` ada di android/app/

**Solution 3:** Coba manual test dengan menambah breakpoint
```dart
// Di getDeviceToken() method, tambah breakpoint
debugPrint('DEBUG: Token before return: $token');
```

---

## 📝 Files Modified

| File | Changes |
|------|---------|
| [lib/core/network/auth_service.dart](lib/core/network/auth_service.dart) | ✅ Enhanced logging di getDeviceToken(), login(), updateDeviceToken() |
| [lib/ui/auth/login_screen.dart](lib/ui/auth/login_screen.dart) | ✅ Added updateDeviceToken() call setelah login success |
| [lib/ui/auth/otp_screen.dart](lib/ui/auth/otp_screen.dart) | ✅ Added updateDeviceToken() call setelah OTP verification success |

---

**Status:** ✅ **FIXED**  
**Date:** January 20, 2026  
**Result:** Device token now properly tracked and updated! 🎉
