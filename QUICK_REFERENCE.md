# Quick Reference - Firebase & Auth Implementation

## ✅ Completed Changes

### 1. Firebase Configuration
- ✅ Created `lib/firebase_options.dart` - Defines `DefaultFirebaseOptions` class
- ✅ Added `firebase_core: ^3.15.2` dependency
- ✅ Added `flutter_dotenv: ^5.2.0` for environment variables
- ✅ Updated `lib/main.dart` with proper Firebase initialization

### 2. Authentication Service
- ✅ Created `lib/core/network/auth_service.dart` with:
  - `getDeviceToken()` - Safe Firebase device token retrieval
  - `login()` - Login with email/password
  - `verifyOtp()` - OTP verification
  - `resendOtp()` - Resend OTP code
  - `logout()` - User logout
  - `LoginResponse` model
  - `OtpResponse` model

### 3. Updated Login Screen
- ✅ `lib/ui/auth/login_screen.dart` refactored to:
  - Use `AuthService` instead of direct API calls
  - Handle OTP requirement properly
  - Improved error handling
  - Cleaner code structure

### 4. Updated OTP Screen
- ✅ `lib/ui/auth/otp_screen.dart` refactored to:
  - Use `AuthService` for OTP operations
  - Removed hardcoded API URLs
  - Improved error messages
  - Removed unnecessary device token parameter

### 5. Code Quality
- ✅ All compilation errors fixed
- ✅ All unused imports removed
- ✅ Flutter analyzer passed with no issues
- ✅ Dependencies installed successfully

## 🔧 How to Use

### Login Flow
```dart
// User enters email/password
// AuthService automatically:
// 1. Gets Firebase device token
// 2. Sends login request with device token
// 3. Returns LoginResponse

// If require_otp == true → Show OTP screen
// If require_otp == false && token present → Save token & go to home
```

### OTP Flow
```dart
// User enters OTP code
// AuthService:
// 1. Sends OTP verification request
// 2. On success, saves token
// 3. Navigates to home screen
```

## 📝 Important Configuration

### Update These Values:
1. **API Base URL** in `auth_service.dart` (line 11):
   ```dart
   AuthService(this._dio, {String baseUrl = 'http://192.168.0.106/api/'})
   ```

2. **Firebase Credentials** in `firebase_options.dart`:
   - Get from Firebase Console
   - Or run: `flutterfire configure --reconfigure`

3. **Backend API Response Format** must match:
   ```json
   {
     "status": true,
     "require_otp": true/false,
     "access_token": "...",
     "message": "..."
   }
   ```

## 🚀 Next Steps

1. Get Firebase project credentials
2. Update API base URL
3. Test login flow
4. Test OTP flow
5. Deploy to devices

## ❌ Error Solutions

| Error | Solution |
|-------|----------|
| `Undefined DefaultFirebaseOptions` | Run `flutter pub get` |
| `firebase_core not found` | Run `flutter pub get` |
| `Device token is null` | Check Firebase Messaging permissions |
| `OTP verification fails` | Verify backend API response format |
| `Token not saved` | Check SharedPreferences permissions |

## 📦 Files Structure

```
lib/
├── main.dart (Firebase init)
├── firebase_options.dart (NEW - Firebase config)
├── core/
│   └── network/
│       ├── auth_service.dart (NEW - Centralized auth)
│       ├── session_manager.dart
│       └── api_service.dart
└── ui/
    └── auth/
        ├── login_screen.dart (Updated)
        └── otp_screen.dart (Updated)
```

## 🔐 Session Management

Token is automatically:
- Saved after successful login/OTP
- Retrieved when needed
- Cleared on logout

Location: `SharedPreferences` with key `access_token`

## 📞 Support

For issues:
1. Check `FIREBASE_FIX_NOTES.md` for detailed docs
2. Run `flutter doctor` to verify setup
3. Check Android/iOS-specific configurations
4. Review backend API logs
