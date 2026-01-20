# 🧪 Register Screen - Test Data & Scenarios

## 📝 Test Data

### Valid Registration
```
Username: testuser001
Email: testuser001@example.com
Password: test@12345678
Full Name: John Doe
Phone: 08123456789
Referral Code: (leave empty for testing basic registration)
```

Expected Result: ✅ Success → Email verification sent

---

## 🔍 Test Scenarios

### 1. **Basic Registration (Valid Data)**
```
Input:
- Username: john_test
- Email: john.test@mail.com
- Password: securepass123
- Full Name: John Tester
- Phone: 081234567890

Expected:
✅ Form validation passes
✅ API request sent with correct headers
✅ Response 201 received
✅ Success toast shown
✅ Redirected to Login Screen
✅ Email saved to registered_emails cache
```

### 2. **Duplicate Email Detection**
```
Input:
- Email: existing@email.com (sudah terdaftar)

Expected:
⚠️ Warning banner shown above form
⚠️ Button disabled/non-functional
❌ Can't submit form
ℹ️ "Email ini sudah pernah terdaftar sebelumnya"
```

### 3. **Form Validation - Username Too Short**
```
Input:
- Username: ab (hanya 2 karakter)

Expected:
❌ Validation error: "Username minimal 3 karakter"
❌ Form can't be submitted
```

### 4. **Form Validation - Invalid Email**
```
Input:
- Email: invalid.email@

Expected:
❌ Validation error: "Email tidak valid"
❌ Form can't be submitted
```

### 5. **Form Validation - Password Too Short**
```
Input:
- Password: 12345 (hanya 5 karakter)

Expected:
❌ Validation error: "Password minimal 6 karakter"
❌ Form can't be submitted
```

### 6. **Empty Required Fields**
```
Input:
- Username: (kosong)
- Email: test@mail.com
- Password: password123

Expected:
❌ Validation error: "Username harus diisi"
❌ Form can't be submitted
```

### 7. **Backend Error - Email Already Exists**
```
Input:
- Email: already-registered@mail.com

Expected:
🔴 Error message: "Email sudah terdaftar"
🔴 Red banner shown
❌ Stay on register screen
✅ Allow retry
```

### 8. **Backend Error - Invalid Referral Code**
```
Input:
- Referral Code: INVALID12345

Expected:
🔴 Error message: "Kode referral tidak valid"
🔴 Red banner shown
✅ Allow retry
```

### 9. **Backend Error - Invalid Admin Token**
```
Cause:
- AppConfig.adminToken wrong or empty

Expected:
🔴 Error message: "Token admin tidak valid"
🔴 Red banner shown
ℹ️ Contact admin message
```

### 10. **Network Error - Timeout**
```
Cause:
- No internet connection
- API server down

Expected:
⏳ Loading spinner shows
🔄 After 10 seconds → Timeout
🔴 Error message: "Terjadi kesalahan: Timeout"
✅ Allow retry
```

### 11. **Registration with Referral Code**
```
Input:
- Username: referred_user
- Email: referred@mail.com
- Password: password123
- Referral Code: REF001 (valid code)

Expected:
✅ Registration success
✅ Referral relationship created
✅ MLM akses enabled (akses_mlm = 'Y')
✅ Redirect to login
```

### 12. **Back Button Click**
```
Action:
- Click back button

Expected:
✅ Navigate back to Login Screen
✅ Form data cleared
✅ No API call sent
```

### 13. **Already Have Account Link**
```
Action:
- Click "Sudah punya akun? Masuk"

Expected:
✅ Navigate to Login Screen
✅ Smooth transition
✅ Form cleared
```

### 14. **Password Toggle Visibility**
```
Action:
- Click eye icon

Expected:
👁️ Password shown/hidden
✅ Toggle works smoothly
```

### 15. **Loading State**
```
Action:
- Submit valid form

Expected:
⏳ Button shows spinner
❌ Button disabled (can't click again)
✅ After response → Button state reset
```

---

## 🔐 Security Test Cases

### 1. **SQL Injection Test**
```
Username: admin' OR '1'='1
Email: test@mail.com
Password: password123

Expected:
✅ Treated as literal string (escaped by backend)
❌ No SQL injection
```

### 2. **XSS Test**
```
Full Name: <script>alert('xss')</script>

Expected:
✅ Treated as literal string
❌ No script execution
```

