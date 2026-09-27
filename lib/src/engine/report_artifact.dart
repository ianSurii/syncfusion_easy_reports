import 'dart:typed_data';

/// Supported export output formats.
enum ExportFormat {
  /// Microsoft Excel OpenXML Workbook (.xlsx)
  excel,

  /// Adobe Portable Document Format (.pdf)
  pdf,

  /// Comma-Separated Values (.csv)
  csv,

  /// JavaScript Object Notation (.json)
  json,
}

/// Represents the final rendered output artifact of a report generation.
///
/// Contains raw document bytes along with file metadata and any non-fatal
/// warnings generated during calculation or rendering.
class ReportArtifact {
  /// Raw binary data of the generated document.
  final Uint8List bytes;

  /// Recommended filename for saving or downloading.
  final String filename;

  /// Standard MIME type of the document.
  final String mimeType;

  /// Format of the exported artifact.
  final ExportFormat format;

  /// Non-fatal warnings encountered during preparation or rendering.
  final List<String> warnings;

  /// Custom metadata or properties associated with this report run.
  final Map<String, dynamic> metadata;

  /// Timestamp when the report was generated.
  final DateTime generatedAt;

  ReportArtifact({
    required List<int> bytes,
    required this.filename,
    required this.mimeType,
    required this.format,
    this.warnings = const [],
    this.metadata = const {},
    DateTime? generatedAt,
  }) : bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
       generatedAt = generatedAt ?? DateTime.now();

  /// Size of the generated artifact in bytes.
  int get length => bytes.length;

  /// Formatted human-readable file size (e.g. "128 KB", "2.4 MB").
  String get formattedSize {
    final double kb = bytes.length / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final double mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  @override
  String toString() =>
      'ReportArtifact($filename, format: $format, size: $formattedSize)';
}
