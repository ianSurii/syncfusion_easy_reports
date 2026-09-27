import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'downloader.dart';

/// Native file downloader implementation for Desktop and Mobile platforms.
class NativeFileDownloader implements FileDownloader {
  @override
  Future<void> downloadFile(
    List<int> bytes,
    String filename, {
    String? mimeType,
  }) async {
    try {
      final Uint8List uint8Bytes = bytes is Uint8List
          ? bytes
          : Uint8List.fromList(bytes);

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop platform: try FilePicker.saveFile
        try {
          final Uri? savedUri = await FilePicker.saveFile(
            dialogTitle: 'Save Report',
            fileName: filename,
            bytes: uint8Bytes,
          );
          if (savedUri != null) {
            return;
          }
        } catch (_) {}

        // Fallback: write directly to user's Downloads directory (preferred on macOS)
        try {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            final filePath = '${downloadsDir.path}/$filename';
            final file = File(filePath);
            await file.writeAsBytes(uint8Bytes);
            // Try to reveal/open the file so the user can access it immediately.
            try {
              if (Platform.isMacOS) {
                await Process.run('open', [filePath]);
              } else if (Platform.isWindows) {
                await Process.run('explorer', [filePath]);
              } else if (Platform.isLinux) {
                await Process.run('xdg-open', [filePath]);
              }
            } catch (_) {}
            return;
          }
        } catch (_) {}

        // Last resort: write to application documents directory
        final desktopDir = await getApplicationDocumentsDirectory();
        final filePath = '${desktopDir.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(uint8Bytes);
        try {
          if (Platform.isMacOS) {
            await Process.run('open', [filePath]);
          } else if (Platform.isWindows) {
            await Process.run('explorer', [filePath]);
          } else if (Platform.isLinux) {
            await Process.run('xdg-open', [filePath]);
          }
        } catch (_) {}
      } else if (Platform.isAndroid) {
        // Android platform: request storage permission if required (API level < 33)
        try {
          if (await Permission.storage.isDenied) {
            await Permission.storage.request();
          }
        } catch (_) {}

        // Try saving directly to public Downloads folder first
        try {
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            final filePath = '${downloadDir.path}/$filename';
            final file = File(filePath);
            await file.writeAsBytes(uint8Bytes);
            return;
          }
        } catch (_) {}

        // Fallback 1: external app storage directory
        try {
          final directory = await getExternalStorageDirectory();
          if (directory != null) {
            final filePath = '${directory.path}/$filename';
            final file = File(filePath);
            await file.writeAsBytes(uint8Bytes);
            return;
          }
        } catch (_) {}

        // Fallback 2: standard application documents directory
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(uint8Bytes);
      } else if (Platform.isIOS) {
        // iOS platform: Save to temp directory and open Share sheet
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(uint8Bytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles([
          XFile(filePath, name: filename, mimeType: mimeType),
        ], subject: filename);
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// Native factory provider
FileDownloader getPlatformDownloader() => NativeFileDownloader();
