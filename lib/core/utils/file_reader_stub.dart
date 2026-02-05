import 'dart:typed_data';

/// Stub for web - File reading not supported directly from path
Future<Uint8List> readFileBytes(String path) async {
  throw UnsupportedError(
    'File reading from path is not supported on web. Use photoBytes instead.',
  );
}
