# Register Screen Implementation Guide

## ✅ File yang Telah Dibuat

### 1. **register_screen.dart** 
📁 Lokasi: `lib/ui/auth/register_screen.dart`

#### Fitur Utama:
- ✨ UI yang menarik dengan background gradient blur
- 📝 Form validation untuk semua field
- ⚠️ Warning jika email sudah terdaftar sebelumnya
- 🔐 Password visibility toggle
- 📧 Support untuk referral code
- 🔄 Loading state dengan spinner
- ✅ Error handling dengan pesan yang jelas

#### Field Form:
1. **Username** (Required) - minimal 3 karakter
2. **Email** (Required) - format email valid
3. **Password** (Required) - minimal 6 karakter  
4. **Nama Lengkap** (Opsional)
5. **Nomor Telepon** (Opsional)
6. **Kode Referral** (Opsional)

#### Validasi:
- Email yang sudah pernah digunakan akan ditampilkan peringatan warning
- Form validation otomatis
- Error message dari backend ditampilkan dengan jelas

---

## 🔧 API Integration

### API Endpoint Added to `api_service.dart`

```dart
/// Registrasi user baru dengan verifikasi email
Future<Response> registerV2({
  required String adminToken,
  required String username,
  required String email,
  required String password,
  required String fullName,
  required String phone,
  String? referralCode,
  String? deviceToken,
})
```

**Endpoint**: `POST https://buysindo.com/api/registerV2`

**Headers Required**:
- `X-Admin-Token`: Token admin dari backend
- `Content-Type: application/json`
- `Accept: application/json`

**Request Body**:
```json
{
  "username": "user123",
  "email": "user@example.com",
  "password": "password123",
  "full_name": "John Doe",
  "phone": "08123456789",
  "referral_code": "REF123",
  "device_token": "flutter-app"
}
```

**Response Success (201)**:
```json
{
  "error": false,
  "message": "Registrasi berhasil! Cek email Anda untuk verifikasi akun."
}
```

**Response Error**:
```json
{
  "error": true,
  "message": "Email sudah terdaftar / Kode referral tidak valid / dll"
}
```

---

## 🚀 Cara Menggunakan

### 1. **Navigasi ke Register Screen**

Dari LoginScreen:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const RegisterScreen()),
);
```

Atau menggunakan named route:
```dart
Navigator.pushNamed(context, '/register');
```

### 2. **Dengan Admin Token Custom**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => RegisterScreen(
      adminToken: 'your-admin-token-here',
    ),
  ),
);
```

---

## 🔌 Backend Response Handling

Register screen sudah menangani semua response dari backend:

| Status Code | Handling |
|---|---|
| **201** | ✅ Registrasi sukses, redirect ke login |
| **400** | ❌ Validation error atau input tidak valid |
| **403** | ❌ Token admin tidak valid |
| **500** | ❌ Server error |

---

## 🛡️ Keamanan

- ✅ Password validation di frontend (min 6 karakter)
- ✅ Email format validation
- ✅ Admin token required untuk registrasi
- ✅ Duplicate email detection
- ✅ Device token tracking untuk security

---

## 📱 UI/UX Features

### Background
- Gradient blur effect
- Professional look dengan blue theme
- Responsive design

### User Experience
- Real-time email duplicate warning
- Loading spinner saat registrasi
- Success/Error messages yang jelas
- Auto redirect ke login setelah sukses

### Error Handling
- Form validation errors
- Network errors
- Backend validation errors
- Server errors

---

## 🔐 Admin Token Configuration

Update **app_config.dart** dengan admin token:

```dart
static const String adminToken = 'your-admin-token';
```

Atau pass saat menavigasi:
```dart
RegisterScreen(adminToken: 'your-token')
```

---

## 📋 Checklist Implementasi

- ✅ Register screen dibuat dengan UI menarik
- ✅ Form validation lengkap
- ✅ API endpoint registerV2 ditambahkan ke api_service.dart
- ✅ Error handling dari backend
- ✅ Warning untuk duplicate email
- ✅ Routes dikonfigurasi di main.dart
- ✅ Loading state indicator
- ✅ Success/redirect behavior

---

## 🐛 Troubleshooting

### Error: "Token admin tidak valid"
- Pastikan `adminToken` yang digunakan sesuai dengan backend
- Cek di `AppConfig.adminToken` atau pass melalui constructor

### Error: "Email sudah terdaftar"
- Email sudah digunakan di backend
- Warning akan ditampilkan di UI
- Gunakan email lain

### Error: "Kode referral tidak valid"
- Referral code tidak ada di database
- Pastikan kode referral benar

### Email tidak terkirim
- Cek konfigurasi email di backend
- Pastikan email address valid

---

## 📞 Next Steps

1. Setup background image untuk register (opsional):
   - Tempat: `assets/images/register_bg.png`
   - Ukuran: 1080x1920px (atau sesuaikan)

2. Konfigurasi admin token di `AppConfig`

3. Test registrasi dengan data valid

4. Verify email link akan redirect ke:
   `myapp://verify-success?status=success&token={accessToken}`

---

**Selesai! Register screen siap digunakan.** ✨
