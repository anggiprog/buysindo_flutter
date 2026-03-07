# Online Deployment Fix - Technical Summary

**Problem**: Flutter web app stuck at splash screen on `https://agicell.bukatoko.online/` (works on `http://agicell.bukatoko.local/`)

**Root Cause**: `ApiService.instance` was using hardcoded default URL instead of detecting current window location

**Status**: BUILD IN PROGRESS - Applied 6 critical fixes

---

## Changes Made

### 1. **ApiService Singleton - CRITICAL FIX** 
📄 [/lib/core/network/api_service.dart](lib/core/network/api_service.dart#L284)

```dart
// BEFORE (broken for online):
static final ApiService instance = ApiService(Dio());
// → Always used hardcoded fallback: https://buysindo.com/

// AFTER (works for local + online):
static ApiService? _instanceCache;

static ApiService get instance {
  if (_instanceCache == null) {
    _instanceCache = ApiService.auto(Dio());  // ← Auto-detects window.location!
  }
  return _instanceCache!;
}
```

**Impact**: All API calls from HomeScreen, DashboardScreen, etc. now use correct base URL

---

### 2. **WebHelper Enhanced Logging**
📄 [/lib/core/utils/web_helper.dart](lib/core/utils/web_helper.dart#L29)

Added detailed debug output:
- Detects window.location.origin first (most reliable)
- Falls back to subdomain parsing
- Logs production vs. local mode detection

**Console Output Example**:
```
🔍 [WebHelper.getBaseUrl] Host detected: https://agicell.bukatoko.online
✅ [WebHelper.getBaseUrl] Using host as baseUrl: https://agicell.bukatoko.online/
```

---

### 3. **WebHelper Web Implementation Logging**
📄 [/lib/core/utils/web_helper_web.dart](lib/core/utils/web_helper_web.dart#L60)

```dart
static void logDebugInfo() {
  debugPrint('🌐 [WebHelper] Window Location Debug:');
  debugPrint('   Origin: ${html.window.location.origin}');
  debugPrint('   Hostname: ${html.window.location.hostname}');
  debugPrint('   Protocol: ${html.window.location.protocol}');
  debugPrint('   Full URL: ${html.window.location.href}');
}
```

**Helps identify**: SSL/HTTPS issues, hostname mismatches, iframe context problems

---

### 4. **Main App Initialization Logging**
📄 [/lib/main.dart](lib/main.dart#L285)

```dart
Future<void> _fetchConfigAsync() async {
  debugPrint('🚀 [_fetchConfigAsync] Starting API configuration fetch...');
  try {
    // ... initialization code ...
  } catch (e) {
    print('ERROR: Config failed - $e');  // Prints to console for visibility
  }
}
```

**Benefit**: Errors are now visible in browser console, not just debugPrint

---

### 5. **Splash Screen Lifecycle Logging**
📄 [/lib/ui/splash_screen.dart](lib/ui/splash_screen.dart#L38)

```dart
@override
void initState() {
  super.initState();
  debugPrint('🎬 [SplashScreen] initState started');
  // ... lifecycle logging added ...
  debugPrint('🎬 [SplashScreen] Navigating to: $next');
}
```

**Traces**: Splash load → cache check → navigation flow

---

### 6. **Home Screen API Call Logging**
📄 [/lib/ui/home/home_screen.dart](lib/ui/home/home_screen.dart#L25)

Added logging for `ApiService.instance.getPaket()` call which was hanging

---

## Expected Behavior After Fix

### Local Version: `http://agicell.bukatoko.local/`
✅ Already working - no changes  
✅ BaseURL detected as: `http://agicell.bukatoko.local/`

### Online Version: `https://agicell.bukatoko.online/` 
**Before Fix**:
- API calls to `https://buysindo.com/api/...` (WRONG!)
- App hangs after splash screen
- Gray background (stuck)

**After Fix**:
- API calls to `https://agicell.bukatoko.online/api/...` (CORRECT!)
- Dashboard loads in 2-3 seconds
- Banners, products, saldo all work

---

## Build & Deploy Process

### 1. Build (In Progress)
```bash
cd E:\projek_flutter\buysindo\buysindo_app
flutter clean
flutter pub get
flutter build web --release --no-tree-shake-icons
# ↓ Compiling for ~5 minutes...
```

### 2. Deploy (Next)
```bash
xcopy build\web C:\xampp\htdocs\buysindo\public\app /E /I /Y
# ↓ Copy all 47 files to webroot
```

### 3. Test (After Deploy)
```
Open in browser: https://agicell.bukatoko.online/
Press F12 → Console
Look for success messages instead of errors
```

---

## Testing Expectations

### Console Messages (F12 → Console)

If build succeeded with fixes:
```
✅ [WebHelper] Using host as baseUrl: https://agicell.bukatoko.online/
🔧 [ApiService] Creating ApiService singleton with auto-detection...
✅ [ApiService] ApiService singleton created
🚀 [_fetchConfigAsync] Starting API configuration fetch...
✅ [_fetchConfigAsync] Successfully initialized AppConfig
🎬 [SplashScreen] Checking token after 800ms delay...
🎬 [SplashScreen] Navigating to: /home
```

### Network Tab (F12 → Network)

All these should return **200 OK**:
- `api/app/config/1050/app`
- `api/banner?admin_user_id=1050`
- `api/splash-screen?admin_id=1050`
- `api/user/saldo` (requires token)
- `api/user/poin` (requires token)

### UI Result

- ✅ Splash screen shows
- ✅ Dashboard loads with data
- ✅ Banners visible
- ✅ Saldo shows  
- ✅ Can navigate menus

---

## Fallback Plan

If online build still doesn't work after these fixes:

1. **Check Backend API** - Are these endpoints accessible?
   ```javascript
   fetch('https://agicell.bukatoko.online/api/app/config/1050/app')
     .then(r => r.json())
     .then(d => console.log(d))
   ```

2. **Check CORS Headers** - Laravel backend may need CORS middleware
   ```
   Access-Control-Allow-Origin: https://agicell.bukatoko.online
   Access-Control-Allow-Methods: GET, POST, OPTIONS
   Access-Control-Allow-Credentials: true
   ```

3. **Check SSL Cert** - Verify cert is valid (DevTools → Security tab)

4. **Check DNS** - Ensure `agicell.bukatoko.online` resolves correctly

---

## Files Changed

- ✅ `/lib/core/network/api_service.dart` - Lazy singleton initialization
- ✅ `/lib/core/utils/web_helper.dart` - Enhanced logging
- ✅ `/lib/core/utils/web_helper_web.dart` - Window location debug
- ✅ `/lib/main.dart` - Config fetch visibility
- ✅ `/lib/ui/splash_screen.dart` - Lifecycle logging
- ✅ `/lib/ui/home/home_screen.dart` - API call logging

**Total Changes**: 6 files, ~50 new lines of logging, 1 critical API singleton fix

---

## Time to Test

After build completes:
1. **Deploy**: 10 seconds
2. **Load Page**: 5-10 seconds
3. **Check Console**: 2-3 seconds
4. **Make Decision**: See if dashboard loads

**Total**: ~30 seconds to know if fix works ✓

---

**Next Action**: Wait for build to complete, then deploy and test

