# Transaction Success Page Refactor

## Overview
Memisahkan success dialog menjadi halaman terpisah yang reusable untuk semua produk (prabayar, data, voucher, dll).

## Perubahan Utama

### 1. **File Baru: `transaction_success_page.dart`**

Halaman sukses transaksi yang **reusable** untuk semua jenis produk.

**Fitur:**
- ✅ Loading state dengan verification counter (2 detik)
- ✅ Status progress tracker (Transaksi dikirim → Verifikasi ID → Selesai)
- ✅ Automatic transaction verification setelah loading
- ✅ Retry mechanism jika transaksi tidak ditemukan
- ✅ Error state dengan "Coba Lagi" button
- ✅ Success state menampilkan detail transaksi
- ✅ Copy-able transaction ID dan reference code (long press)
- ✅ Dual buttons: "Selesai" dan "Lihat Detail"

**Constructor Parameters:**
```dart
TransactionSuccessPage(
  productName: String,           // Nama produk (Prabayar, Data, Voucher, dll)
  phoneNumber: String,           // Nomor tujuan transaksi
  totalPrice: int,               // Harga total
  transaction: TransactionResponse, // Response dari backend
)
```

**Reusability:**
Dapat digunakan untuk semua produk karena menggunakan parameter generik:
- Prabayar (pulsa, SMS)
- Data
- Voucher
- Produk lainnya

---

### 2. **Update: `detail_pulsa_page.dart`**

**Perubahan:**
1. **Hapus:** Method `_showSuccessDialog()` dan `_buildSuccessInfo()`
   - Kedua method dipindah ke `TransactionSuccessPage`

2. **Update:** Method `_processTransaction()`
   ```dart
   // BEFORE: Tampilkan dialog
   if (transaction.status) {
     _showSuccessDialog(transaction);
   }
   
   // AFTER: Navigate ke success page
   if (transaction.status) {
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => TransactionSuccessPage(
           productName: widget.product.productName,
           phoneNumber: widget.phone,
           totalPrice: widget.product.totalHarga,
           transaction: transaction,
         ),
       ),
     );
   }
   ```

3. **Tambah:** Import untuk `TransactionSuccessPage`

---

### 3. **Update: `transaction_detail_page.dart`**

**Perbaikan:**
1. **Improve Transaction Finding Logic:**
   - Sebelum: Hanya cari berdasarkan `refId`
   - Sesudah: Cari berdasarkan `refId` ATAU `id` (transaction ID)
   ```dart
   transaction = detailResponse.data.firstWhere(
     (t) =>
         t.refId == widget.refId ||
         t.id.toString() == widget.transactionId,
   );
   ```

2. **Add Retry Mechanism:**
   - Jika transaksi tidak ditemukan di attempt pertama
   - Tunggu 2 detik kemudian retry
   - Debug log menampilkan transaction ID yang tersedia
   ```dart
   if (transaction == null && mounted) {
     debugPrint('⚠️ Transaction not found on first attempt');
     await Future.delayed(const Duration(seconds: 2));
     _loadTransactionDetail(); // Recursive call
   }
   ```

3. **Improve Error UI:**
   - Tambah "Coba Lagi" button selain "Kembali"
   - User bisa retry tanpa keluar halaman
   ```dart
   Row(
     mainAxisAlignment: MainAxisAlignment.center,
     children: [
       ElevatedButton(
         onPressed: _loadTransactionDetail,
         child: const Text('Coba Lagi'),
       ),
       const SizedBox(width: 12),
       OutlinedButton(
         onPressed: () => Navigator.pop(context),
         child: const Text('Kembali'),
       ),
     ],
   )
   ```

---

## Flow Diagram

### Sebelum (Dialog-based)
```
DetailPulsaPage (Checkout)
    ↓
_processTransaction()
    ↓
Success → _showSuccessDialog() [Dialog, Modal]
    ↓
"Lihat Detail" → TransactionDetailPage
```