### 3. **Token Security**
```
Verify:
- Admin token not sent in body (only in header)
- Admin token not logged in plain text
- Password hashed before sending to server (HTTPS used)
```

---

## 📊 API Response Test Cases

### Test dengan Postman/Insomnia

```
POST https://buysindo.com/api/registerV2

Headers:
X-Admin-Token: your-token
Content-Type: application/json
Accept: application/json

Body:
{
  "username": "postman_test",
  "email": "postman@test.com",
  "password": "test123456",
  "full_name": "Postman Test",
  "phone": "08123456789",
  "referral_code": "",
  "device_token": "postman-test"
}
```

### Expected Response (201):
```json
{
  "error": false,
  "message": "Registrasi berhasil! Cek email Anda untuk verifikasi akun."
}
```

---

## 🧩 Unit Test Examples

```dart
// test/register_screen_test.dart

void main() {
  group('RegisterScreen Tests', () {
    testWidgets('Form validation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      // Verify form fields exist
      expect(find.byType(TextFormField), findsWidgets);
      
      // Try submit with empty fields
      await tester.tap(find.byText('DAFTAR'));
      await tester.pumpAndSettle();
      
      // Verify error messages
      expect(find.text('Username harus diisi'), findsOneWidget);
    });

    testWidgets('Valid registration succeeds', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      // Fill form
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@mail.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      
      // Submit
      await tester.tap(find.byText('DAFTAR'));
      await tester.pumpAndSettle();
      
      // Verify success
      expect(find.byText('Registrasi berhasil'), findsOneWidget);
    });
  });
}
```

---

## 🎯 Performance Test

### Metrics to Measure:
- **Form Load Time**: < 500ms
- **Validation Time**: < 100ms
- **API Request**: 2-5 seconds
- **Navigation Transition**: < 300ms
- **Error Display**: < 200ms

### Load Testing:
```bash
# Simulate multiple concurrent registrations
ab -n 100 -c 10 https://buysindo.com/api/registerV2
```

---

## 📱 Platform-Specific Tests

### Android
- [ ] Keyboard opens/closes smoothly
- [ ] Form is not covered by keyboard
- [ ] Back button behavior correct
- [ ] Toast messages visible

### iOS
- [ ] Safe area respected
- [ ] Keyboard return button works
- [ ] Navigation smooth
- [ ] Screenshots for App Store

### Web
- [ ] Form responsive on mobile width
- [ ] Tab navigation works
- [ ] Browser back button works

---

## 🔔 Email Verification Test

### Step 1: Register User
```
Email: test@example.com
```

### Step 2: Check Email
- [ ] Email received within 5 minutes
- [ ] Email from correct sender
- [ ] Verification link works
- [ ] Link expires after 24 hours

### Step 3: Click Verification Link
```
Expected redirect:
myapp://verify-success?status=success&token=xxx
```

### Step 4: Auto Login
- [ ] Access token received
- [ ] User logged in automatically
- [ ] Profile loaded
- [ ] Can use app features

---

## 📋 Regression Test Checklist

After each update:
- [ ] Form fields render correctly
- [ ] Validation works for all fields
- [ ] Error messages display properly
- [ ] API integration still works
- [ ] Navigation functions correctly
- [ ] Loading states show/hide
- [ ] No console errors
- [ ] No memory leaks

---

## 🚀 Pre-Deployment Test

```
1. [ ] Test on Android device
2. [ ] Test on iOS device
3. [ ] Test network connectivity (wifi + mobile data)
4. [ ] Test with slow internet (throttle to 3G)
5. [ ] Test with offline mode
6. [ ] Test with expired token
7. [ ] Test with wrong admin token
8. [ ] Test backend error responses
9. [ ] Performance profiling
10. [ ] Security scan
```

---

## 📞 Test Result Template

```
Test Case: [Name]
Date: [Date]
Device: [Model]
OS: [Version]
App Version: [Version]

Input:
[Description of input]

Expected Result:
[What should happen]

Actual Result:
[What actually happened]

Status: ✅ PASS / ⚠️ FAIL / 🔄 PENDING

Notes:
[Additional notes]
```

---

## 🐛 Known Issues & Workarounds

### Issue: Email takes too long to arrive
**Workaround**: Check spam folder or increase timeout in settings

### Issue: Referral code doesn't work
**Workaround**: Verify referral code is correct and active

### Issue: Network timeout frequently
**Workaround**: Check internet speed or use different network

---

**Happy Testing!** ✅
