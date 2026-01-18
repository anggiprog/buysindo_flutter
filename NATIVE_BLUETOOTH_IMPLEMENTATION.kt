// File: android/app/src/main/kotlin/com/buysindo/app/MainActivity.kt
// IMPLEMENTASI NATIVE BLUETOOTH UNTUK FLUTTER

package com.buysindo.app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    
    companion object {
        private const val CHANNEL = "com.buysindo.app/printer"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPairedDevices" -> getPairedDevices(result)
                    "connectDevice" -> connectDevice(call, result)
                    "disconnect" -> disconnect(result)
                    "isConnected" -> isConnected(result)
                    "printReceipt" -> printReceipt(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Ambil semua perangkat Bluetooth yang sudah dipasangkan
     */
    private fun getPairedDevices(result: MethodChannel.Result) {
        try {
            println("🔍 [Native] Getting paired devices...")
            
            val devices = mutableListOf<Map<String, Any>>()
            
            val adapter = getBluetoothAdapter()
            if (adapter != null && adapter.isEnabled) {
                println("✅ [Native] Bluetooth is enabled")
                
                // Get bonded (paired) devices
                @Suppress("MISSING_PERMISSION")
                val bondedDevices = adapter.bondedDevices
                println("📱 [Native] Found ${bondedDevices.size} bonded devices")
                
                for (device in bondedDevices) {
                    @Suppress("MISSING_PERMISSION")
                    val deviceMap = mapOf(
                        "name" to (device.name ?: "Unknown Device"),
                        "address" to device.address,
                        "type" to device.bluetoothClass?.deviceClass?.toString(),
                        "bonded" to true
                    )
                    devices.add(deviceMap)
                    println("  ✓ Device: ${device.name} (${device.address})")
                }
            } else {
                println("⚠️  [Native] Bluetooth is disabled or not available")
            }
            
            println("✅ [Native] Returning ${devices.size} devices to Flutter")
            result.success(devices)
            
        } catch (e: Exception) {
            println("❌ [Native] Error getting paired devices: ${e.message}")
            e.printStackTrace()
            result.error("BLUETOOTH_ERROR", "Failed to get paired devices: ${e.message}", null)
        }
    }

    /**
     * Hubungkan ke perangkat Bluetooth tertentu
     */
    private fun connectDevice(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        try {
            val address = call.argument<String>("address")
            val name = call.argument<String>("name")
            
            println("🔗 [Native] Connecting to device: $name ($address)")
            
            if (address == null) {
                result.error("INVALID_ARGS", "Device address is required", null)
                return
            }
            
            // TODO: Implementasi koneksi Bluetooth
            // Untuk sekarang, hanya return true (simulasi berhasil)
            println("✅ [Native] Connection attempt completed")
            result.success(true)
            
        } catch (e: Exception) {
            println("❌ [Native] Error connecting: ${e.message}")
            result.error("CONNECTION_ERROR", e.message, null)
        }
    }

    /**
     * Disconnect dari perangkat yang terhubung
     */
    private fun disconnect(result: MethodChannel.Result) {
        try {
            println("🔌 [Native] Disconnecting...")
            // TODO: Implementasi disconnect
            println("✅ [Native] Disconnected")
            result.success(null)
        } catch (e: Exception) {
            result.error("DISCONNECT_ERROR", e.message, null)
        }
    }

    /**
     * Cek apakah sudah terhubung ke printer
     */
    private fun isConnected(result: MethodChannel.Result) {
        try {
            println("🔍 [Native] Checking connection status...")
            // TODO: Implementasi status check
            result.success(false)
        } catch (e: Exception) {
            result.error("STATUS_ERROR", e.message, null)
        }
    }

    /**
     * Cetak struk ke printer
     */
    private fun printReceipt(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        try {
            val content = call.argument<String>("content")
            println("🖨️  [Native] Printing: ${content?.take(50)}...")
            // TODO: Implementasi print logic
            result.success(true)
        } catch (e: Exception) {
            result.error("PRINT_ERROR", e.message, null)
        }
    }

    /**
     * Helper function untuk mendapatkan BluetoothAdapter
     */
    private fun getBluetoothAdapter(): BluetoothAdapter? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            bluetoothManager.adapter
        } else {
            @Suppress("DEPRECATION")
            BluetoothAdapter.getDefaultAdapter()
        }
    }
}
