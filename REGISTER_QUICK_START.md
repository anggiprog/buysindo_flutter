# ⚡ Quick Start - Register Screen

## 🚀 Setup Cepat (5 menit)

### Step 1: Tambah Admin Token
Edit `lib/core/app_config.dart` baris ~25:

```dart
static const String adminToken = 'your-admin-token-here';
```

> 💡 **Dapatkan token dari**: Backend admin atau `.env` file

---

### Step 2: Test Navigation
Di Login Screen, klik "DAFTAR" button
→ Akan membuka Register Screen

---

### Step 3: Submit Form
```
1. Isi semua field yang required (Username, Email, Password)
2. Opsional: Isi Nama, Telepon, Kode Referral
3. Klik DAFTAR
4. Tunggu response dari backend
5. Jika sukses → Redirect ke Login
6. Cek email untuk verifikasi
```

---

## 🔧 Konfigurasi Advanced

### Dengan Environment Variable (Build Time)
```bash
flutter run --dart-define=ADMIN_TOKEN='token-dari-backend'
```

### Dengan Firebase Remote Config (Runtime)
```dart
// Di main() atau AppConfig.initializeApp()
final adminToken = await FirebaseRemoteConfig.instance
    .getString('admin_token');
```

### Dengan API Call (Best Practice)
```dart
// Di AuthService atau API Service
Future<String> getAdminToken() async {
  final response = await dio.get('api/get-admin-token');
  return response.data['admin_token'];
}
```

---

## 📡 API Response Mapping

### Success (201)
```json
{
  "error": false,
  "message": "Registrasi berhasil! Cek email Anda untuk verifikasi akun."
}
```
**Action**: Toast Success → Redirect Login

### Email Sudah Ada (400)
```json
{
  "error": true,
  "message": "Email sudah terdaftar"
}
```
**Action**: Show Error Banner

### Invalid Token (403)
```json
{
  "error": true,
  "message": "Token admin tidak valid"
}
```
**Action**: Show Error + Alert Admin

### Server Error (500)
```json
{
  "error": true,
  "message": "Terjadi kesalahan saat registrasi"
}
```
**Action**: Show Error + Retry Button

---

## 🎨 Customization

### Ubah Warna Button
`register_screen.dart` ~ line 360:
```dart
gradient: LinearGradient(
  colors: [
    Color(0xFF1A56BE),  // ← Primary color
    Color(0xFF2563EB),  // ← Secondary color
  ],
),
```

### Ubah Background
`register_screen.dart` ~ line 53:
```dart
image: DecorationImage(
  image: const AssetImage('assets/images/register_bg.png'),
  // Atau gunakan network image:
  // image: NetworkImage('https://...')
  fit: BoxFit.cover,
),
```

### Ubah Validation Rules
`register_screen.dart` ~ line 174-186:
```dart
validator: (value) {
  if (value?.isEmpty ?? true) {
    return 'Username harus diisi';
  }
  if (value!.length < 3) {  // ← Ubah minimum
    return 'Username minimal 3 karakter';
  }
  return null;
},
```

---

## 🐛 Debug Mode

### Enable Debug Logs
```dart
// Di register_screen.dart, uncomment debug prints:
debugPrint('📝 Attempting registration with email: ${_emailController.text}');
debugPrint('📋 Register Response: ${response.statusCode} - ${response.data}');
```

### View Logs
```bash
flutter logs
```

### Check Network Request
1. Open DevTools: `flutter run -d web`
2. Check Network tab
3. Lihat request/response dari `/api/registerV2`

---

## 🔄 Flow Diagram

```
User Input
    ↓
Form Validation
    ↓
Check Existing Email
    ↓
Show Warning? (Yes) → Can't Submit
            (No)
    ↓
POST /api/registerV2
    ↓
Parse Response
    ├─ Status 201 ✅ → Save Email to Cache → Toast Success → Redirect Login
    ├─ Status 400 ❌ → Show Error Message
    ├─ Status 403 ❌ → Token Invalid Error
    └─ Status 500 ❌ → Server Error
```

---

## 📊 State Management

Register Screen menggunakan **StatefulWidget** dengan:
- `_isLoading` - For loading state
- `_errorMessage` - For error display
- `_existingUserWarning` - For duplicate email detection
- Controllers untuk form inputs

---

## 🔐 Security Notes

✅ **Implemented**:
- Password validation (min 6 chars)
- Email format validation
- Admin token in header
- Device token tracking
- Email verification required

⚠️ **TODO** (Optional):
- Rate limiting (backend)
- CAPTCHA (backend)
- 2FA/OTP verification
- Encryption for sensitive data

---

## 📞 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "Token tidak valid" | Update `AppConfig.adminToken` |
| "Email sudah terdaftar" | Gunakan email berbeda atau login |
| "Network timeout" | Cek koneksi internet & endpoint URL |
| "Cant navigate to register" | Ensure `registerV2()` imported di login_screen.dart |
| "Email tidak terkirim" | Cek SMTP config di backend |

---

## 📱 Device Testing

### Android
```bash
flutter run -d android
```
**Test Cases**:
- [ ] Buka register dari login
- [ ] Isi form dan submit
- [ ] Check email verification link

### iOS
```bash
flutter run -d ios
```
**Test Cases**:
- [ ] Keyboard behavior
- [ ] Safe area handling
- [ ] Email link opening

### Web
```bash
flutter run -d web
```
**Test Cases**:
- [ ] Form validation
- [ ] Error messages
- [ ] Loading states

---

## 📈 Performance

- **Form Validation**: Instant (client-side)
- **Duplicate Email Check**: ~500ms (local cache)
- **API Request**: 2-3 seconds (network dependent)
- **Redirect**: <500ms (navigation)

---

## ✅ Deployment Checklist

- [ ] Admin token configured
- [ ] Backend API running
- [ ] Email service configured
- [ ] Test registration flow
- [ ] Test error scenarios
- [ ] Build APK/IPA
- [ ] Test on real device
- [ ] App store submission

---

**Ready to deploy?** ✨

Need help? Check `REGISTER_IMPLEMENTATION.md` for detailed guide.
