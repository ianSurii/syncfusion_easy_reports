import 'downloader.dart';

/// Platform-specific function signature returning FileDownloader.
FileDownloader getPlatformDownloader() => throw UnsupportedError(
  'Cannot create a downloader without dart:html or dart:io',
);
