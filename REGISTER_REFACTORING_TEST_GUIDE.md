# Register Screen Refactoring - Quick Test Guide

## What Changed
✅ Admin token now fetched dynamically from `/api/admin-tokens/1050`  
✅ All API calls moved to centralized `ApiService`  
✅ All hardcoded blue colors replaced with `appConfig.primaryColor`  

## Testing Steps

### 1. Load RegisterScreen
```dart
Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
```

**Expected Result**: Loading screen appears briefly with:
- Gradient background using app's primary color
- CircularProgressIndicator spinner
- Text: "Mempersiapkan form registrasi..."

### 2. Token Fetching
**What happens internally**:
- `initState()` calls `_fetchAdminToken()`
- Calls `apiService.getAdminToken('1050')`
- Extracts token from response: `data['data'][0]['token']`
- Updates state `_adminToken` with fetched token

**Console Output** (if debugPrint working):
```
🔐 Fetching admin token...
✅ Admin token fetched successfully
```

### 3. Registration Form Display
**Expected Result**:
- Form appears with all fields
- Register button uses app's primary color (not blue)
- Background gradient uses app's primary color

### 4. Test Registration
Complete form:
- Username: `testuser123`
- Email: `test@example.com`
- Password: `123456789`
- Full Name: `Test User`
- Phone: `081234567890`
- Referral Code: (leave empty)

Click "DAFTAR"

**Console Output**:
```
📝 Attempting registration with email: test@example.com
📋 Register Response: 201 - {success data...}
```

**Expected Result**:
- Success toast: "Registrasi berhasil! Cek email Anda untuk verifikasi."
- Auto-redirect to login screen after 2 seconds

### 5. Error Scenarios

#### Missing Admin Token
```
❌ Error fetching admin token: ...
_errorMessage: 'Gagal mengambil token admin: ...'
```

**Result**: Error banner displayed on form (red background)

#### Invalid Email
Fill email: `invalid-email`  
**Result**: Form validation message: "Email tidak valid"

#### Existing Email
Register with email that was registered before  
**Result**: Orange warning banner appears above form

#### Server Error
API returns 500  
**Result**: Error message: "Terjadi kesalahan server. Silakan coba lagi nanti."

---

## Color Testing

### Check Dynamic Colors
Open RegisterScreen with different `appConfig.primaryColor` values:

**Primary Color: Blue (0xFF0D6EFD)**
- Button gradient: Blue → Lighter Blue
- Background: Blue gradient
- Loading spinner: Blue

**Primary Color: Green (0xFF10B981)**
- Button gradient: Green → Lighter Green
- Background: Green gradient
- Loading spinner: Green

**Primary Color: Red (0xFFEF4444)**
- Button gradient: Red → Lighter Red
- Background: Red gradient
- Loading spinner: Red

---

## API Calls Verification

### Request 1: Get Admin Token
```http
GET /api/admin-tokens/1050
Accept: application/json

Response (200):
{
  "status": "success",
  "data": [
    {
      "id": 2,
      "admin_user_id": 1050,
      "token": "NM3dTOb3aBYzVI9prZaVi2wL6GGqh7qCTBklOXc5017B6H3AnyjpkRZ4GaPS",
      "created_at": "2025-10-26 00:47:32"
    }
  ]
}
```

### Request 2: Register User
```http
POST /api/registerV2
X-Admin-Token: NM3dTOb3aBYzVI9prZaVi2wL6GGqh7qCTBklOXc5017B6H3AnyjpkRZ4GaPS
Content-Type: application/json

{
  "username": "testuser",
  "email": "test@example.com",
  "password": "123456",
  "full_name": "Test User",
  "phone": "081234567890",
  "referral_code": "",
  "device_token": "flutter-app"
}

Response (201):
{
  "error": false,
  "message": "Registrasi berhasil. Silakan cek email untuk verifikasi.",
  "data": { ... }
}
```

---

## Code Changes Summary

### Before (Old)
```dart
class RegisterScreen extends StatefulWidget {
  final String? adminToken;  // ❌ Removed
  const RegisterScreen({super.key, this.adminToken});
}

// Colors
Color(0xFF1A56BE)  // ❌ Hardcoded blue
Color(0xFF2563EB)  // ❌ Hardcoded blue

// API call
final dio = Dio();
dio.post('https://buysindo.com/api/registerV2', ...)  // ❌ Inline
```

### After (New)
```dart
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});  // ✅ No token parameter
}

// Colors
appConfig.primaryColor  // ✅ Dynamic theme color
appConfig.primaryColor.withOpacity(0.8)  // ✅ Dynamic variant

// API calls
final apiService = ApiService(dio);
apiService.getAdminToken(appConfig.adminId)  // ✅ Centralized
apiService.registerV2(adminToken: _adminToken!, ...)  // ✅ Centralized
```

---

## Deployment Checklist

- [ ] Verify no compilation errors: `flutter analyze`
- [ ] Run tests if available
- [ ] Test on Android device
- [ ] Test on iOS device
- [ ] Verify loading screen displays correctly
- [ ] Test registration flow end-to-end
- [ ] Test error scenarios
- [ ] Verify theme colors match app configuration
- [ ] Check console logs for API call debugPrints

---

## Troubleshooting

### Issue: Loading screen stuck
**Cause**: API call to `/api/admin-tokens/1050` failed  
**Solution**: Check backend logs, verify endpoint is accessible

### Issue: "Token admin tidak ditemukan"
**Cause**: API response doesn't have expected format  
**Solution**: Verify backend returns `data['status'] == 'success'` and `data['data']` is not empty

### Issue: Colors still showing blue
**Cause**: AppConfig not initialized or primaryColor not set  
**Solution**: Verify `appConfig.primaryColor` is properly set in app initialization

### Issue: Registration fails with 403
**Cause**: Admin token is invalid  
**Solution**: Verify token is correctly extracted from API response

---

## Performance Notes

- Token is fetched once when screen loads (not on every build)
- State updates use `setState()` for UI refresh
- API calls properly handled with try-catch
- Error messages cached in state to prevent multiple calls

---

## Future Improvements

Possible enhancements (not included in current refactoring):

1. Cache admin token with expiration
2. Retry token fetch if it fails
3. Add offline registration queueing
4. Implement biometric auto-fill
5. Add progress indicator to form submission

---

## Related Files

- [lib/ui/auth/register_screen.dart](lib/ui/auth/register_screen.dart) - Main refactored file
- [lib/core/network/api_service.dart](lib/core/network/api_service.dart) - API methods
- [lib/core/app_config.dart](lib/core/app_config.dart) - Configuration source
- [REGISTER_REFACTORING_SUMMARY.md](REGISTER_REFACTORING_SUMMARY.md) - Detailed changes

---

## Support

For issues or questions:
1. Check the error message displayed in the app
2. Review console debugPrints (search for 🔐, ✅, ❌)
3. Verify backend API responses match expected format
4. Check AppConfig initialization for theme colors
