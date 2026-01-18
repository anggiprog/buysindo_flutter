# Fix: Bluetooth Permission Error

## Masalahnya

Error: **"Izin Bluetooth diperlukan untuk mencetak"**

Muncul ketika user sudah:
- ✅ Aktifkan Bluetooth di device
- ✅ Sandingkan printer thermal
- ❌ Tapi belum memberikan izin ke aplikasi

## Solusi

### 1. **Cara Memberikan Izin Bluetooth ke Aplikasi**

**Di Android:**

1. Buka **Pengaturan** (Settings)
2. Pilih **Aplikasi** (Apps) atau **Aplikasi yang Terinstall**
3. Cari **Buysindo**
4. Pilih **Izin** (Permissions)
5. Aktifkan:
   - ✅ **Bluetooth**
   - ✅ **Nearby Devices** (atau **Bluetooth Device Scanning**)
6. Kembali ke aplikasi Buysindo

### 2. **Update Terbaru**

Saya sudah memperbaiki logika permission check:

**Sebelumnya:**
- Perlu ALL permissions granted ❌ (terlalu ketat)

**Sekarang:**
- Cukup BLUETOOTH_CONNECT ATAU BLUETOOTH_SCAN granted ✅ (lebih fleksibel)

### 3. **Flow Yang Benar**

```
User klik icon printer
    ↓
App meminta izin Bluetooth (permission dialog muncul)
    ↓
User klik "Allow" (Izinkan)
    ↓
✅ Bluetooth devices dialog muncul
    ↓
User pilih printer dari list
    ↓
App connect ke printer
    ↓
Struk tercetak 🖨️
```

### 4. **Jika Masih Tidak Muncul Dialog**

Kemungkinan:
1. **Izin sudah sebelumnya ditolak** → Harus reset atau buka settings
2. **Device Bluetooth printer belum disandingkan** → Sandingkan dulu di Android Settings
3. **Android version < 5.0** → Device terlalu lama

### 5. **Debug Info**

Lihat console untuk melihat status permission:
```
🔵 Bluetooth Permissions requested
📋 Requested statuses: {Permission.bluetoothConnect: PermissionStatus.granted, ...}
✅ BLUETOOTH_CONNECT: true, BLUETOOTH_SCAN: true
```

## Checklist Sebelum Cetak

- [ ] Bluetooth device sudah diaktifkan di Android
- [ ] Printer thermal sudah disandingkan di Android Settings
- [ ] Aplikasi Buysindo sudah diberi izin Bluetooth
- [ ] Printer thermal dalam jarak jangkau
- [ ] Printer thermal dalam kondisi menyala

## Pesan Error yang Mungkin Muncul

| Pesan | Solusi |
|-------|--------|
| "Izin Bluetooth diperlukan. Aktifkan di Pengaturan..." | Buka Settings > Aplikasi > Buysindo > Izin > Bluetooth |
| "Tidak ada printer Bluetooth yang dipasangkan" | Sandingkan printer di Android Settings Bluetooth |
| "Gagal terhubung ke printer" | Pastikan printer dalam jarak jangkau dan menyala |
| "Gagal mencetak struk" | Periksa koneksi printer atau coba ulang |

---

**Catatan:** Setelah memberikan izin sekali, izin akan tetap tersimpan dan user tidak perlu memberikan izin lagi.
