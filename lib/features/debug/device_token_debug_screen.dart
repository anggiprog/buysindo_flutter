import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/network/session_manager.dart';

/// 🔍 DEBUG SCREEN: Diagnose & Fix Device Token Issues
class DeviceTokenDebugScreen extends StatefulWidget {
  const DeviceTokenDebugScreen({Key? key}) : super(key: key);

  @override
  State<DeviceTokenDebugScreen> createState() => _DeviceTokenDebugScreenState();
}

class _DeviceTokenDebugScreenState extends State<DeviceTokenDebugScreen> {
  final apiService = ApiService.instance;
  String _diagnosticResult = 'Tap "Run Diagnostic" to start...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() => _isLoading = true);
    try {
      final result = await apiService.diagnosticFcmStatus();
      
      result.forEach((key, value) {
        
      });

      setState(() {
        _diagnosticResult =
            '''
📊 FCM DIAGNOSTIC RESULTS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Firebase Initialized: ${result['firebase_initialized']}
FCM Token Valid: ${result['fcm_token_valid']}
Is Mock Token: ${result['is_mock_token']}
Token Source: ${result['token_source']}

📌 Current Token:
${(result['current_device_token'] as String).length > 50 ? (result['current_device_token'] as String).substring(0, 50) + '...' : result['current_device_token']}

${result['is_mock_token'] == true ? '⚠️ MOCK TOKEN - FCM not working!' : '✅ REAL FCM TOKEN!'}
        ''';
      });
    } catch (e) {
      setState(() {
        _diagnosticResult = '❌ ERROR: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _forceRefreshToken() async {
    setState(() => _isLoading = true);
    try {
      final newToken = await apiService.forceRefreshFcmToken();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Token refreshed!\n${newToken.substring(0, 30)}...'),
        ),
      );
      await _runDiagnostic();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Refresh failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateDeviceToken() async {
    setState(() => _isLoading = true);
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❌ Not logged in')));
        return;
      }

      await apiService.updateDeviceToken(token);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Device token updated!')));
      await _runDiagnostic();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Update failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Device Token Debug'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Diagnostic Result Card
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Current Status:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _diagnosticResult,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            const Text(
              '🎯 Quick Actions:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Button 1: Run Diagnostic
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _runDiagnostic,
                icon: const Icon(Icons.refresh),
                label: const Text('Run Diagnostic'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Button 2: Force Refresh Token
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _forceRefreshToken,
                icon: const Icon(Icons.cached),
                label: const Text('Force Refresh FCM Token'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Button 3: Update Device Token
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateDeviceToken,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Update Device Token to Backend'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '📌 INFO:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 🟢 Real FCM Token: Starts with eyJ... (long string, 100+ chars)',
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• 🔴 Mock Token: device_TIMESTAMP_RANDOMNUMBER',
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• ⚠️ If mock token: Firebase/Google Play Services issue',
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• 💡 Try: Force Refresh → Update Backend → Verify',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

