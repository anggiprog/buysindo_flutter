# FIX: User Registration to Wrong Admin (1050 instead of subdomain-based admin)

## Problem Summary
Ketika user mendaftar melalui subdomain tertentu (misalnya `nabilacell.bukatoko.online`), user tersebut terdaftar ke admin_user_id = **1050** (default) **alih-alih admin_user_id = 123** (yang seharusnya untuk nabilacell).

## Root Cause
Ada gap antara frontend dan backend dalam menggunakan admin_user_id saat registrasi:

### Frontend (Flutter App):
1. **`app_config.dart`** memiliki dua property:
   - `adminId` → **Static/hardcoded ke "1050"** (dari environment atau default)
   - `adminUserId` → **Dynamic value fetched dari API berdasarkan subdomain**

2. **`register_screen.dart`** (BEFORE FIX):
   - Menggunakan `appConfig.adminId` (WRONG - selalu 1050)
   - Seharusnya menggunakan `appConfig.adminUserId` (CORRECT - subdomain-based)

### Backend (Laravel):
- Bekerja dengan baik: `admin_user_tokens` linked ke `admin_user_id` yang benar
- Registrasi menggunakan `X-Admin-Token` header untuk extract admin_user_id yang tepat
- Masalahnya: Frontend mengirimkan token dari admin 1050 bukan dari admin yang seharusnya

## Changes Made

### 1. **Flutter: register_screen.dart**
**File:** `buysindo_app/lib/ui/auth/register_screen.dart`

**What Changed:**
- Line 48-49: Mengubah dari `appConfig.adminId` → `appConfig.adminUserId`
- Menambahkan waiting logic untuk memastikan `adminUserId` sudah properly initialized dengan value dari subdomain, bukan default 1050
- Jika masih default setelah waiting ~5 detik, tetap lanjut (fallback)

**Before:**
```dart
final response = await apiService.getAdminToken(appConfig.adminId);
```

**After:**
```dart
String adminUserId = appConfig.adminUserId;
int retries = 0;
const maxRetries = 10;
const retryDelayMs = 500;

// Poll until we get a subdomain-based config (or timeout after ~5 seconds)
while (adminUserId == '1050' && retries < maxRetries) {
  debugPrint('⏳ Waiting for subdomain config... (retry ${retries + 1}/$maxRetries)');
  await Future.delayed(const Duration(milliseconds: retryDelayMs));
  adminUserId = appConfig.adminUserId;
  retries++;
}

final response = await apiService.getAdminToken(adminUserId);
```

## How It Should Work Now

### Flow:
1. User mengakses `https://nabilacell.bukatoko.online/register`

2. **Frontend (Flutter Web):**
   - `app_config.dart` → `_getSubdomainFromWindow()` extracts "nabilacell" dari hostname
   - `initializeApp()` dipanggil → calls `getConfigBySubdomain("nabilacell")`
   - API returns: `{ admin_user_id: 123, name: "Nabilacell Toko", ... }`
   - Saves: `_adminUserId = "123"`

3. **Register Screen:**
   - `_fetchAdminToken()` dipanggil
   - Checks: `appConfig.adminUserId` → nilai "123" (bukan 1050)
   - Calls: `GET /api/admin-tokens/123`
   - Backend returns: token yang linked ke admin 123

4. **User Registration:**
   - Sends token (linked ke admin 123) + user data
   - Backend validates token → extracts admin_user_id = 123
   - **Creates user with admin_user_id = 123** ✓

## Database Verification Needed

### 1. Check Applications Table
```sql
SELECT id, subdomain, admin_user_id, name, status 
FROM applications 
WHERE subdomain = 'nabilacell';
-- Expected: admin_user_id = 123
```

### 2. Check Admin Tokens
```sql
SELECT id, admin_user_id, token 
FROM admin_user_tokens 
WHERE admin_user_id = 123;
-- Expected: At least 1 token should exist for admin 123
```

### 3. Check Default Admin (1050)
```sql
SELECT id, subdomain, admin_user_id, name 
FROM applications 
WHERE admin_user_id = 1050;
-- This should be the FALLBACK/default store, not for nabilacell
```

## If Problem Still Occurs

### Checklist:
- [ ] Is nabilacell mapping exists in `applications` table? → admin_user_id should be 123
- [ ] Does admin_user_id 123 have tokens in `admin_user_tokens`? → Query to check
- [ ] Is the web server properly detecting subdomain? → Check browser console logs
- [ ] Is `getConfigBySubdomain()` API endpoint working? → Test directly: `/api/config/subdomain/nabilacell`

### Debug Steps:
1. **Open browser console** on `https://nabilacell.bukatoko.online/`
2. **Look for logs:**
   - "✅ Got subdomain-based adminUserId: 123" → Means config loaded correctly
   - "⏳ Waiting for subdomain config..." → Means config still loading
   - "⚠️ Config still default (1050) after waiting" → Means API didn't return config

3. **Test API directly:**
   - `curl https://nabilacell.bukatoko.online/api/config/subdomain/nabilacell`
   - Should return: `{ admin_user_id: 123, ... }`

## Files Modified
- `buysindo_app/lib/ui/auth/register_screen.dart` → Changed from `adminId` to `adminUserId` with waiting logic

## Files Not Modified (Already Working)
- `buysindo_app/lib/core/app_config.dart` → Already fetches `adminUserId` from API correctly
- `buysindo/app/Http/Controllers/Api/AuthController.php` → Already validates token and extracts admin_user_id correctly
- `buysindo/app/Http/Controllers/Api/ApplicationConfigController.php` → Already returns correct admin_user_id per subdomain
