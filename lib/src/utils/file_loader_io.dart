import 'dart:io';

/// Native implementation of platformLoadFileBytes using dart:io.
Future<List<int>?> platformLoadFileBytes(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
  } catch (_) {}
  return null;
}
