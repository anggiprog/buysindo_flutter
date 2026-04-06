package com.buysindo.app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.OutputStream
import java.util.UUID

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.buysindo.app/printer"
        private const val DEEPLINK_CHANNEL = "com.buysindo.app/deeplink"
        private val PRINTER_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    }

    private var socket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Printer channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPairedDevices" -> {
                    val devices = getPairedBluetoothDevices()
                    result.success(devices)
                }
                "connectDevice" -> {
                    val address = call.argument<String>("address")
                    val name = call.argument<String>("name")
                    if (address != null) {
                        val connected = connectToDevice(address)
                        result.success(connected)
                    } else {
                        result.error("INVALID_ARGS", "Address is required", null)
                    }
                }
                "disconnect" -> {
                    disconnect()
                    result.success(null)
                }
                "isConnected" -> {
                    result.success(socket?.isConnected ?: false)
                }
                "printReceipt" -> {
                    val content = call.argument<String>("content") ?: ""
                    val printed = printToSocket(content)
                    result.success(printed)
                }
                else -> result.notImplemented()
            }
        }

        // Deep link channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEPLINK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialUri" -> {
                    val initialUri = getInitialUri()
                    result.success(initialUri)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getInitialUri(): String? {
        val intent = intent
        val action = intent?.action
        val data = intent?.data

        println("🔗 [MainActivity] getInitialUri called")
        println("🔗 [MainActivity] Action: $action")
        println("🔗 [MainActivity] Data: $data")
        println("🔗 [MainActivity] Intent: ${intent.toString()}")

        return if (action == Intent.ACTION_VIEW && data != null) {
            val uri = data.toString()
            println("✅ [MainActivity] Returning URI: $uri")
            uri
        } else {
            println("⚠️ [MainActivity] No VIEW action or data found")
            null
        }
    }

    private fun getPairedBluetoothDevices(): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        val adapter = BluetoothAdapter.getDefaultAdapter()
        if (adapter != null) {
            val pairedDevices: Set<BluetoothDevice>? = adapter.bondedDevices
            pairedDevices?.forEach { device ->
                val map = mapOf(
                    "name" to (device.name ?: "Unknown"),
                    "address" to device.address,
                    "bonded" to (device.bondState == BluetoothDevice.BOND_BONDED),
                    "type" to device.type
                )
                list.add(map)
            }
        }
        return list
    }

    private fun connectToDevice(address: String): Boolean {
        try {
            val adapter = BluetoothAdapter.getDefaultAdapter()
            val device = adapter.getRemoteDevice(address)
            // Close prior socket
            socket?.close()

            // Use insecureRfcommSocketToServiceRecord for broader compatibility
            socket = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.GINGERBREAD) {
                device.createRfcommSocketToServiceRecord(PRINTER_UUID)
            } else {
                device.createInsecureRfcommSocketToServiceRecord(PRINTER_UUID)
            }

            // Cancel discovery to improve connection
            adapter.cancelDiscovery()

            socket?.connect()
            outputStream = socket?.outputStream
            return socket?.isConnected ?: false
        } catch (e: Exception) {
            e.printStackTrace()
            try {
                socket?.close()
            } catch (ioe: IOException) {
                // ignore
            }
            socket = null
            outputStream = null
            return false
        }
    }

    private fun disconnect() {
        try {
            outputStream?.close()
        } catch (e: Exception) {
            // ignore
        }
        try {
            socket?.close()
        } catch (e: Exception) {
            // ignore
        }
        socket = null
        outputStream = null
    }

    private fun printToSocket(content: String): Boolean {
        try {
            if (outputStream == null) return false
            // Convert string to bytes - printers expect CP437 or default charset; adjust if needed
            val bytes = content.toByteArray(Charsets.UTF_8)
            outputStream?.write(bytes)
            outputStream?.flush()
            // Give some time for the printer to process
            Handler(Looper.getMainLooper()).postDelayed({}, 200)
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
}
