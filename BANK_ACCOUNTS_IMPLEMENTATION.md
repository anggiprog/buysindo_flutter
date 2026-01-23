# Bank Accounts Dynamic Implementation

## Overview
Implemented dynamic bank account display on the TopUp Manual page. Bank accounts are now fetched from the backend API (`/api/rekening-bank`) instead of being hardcoded.

## Changes Made

### 1. Models - `lib/features/topup/models/topup_response_models.dart`
Added two new model classes:

- **`BankAccountResponse`**: Represents the API response containing a list of bank accounts
  - `status`: Response status
  - `data`: List of BankAccount objects

- **`BankAccount`**: Represents individual bank account details
  - `id`: Bank account ID
  - `adminUserId`: Admin user ID
  - `namaBank`: Bank name
  - `nomorRekening`: Account number
  - `atasNamaRekening`: Account holder name
  - `logoBank`: Bank logo URL
  - `jenisPembayaranId`: Payment type ID
  - `superadminUsers`: Superadmin users
  - `status`: Account status
  - `createdAt`: Created timestamp
  - `updatedAt`: Updated timestamp

### 2. API Service - `lib/core/network/api_service.dart`
Added new API method:

```dart
/// Ambil daftar rekening bank untuk pembayaran manual
Future<BankAccountResponse> getBankAccounts(String token) async
```

- Endpoint: `api/rekening-bank`
- Authentication: Bearer token
- Returns: `BankAccountResponse` with list of bank accounts

### 3. TopUp Manual Page - `lib/ui/home/topup/topup_manual.dart`

#### Updated Imports
- Added `app_config.dart` import for accessing `textColor`
- Added `topup_response_models.dart` import for models

#### State Updates
- Added `List<BankAccount> _bankAccounts = []` to store fetched bank accounts

#### Data Fetching
- Combined `_fetchAdminFee()` with bank accounts fetching into `_fetchAdminFeeAndBankAccounts()`
- Uses token authentication from SessionManager
- Handles errors gracefully with fallback to empty list

#### UI Components

**New Widget: `_BankDetailCard`**
- Displays individual bank account information
- Shows bank logo (with fallback to bank icon)
- Displays bank name with custom text color from `AppConfig().textColor`
- Shows account holder name (Atas Nama) - copyable
- Shows account number (No. Rekening) - copyable
- Copy functionality with clipboard support and feedback snackbar

**New Widget: `_BankDetailRow`**
- Reusable component for displaying bank detail rows
- Label and value layout
- Optional copy icon with callback
- Uses text color from app config

**Updated Bank Details Card**
- Replaced static 3-field display with dynamic ListView
- Displays all available bank accounts from backend
- Shows "Tidak ada rekening tersedia" if no accounts exist
- Each bank account displayed in a separate card with proper spacing

## Features

✅ **Token Authentication**: All API calls use bearer token authentication
✅ **Copyable Fields**: Both account holder name and account number are copyable
✅ **Dynamic Styling**: Bank information uses `textColor` from `AppConfig`
✅ **Bank Logos**: Displays bank logos from backend URLs with fallback icons
✅ **Error Handling**: Graceful error handling with user feedback
✅ **Loading State**: Shows loading indicator while fetching data
✅ **Multiple Accounts**: Supports displaying multiple bank accounts from backend
✅ **Responsive Design**: Proper spacing and layout for multiple accounts

## API Response Format

Expected response from `/api/rekening-bank`:

```json
{
    "status": "success",
    "data": [
        {
            "id": 3461,
            "admin_user_id": 1050,
            "nama_bank": "Bank Neo Commerce",
            "nomor_rekening": "5859459401274500",
            "atas_nama_rekening": "Anggiansyah",
            "logo_bank": "https://tuwaga.id/wp-content/uploads/2025/01/FI029-_-Bank-Neo-Commerce-10.png",
            "jenis_pembayaran_id": null,
            "superadmin_users": null,
            "status": "0",
            "created_at": "2025-08-24T09:51:32.000000Z",
            "updated_at": "2025-08-24T09:51:32.000000Z"
        },
        {
            "id": 3553,
            "admin_user_id": 1050,
            "nama_bank": "BCA",
            "nomor_rekening": "5321513213213",
            "atas_nama_rekening": "ANGGIANSYAH",
            "logo_bank": "https://www.bing.com/th/id/OIP.taUZzLgaZLC-BRARyDrXYAHaHa?w=186&h=211&c=8&rs=1&qlt=90&o=6&pid=3.1&rm=2",
            "jenis_pembayaran_id": null,
            "superadmin_users": null,
            "status": "0",
            "created_at": "2025-09-19T05:01:51.000000Z",
            "updated_at": "2025-09-19T05:01:51.000000Z"
        }
    ]
}
```

## Testing

1. Build and run the application
2. Navigate to the Top Up Manual page
3. Verify:
   - Bank accounts are loaded dynamically
   - Bank logos display correctly
   - Account names and numbers are copyable
   - Copy buttons show confirmation snackbar
   - Text colors match app configuration
   - Multiple accounts display properly

## Files Modified

1. `lib/core/network/api_service.dart` - Added `getBankAccounts()` method
2. `lib/features/topup/models/topup_response_models.dart` - Added `BankAccount` and `BankAccountResponse` models
3. `lib/ui/home/topup/topup_manual.dart` - Updated UI to display dynamic bank accounts
