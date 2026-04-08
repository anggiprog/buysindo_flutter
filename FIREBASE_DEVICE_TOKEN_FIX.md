# 🔧 Firebase Device Token - Diagnosis & Fix

## ❓ Masalah
Device token yang tersimpan: `device_1775461431865_920072` (mock token)  
**Ini adalah fallback token ketika FCM gagal ambil real token dari Firebase**

---

## 🔍 Diagnosis

### **Alur Saat Ini:**
```
1. getDeviceToken() dipanggil
2. FirebaseMessaging.instance.getToken() → ❌ NULL
3. Fallback ke mock token → device_TIMESTAMP_RANDOMNUMBER
4. Mock token disimpan ke database
5. FCM notifikasi tidak bisa terkirim ❌
```

### **Sebab FCM Token NULL:**
- ❌ Firebase tidak berhasil diinisialisasi
- ❌ Device tanpa Google Play Services (Android emulator?)
- ❌ google-services.json invalid atau missing
- ❌ Permissions tidak diberikan
- ❌ Network issue

---

## ✅ Langkah Fix

### **Step 1: Check Logs**

Buka app dan lihat console output:

```
✅ Seharusnya tampil:
🔥 [main] Initializing Firebase...
✅ [main] Firebase initialized successfully
✅ [main] FCM Permission requested

❌ Jika error, akan tampil:
❌ [main] Firebase initialization error: ...
```

**Copy error message untuk debugging lebih lanjut.**

---

### **Step 2: Verify Firebase Config**

#### **Android:**
1. Download `google-services.json` dari Firebase Console
2. Paste ke: `android/app/google-services.json`
3. Check `android/app/build.gradle`:
   ```gradle
   plugins {
       id 'com.android.application'
       id 'com.google.gms.google-services'  // ✅ HARUS ADA
   }
   ```

#### **iOS:**
1. Download `GoogleService-Info.plist` dari Firebase Console
2. Add ke Xcode project
3. Target harus correct

---

### **Step 3: Check Device Token Status**

**Dari Debug Console / Logcat:**
```
✅ Cari output seperti ini:

📱 [ApiService] Firebase.apps.length: 1
📱 [ApiService] Firebase initialized: true
📱 [ApiService] Firebase.getToken() returned: ✅ TOKEN
✅ [ApiService] Firebase device token fetched: eyJhbGciOi...

❌ Jika mock token:

📱 [ApiService] Firebase.getToken() returned: ❌ NULL
⚠️ [ApiService] Using fallback stored device ID instead...
⚠️ [ApiService] Fallback device ID: device_1775461431865_920072
```

---

### **Step 4: Force Refresh FCM Token**

Jika FCM tidak bisa direfresh, coba manual reset:

```bash
# Android:
adb shell pm clear com.google.android.gms
adb shell pm clear package_name_app_anda

# iOS:
# Uninstall app, clear cache, reinstall
```

---

## 🚀 How to Test

### **Option A: From Logs (Easiest)**
1. Run app
2. Open logcat/console
3. Search: `[ApiService] Firebase device token`
4. Lihat apakah token valid atau mock

### **Option B: From Database**
```sql
SELECT 
    id, 
    email, 
    device_token,
    CASE 
        WHEN device_token LIKE 'device_%' THEN '❌ MOCK'
        ELSE '✅ REAL FCM'
    END as token_type
FROM users 
WHERE email = 'your_email';
```

### **Option C: Call Diagnostic Method (Dev)**
Dari code Anda (UI atau backend):
```dart
final apiService = serviceLocator<ApiService>();
final status = await apiService.diagnosticFcmStatus();
print(status);

// Output:
// {
//   'firebase_initialized': true,
//   'fcm_token_valid': true/false,
//   'stored_device_id': 'device_...',
//   'is_mock_token': true/false,
//   'current_device_token': '...',
//   'token_source': 'FCM' or 'FALLBACK'
// }
```

---

## 🔄 Recovery Steps

### **Jika masih mock token:**

1. **Force Refresh:**
   ```dart
   try {
     final newToken = await apiService.forceRefreshFcmToken();
     print('✅ New FCM token: $newToken');
   } catch (e) {
     print('❌ Force refresh failed: $e');
   }
   ```

2. **Update Backend dengan Token Baru:**
   ```dart
   await apiService.setDeviceTokenManual(newToken);
   ```

3. **Verify di Database:**
   ```sql
   SELECT device_token FROM users WHERE id = YOUR_USER_ID;
   ```

---

## 📊 FCM Token Format

### **Real FCM Token** ✅
- Length: 100-200+ characters
- Format: Base64-like, random chars
- Example: `eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...`

### **Mock Token** ❌ (Fallback)
- Format: `device_TIMESTAMP_RANDOMNUMBER`
- Example: `device_1775461431865_920072`
- **Cannot be used for FCM messaging**

---

## 🎯 Permanent Solution

### **For Testing/Development:**
Mock tokens sekarang diterima backend (untuk dev).  
Tapi FCM notifications tidak akan terkirim.

### **For Production:**
Pastikan:
1. ✅ Firebase properly configured
2. ✅ google-services.json valid
3. ✅ Device has Google Play Services
4. ✅ Permissions granted
5. ✅ Network connectivity OK

---

## 🔧 Troubleshooting Checklist

| Issue | Solution |
|-------|----------|
| Firebase init error | Check google-services.json |
| FCM token NULL | Check Google Play Services |
| Mock token persists | Force refresh & update |
| FCM not working | Verify real FCM token, not mock |
| Permissions denied | App > Settings > Notifications: ON |

---

## 📝 Log Reference

### **Good Logs** ✅
```
✅ [main] Firebase initialized successfully
✅ [main] FCM Permission requested
✅ [ApiService] Firebase device token fetched: eyJhb...
```

### **Bad Logs** ❌
```
❌ [main] Firebase initialization error: ...
⚠️ [ApiService] Firebase token is NULL/EMPTY!
⚠️ [ApiService] Using fallback stored device ID...
```

---

**Generated**: 2026-04-06  
**Updated**: Latest
