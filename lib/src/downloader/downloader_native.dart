import 'dart:io';
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
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop platform: try FilePicker.saveFile when available, otherwise
        // fall back to writing directly to the Downloads folder and open it.
        final dynamic platformPicker = FilePicker.platform;
        String? outputPath;
        try {
          // Some versions of file_picker expose `saveFile`, others do not.
          // Call dynamically and catch NoSuchMethodError at runtime.
          outputPath = await platformPicker.saveFile(
            dialogTitle: 'Save Report',
            fileName: filename,
          );
        } on NoSuchMethodError catch (_) {
          // saveFile not available on this FilePicker build; fallback below.
          outputPath = null;
        } catch (_) {
          outputPath = null;
        }

        if (outputPath != null) {
          final file = File(outputPath);
          await file.writeAsBytes(bytes);
          return;
        }

        // Fallback: write to user's Downloads directory (preferred on macOS)
        try {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            final filePath = '${downloadsDir.path}/$filename';
            final file = File(filePath);
            await file.writeAsBytes(bytes);
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
        await file.writeAsBytes(bytes);
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
        // Request storage permission
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
            await file.writeAsBytes(bytes);
            return;
          }
        } catch (_) {}

        // Fallback 1: external app storage directory
        try {
          final directory = await getExternalStorageDirectory();
          if (directory != null) {
            final filePath = '${directory.path}/$filename';
            final file = File(filePath);
            await file.writeAsBytes(bytes);
            return;
          }
        } catch (_) {}

        // Fallback 2: standard application documents directory
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
      } else if (Platform.isIOS) {
        // iOS platform: Save to temp directory and open Share sheet
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // share_plus updated API; suppress deprecation warning for now
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
