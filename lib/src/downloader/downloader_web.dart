import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'downloader.dart';

/// Web file downloader implementation
class WebFileDownloader implements FileDownloader {
  @override
  Future<void> downloadFile(List<int> bytes, String filename, {String? mimeType}) async {
    try {
      final Uint8List uint8List = Uint8List.fromList(bytes);
      final web.Blob blob = web.Blob(
        [uint8List.toJS].toJS,
        web.BlobPropertyBag(type: mimeType ?? 'application/octet-stream'),
      );
      final String url = web.URL.createObjectURL(blob);
      final web.HTMLAnchorElement anchor =
          web.document.createElement('a') as web.HTMLAnchorElement
            ..href = url
            ..download = filename
            ..style.display = 'none';
      web.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      web.URL.revokeObjectURL(url);
    } catch (e) {
      rethrow;
    }
  }
}

/// Web factory provider
FileDownloader getPlatformDownloader() => WebFileDownloader();
