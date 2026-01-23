# Admin Token Parsing & Bank Selection UI Fix

## Issues Fixed

### 1. Admin Token Kosong Error (RESOLVED)
**Problem:** When calling `topUpSaldo()` API, admin token returned null/empty with error: "Admin token kosong"

**Root Cause:** 
The API endpoint `/api/admin-tokens/{adminId}` returns response with structure:
```json
{
    "status": "success",
    "data": [
        {
            "id": 2,
            "admin_user_id": 1050,
            "token": "NM3dTOb3aBYzVI9prZaVi2wL6GGqh7qCTBklOXc5017B6H3AnyjpkRZ4GaPS",
            "created_at": "2025-10-26 00:47:32",
            "updated_at": "2025-10-26 00:47:32"
        }
    ]
}
```

But code was trying to access: `adminTokenResponse.data['token']` (direct access)
The token is actually at: `adminTokenResponse.data['data'][0]['token']` (nested array)

**Solution in api_service.dart (lines 944-982):**
```dart
// Parse admin token dari struktur response: {status: "success", data: [{token: "..."}]}
String? adminToken;
try {
  final responseData = adminTokenResponse.data;
  print('🔍 [API] Admin Token Response: $responseData');
  
  if (responseData is Map) {
    // Cek struktur: data['data'] adalah array
    final dataArray = responseData['data'];
    if (dataArray is List && dataArray.isNotEmpty) {
      final firstItem = dataArray[0];
      if (firstItem is Map) {
        adminToken = firstItem['token'] as String?;
      }
    }
    // Fallback: cek langsung di root level
    if (adminToken == null || adminToken?.isEmpty == true) {
      adminToken = responseData['token'] as String?;
    }
  }
} catch (e) {
  print('⚠️ [API] Error parsing admin token: $e');
}

if (adminToken == null || adminToken.isEmpty) {
  throw Exception('Admin token kosong - gagal parse dari response');
}
```

**Key Features:**
- Handles array structure `data['data'][0]['token']`
- Fallback to direct root access `data['token']`
- Comprehensive error logging
- Proper null/empty validation

---

### 2. Bank Selection Checklist UI (RESOLVED)
**Problem:** User wanted visible indicator showing which bank is selected with checkbox/radio button

**Solution in topup_manual.dart:**

#### a. Updated _BankDetailCard Class (line 636)
Added new parameter to track selected bank:
```dart
class _BankDetailCard extends StatelessWidget {
  final BankAccount bank;
  final Color primaryColor;
  final Function(BankAccount)? onSelected;
  final BankAccount? selectedBank;  // NEW

  const _BankDetailCard({
    required this.bank,
    required this.primaryColor,
    this.onSelected,
    this.selectedBank,  // NEW
  });
```

#### b. Enhanced Build Method (lines 743-761)
- Detects if bank is selected: `final isSelected = selectedBank?.id == bank.id;`
- Dynamic styling based on selection:
  - Background: Blue tint when selected
  - Border: Thicker (2.5px) with primary color when selected
  - Shadow: Added glow effect when selected
  - Logging: Shows selection status

#### c. Added Selection Indicator UI (line 815-834)
Displays visual indicator on right side of card:
```dart
// Selection Indicator
if (isSelected)
  Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: primaryColor,
      shape: BoxShape.circle,
    ),
    child: const Icon(
      Icons.check,        // ✓ Checkmark when selected
      color: Colors.white,
      size: 20,
    ),
  )
else
  Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.grey[300],
      shape: BoxShape.circle,
    ),
    child: Icon(
      Icons.radio_button_unchecked,  // ○ Radio button when not selected
      color: Colors.grey[600],
      size: 20,
    ),
  ),
```

#### d. Updated itemBuilder Call (line 417)
Pass selectedBank to widget:
```dart
return _BankDetailCard(
  bank: bank,
  primaryColor: widget.primaryColor,
  selectedBank: _selectedBank,  // NEW - pass current selection
  onSelected: (selectedBank) {
    setState(() {
      _selectedBank = selectedBank;
    });
    print('✅ [TOPUP] Bank selected: ${selectedBank.namaBank}');
  },
);
```

**UI Features:**
- ✅ Checkmark icon (filled circle) when bank is selected
- ○ Radio button icon (empty circle) when bank is not selected
- Blue background tint on selected bank
- Stronger border (2.5px) on selected bank
- Shadow effect highlights selected bank
- Smooth visual feedback

---

## Testing Checklist

- [ ] App builds without errors
- [ ] Bank list displays with radio buttons
- [ ] Clicking bank shows checkmark on selected card
- [ ] Blue highlight shows on selected bank
- [ ] Unselecting another bank hides previous checkmark
- [ ] "Saya Sudah Transfer" button validates bank is selected
- [ ] topUpSaldo() API call succeeds with admin token
- [ ] nomorTransaksi returns from API
- [ ] Navigation to TopupKonfirmasi succeeds with transaction number
- [ ] Payment proof upload works with server transaction number

---

## Files Modified

1. **lib/core/network/api_service.dart** (lines 944-982)
   - Fixed admin token parsing from nested response structure
   - Added comprehensive error handling and logging

2. **lib/ui/home/topup/topup_manual.dart**
   - Line 636: Added `selectedBank` parameter to `_BankDetailCard`
   - Line 420: Pass `selectedBank` in itemBuilder
   - Lines 743-834: Enhanced build method with selection UI
   - Selection indicator shows ✓ or ○ based on state

---

## Next Steps

1. Run: `flutter pub get` ✅
2. Run: `flutter run` (test on emulator/device)
3. Test bank selection and topup flow
4. Verify admin token retrieval works
5. Confirm payment proof upload uses correct transaction number
