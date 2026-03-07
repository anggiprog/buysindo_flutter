# Testing Online Deployment - Debug Guide

## Problem

Flutter web app stuck at splash screen on online version (`https://agicell.bukatoko.online/`), but works on local (`http://agicell.bukatoko.local/`).

## Root Cause

**FIXED**: `ApiService.instance` was using default `Dio()` instead of auto-detecting base URL from window location.

- **Before**: Used hardcoded fallback URL `https://buysindo.com/`  
- **After**: Now uses `ApiService.auto()` which detects `window.location.origin`

## Debug Steps

### 1. **New Build & Deploy**

Run the automated rebuild script:

```bash
cd E:\projek_flutter\buysindo\buysindo_app
rebuild_web.bat
```

Or manual steps:

```bash
flutter clean
flutter pub get
flutter build web --release --no-tree-shake-icons
# Then copy to C:\xampp\htdocs\buysindo\public\app
```

### 2. **Check Browser Console Logging**

Open `https://agicell.bukatoko.online/` and press `F12` to open DevTools.

Go to **Console** tab and look for these messages:

#### Expected Output (Working):

```
✅ [WebHelper] Window Location Debug:
   Origin: https://agicell.bukatoko.online
   Hostname: agicell.bukatoko.online
   Protocol: https:
   Full URL: https://agicell.bukatoko.online/app/

✅ [WebHelper.getBaseUrl] Using host as baseUrl: https://agicell.bukatoko.online/

🔧 [ApiService] Creating ApiService singleton with auto-detection...
✅ [ApiService] ApiService singleton created

🚀 [_fetchConfigAsync] Starting API configuration fetch...
✅ [_fetchConfigAsync] Successfully initialized AppConfig

🎬 [SplashScreen] initState started
✅ [SplashScreen] Cached logo found, showing immediately
🎬 [SplashScreen] Checking token after 800ms delay...
🎬 [SplashScreen] Token retrieved: true
🎬 [SplashScreen] Navigating to: /home
```

#### Error Cases (Need Debugging):

**Case 1: API Config timeout**

```
ERROR: Config timeout - TimeoutException: API config timeout after 15 seconds
```

→ **Fix**: Check API endpoint = `https://agicell.bukatoko.online/api/app/config/1050/app`

**Case 2: API fetch failed**

```
ERROR: Config failed - DioException: Connection timeout...
```

→ **Fix**: Check CORS headers on backend, SSL certificate, network connectivity

**Case 3: Splash fetch failed**

```
ERROR: Splash fetch failed - DioException: ...
```

→ **Fix**: getSplashScreen API endpoint is failing

### 3. **Network Tab Inspection**

In DevTools, go to **Network** tab and check these API calls:

| Endpoint | Expected | Status | Size |
|----------|----------|--------|------|
| `api/app/config/1050/app` | ✓ | 200 | ~1KB |
| `api/banner?admin_user_id=1050` | ✓ | 200 | ~5KB |
| `api/splash-screen?admin_id=1050` | ✓ | 200 | ~1KB |

**All should be 200 OK**. If any are:
- **407**: Permissions issue
- **500**: Server error
- **timeout**: Network/DNS issue
- **Blocked by CORS**: Missing CORS headers on backend

### 4. **Detailed Logging Keywords to Search**

Copy-paste into browser console to filter logs:

```javascript
// Show all app-related logs
console.log(document.body.innerHTML.match(/\[WebHelper\].*\[SplashScreen\].*\[ApiService\]/g))
```

### 5. **Common Issues & Fixes**

| Issue | Symptom | Fix |
|-------|---------|-----|
| Wrong base URL | API calls to `https://buysindo.com/` | ✅ FIXED: Now uses `window.location.origin` |
| API not accessible | Status 500 or timeout | Check backend `https://agicell.bukatoko.online/api` is accessible |
| CORS blocked | Network tab shows CORS error | Add CORS headers on backend |
| SSL cert untrusted | API calls fail silently | Chrome DevTools → Security tab to verify |
| Service worker cache | Old app version loads | Press `Ctrl+Shift+Delete`, clear cache, hard refresh `Ctrl+F5` |

## What Was Changed

### `/lib/core/network/api_service.dart`

```dart
// BEFORE (broken for web):
static final ApiService instance = ApiService(Dio());

// AFTER (works for both local and online):
static ApiService? _instanceCache;

static ApiService get instance {
  if (_instanceCache == null) {
    _instanceCache = ApiService.auto(Dio());  // Auto-detects base URL!
  }
  return _instanceCache!;
}
```

### `/lib/core/utils/web_helper.dart` + `/web_helper_web.dart`

Added extensive logging:
- Window location detection
- Protocol and hostname verification
- Production vs local mode detection
- Fallback URL logic

### `/lib/ui/splash_screen.dart`

Added lifecycle logging:
- SplashScreen initialization
- Token checking
- Navigation points
- API failure handling

### `/lib/main.dart`

Added error visibility:
- Config fetch logging
- Timeout messages printed to console
- Better error messages

## Testing Checklist

- [ ] Build completes successfully
- [ ] Web deploy succeeds (all 47 files copied)
- [ ] Local version still works: `http://agicell.bukatoko.local/`
- [ ] Online version shows splash: `https://agicell.bukatoko.online/`
- [ ] Console shows WebHelper/ApiService messages
- [ ] Dashboard loads after 2-3 seconds
- [ ] Banners & products load
- [ ] API Network tab shows all 200 OK

## Next Steps If Still Broken

1. **Check backend API** - Is `https://agicell.bukatoko.online/api/app/config/1050/app` working?
   
   Test in browser:
   ```javascript
   fetch('https://agicell.bukatoko.online/api/app/config/1050/app')
     .then(r => r.json())
     .then(d => console.log(d))
     .catch(e => console.log('ERROR:', e.message))
   ```

2. **Check CORS** - Are CORS headers set up on Laravel backend?

   Expected headers:
   ```
   Access-Control-Allow-Origin: https://agicell.bukatoko.online
   Access-Control-Allow-Credentials: true
   ```

3. **Check SSL** - Is SSL cert valid?

   In DevTools → Security tab, verify no cert warnings.

4. **Check Network** - Can you ping the backend server?

   Test in browser console:
   ```javascript
   fetch('https://agicell.bukatoko.online/', {mode: 'no-cors'})
   ```

## Reverting (if needed)

If things break, revert this commit or use previous web build:

```bash
git log --oneline lib/core/network/api_service.dart
git checkout <previous-commit> -- lib/core/network/api_service.dart
```

---

**Last Updated**: March 7, 2026  
**Status**: TESTING - Fixes applied, awaiting feedback  
**Next**: Redeploy web build and test
