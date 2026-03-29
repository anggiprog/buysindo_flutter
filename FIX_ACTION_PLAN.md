# 🔧 ACTIONABLE SUMMARY: User Registration Subdomain Fix

## What Was Wrong
User registration untuk subdomain `nabilacell.bukatoko.online` menghasilkan:
- ❌ `admin_user_id = 1050` (hardcoded default)
- ✓ Seharusnya `admin_user_id = 123` (untuk nabilacell)

## What I Fixed
**File:** `buysindo_app/lib/ui/auth/register_screen.dart`

### Change Detail:
**BEFORE (WRONG):**
```dart
final response = await apiService.getAdminToken(appConfig.adminId);
// adminId adalah konstanta hardcoded ke "1050"
```

**AFTER (CORRECT):**
```dart
String adminUserId = appConfig.adminUserId;
// Menunggu hingga appConfig diinisialisasi dengan subdomain-based value

// Poll untuk memastikan config sudah loaded (bukan default 1050)
while (adminUserId == '1050' && retries < maxRetries) {
  debugPrint('Waiting for subdomain config... (retry ${retries + 1}/10)');
  await Future.delayed(const Duration(milliseconds: 500));
  adminUserId = appConfig.adminUserId;
  retries++;
}

final response = await apiService.getAdminToken(adminUserId);
// Menggunakan correct admin_user_id berdasarkan subdomain
```

## How Flow Bekerja Sekarang

```
User membuka: https://nabilacell.bukatoko.online/register
                                ↓
          Frontend extracts subdomain: "nabilacell"
                                ↓
        API: getConfigBySubdomain("nabilacell")
                                ↓
        Database: SELECT admin_user_id FROM applications 
                  WHERE subdomain = 'nabilacell'
                                ↓
        Returns: admin_user_id = 123
                                ↓
        appConfig.adminUserId = "123"
                                ↓
        Register screen waits untuk nilai ini
                                ↓
        Fetch admin token dengan: getAdminToken("123")
                                ↓
        Backend: SELECT token FROM admin_user_tokens 
                 WHERE admin_user_id = 123
                                ↓
        User registrasi dengan token yang linked ke admin 123
                                ↓
        ✅ User created dengan admin_user_id = 123 (CORRECT!)
```

## ✅ What's Already Working (No Changes Needed)

1. **Frontend Config Loading** (`app_config.dart`)
   - Correctly extracts subdomain dari hostname
   - Calls `getConfigBySubdomain()` di background
   - Stores hasil ke `appConfig.adminUserId`

2. **Backend Registration** (`AuthController.php`)
   - Validates admin token via `admin_user_tokens` table
   - Extracts correct `admin_user_id` dari token
   - Creates user dengan correct admin_user_id

3. **Config Endpoint** (`ApplicationConfigController.php`)
   - Returns correct admin_user_id per subdomain
   - Already tested dan working

## ⚠️ Prerequisites untuk Fix Bekerja

### Database HARUS setup dengan benar:

**1. Applications Table:**
```sql
INSERT INTO applications (subdomain, admin_user_id, name, status) 
VALUES ('nabilacell', 123, 'Nabilacell Toko', 'selesai');
```

**2. Admin Tokens Table:**
```sql
INSERT INTO admin_user_tokens (admin_user_id, token) 
VALUES (123, 'generated-token-here');
```

### Verification SQL:
```sql
-- Check subdomain mapping
SELECT id, subdomain, admin_user_id, name FROM applications WHERE subdomain='nabilacell';
-- Expected: Should show admin_user_id = 123

-- Check tokens exist for this admin
SELECT id, admin_user_id FROM admin_user_tokens WHERE admin_user_id=123;
-- Expected: Should have at least 1 token
```

## 🧪 Testing Steps (After Deploy)

1. **Build Flutter:**
   ```bash
   cd buysindo_app
   flutter build web --release
   ```

2. **Deploy to web server**

3. **Test Registration:**
   - Open: `https://nabilacell.bukatoko.online/`
   - Go to registration page
   - **Open browser console (F12)** → Look for debug logs
   - You should see:
     ```
     ✅ Got subdomain-based adminUserId: 123
     Using adminUserId: 123 (subdomain-based)
     ```
   - Register a test user (e.g., test@nabilacell.com)

4. **Verify Database:**
   ```sql
   SELECT username, email, admin_user_id 
   FROM users 
   WHERE email = 'test@nabilacell.com';
   -- Expected: admin_user_id = 123 (NOT 1050)
   ```

## 🚨 Troubleshooting

### If Still Getting admin_user_id = 1050:

**Check 1: Database**
```sql
SELECT * FROM applications WHERE subdomain='nabilacell';
-- If empty → Need to add record
-- If admin_user_id=1050 → Wrong mapping, change to 123
```

**Check 2: Browser Console Logs**
- "⏳ Waiting for subdomain config..." → Config API call is pending
- "⚠️ Config still default (1050)" → API not returning config (API error!)
- "✅ Got subdomain-based adminUserId: 123" → Working correctly ✓

**Check 3: API Endpoint**
Test manually in Postman:
```
GET https://nabilacell.bukatoko.online/api/config/subdomain/nabilacell
Expected Response:
{
  "status": "success",
  "data": {
    "admin_user_id": 123,
    ...
  }
}
```

**Check 4: File Changes**
Verify changes were applied:
```bash
grep -n "adminUserId" buysindo_app/lib/ui/auth/register_screen.dart
# Should show the new code using adminUserId
```

## 📋 Summary

| Aspek | Status |
|-------|--------|
| Frontend Fix | ✅ Done - Using adminUserId |
| Backend Logic | ✅ Already working |
| API Config | ✅ Already working |
| Database Setup | ⚠️ Need to verify |
| Testing | ⏳ Need after deploy |

## 📁 Files Modified
- ✅ `buysindo_app/lib/ui/auth/register_screen.dart` - Changed from adminId to adminUserId
- 📄 Created: `buysindo_app/REGISTRATION_SUBDOMAIN_FIX.md` - Detailed documentation
- 📄 Created: `buysindo_app/verify_subdomain_fix.sh` - Verification script
