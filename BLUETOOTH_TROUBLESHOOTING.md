# 🚨 Bluetooth Printer Troubleshooting

## ⚠️ Masalah: "Tidak Ada Printer Ditemukan"

### Quick Checklist (Lakukan Berturut-turut):

✅ **1. Cek Device Bluetooth**
```
Pengaturan > Bluetooth
- Pastikan Bluetooth ON
- Pastikan printer terlihat di list perangkat yang terhubung
- Jika belum: Hubungkan printer terlebih dahulu
```

✅ **2. Restart Bluetooth**
```
1. Matikan Bluetooth di Pengaturan
2. Tunggu 3 detik
3. Nyalakan kembali
```

✅ **3. Cek Izin Aplikasi**
```
Pengaturan > Aplikasi > Buysindo
- Pilih "Izin"
- Pastikan "Bluetooth" = DIIZINKAN
- Pastikan "Lokasi" = DIIZINKAN (diperlukan untuk scan Bluetooth)
```

✅ **4. Buka Ulang Aplikasi**
```
1. Tutup aplikasi Buysindo
2. Tunggu 2 detik
3. Buka kembali
```

✅ **5. Lihat Debug Info**
Saat membuka fitur Print/Share:
- Layar akan menampilkan "🔧 DEBUG INFO"
- Lihat berapa device yang ditemukan
- Jika 0 device: Printer belum terhubung

---

## 📋 Android Version Specific Issues

### Android 12+ (Versi Terbaru)
**Masalah**: Permission BLUETOOTH_SCAN/CONNECT tidak granted
**Solusi**:
1. Buka Pengaturan > Aplikasi > Buysindo > Izin
2. Aktifkan "Bluetooth" dan "Lokasi Tepat"
3. Restart aplikasi

### Android 10-11
**Masalah**: Izin lokasi diperlukan untuk Bluetooth
**Solusi**:
1. Buka Pengaturan > Aplikasi > Buysindo > Izin
2. Aktifkan "Lokasi Tepat" dan "Bluetooth"

---

## 🔍 Debug Log untuk Developer

Jalankan command ini untuk melihat detail error:

```bash
# Terminal 1: Jalankan aplikasi
flutter run -v

# Terminal 2: Lihat Bluetooth logs
adb logcat | grep -E "(bluetooth|getPairedDevices|Discovery)"
```

**Output yang diharapkan jika berhasil:**
```
✅ Permissions granted: true
📱 Fetching paired devices...
📊 Devices retrieved: 1 device(s)
  Device 0: BluetoothDevice(Printer Name, MAC:ADDRESS)
```

**Jika error muncul:**
```
❌ Discovery error: PlatformException(...)
```

---

## 🛠️ Implementasi Native (Untuk Tim Developer)

File yang perlu di-check: `android/app/src/main/kotlin/com/buysindo/app/MainActivity.kt`

Pastikan method `getPairedDevices` sudah di-implement dengan benar.

Lihat: `BLUETOOTH_DEBUG_GUIDE.md` untuk detail implementasi.

---

## 📞 Jika Masih Tidak Berhasil

1. Screenshot layar debug
2. Catat Android version (Pengaturan > Tentang Telepon)
3. Catat tipe printer Bluetooth
4. Kirim ke developer dengan info di atas

