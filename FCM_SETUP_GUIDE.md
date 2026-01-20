# 🔔 Firebase Cloud Messaging (FCM) Setup & Troubleshooting

## ✅ Fixes Applied

### 1. **Enhanced FCM Initialization in main.dart**
- ✅ Proper notification permission request dengan opsi lengkap
- ✅ Background message handler registration
- ✅ Token refresh listener
- ✅ Detailed logging untuk setiap tahap FCM setup

### 2. **Foreground Message Handler di MyApp**
- ✅ Listen ke `FirebaseMessaging.onMessage` (ketika app di foreground)
- ✅ Listen ke `FirebaseMessaging.onMessageOpenedApp` (ketika notif di-tap)
- ✅ Show in-app notification dialog
- ✅ Detailed logging

### 3. **Android Manifest Permission**
- ✅ Added `android.permission.POST_NOTIFICATIONS` (required for Android 13+)

### 4. **Background Message Handler**
- ✅ Enhanced dengan logging detail

---

## 🔍 Debug Flow - Device Token Testing

### **Step 1: Pastikan Device Token Terupdate**

Setelah login, lihat console untuk logs berikut:

```
✅ [FCM] Device Token: dQarKFa4QbmQKo0yli0tE_:APA91bHcfLu...
```

✅ Jika muncul → token berhasil di-fetch  
❌ Jika tidak muncul → cek Firebase Messaging initialization

### **Step 2: Update Device Token ke Backend**

Device token harus disimpan di database backend agar server bisa mengirim notif.

