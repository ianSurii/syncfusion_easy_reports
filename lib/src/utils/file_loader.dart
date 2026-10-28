import 'file_loader_stub.dart' if (dart.library.io) 'file_loader_io.dart';

/// Loads raw bytes from a local file path on platforms that support dart:io.
/// Returns null on web, WASM, or if the file cannot be read.
Future<List<int>?> loadFileBytes(String path) => platformLoadFileBytes(path);
