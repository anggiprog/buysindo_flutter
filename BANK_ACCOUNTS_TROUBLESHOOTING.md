# Bank Accounts Feature - Troubleshooting Guide

## Problem: Bank accounts not displaying

### Quick Diagnosis Steps

1. **Check Console Logs** (When running `flutter run`)
   - Look for: `🔍 [TOPUP] Bank accounts received: X accounts`
   - If shows `0 accounts`, proceed to Step 2
   - If error logs appear, check the error message

2. **Verify API is Returning Data**
   ```bash
   # Open terminal and test API directly
   curl -X GET https://buysindo.com/api/rekening-bank \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json"
   ```
   - Should return 200 status
   - Should have `data` array with bank objects

3. **Check Token is Valid**
   - Look for log: `🔍 [TOPUP] Token retrieved: ...`
   - If shows `Token is null`, user not authenticated
   - User needs to login first

### Common Issues & Solutions

---

## Issue 1: "Tidak ada rekening tersedia" message

**Symptom:**
- Bank section shows "Tidak ada rekening tersedia"
- Log shows: `🔍 [API] Parsed Bank Accounts Count: 0`

**Possible Causes:**
1. Backend returns empty data array
2. API endpoint returns error (but no exception)
3. Response format doesn't match expected structure

**Solutions:**
```bash
# Test backend API directly
curl -i https://buysindo.com/api/rekening-bank \
  -H "Authorization: Bearer YOUR_TOKEN"

# Check response status and body
# Status should be 200
# Body should have "data" array with bank objects
```

**Check Implementation:**
- Verify endpoint in api_service.dart: `'api/rekening-bank'` ✓
- Verify token is being sent: `'Authorization': 'Bearer $token'` ✓
- Verify parsing logic in BankAccountResponse.fromJson() ✓

---

## Issue 2: Logo not loading (shows fallback icon)

**Symptom:**
- Bank card displays with bank icon instead of logo
- Console may show network warnings

**Possible Causes:**
1. Logo URL in database is incorrect
2. CORS not enabled on backend
3. Image server is down
4. URL is broken/invalid

**Solutions:**
```dart
// Extract URL from logs
🔍 [BANK] Logo URL: https://tuwaga.id/...

// Test URL in browser
# Open URL directly in browser
# If blank/error, URL is invalid

// Check CORS on backend
# Ensure backend allows cross-origin image requests
```

**Fallback Behavior:**
- If logo URL fails to load, shows bank icon (🏦)
- User can still copy account details
- Functionality not affected

---

## Issue 3: Copy to clipboard not working

**Symptom:**
- Click copy icon but nothing happens
- No snackbar appears
- Log shows: `❌ ERROR copying to clipboard: ...`

**Possible Causes:**
1. Android/iOS permission not granted
2. System clipboard access denied
3. Device issue (unlikely)

**Solutions:**

**Android:**
```xml
<!-- In android/app/src/main/AndroidManifest.xml -->
<!-- Should already have: -->
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS:**
```yaml
# In ios/Podfile - should work by default
# Clipboard access is usually allowed
```

**App Permissions:**
1. Go to Settings > Apps > Your App
2. Check "Clipboard" or "Storage" permissions
3. Enable if disabled
4. Restart app

---

## Issue 4: Logo preview dialog not opening

**Symptom:**
- Click logo but nothing happens
- No dialog appears

**Possible Causes:**
1. Logo is null/empty (but you see fallback icon)
2. GestureDetector tap not detected
3. Dialog not building properly

**Debug Steps:**
1. Check logs for: `🔍 [BANK] Opening logo preview: https://...`
2. If no log, tap is not being detected - UI issue
3. If log shows but dialog doesn't appear - dialog issue

**Solution:**
- Try tapping logo again (sometimes first tap doesn't register)
- Restart app if UI is unresponsive
- Check console for exceptions

---

## Issue 5: Bank names showing with wrong color

**Symptom:**
- Bank name text color doesn't match app theme

**Possible Causes:**
1. AppConfig().textColor not initialized
2. Incorrect color value in app_config.dart
3. AppConfig is null

**Debug:**
```dart
// Check what color is being used
final textColor = AppConfig().textColor;
print('Text color: $textColor');  // Check this in logs
```

**Solution:**
1. Verify AppConfig is properly initialized in main.dart
2. Check app_config.dart for correct textColor value
3. Ensure app_config.dart is imported correctly

---

## Issue 6: Slow loading or freezing

**Symptom:**
- Page takes long time to load
- UI freezes while loading
- Spinner appears for extended time

**Possible Causes:**
1. Slow network connection
2. API is slow
3. Images taking long to load
4. Too many bank accounts

**Debug:**
Check logs for timing:
```
🔍 [TOPUP] ===== FETCHING START ===== <- T=0
🔍 [API] Status Code: 200                <- T=1-2s
🔍 [TOPUP] Bank accounts received: 5     <- T=1-2s
🔍 [BANK] Building card for: Bank 1      <- T=2-3s (UI rebuild)
```

**Solutions:**
1. Check network speed
2. Reduce number of bank accounts on backend
3. Optimize image sizes
4. Use image caching library if needed

---

## Issue 7: Error: "Undefined name 'context'"

**Symptom:**
- Build error in topup_manual.dart
- Error at line ~551

**Status:** ✅ **FIXED**
- Context parameter added to _copyToClipboard method
- All calls updated to pass context

**If error still appears:**
1. Run `flutter clean`
2. Run `flutter pub get`
3. Restart VS Code or flutter server

---

## Issue 8: Logo dimensions too small

**Symptom:**
- Bank logo hard to see
- Want larger preview

**Current:**
- Display size: 50x50px
- Preview size: 400px height

**To increase:**
1. Display size: Change `width: 50, height: 50` in _BankDetailCard build()
2. Preview size: Change `height: 400` in _showLogoPreview()

---

## Test Checklist

- [ ] App loads without errors
- [ ] Top Up page accessible
- [ ] Bank accounts list appears
- [ ] All bank logos display or show fallback
- [ ] Bank names visible with correct color
- [ ] Can tap logo to see preview
- [ ] Preview dialog shows full image
- [ ] Preview dialog closes with X button
- [ ] Can copy account holder name
- [ ] Can copy account number
- [ ] Copy shows snackbar confirmation
- [ ] Multiple banks display with proper spacing
- [ ] No console errors or warnings

---

## Getting Help

### Enable Verbose Logging
```bash
flutter run -v
```

### Check Specific Logs
```bash
# Filter for bank logs only
flutter run | grep "\[BANK\]"
flutter run | grep "\[API\]"
flutter run | grep "\[TOPUP\]"
```

### Full Debugging
1. Add print statements to understand flow
2. Use breakpoints in debugger
3. Check device logs via Android Studio/Xcode
4. Verify backend API independently

### Report Issues With:
1. Console output (full logs)
2. Device type (Android/iOS)
3. Steps to reproduce
4. Expected vs actual behavior
5. Screenshot of error (if UI related)

---

## Performance Tips

1. **Image Caching**
   - Logos are cached by Flutter's Image widget
   - No action needed

2. **API Optimization**
   - Request includes only necessary fields
   - Backend should return only active accounts

3. **UI Optimization**
   - ListView.separated prevents rebuild issues
   - Non-blocking image loading
   - Proper error handling

4. **Memory**
   - Dialog properly disposed on close
   - No memory leaks in image loading
   - Clipboard operations are lightweight
