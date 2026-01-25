# PLN Pascabayar - API Integration Guide

## API Endpoints

### 1. Get Product Info
**URL:** `https://buysindo.com/api/pascabayar`  
**Method:** `GET`  
**Query Parameters:**
- `brand=PLN PASCABAYAR` (optional filter)

**Response Structure:**
```json
{
  "product_name": "Pln Pascabayar",
  "buyer_sku_code": "pln",
  "admin": "3000",
  "commission": "1988",
  "category": "Pascabayar",
  "brand": "PLN PASCABAYAR",
  "seller_name": "PT Billfazz Teknologi Nusantara",
  "price": "0",
  "admin_fee": "100",
  "markup_admin": "0",
  "produk_diskon": "0",
  "total_harga": "100",
  "buyer_product_status": true,
  "seller_product_status": true,
  "desc": "-"
}
```

**Used in:** `pln_pascabayar.dart` → `_loadProductInfo()`

---

### 2. Check Bill (Cek Tagihan)
**URL:** `https://buysindo.com/api/v2/pln-pascabayar/cek-tagihan`  
**Method:** `POST`  
**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "admin_user_id": "1050",
  "customer_no": "530000000001",
  "product_name": "Pln Pascabayar",
  "brand": "PLN PASCABAYAR",
  "buyer_sku_code": "pln"
}
```

**Response Structure:**
```json
{
  "status": "success",
  "message": "Transaksi Sukses",
  "ref_id": "6974c5b12d36f",
  "product_name": "Pln Pascabayar",
  "buyer_sku_code": "pln",
  "brand": "PLN PASCABAYAR",
  "customer_name": "Nama Pelanggan Pertama",
  "customer_no": "530000000001",
  "periode": "201901",
  "tagihan": 8000,
  "admin": 2600,
  "denda": 500,
  "total_tagihan": 11100,
  "lembar_tagihan": 1
}
```

**Used in:** `cek_tagihan.dart` → `_checkBill()`

---

## Flow Diagram

```
┌──────────────────────────────────────────┐
│  1. Open PLN Pascabayar Page            │
│     (pln_pascabayar.dart)                │
└───────────────┬──────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────┐
│  2. Load Product Info                    │
│     GET /api/pascabayar                  │
│     Filter: brand=PLN PASCABAYAR         │
└───────────────┬──────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────┐
│  3. Display Product Information          │
│     - Product Name                       │
│     - Brand                              │
│     - SKU Code                           │
│     - Admin Fee                          │
│     - Commission                         │
└───────────────┬──────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────┐
│  4. User Clicks "Cek Tagihan" Button     │
└───────────────┬──────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────┐
│  5. Open Bottom Sheet                    │
│     (cek_tagihan.dart)                   │
│     CekTagihanPascabayar.showCekTagihan()│
└───────────────┬──────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────┐
│  6. User Inputs Customer Number          │
│     - Manual input OR                    │
│     - Barcode scanner                    │
└───────────────┬──────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────┐
│  7. User Clicks "Cek Tagihan"            │
│     POST /api/v2/pln-pascabayar/cek-tagihan│
│     Request:                             │
│     - admin_user_id                      │
│     - customer_no                        │
│     - product_name                       │
│     - brand                              │
│     - buyer_sku_code                     │
└───────────────┬──────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────┐
│  8. Display Bill Details                 │
│     - Customer Name                      │
│     - Customer No                        │
│     - Periode                            │
│     - Tagihan (Bill Amount)              │
│     - Admin (Admin Fee)                  │
│     - Denda (Penalty)                    │
│     - Total Tagihan (Total)              │
│     - Lembar Tagihan (Bill Sheets)       │
└───────────────┬──────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────┐
│  9. User Confirms "Lanjutkan Pembayaran" │
│     Return bill data to parent           │
└───────────────┬──────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────┐
│ 10. Back to PLN Pascabayar Page          │
│     Display bill details                 │
│     User enters PIN                      │
│     Process payment                      │
└──────────────────────────────────────────┘
```

---

## Response Field Mapping

### From Product API to Flutter State
| API Field            | Flutter Variable      | Type    | Description                    |
|----------------------|-----------------------|---------|--------------------------------|
| `product_name`       | `product_name`        | String  | Nama produk                    |
| `buyer_sku_code`     | `buyer_sku_code`      | String  | SKU code untuk buyer           |
| `brand`              | `brand`               | String  | Brand produk (PLN PASCABAYAR)  |
| `admin`              | `admin`               | String  | Biaya admin dari provider      |
| `admin_fee`          | `admin_fee`           | String  | Fee admin tambahan             |
| `commission`         | `commission`          | String  | Komisi                         |
| `seller_name`        | `seller_name`         | String  | Nama seller/provider           |
| `desc`               | `desc`                | String  | Deskripsi produk               |

### From Check Bill API to Flutter State
| API Field            | Flutter Variable      | Type    | Description                    |
|----------------------|-----------------------|---------|--------------------------------|
| `status`             | `status`              | String  | success/failed                 |
| `message`            | `message`             | String  | Message response               |
| `ref_id`             | `ref_id`              | String  | Reference ID transaksi         |
| `product_name`       | `product_name`        | String  | Nama produk                    |
| `buyer_sku_code`     | `buyer_sku_code`      | String  | SKU code                       |
| `brand`              | `brand`               | String  | Brand                          |
| `customer_name`      | `customer_name`       | String  | Nama pelanggan                 |
| `customer_no`        | `customer_no`         | String  | Nomor pelanggan                |
| `periode`            | `periode`             | String  | Periode tagihan (YYYYMM)       |
| `tagihan`            | `tagihan`             | int     | Jumlah tagihan listrik         |
| `admin`              | `admin`               | int     | Biaya admin                    |
| `denda`              | `denda`               | int     | Denda keterlambatan            |
| `total_tagihan`      | `total_tagihan`       | int     | Total yang harus dibayar       |
| `lembar_tagihan`     | `lembar_tagihan`      | int     | Jumlah lembar tagihan          |

---

## File Structure

```
lib/ui/home/customer/tabs/templates/pascabayar/
├── pln_pascabayar.dart          # Main PLN Pascabayar page
├── cek_tagihan.dart             # Global bottom sheet untuk cek tagihan
├── CEK_TAGIHAN_DOKUMENTASI.md
└── CONTOH_PENGGUNAAN_CEK_TAGIHAN.dart
```

---

## Code Implementation

### 1. Load Product Info (pln_pascabayar.dart)

```dart
Future<void> _loadProductInfo() async {
  setState(() => _isLoadingProduct = true);

  try {
    final token = await SessionManager.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    // Fetch products dari API pascabayar
    final response = await _apiService.getProducts(token);

    // Cari produk PLN PASCABAYAR
    final plnProduct = response.firstWhere(
      (product) => product.brand?.toUpperCase() == 'PLN PASCABAYAR',
      orElse: () => throw Exception('Produk PLN Pascabayar tidak ditemukan'),
    );

    if (mounted) {
      setState(() {
        _productInfo = {
          'product_name': plnProduct.productName,
          'buyer_sku_code': plnProduct.buyerSkuCode,
          'brand': plnProduct.brand,
          'admin': plnProduct.admin,
          'admin_fee': plnProduct.adminFee,
          'commission': plnProduct.commission,
          'seller_name': plnProduct.sellerName,
          'desc': plnProduct.desc,
        };
        _isLoadingProduct = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoadingProduct = false);
      _showSnackbar('Error: ${e.toString()}', Colors.red);
    }
  }
}
```

### 2. Check Bill (cek_tagihan.dart)

```dart
Future<void> _checkBill() async {
  if (_customerNoController.text.isEmpty) {
    _showSnackbar('Masukkan nomor pelanggan terlebih dahulu', Colors.orange);
    return;
  }

  setState(() {
    _isLoading = true;
    _billData = null;
  });

  try {
    final token = await SessionManager.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    final response = await _apiService.checkPascabayarBill(
      adminUserId: widget.adminUserId,
      customerNo: _customerNoController.text.trim(),
      productName: widget.productName,
      brand: widget.brand,
      buyerSkuCode: widget.buyerSkuCode,
      token: token,
    );

    if (response.statusCode == 200) {
      final responseData = response.data;

      if (responseData['status'] == 'success') {
        final billData = {
          'status': responseData['status'],
          'message': responseData['message'],
          'ref_id': responseData['ref_id'],
          'product_name': responseData['product_name'],
          'buyer_sku_code': responseData['buyer_sku_code'],
          'brand': responseData['brand'],
          'customer_name': responseData['customer_name'],
          'customer_no': responseData['customer_no'],
          'periode': responseData['periode'],
          'tagihan': responseData['tagihan'],
          'admin': responseData['admin'],
          'denda': responseData['denda'] ?? 0,
          'total_tagihan': responseData['total_tagihan'],
          'lembar_tagihan': responseData['lembar_tagihan'] ?? 1,
        };

        await _cacheCustomerNo(_customerNoController.text.trim());

        if (mounted) {
          setState(() {
            _billData = billData;
            _isLoading = false;
          });

          _showSnackbar('Tagihan berhasil ditemukan', Colors.green);
        }
      } else {
        throw Exception(responseData['message'] ?? 'Gagal mengambil tagihan');
      }
    } else {
      throw Exception('Gagal mengambil tagihan');
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      _showSnackbar('Error: ${e.toString()}', Colors.red);
    }
  }
}
```

### 3. ApiService Method (api_service.dart)

```dart
Future<Response> checkPascabayarBill({
  required int adminUserId,
  required String customerNo,
  required String productName,
  required String brand,
  required String buyerSkuCode,
  required String token,
}) async {
  final response = await _dio.post(
    'api/v2/pln-pascabayar/cek-tagihan',
    data: {
      'admin_user_id': adminUserId.toString(),
      'customer_no': customerNo,
      'product_name': productName,
      'brand': brand,
      'buyer_sku_code': buyerSkuCode,
    },
    options: Options(
      headers: {'Authorization': 'Bearer $token'},
    ),
  );
  return response;
}
```

---

## Testing Guide

### Test Case 1: Load Product Info
1. Open PLN Pascabayar page
2. **Expected:** Product info loads and displays
3. **Verify:**
   - Product Name: "Pln Pascabayar"
   - Brand: "PLN PASCABAYAR"
   - SKU Code: "pln"
   - Admin: "3000"
   - Admin Fee: "100"

### Test Case 2: Check Bill - Valid Customer
1. Click "Cek Tagihan" button
2. Enter customer number: `530000000001`
3. Click "Cek Tagihan"
4. **Expected:** Bottom sheet shows bill details
5. **Verify:**
   - Customer name displayed
   - Customer number matches input
   - Periode shown
   - Tagihan amount displayed
   - Admin fee displayed
   - Denda (if any) displayed
   - Total tagihan calculated correctly

### Test Case 3: Check Bill - Invalid Customer
1. Click "Cek Tagihan" button
2. Enter invalid customer number
3. Click "Cek Tagihan"
4. **Expected:** Error message displayed

### Test Case 4: Barcode Scanner
1. Click "Cek Tagihan" button
2. Click barcode scanner icon
3. Scan customer number barcode
4. **Expected:** Customer number auto-filled
5. Click "Cek Tagihan"
6. **Expected:** Bill details loaded

### Test Case 5: Complete Payment Flow
1. Load product info ✓
2. Check bill ✓
3. Confirm bill details ✓
4. Enter PIN
5. Click "Bayar Tagihan"
6. **Expected:** Payment processed successfully

---

## Error Handling

### Common Errors
1. **Token not found**
   - Message: "Token tidak ditemukan"
   - Action: User should re-login

2. **Product not found**
   - Message: "Produk PLN Pascabayar tidak ditemukan"
   - Action: Contact admin

3. **Invalid customer number**
   - Message from backend
   - Action: User should verify customer number

4. **Network error**
   - Message: Connection error
   - Action: Check internet connection

---

## Caching Strategy

### Product Info Cache
- **Key:** `pln_pascabayar_product_info`
- **Expiry:** 24 hours
- **Update:** On app start or manual refresh

### Customer Number Cache
- **Key:** `last_customer_no_PLN PASCABAYAR`
- **Expiry:** Never (manual clear)
- **Update:** After successful bill check

### Bill Data Cache
- **Key:** `pln_pascabayar_last_bill`
- **Expiry:** 5 minutes
- **Update:** After successful bill check

---

## UI/UX Features

✅ **Animated Bottom Sheet** - Smooth slide from bottom  
✅ **Loading States** - Show loading indicator during API calls  
✅ **Error Handling** - User-friendly error messages  
✅ **Auto-fill** - Pre-fill customer number from cache  
✅ **Barcode Scanner** - Quick input via camera  
✅ **Gradient UI** - Modern design with shadows  
✅ **Responsive** - Adapts to keyboard height  
✅ **Validation** - Input validation before API call  

---

## Notes

- All amounts (tagihan, admin, denda, total_tagihan) are in **Rupiah (IDR)**
- Periode format: **YYYYMM** (e.g., "201901" = January 2019)
- Customer number must be **numeric only**
- Barcode scanner requires **camera permission**
- Bottom sheet is **reusable** for other pascabayar products (BPJS, Telkom, etc.)
