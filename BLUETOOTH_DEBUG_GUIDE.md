# 🔧 Bluetooth Printer Debug Guide

## Masalah: Printer Tidak Terdeteksi Padahal Sudah Terhubung

### Langkah-langkah Debugging:

#### 1. **Buka Logcat untuk Melihat Debug Messages**
```bash
# Terminal 1: Jalankan aplikasi dengan logging
flutter run -v

# Terminal 2: Lihat logcat
adb logcat | grep -i bluetooth
```

#### 2. **Debug Messages yang Akan Dilihat**

**Jika berhasil:**
```
🔍 Starting Bluetooth device discovery...
✅ Permissions granted: true
📱 Fetching paired devices...
📊 Devices retrieved: 2 device(s)
  Device 0: BluetoothDevice(Printer HP, 00:11:22:33:44:55)
  Device 1: BluetoothDevice(Speaker Sony, AA:BB:CC:DD:EE:FF)
✅ Found 2 devices
```

**Jika ada error:**
```
❌ Discovery error: PlatformException(...)
❌ Error type: PlatformException
❌ Stack trace: ...
```

#### 3. **Kemungkinan Masalah & Solusi**

| Masalah | Penyebab | Solusi |
|---------|---------|--------|
| **PlatformException: getPairedDevices** | Native method tidak ada | Implementasikan di Kotlin/Java |
| **Permission denied** | Izin Bluetooth belum diberikan | Buka Pengaturan > Aplikasi > Buysindo > Izin |
| **0 devices ditemukan** | Device tidak terhubung | Hubungkan dari Pengaturan Bluetooth dulu |
| **Method Not Implemented** | MethodChannel belum di-register | Setup native bridge di MainActivity |

#### 4. **Cara Setup Native Bridge (Android)**

File: `android/app/src/main/kotlin/com/buysindo/app/MainActivity.kt`

```kotlin
package com.buysindo.app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.buysindo.app/printer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPairedDevices" -> {
                    try {
                        val devices = mutableListOf<Map<String, Any>>()
                        
                        val bluetoothManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
                        } else {
                            @Suppress("DEPRECATION")
                            BluetoothAdapter.getDefaultAdapter()?.let { adapter ->
                                BluetoothManager(context, adapter)
                            }
                        }

                        val adapter = bluetoothManager?.adapter
                        if (adapter != null && adapter.isEnabled) {
                            @Suppress("MISSING_PERMISSION")
                            val pairedDevices = adapter.bondedDevices
                            for (device in pairedDevices) {
                                devices.add(mapOf(
                                    "name" to (device.name ?: "Unknown"),
                                    "address" to device.address
                                ))
                            }
                        }
                        result.success(devices)
                    } catch (e: Exception) {
                        result.error("BLUETOOTH_ERROR", e.message, null)
                    }
                }
                "connectDevice" -> {
                    // Implementasi connect logic
                    result.notImplemented()
                }
                else -> result.notImplemented()
            }
        }
    }
}
```

#### 5. **Cek AndroidManifest.xml**

File: `android/app/src/main/AndroidManifest.xml`

Pastikan permissions ada:
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

#### 6. **Test Manual dari Flutter**

```dart
// Tambah di main atau debugging widget
import 'package:flutter/services.dart';

const platform = MethodChannel('com.buysindo.app/printer');

Future<void> testBluetooth() async {
  try {
    final List<dynamic> devices = await platform.invokeMethod('getPairedDevices');
    print('✅ Devices: $devices');
  } on PlatformException catch (e) {
    print('❌ Error: ${e.message}');
  }
}
```

#### 7. **Checklist Debugging**

- [ ] Bluetooth HP aktif?
- [ ] Printer Bluetooth aktif?
- [ ] Printer sudah dipasangkan di Pengaturan Bluetooth?
- [ ] Aplikasi sudah memberikan izin Bluetooth?
- [ ] Logcat menampilkan "Found X devices"?
- [ ] Native method channel sudah di-implement?
- [ ] AndroidManifest.xml sudah punya permissions?

#### 8. **Lihat Debug UI Dalam Aplikasi**

Saat tidak ada printer ditemukan, layar akan menampilkan:
- Debug info (jumlah device ditemukan)
- Daftar device (jika ada)
- Tips untuk mengatasi masalah

---

## Output Debug yang Diharapkan

### Success Case:
```
📱 Devices retrieved: 1 device(s)
  Device 0: BluetoothDevice(HP OfficeJet, 00:1A:7D:DA:71:13)
```

### Error Case:
```
❌ Discovery error: MissingPluginException(No implementation found for method getPairedDevices on channel com.buysindo.app/printer)
❌ Error type: MissingPluginException
```

Jika error ini muncul, native implementasi belum ada di MainActivity.

---

## Hubungi Jika Masih Ada Masalah

1. Screenshot debug panel (bagian "🔧 DEBUG INFO")
2. Output dari `adb logcat | grep -i bluetooth`
3. Versi Android device Anda
4. Tipe printer Bluetooth