### Sesudah (Page-based, Reusable)
```
DetailPulsaPage (Checkout)
    ↓
_processTransaction()
    ↓
Success → Navigate to TransactionSuccessPage [Full Page, Loading State]
    ↓
TransactionSuccessPage (Loading 2 sec, Verify Transaction)
    ↓
Found → Show Success with Detail
    ↓
"Lihat Detail" → TransactionDetailPage (dengan retry)
```

---

## Benefits

### ✅ Reusability
- Satu halaman success untuk semua produk
- Cukup ubah `productName`, `phoneNumber`, `totalPrice`
- Tidak perlu duplicated code untuk produk lain

### ✅ Better UX
- Loading state yang jelas ketika verifikasi transaksi
- Automatic retry jika transaksi belum appear di database
- Progress tracker menunjukkan status proses
- Error handling dengan retry button

### ✅ Cleaner Code
- `detail_pulsa_page.dart` lebih sederhana, fokus di checkout flow
- Separation of concerns: checkout logic vs success display
- Easier to maintain dan modify

### ✅ Transaction Verification
- Halaman success tidak langsung ke detail
- Tunggu verifikasi transaksi dari backend terlebih dahulu
- Reduce "Transaksi tidak ditemukan" error

---

## Usage Example

### Untuk Prabayar (Pulsa)
```dart
// Di detail_pulsa_page.dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TransactionSuccessPage(
      productName: 'Pulsa Indosat 5GB',
      phoneNumber: '08123456789',
      totalPrice: 50000,
      transaction: transactionResponse,
    ),
  ),
);
```

### Untuk Data (Future)
```dart
// Di detail_data_page.dart (ketika ditambah)
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TransactionSuccessPage(
      productName: 'Paket Data 25GB',
      phoneNumber: '08123456789',
      totalPrice: 150000,
      transaction: transactionResponse,
    ),
  ),
);
```

### Untuk Voucher (Future)
```dart
// Di detail_voucher_page.dart (ketika ditambah)
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TransactionSuccessPage(
      productName: 'Google Play Voucher 100K',
      phoneNumber: emailAddress,
      totalPrice: 100000,
      transaction: transactionResponse,
    ),
  ),
);
```

---

## Technical Details

### API Integration
- `TransactionSuccessPage` otomatis panggil `getTransactionDetailPrabayar()` API
- Tunggu 2 detik sebelum verifikasi (time for backend to process)
- Retry otomatis jika transaksi belum di database

### Retry Logic
```dart
_verifyTransaction() {
  // 1. Tunggu 2 detik
  await Future.delayed(const Duration(seconds: 2));
  
  // 2. Fetch dari API
  final response = await _apiService.getTransactionDetailPrabayar(token);
  
  // 3. Cari transaction
  final transaction = detailResponse.data.firstWhere((t) =>
      t.refId == widget.transaction.referenceCode ||
      t.id.toString() == widget.transaction.transactionId);
  
  // 4. Jika tidak ada, retry lagi
  if (transaction == null && mounted) {
    await Future.delayed(const Duration(seconds: 2));
    _verifyTransaction(); // Recursive
  }
}
```

---

## Testing Checklist

- [ ] Test transaction success di prabayar (pulsa)
- [ ] Verify loading state muncul 2 detik
- [ ] Verify progress tracker bertransisi
- [ ] Click "Lihat Detail" → masuk transaction detail page
- [ ] Click "Selesai" → kembali ke home
- [ ] Copy transaction ID dengan long press
- [ ] Copy reference code dengan long press
- [ ] Test retry di transaction detail page
- [ ] Test dengan network error (coba lagi harus work)
- [ ] Prepare untuk produk lain (data, voucher)

---

## Files Modified

| File | Changes |
|------|---------|
| `transaction_success_page.dart` | ✅ CREATED (New) |
| `detail_pulsa_page.dart` | ✅ UPDATED (Removed dialog, added navigation) |
| `transaction_detail_page.dart` | ✅ UPDATED (Improved retry logic, better error UI) |

---

## Next Steps

1. **Test di device atau emulator**
2. **Implement thermal printer di `_printThermal()`**
3. **Add untuk produk lain (data, voucher)** dengan reuse `TransactionSuccessPage`
4. **Monitor user feedback** tentang loading time dan retry mechanism
