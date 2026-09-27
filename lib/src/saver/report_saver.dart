import 'dart:typed_data';
import 'package:logging/logging.dart';

import '../downloader/downloader.dart';
import '../engine/report_artifact.dart';

/// Service for persisting, downloading, or sharing generated [ReportArtifact] instances.
class ReportSaver {
  static final Logger _log = Logger('ReportSaver');
  final FileDownloader _downloader;

  ReportSaver({FileDownloader? downloader})
    : _downloader = downloader ?? FileDownloader();

  /// Saves or downloads the [artifact] to the local device or browser.
  Future<void> save(ReportArtifact artifact) async {
    _log.info(
      'Saving report artifact: "${artifact.filename}" (${artifact.formattedSize})',
    );
    await _downloader.downloadFile(
      artifact.bytes,
      artifact.filename,
      mimeType: artifact.mimeType,
    );
  }

  /// Convenience method to save raw [bytes] with a specified [filename].
  Future<void> saveBytes(
    List<int> bytes,
    String filename, {
    String? mimeType,
  }) async {
    _log.info('Saving raw bytes to file: "$filename"');
    await _downloader.downloadFile(
      bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      filename,
      mimeType: mimeType,
    );
  }
}
