# 📋 Implementasi Fitur Mutasi (Log Transaksi Saldo)

## ✅ Fitur yang Ditambahkan

### 1. Model Data
**File**: `lib/features/customer/data/models/transaction_mutasi_model.dart`
- Field: id, trxId, userId, username, saldoAwal, saldoAkhir, jumlah, markupAdmin, adminFee, keterangan, createdAt, namaToko
- Formatters untuk display Rupiah
- Deteksi tipe transaksi (debit/credit)

### 2. API Endpoint
**File**: `lib/core/network/api_service.dart`
```dart
Future<Response> getLogTransaksiMutasi(String token)
  → GET https://buysindo.com/api/admin/log-transaksi
```

### 3. UI Tab Mutasi
**File**: `lib/ui/home/customer/tabs/transaction_history_tab.dart`
- Implementasi lengkap seperti prabayar & pascabayar
- Search by Trx ID, Username, atau Keterangan
- Cache dengan SharedPreferences (30 menit validity)
- Pull to refresh
- Loading & error states

### 4. Detail Page & Print
**File**: `lib/ui/home/customer/tabs/templates/transaction_mutasi_detail_page.dart`
- Status card dengan icon debit/credit
- Detail informasi transaksi
- Ringkasan saldo (awal → perubahan → akhir)
- Detail biaya (markup admin + admin fee)
- Print button dengan HTML format
- Professional receipt layout

## 📊 Data Structure

```json
{
  "id": 22266,
  "trx_id": "TRX20260119105813697",
  "user_id": 2229,
  "username": "demoagicell",
  "saldo_awal": "519726",
  "saldo_akhir": "513626",
  "jumlah": "-6100",
  "markup_admin": "200",
  "admin_fee": "50",
  "keterangan": "Xl 5.000",
  "created_at": "2026-01-19 10:58:14"
}
```

## 🎨 UI Features

### Tab Mutasi
- ✅ Search bar untuk mencari Trx ID, Username, atau Keterangan
- ✅ List view dengan kartu transaksi
- ✅ Color coding: Merah untuk pengeluaran, Hijau untuk pemasukan
- ✅ Copy Trx ID button
- ✅ Pull to refresh
- ✅ Cache support

### Detail Page
- ✅ Status card dengan amount besar
- ✅ Informasi transaksi (ID, Tanggal, Username, Toko)
- ✅ Ringkasan saldo visual
- ✅ Detail biaya breakdown
- ✅ Print button
- ✅ Professional HTML receipt template

## 🔄 Data Flow

```
1. User buka tab Mutasi
   ↓
2. Load dari cache (jika ada & valid)
   ↓
3. Jika tidak ada cache → Fetch dari API
   → GET /api/admin/log-transaksi + token
   ↓
4. Parse response → TransactionMutasi model
   ↓
5. Fetch nama_toko dan attach ke setiap transaksi
   ↓
6. Save ke cache SharedPreferences
   ↓
7. Display di list view dengan search/filter
   ↓
8. User klik item → Navigate ke detail page
   ↓
9. Di detail page → bisa lihat detail lengkap & print
```

## 🛠️ Cache Configuration

| Key | Value |
|-----|-------|
| Cache Key | `transaction_mutasi_cache` |
| Timestamp Key | `transaction_mutasi_timestamp` |
| Validity | 30 menit |
| Auto-invalidate | Yes |

## 📱 Features Checklist

| Feature | Status |
|---------|--------|
| API Integration | ✅ |
| Model | ✅ |
| List View | ✅ |
| Search Filter | ✅ |
| Caching | ✅ |
| Store Name | ✅ |
| Detail Page | ✅ |
| Print Receipt | ✅ |
| Responsive Design | ✅ |
| Error Handling | ✅ |
| Loading States | ✅ |

## 🚀 Testing

### Test Scenario 1: Load dari API
1. Clear app cache
2. Buka Transaction History → Mutasi tab
3. Observe: Loading spinner muncul
4. Observe: Data dimuat dari API
5. Observe: List tampil dengan benar

### Test Scenario 2: Search & Filter
1. Ketik di search box
2. Observe: List ter-filter real-time
3. Test dengan Trx ID, Username, Keterangan

### Test Scenario 3: Detail & Print
1. Tap salah satu item
2. Observe: Detail page terbuka
3. Lihat: Saldo, biaya, keterangan
4. Tap print button
5. Observe: HTML preview muncul

### Test Scenario 4: Cache
1. Load data sekali (dari API)
2. Tunggu < 30 menit
3. Buka Mutasi tab lagi
4. Observe: Data dimuat dari cache (cepat)
5. Observe: Refresh button bisa force-refresh dari API

## 📝 Implementation Details

### Search Filter Logic
```dart
_filteredMutasiTransactions = _allMutasiTransactions.where((transaction) {
  bool searchMatch =
      searchQuery.isEmpty ||
      transaction.trxId.toLowerCase().contains(searchQuery.toLowerCase()) ||
      transaction.username.toLowerCase().contains(searchQuery.toLowerCase()) ||
      transaction.keterangan.toLowerCase().contains(searchQuery.toLowerCase());
  return searchMatch;
}).toList();
```

### Sort Order
- By default: Newest first (berdasarkan createdAt)
- Sortir otomatis setiap fetch

### Color Scheme
- **Pengeluaran (Debit)**: Merah (#d32f2f)
- **Pemasukan (Credit)**: Hijau (#388e3c)
- **Saldo**: Orange/Green sesuai status

## 🎯 Next Steps (Optional)

Jika ingin enhance lebih lanjut:
1. **Analytics**: Tambah chart untuk tracking saldo
2. **Export**: Bisa export ke PDF/CSV
3. **Filter Tanggal**: Range picker untuk filter periode
4. **Kategori Biaya**: Group by keterangan/kategori
5. **Statistics**: Total debit/credit per bulan

---

**Status**: ✅ Implementasi Lengkap
**Tested**: Belum (siap untuk testing)
**Last Updated**: 19 Januari 2026
