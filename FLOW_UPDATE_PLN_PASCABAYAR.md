# Flow Update PLN Pascabayar

## Perubahan Flow
Flow PLN Pascabayar telah diupdate untuk menampilkan informasi produk terlebih dahulu sebelum cek tagihan.

### Flow Baru:
1. **Load Halaman PLN Pascabayar**
   - Page: `lib/ui/home/customer/tabs/templates/pascabayar/pln_pascabayar.dart`
   - Auto load product info dari API

2. **Tampilan Product Info**
   - Fetch dari: `GET https://buysindo.com/api/pascabayar?brand=PLN PASCABAYAR`
   - Tampilkan:
     - Product Name
     - Brand
     - SKU Code (buyer_sku_code)
     - Biaya Admin
     - Admin Fee

3. **Klik Button "Cek Tagihan"**
   - Membuka bottom sheet dari `cek_tagihan.dart`
   - Tidak perlu input customer ID di halaman utama
   - Pass data produk ke bottom sheet

4. **Bottom Sheet Cek Tagihan**
   - File: `lib/ui/home/customer/tabs/templates/pascabayar/cek_tagihan.dart`
   - Widget global: `CekTagihanPascabayar.showCekTagihan()`
   - User input nomor pelanggan
   - Support barcode scanner
   - Call API: `POST https://buysindo.com/api/v2/pln-pascabayar/cek-tagihan`

5. **Response dari API**
   - Backend response structure:
     ```json
     {
       "status": "success",
       "customer_name": "...",
       "customer_no": "...",
       "periode": "...",
       "tagihan": 350000,
       "admin": 3100,
       "denda": 0,
       "total_tagihan": 353100,
       "ref_id": "..."
     }
     ```

6. **Konfirmasi Bill di Bottom Sheet**
   - Tampilkan detail tagihan
   - Button "Lanjutkan Pembayaran"
   - Return bill data ke halaman utama

7. **Payment Flow**
   - Bill data ditampilkan di halaman utama
   - Input PIN
   - Klik "Bayar Tagihan"
   - Process payment via API

## File Structure
```
lib/ui/home/customer/tabs/templates/pascabayar/
├── cek_tagihan.dart          # Global widget untuk cek tagihan (bottom sheet)
├── pln_pascabayar.dart       # PLN Pascabayar main page
├── CEK_TAGIHAN_DOKUMENTASI.md
└── CONTOH_PENGGUNAAN_CEK_TAGIHAN.dart
```

## Response Field Mapping
| Backend Response    | Flutter Variable    |
|---------------------|---------------------|
| `customer_name`     | `customer_name`     |
| `customer_no`       | `customer_no`       |
| `periode`           | `periode`           |
| `tagihan`           | `tagihan`           |
| `admin`             | `admin`             |
| `denda`             | `denda`             |
| `total_tagihan`     | `total_tagihan`     |
| `ref_id`            | `ref_id`            |

## API Integration

### 1. Get Product Info
**Endpoint:** `GET /api/pascabayar`
**Query Params:** `brand=PLN PASCABAYAR`
**Method:** `_loadProductInfo()` in pln_pascabayar.dart

### 2. Check Bill
**Endpoint:** `POST /api/v2/pln-pascabayar/cek-tagihan`
**Params:**
- `admin_user_id`
- `customer_no`
- `product_name`
- `brand`
- `buyer_sku_code`

**Method:** `checkPascabayarBill()` in ApiService

### 3. Pay Bill
**Endpoint:** `POST /api/pay-pln-pascabayar`
**Params:**
- `customer_id`
- `pin`
- `total_amount`

## UI Components

### 1. Product Info Card (`_buildProductInfo`)
- Menampilkan informasi produk dari API
- Background: White dengan shadow
- Icon: Info outline
- Fields: Product name, brand, SKU code, admin, admin fee

### 2. Cek Tagihan Button (`_buildCekTagihanButton`)
- Full width button
- Primary color background
- Icon: Search
- Text: "Cek Tagihan"
- Action: Open bottom sheet

### 3. Bottom Sheet (CekTagihanPascabayar)
- Animated slide from bottom
- Input customer number
- Barcode scanner integration
- API call untuk cek tagihan
- Display bill details
- Confirmation button

### 4. Bill Details Card (`_buildBillDetails`)
- Tampilkan setelah cek tagihan success
- Fields:
  - Nama pelanggan
  - ID pelanggan
  - Periode
  - Tagihan listrik
  - Biaya admin
  - Denda (jika ada)
  - Total bayar

## Caching
- **Product Info:** Cached di SharedPreferences
- **Customer Number:** Cached per brand `last_customer_no_{brand}`
- **Bill Data:** Cached dengan expiry 5 menit

## Features
✅ Global cek tagihan widget (reusable)
✅ Barcode scanner untuk customer number
✅ Bottom sheet dengan animations
✅ Response mapping sesuai backend
✅ SharedPreferences caching
✅ Auto pre-fill customer number dari cache
✅ Field validation
✅ Error handling
✅ Beautiful UI dengan gradient dan shadows

## Testing Checklist
- [ ] Load product info berhasil
- [ ] Tampilan product info sesuai
- [ ] Button cek tagihan muncul setelah product info load
- [ ] Bottom sheet muncul dengan animasi
- [ ] Input customer number berfungsi
- [ ] Barcode scanner berfungsi
- [ ] API cek tagihan berhasil
- [ ] Response mapping benar
- [ ] Bill details tampil sesuai
- [ ] Konfirmasi dan kembali ke halaman utama
- [ ] Payment flow berfungsi
