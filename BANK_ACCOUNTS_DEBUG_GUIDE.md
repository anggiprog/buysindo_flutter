# Bank Accounts Display Debug Guide

## Updates Made

### 1. Enhanced Logo Display with Preview
- Logo size increased from 40x40 to 50x50 for better visibility
- Added border (2px) around logo using primary color
- Added zoom icon indicator to show it's clickable
- Added "Tap logo untuk preview" text
- Logo now opens full-screen preview dialog on tap

### 2. Full-Screen Logo Preview Dialog
- Tap bank logo to see full preview (height: 400px)
- Dialog shows bank name below the image
- Perfect for viewing QR codes and payment details
- Close button in top-right corner
- Error handling with broken image icon fallback

### 3. Comprehensive Debug Logging
Added detailed logging at multiple levels:

#### API Level (`api_service.dart`)
```
🔍 [API] ===== FETCHING BANK ACCOUNTS START =====
🔍 [API] Endpoint: api/rekening-bank
🔍 [API] Token: XXX...
🔍 [API] Status Code: 200
🔍 [API] Response Data: {...}
🔍 [API] Parsed Bank Accounts Count: 2
🔍 [API]   [0] Bank Neo Commerce - 5859459401274500
🔍 [API]   [1] BCA - 5321513213213
```

#### UI Level (`topup_manual.dart`)
```
🔍 [TOPUP] ===== FETCHING ADMIN FEE AND BANK ACCOUNTS START =====
🔍 [TOPUP] Token retrieved: XXX...
🔍 [TOPUP] Fetching admin fee...
🔍 [TOPUP] Admin fee received: 5000
🔍 [TOPUP] Fetching bank accounts...
🔍 [TOPUP] Bank accounts received: 2 accounts
🔍 [TOPUP] ===== API RESPONSES RECEIVED =====
🔍 [TOPUP] Admin Fee: 5000
🔍 [TOPUP] Total: 55000
🔍 [TOPUP] Bank Accounts Count: 2
```

#### Card Building Level
```
🔍 [BANK] Building card for: Bank Neo Commerce (ID: 3461)
🔍 [BANK] Logo URL: https://tuwaga.id/wp-content/uploads/...
🔍 [BANK] Account: 5859459401274500
```

#### Clipboard Actions
```
🔍 [BANK] Copying to clipboard: Atas nama = Anggiansyah
✅ [BANK] Successfully copied: Atas nama
```

#### Dialog Preview
```
🔍 [BANK] Opening logo preview: https://...
```

## How to Debug

### Step 1: Run the App
```bash
flutter run
```

### Step 2: Navigate to Top Up Manual
1. Open the app
2. Go to Top Up section
3. Click "Pembayaran Manual"
4. Select an amount
5. Click "Lanjutkan Pembayaran Manual"

### Step 3: Check Console Logs
Open VS Code terminal and look for:
- 🔍 logs to see flow
- ❌ logs to see errors
- ✅ logs to see successful operations

### Common Issues & Solutions

#### Issue: Bank accounts not showing
**Check logs for:**
```
🔍 [TOPUP] Bank accounts received: 0 accounts
```

**Solutions:**
1. Verify token is valid: `🔍 [TOPUP] Token retrieved: ...`
2. Check API response: `🔍 [API] Status Code: 200`
3. Verify backend endpoint is working

#### Issue: Logo not loading
**Check logs for:**
```
🔍 [BANK] Logo URL: https://...
```

**Solutions:**
1. Copy the URL from logs
2. Open in browser to verify it's accessible
3. Check CORS headers on backend
4. Fallback icon (🏦) should show if URL fails

#### Issue: Copy to clipboard not working
**Check logs for:**
```
🔍 [BANK] Copying to clipboard: ...
❌ ERROR copying to clipboard: ...
```

**Solution:**
- Usually a permissions issue on Android/iOS
- Verify clipboard access is granted in app settings

## Test Scenarios

### Test 1: Display Multiple Banks ✅
- Verify list shows all banks from backend
- Check each bank has logo, name, account details
- Logo should be clickable

### Test 2: Preview Logos ✅
- Tap each bank logo
- Full preview dialog should appear
- QR codes should be visible
- Close button should work

### Test 3: Copy Functions ✅
- Tap copy icon on "Atas Nama"
- Tap copy icon on "No. Rekening"
- Snackbar should show "disalin ke clipboard"
- Paste elsewhere to verify content

### Test 4: Error Handling ✅
- Disable network temporarily
- App should show error message
- Try again should retry the request
- Error logs should show details

## Expected Output

When everything works correctly:

1. **Page loads** → Shows "Informasi Top Up" with amount and admin fee
2. **Bank accounts section** → Shows:
   - Bank logo (50x50 with border) with zoom indicator
   - Bank name in custom color
   - "Tap logo untuk preview" text
   - "Atas Nama" field with copy icon
   - "No. Rekening" field with copy icon
3. **On logo tap** → Full preview dialog opens with:
   - Large image (400px height)
   - Bank name below image
   - Close button
4. **On copy icon tap** → Snackbar shows "disalin ke clipboard"

## Performance Notes

- Logo images are loaded asynchronously (non-blocking)
- Broken images show fallback icon immediately
- ListView.separated prevents rendering issues with multiple banks
- Dialog uses Image.network with proper error handling

## Future Improvements

- [ ] Add search/filter for banks
- [ ] Favorite bank selection
- [ ] Download QR code as image
- [ ] Share payment details
- [ ] Bank account management (add/edit/delete)
