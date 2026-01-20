# 🔗 Flutter Register Integration dengan Backend

## Backend Verification

Register screen Flutter sudah sepenuhnya terintegrasi dengan backend endpoint:
**`POST /api/registerV2`**

---

## 📋 Request yang Dikirim dari Flutter

### Headers
```
POST https://buysindo.com/api/registerV2

X-Admin-Token: {admin_token}
Content-Type: application/json
Accept: application/json
```

### Body
```json
{
  "username": "john_doe",
  "email": "john@example.com", 
  "password": "securepass123",
  "full_name": "John Doe",
  "phone": "08123456789",
  "referral_code": "REF123",
  "device_token": "flutter-app"
}
```

---

## ✅ Backend Response Handling

### Success (201)
```json
{
  "error": false,
  "message": "Registrasi berhasil! Cek email Anda untuk verifikasi akun."
}
```
**Flutter Action**: Toast success → Redirect to login

---

### Error Cases

#### 1. Email Already Exists (400)
```json
{
  "error": true,
  "message": "Email sudah terdaftar"
}
```
**Flutter Shows**: Error banner (red)

#### 2. Username Already Exists (400)
```json
{
  "error": true,
  "message": "Username sudah terdaftar"
}
```
**Flutter Shows**: Error banner (red)

#### 3. Invalid Referral Code (400)
```json
{
  "error": true,
  "message": "Kode referral tidak valid"
}
```
**Flutter Shows**: Error banner (red)

#### 4. Invalid Admin Token (403)
```json
{
  "error": true,
  "message": "Token admin tidak valid"
}
```
**Flutter Shows**: Error banner + Alert

#### 5. Referral Limit Exceeded (400)
```json
{
  "error": true,
  "message": "Batas downline untuk program ini sudah tercapai"
}
```
**Flutter Shows**: Error banner (red)

#### 6. Device Already Used (400)
```json
{
  "error": true,
  "message": "Kode referral tidak bisa digunakan pada perangkat yang sama"
}
```
**Flutter Shows**: Error banner (red)

#### 7. Server Error (500)
```json
{
  "error": true,
  "message": "Terjadi kesalahan saat registrasi"
}
```
**Flutter Shows**: Error banner + Retry option

---

## 🔄 Email Verification Flow

### 1. User Registration Success
- Email verifikasi dikirim ke user
- Link format: `{baseUrl}/api/verify-email?token={verificationToken}`

### 2. User Clicks Email Link
- Backend verifies token
- Sets `verified = 1`
- Creates access token
- Redirects to: `myapp://verify-success?status=success&token={accessToken}`

### 3. Flutter Deep Link Handler
- Catches deep link
- Auto logs in user with token
- Redirects to home screen

---

## 💾 Database Tables Involved

### users
```sql
- id (primary)
- username (unique)
- email (unique)
- password (hashed)
- phone
- verified (0/1)
- verification_token
- device_token
- role
- admin_user_id
- akses_mlm (Y/N) -- Set to 'Y' if referral code provided
- status
- created_at
```

### user_profiles
```sql
- id (primary)
- user_id (foreign)
- phone
- full_name
```

### referrals
```sql
- id (primary)
- referring_user_id
- referred_user_id
- device_token
- admin_user_id
- komisi_upline
- komisi_downline
- jumlah_poin
- status (Aktif/Inactive)
- referral_date
```

### admin_user_tokens
```sql
- id (primary)
- admin_user_id
- token (X-Admin-Token value)
- created_at
```

---

## 🔐 Security Checklist (Backend)

✅ **Must Do**:
- [ ] Validate X-Admin-Token in header
- [ ] Hash password before storing
- [ ] Check for duplicate email/username
- [ ] Sanitize all inputs (XSS protection)
- [ ] Use HTTPS (not HTTP)
- [ ] Rate limit registration endpoint
- [ ] Send verification email
- [ ] Validate referral code
- [ ] Track device tokens

⚠️ **Recommended**:
- [ ] Add CAPTCHA for mass registration prevention
- [ ] Implement 2FA/OTP
- [ ] Log all registration attempts
- [ ] Monitor suspicious patterns
- [ ] Use PII encryption for sensitive data

---

## 🧪 Test Integration

### Postman Test

```
POST https://buysindo.com/api/registerV2

Headers:
X-Admin-Token: test-admin-token
Content-Type: application/json

Body:
{
  "username": "flutter_test_001",
  "email": "flutter.test.001@example.com",
  "password": "flutter@test123",
  "full_name": "Flutter Test",
  "phone": "08987654321",
  "referral_code": "",
  "device_token": "postman-test"
}
```

### Expected Success (201)
```json
{
  "error": false,
  "message": "Registrasi berhasil! Cek email Anda untuk verifikasi akun."
}
```

---

## 📊 API Metrics

### Response Times (Expected)
- Valid registration: 1-2 seconds
- Email send: 3-5 seconds
- Duplicate check: 100-200ms
- Token validation: 50-100ms

### Rate Limiting (Recommended)
- 5 registrations per IP per hour
- 1 registration per email per day
- 10 registrations per device token per day

---

## 🔄 Verification Email Template

Register screen expects email with verification link:

```html
<h1>Selamat datang!</h1>
<p>Terima kasih telah mendaftar.</p>
<p>Silakan klik link berikut untuk memverifikasi akun Anda:</p>
<a href="https://buysindo.com/api/verify-email?token=abc123xyz">
  Verifikasi Akun
</a>
<p>Link berlaku selama 24 jam.</p>
```

---

## 🚨 Common Backend Issues

### Issue: Email not sending
**Solution**: Check SMTP configuration and mail queue

### Issue: Token always invalid
**Solution**: Check admin_user_tokens table and token format

### Issue: Referral not creating
**Solution**: Verify program_referrals status is 'aktif'

### Issue: Deep link not working
**Solution**: Ensure scheme registered in AndroidManifest/Info.plist

---

## 📝 Logging

Backend should log:
```
[REGISTER] User registration attempt
  - Username: {username}
  - Email: {email}
  - Referral: {referral_code}
  - Device: {device_token}
  - Status: SUCCESS/FAILED
  - Error: {error_message}
```

---

## 🎯 Integration Checklist

- [ ] X-Admin-Token validation implemented
- [ ] All validation rules working
- [ ] Email sending configured
- [ ] Referral logic working
- [ ] Device token tracking
- [ ] Response format matches spec
- [ ] Error messages clear and helpful
- [ ] Rate limiting in place
- [ ] Logging enabled
- [ ] HTTPS enforced
- [ ] Tested with Flutter app
- [ ] Production ready

---

## 📞 Backend API Documentation

For complete backend documentation, see:
`C:\xampp\htdocs\buysindo\app\Http\Controllers\Api\AuthController.php`

Key method: `public function registerV2(Request $request)`

---

**Backend Integration Complete!** ✅
