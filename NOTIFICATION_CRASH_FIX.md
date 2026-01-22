# Notification Crash Fix - Diagnostic & Recovery

## Problem Reported
- ✅ Notification arrives
- ❌ Screen goes black after clicking
- ❌ App crashes back to splash screen

## Root Causes Addressed

### 1. **Unhandled Exception in NotificationsPage Widget**
- Added try-catch in `build()` method
- Added error fallback UI that shows actual error message
- Now shows "Error loading notifications" instead of black screen

### 2. **TabController Initialization Issues**
- Added error handling in `initState()`
- Added proper `dispose()` method
- TabController now has safe creation with try-catch

### 3. **API Response Parsing Errors**
- Added detailed logging for API calls
- Added error handling for different response types
- Added fallback parsing for array responses

### 4. **Navigation Before Page Ready**
- Wrapped NotificationsPage creation with error handler
- Added fallback error page in MaterialPageRoute builder
- Navigator now won't crash if page fails to initialize

### 5. **Status Bar/Theme Issues**
- Added try-catch in `didChangeDependencies()`
- Wrapped SystemChrome.setSystemUIOverlayStyle() with error handling

## Files Modified

### 1. `lib/main.dart` - Enhanced Notification Handler
```dart
// Now wraps NotificationsPage creation with error handling
MaterialPageRoute(
  builder: (_) {
    try {
      return const NotificationsPage();
    } catch (e) {
      // Returns error page instead of crashing
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $e')),
      );
    }
  },
);
```

### 2. `lib/ui/home/customer/notifications_page.dart` - Complete Error Handling
- ✅ Enhanced `initState()` with error handling
- ✅ Added proper `dispose()` method
- ✅ Enhanced `_loadNotifications()` with detailed logging
- ✅ Enhanced `build()` with try-catch and error UI fallback
- ✅ Enhanced `didChangeDependencies()` with error handling

## Debug Output to Check

When you click notification, check console for:

```
📲 Handling notification tap - route: notifications
✅ Navigator ready - pushing NotificationsPage

📲 Loading notifications...
📲 API Response Status: 200
📲 API Response Data Type: _InternalLinkedHashMap
✅ Notifications loaded: 5 items
✅ Status bar color set
```

### If Errors Appear

**Error during page creation:**
```
❌ Error creating NotificationsPage: ...
```
→ Fix: Page will show error message instead of crashing

**Error loading API:**
```
❌ Error loading notifications: ...
```
→ Fix: Will show "Terjadi kesalahan" with retry button

**Error parsing response:**
```
❌ Error parsing notification list: ...
```
→ Fix: Will show error page with retry option

## Testing Steps

### Test 1: Normal Flow
```bash
1. flutter run -v
2. Send notification from admin panel
3. Click notification while app is open
4. Check logs for "✅ Notifications loaded"
5. Should see notifications list (not black screen)
```

### Test 2: Error Handling
```bash
1. Block internet / turn off WiFi
2. Click notification
3. Should see "Terjadi kesalahan" with retry button
4. NOT crash to splash screen
```

### Test 3: Background Tap
```bash
1. Send app to background
2. Send notification
3. Click notification
4. App should come to foreground
5. Should show notifications page
```

## Error Recovery Flow

**Old Flow:**
```
Click Notification
  ↓
Navigation to NotificationsPage
  ↓
[CRASH] → Splash Screen
```

**New Flow:**
```
Click Notification
  ↓
Try to navigate to NotificationsPage
  ↓
├─ Success → Show notifications
│
└─ Error → Show error page
    └─ User can tap "Coba Lagi"
```

## Key Improvements

| Issue | Old | New |
|-------|-----|-----|
| Page creation error | ❌ Crash | ✅ Error UI |
| API call fails | ❌ Crash | ✅ Error UI + Retry |
| TabController error | ❌ Crash | ✅ Error UI + Retry |
| Status bar error | ❌ Crash | ✅ Logged, handled |
| Parsing error | ❌ Crash | ✅ Error UI + Retry |
| Navigator not ready | ❌ Crash | ✅ Queued fallback |

## Logs to Verify

Check for these success messages in logs:

```
✅ Navigator ready - pushing NotificationsPage
✅ Notifications loaded: X items
✅ Status bar color set
✅ Navigation succeeded in post-frame callback
```

Or these error messages (which won't crash):

```
⚠️ Direct push failed: ...
⚠️ Trying named route /notifications
⚠️ Error creating NotificationsPage: ...
⚠️ Error setting status bar color: ...
❌ Error loading notifications: ...
```

## If Still Crashing

If you still see crashes, check:

1. **Token validity**: 
   - Ensure user is properly logged in
   - Check `SessionManager.getToken()` is working

2. **API endpoint**:
   - Verify `getUserNotifications()` endpoint exists
   - Check backend returns proper format

3. **Model parsing**:
   - Ensure `NotificationModel.fromJson()` handles all fields
   - Check API response matches model structure

4. **Firebase config**:
   - Verify Firebase project matches both frontend & backend
   - Check device token is valid

## Quick Debug: Add Log to Verify

```dart
// Add to _loadNotifications() to debug API format
debugPrint('📲 Full API Response: ${json.encode(response.data)}');
```

Then check console output to see exact API response format.

---

**Status**: Enhanced with comprehensive error handling ✅
All crash points now have recovery paths.
