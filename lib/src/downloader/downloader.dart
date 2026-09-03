import 'downloader_stub.dart'
    if (dart.library.html) 'downloader_web.dart'
    if (dart.library.io) 'downloader_native.dart';

/// Cross-platform helper to save or download bytes to the local file system.
abstract class FileDownloader {
  /// Saves the [bytes] as a file with the given [filename].
  /// On Web, this triggers a browser download.
  /// On Desktop, this prompts a save dialog.
  /// On Android, this saves to the public Downloads folder.
  /// On iOS, this opens a share sheet to save or send the document.
  Future<void> downloadFile(
    List<int> bytes,
    String filename, {
    String? mimeType,
  });

  /// Factory constructor to get the platform-specific downloader.
  factory FileDownloader() => getPlatformDownloader();
}
