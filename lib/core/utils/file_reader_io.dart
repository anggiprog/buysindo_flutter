import 'dart:io';
import 'dart:typed_data';

/// Read file bytes from path (mobile platforms only)
Future<Uint8List> readFileBytes(String path) async {
  final file = File(path);
  return await file.readAsBytes();
}
