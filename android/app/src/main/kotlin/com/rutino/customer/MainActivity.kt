package com.rutino.customer

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.rutino.customer/printer"
    private var bluetoothSocket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null
    private val SPP_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB") // SPP UUID

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPairedDevices" -> {
                        try {
                            val devices = getPairedBluetoothDevices()
                            result.success(devices)
                        } catch (e: Exception) {
                            result.error("BLUETOOTH_ERROR", e.message, null)
                        }
                    }
                    "connectDevice" -> {
                        try {
                            val address = call.argument<String>("address") ?: ""
                            val name = call.argument<String>("name") ?: ""
                            val success = connectToDevice(address)
                            result.success(success)
                        } catch (e: Exception) {
                            result.error("CONNECT_ERROR", e.message, null)
                        }
                    }
                    "printReceipt" -> {
                        try {
                            val content = call.argument<String>("content") ?: ""
                            val success = printToDevice(content)
                            result.success(success)
                        } catch (e: Exception) {
                            result.error("PRINT_ERROR", e.message, null)
                        }
                    }
                    "disconnect" -> {
                        try {
                            disconnectDevice()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("DISCONNECT_ERROR", e.message, null)
                        }
                    }
                    "isConnected" -> {
                        try {
                            val connected = bluetoothSocket?.isConnected == true
                            result.success(connected)
                        } catch (e: Exception) {
                            result.error("CHECK_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getPairedBluetoothDevices(): List<Map<String, Any>> {
        val devices = mutableListOf<Map<String, Any>>()
        try {
            val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            if (bluetoothAdapter != null) {
                val pairedDevices = bluetoothAdapter.bondedDevices
                
                android.util.Log.d("Bluetooth", "Found ${pairedDevices.size} paired devices")
                
                for (device in pairedDevices) {
                    try {
                        devices.add(mapOf(
                            "name" to (device.name ?: "Unknown"),
                            "address" to device.address,
                            "type" to device.type,
                            "bondState" to device.bondState
                        ))
                        
                        android.util.Log.d("Bluetooth", "Device: ${device.name} (${device.address})")
                    } catch (e: Exception) {
                        android.util.Log.e("Bluetooth", "Error adding device: ${e.message}")
                    }
                }
            } else {
                android.util.Log.e("Bluetooth", "BluetoothAdapter is null")
            }
        } catch (e: Exception) {
            android.util.Log.e("Bluetooth", "Error getting paired devices: ${e.message}")
        }
        return devices
    }

    private fun connectToDevice(address: String): Boolean {
        return try {
            android.util.Log.d("Bluetooth", "Attempting to connect to $address")
            
            disconnectDevice() // Close any existing connection
            
            val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            val bluetoothDevice = bluetoothAdapter?.getRemoteDevice(address)
                ?: throw Exception("Device not found")
            
            // Create socket
            bluetoothSocket = bluetoothDevice.createRfcommSocketToServiceRecord(SPP_UUID)
                ?: throw Exception("Failed to create socket")
            
            // Connect (blocking call)
            bluetoothSocket?.connect()
            outputStream = bluetoothSocket?.outputStream
                ?: throw Exception("Failed to get output stream")
            
            android.util.Log.d("Bluetooth", "Connected to $address")
            true
        } catch (e: Exception) {
            android.util.Log.e("Bluetooth", "Connection error: ${e.message}")
            disconnectDevice()
            false
        }
    }

    private fun printToDevice(content: String): Boolean {
        return try {
            if (bluetoothSocket?.isConnected != true || outputStream == null) {
                android.util.Log.e("Bluetooth", "Not connected to device")
                return false
            }
            
            android.util.Log.d("Bluetooth", "Printing ${content.length} bytes")
            
            // Send content to printer
            outputStream?.write(content.toByteArray())
            outputStream?.flush()
            
            // Add some delay for printer to process
            Thread.sleep(500)
            
            android.util.Log.d("Bluetooth", "Print completed")
            true
        } catch (e: Exception) {
            android.util.Log.e("Bluetooth", "Print error: ${e.message}")
            false
        }
    }

    private fun disconnectDevice() {
        try {
            outputStream?.close()
            bluetoothSocket?.close()
            outputStream = null
            bluetoothSocket = null
            android.util.Log.d("Bluetooth", "Disconnected")
        } catch (e: Exception) {
            android.util.Log.e("Bluetooth", "Disconnect error: ${e.message}")
        }
    }
}
