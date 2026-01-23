# Bank Selection Visual Indicator Summary

## UI Changes Overview

### Before
```
Bank Card (No Visual Feedback)
┌─────────────────────────────────┐
│  [Logo]  Bank Name              │  <- No indication of selection
│          Tap logo untuk preview  │
├─────────────────────────────────┤
│ Atas Nama: XXX                  │
│ No. Rekening: XXXX              │
└─────────────────────────────────┘
```

### After - Unselected
```
Bank Card (Unselected State)
┌─────────────────────────────────┐
│  [Logo]  Bank Name          [○]  │  <- Empty radio button
│          Tap logo preview    │   │
├─────────────────────────────────┤
│ Atas Nama: XXX                  │
│ No. Rekening: XXXX              │
└─────────────────────────────────┘
```

### After - Selected
```
Bank Card (Selected State - With Blue Highlight)
╔═════════════════════════════════╗  <- Thicker border (2.5px)
║  [Logo]  Bank Name          [✓]  ║  <- Green checkmark
║          Tap logo preview   ║    ║
╠═════════════════════════════════╣  <- Blue background
║ Atas Nama: XXX                  ║
║ No. Rekening: XXXX              ║
╚═════════════════════════════════╝
 └─ Shadow effect (glow)
```

## Selection State Indicators

| State | Icon | Container Color | Border Color | Background | Shadow |
|-------|------|-----------------|--------------|------------|--------|
| **Unselected** | ○ (empty circle) | Grey[300] | Grey[300] (1px) | Grey[100] | None |
| **Selected** | ✓ (checkmark) | Primary Color | Primary Color (2.5px) | Blue[opacity 0.1] | Primary[opacity 0.2] |

## Code Changes

### 1. _BankDetailCard Constructor (line 636)
```dart
class _BankDetailCard extends StatelessWidget {
  final BankAccount bank;
  final Color primaryColor;
  final Function(BankAccount)? onSelected;
  final BankAccount? selectedBank;  // ← NEW: Track which bank is selected
  
  const _BankDetailCard({
    required this.bank,
    required this.primaryColor,
    this.onSelected,
    this.selectedBank,  // ← NEW: Pass current selection
  });
```

### 2. Build Method (line 743-761)
```dart
@override
Widget build(BuildContext context) {
  final textColor = AppConfig().textColor;
  final isSelected = selectedBank?.id == bank.id;  // ← NEW: Check if this bank is selected
  
  // ... build with dynamic styling based on isSelected
}
```

### 3. Container Decoration (line 755-760)
```dart
decoration: BoxDecoration(
  color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[100],  // ← NEW: Blue tint when selected
  borderRadius: BorderRadius.circular(10),
  border: Border.all(
    color: isSelected ? primaryColor : Colors.grey[300]!,  // ← NEW: Primary color when selected
    width: isSelected ? 2.5 : 1,  // ← NEW: Thicker border when selected
  ),
  boxShadow: isSelected  // ← NEW: Shadow glow when selected
      ? [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ]
      : [],
),
```

### 4. Selection Indicator Widget (line 815-834)
```dart
// Selection Indicator - appears on right side of card
if (isSelected)
  Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: primaryColor,
      shape: BoxShape.circle,
    ),
    child: const Icon(
      Icons.check,  // ✓ Checkmark
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
      Icons.radio_button_unchecked,  // ○ Empty circle
      color: Colors.grey[600],
      size: 20,
    ),
  ),
```

### 5. Item Builder Call (line 420)
```dart
itemBuilder: (context, index) {
  final bank = _bankAccounts[index];
  return _BankDetailCard(
    bank: bank,
    primaryColor: widget.primaryColor,
    selectedBank: _selectedBank,  // ← NEW: Pass currently selected bank
    onSelected: (selectedBank) {
      setState(() {
        _selectedBank = selectedBank;  // ← Update state when bank is tapped
      });
    },
  );
},
```

## User Interaction Flow

1. **View Bank List**: All banks show ○ (empty circle) indicator
2. **Tap Bank**: 
   - Selected bank shows ✓ (checkmark) indicator
   - Background turns blue with shadow
   - Border becomes thicker and changes to primary color
3. **Tap Another Bank**:
   - Previous bank reverts to ○ with grey background
   - New bank shows ✓ with blue background
4. **Tap "Saya Sudah Transfer"**:
   - Validates that _selectedBank is not null
   - Uses _selectedBank data (bank name, account number)
   - Calls topUpSaldo() API with selected bank information

## Admin Token Fix

### Before (Error)
```dart
String? adminToken = adminTokenResponse.data['token'] as String?;
// ❌ Returns null because 'token' is not at root level
```

### After (Fixed)
```dart
String? adminToken;
final responseData = adminTokenResponse.data;

if (responseData is Map) {
  // Primary: Check nested array structure
  final dataArray = responseData['data'];
  if (dataArray is List && dataArray.isNotEmpty) {
    final firstItem = dataArray[0];
    if (firstItem is Map) {
      adminToken = firstItem['token'] as String?;  // ✓ Correct access
    }
  }
  // Fallback: Check root level
  if (adminToken == null || (adminToken != null && adminToken.isEmpty)) {
    adminToken = responseData['token'] as String?;
  }
}
```

Response structure handled:
```json
{
  "status": "success",
  "data": [
    {
      "token": "NM3dTOb3aBYzVI9prZaVi2wL6GGqh7qCTBklOXc5017B6H3AnyjpkRZ4GaPS"
    }
  ]
}
```

## Testing Recommendations

### Visual Tests
- [ ] Launch app and navigate to TopUp Manual
- [ ] Verify all banks display with ○ indicator
- [ ] Tap each bank and verify:
  - [ ] ✓ appears only on tapped bank
  - [ ] Blue background appears on tapped bank
  - [ ] Border becomes thicker and blue
  - [ ] Shadow glow appears
  - [ ] Previous selection reverts to ○ and grey
- [ ] Verify smooth transition between selections

### Functional Tests
- [ ] Tap "Saya Sudah Transfer" without selecting bank → Error message
- [ ] Select bank, tap "Saya Sudah Transfer" → API call succeeds
- [ ] Admin token is retrieved correctly (check logs)
- [ ] nomorTransaksi is generated and returned
- [ ] Navigation to TopupKonfirmasi passes correct data
- [ ] Payment proof upload uses returned transaction number