**Location:** [lib/ui/auth/login_screen.dart](lib/ui/auth/login_screen.dart#L74-L78)

```dart
// Update device token di server
debugPrint('📱 Updating device token...');
try {
  await authService.updateDeviceToken(loginResponse.accessToken!);
} catch (e) {
  debugPrint('⚠️ Device token update failed (non-critical): $e');
}
```

Lihat di console:
```
📝 [AuthService] updateDeviceToken() called
✅ [AuthService] Device token updated successfully!
📌 [AuthService] Device Token: dQarKFa4QbmQKo0yli0tE_:APA91bHcfLu...
```

✅ Jika muncul → backend sudah menerima device token  
❌ Jika tidak → cek API endpoint `/device-token/update`

### **Step 3: Testing Notifikasi di Firebase Console**

1. Buka: https://console.firebase.google.com
2. Pilih project Anda
3. Pilih **Messaging** → **Create your first campaign**
4. **Notification title**: "Test Notifikasi"
5. **Notification text**: "Ini test dari Firebase"
6. Di bagian **Send test message**:
   - Paste device token: `dQarKFa4QbmQKo0yli0tE_:APA91bHcfLu...`
   - Click **+** icon
   - Click **Send test message**

---

## 📊 Expected Debug Output

### **Saat App Startup:**
```
🔔 [FCM] Requesting notification permission...
✅ [FCM] Notification permission: authorized
📨 [FCM] Registering background message handler...
✅ [FCM] Background message handler registered
🔑 [FCM] Getting initial device token...
✅ [FCM] Device Token: dQarKFa4QbmQKo0yli0tE_:APA91bHcfLu...
👂 [FCM] Listening to token refresh...
✅ [FCM] Firebase Messaging fully initialized!
📱 [FCM] Setting up foreground message handler...
✅ [FCM] Foreground message handler setup complete
```

### **Saat Notifikasi Diterima (App di Foreground):**
```
🔔 [FOREGROUND FCM] Message received: abc123...
📌 [FOREGROUND FCM] Title: Test Notifikasi
📌 [FOREGROUND FCM] Body: Ini test dari Firebase
📌 [FOREGROUND FCM] Data: {key: value}
💬 [FCM] Showing notification dialog...
```

### **Saat Notifikasi Diterima (App di Background/Terminated):**
```
🔔 [BACKGROUND FCM] Message received: abc123...
📌 [BACKGROUND FCM] Title: Test Notifikasi
📌 [BACKGROUND FCM] Body: Ini test dari Firebase
📌 [BACKGROUND FCM] Data: {key: value}
```

### **Saat Notifikasi Di-tap:**
```
👆 [FCM] Notification tapped: abc123...
📌 [FCM] Data: {key: value}
```

---

## 🧪 Testing Checklist

### **Pre-requisites:**
- [ ] Google account dengan Firebase project
- [ ] `google-services.json` di `android/app/`
- [ ] Aplikasi sudah di-deploy ke device/emulator
- [ ] User sudah login

### **Testing Steps:**

1. **Launch App & Check FCM Init:**
   - [ ] Run `flutter run`
   - [ ] Lihat console untuk FCM initialization logs
   - [ ] Cari: `✅ [FCM] Device Token: ...`
   - [ ] Copy device token tersebut

2. **Test dengan Firebase Console:**
   - [ ] Buka Firebase Console → Messaging
   - [ ] Create new campaign
   - [ ] Send test message ke device token yang Anda copy
   - [ ] Pastikan notifikasi MUNCUL di device

3. **Test Foreground (App Terbuka):**
   - [ ] Keep app buka
   - [ ] Send notifikasi dari Firebase
   - [ ] Harusnya muncul dialog/notification
   - [ ] Cari di console: `🔔 [FOREGROUND FCM]`

4. **Test Background (App di Background):**
   - [ ] Minimize app (home button)
   - [ ] Send notifikasi dari Firebase
   - [ ] Harusnya notifikasi muncul di system tray
   - [ ] Cari di console: `🔔 [BACKGROUND FCM]`

5. **Test Notification Tap:**
   - [ ] Tap notifikasi dari system tray
   - [ ] App harus open/focus
   - [ ] Cari di console: `👆 [FCM] Notification tapped`

---

## 🔧 Troubleshooting

### **Problem 1: Device token tidak muncul di console**

**Cause:** Firebase Messaging tidak initialized dengan baik

**Solutions:**
```bash
# 1. Check google-services.json exists
ls android/app/google-services.json

# 2. Check Firebase plugin loaded
flutter pub get

# 3. Clean & rebuild
flutter clean
flutter pub get
flutter run
```

---

### **Problem 2: Notifikasi tidak diterima sama sekali**

**Cause:** Permission belum di-grant atau device token belum di-update ke backend

**Check List:**
- [ ] Di Android device, Settings → Apps → [AppName] → Notifications → ON
- [ ] Device token sudah update di backend? Cek di database
- [ ] Backend sudah kirim notifikasi? Cek backend logs

**Debug Steps:**
```bash
# 1. Check Android permissions
adb shell dumpsys package com.buysindo.app | grep permission

# 2. Check FCM logs
adb logcat | grep -i fcm

# 3. Manual test di Firebase Console
# (lihat Step 3 di atas)
```

---

### **Problem 3: Notifikasi hanya diterima ketika app terbuka (foreground)**

**Cause:** Background handler tidak properly registered

**Fix:**
- Pastikan `FirebaseMessaging.onBackgroundMessage()` dipanggil di `main()` sebelum `runApp()`
- Check `_firebaseMessagingBackgroundHandler` function exists dan bukan `null`

---

### **Problem 4: "POST_NOTIFICATIONS" permission error**

**Cause:** Android 13+ requires explicit notification permission

**Fix (Already Applied):**
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

---

## 📁 Files Modified

| File | Changes |
|------|---------|
| [lib/main.dart](lib/main.dart) | ✅ Enhanced FCM init, added foreground handler |
| [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) | ✅ Added POST_NOTIFICATIONS permission |

---

## 💡 Next Steps

### **1. Backend Integration:**

Pastikan backend punya endpoint `/device-token/update` yang:
- Receive: `device_token`, `Authorization: Bearer {token}`
- Save device token ke database
- Return: `{status: true, message: "..."}` 

### **2. Send Notification Endpoint:**

Backend harus punya endpoint untuk send notification:
```dart
POST /notification/send
{
  user_id: 123,
  title: "Notifikasi Title",
  body: "Notifikasi Body",
  data: {key: value}
}
```

Backend akan:
1. Get device tokens dari database
2. Call Firebase Admin SDK
3. Send ke semua device tokens

### **3. Monitor Delivery:**

Check di Firebase Console:
- Impressions: berapa banyak notif dikirim
- Conversions: berapa banyak notif di-tap

---

## 📝 Testing Device Token

Device token yang Anda gunakan:
```
dQarKFa4QbmQKo0yli0tE_:APA91bHcfLu-lTEuHUQSKdDau0-q8rGBF-LrOj1RAoiZQubWg40cDRBxLN9K0rPg-IZoDe1_B3PrXUp-m6La8DdP1resVpGIuqgS4Svq5E1Oy_5neBDEZ4M
```

✅ Format valid (APA91b format)  
⚠️ Pastikan token ini:
- Sudah di-update ke backend setelah login
- Belum expired (tokens expire after some time)
- Dari device yang sama dengan testing

---

**Status:** ✅ **FCM Setup Complete**  
**Date:** January 20, 2026  
**Last Updated:** When notifications work properly
