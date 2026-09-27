import 'dart:convert';
import 'package:excel_plus/excel_plus.dart' as ep;
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xio;

import '../downloader/downloader.dart';

/// Column definition for template generation and validation.
class ExcelTemplateColumn {
  final String name;
  final String sampleValue;
  final List<String>? dropdownList;
  final String? dropdownFormula;
  final bool isRequired;
  final String? description;

  ExcelTemplateColumn({
    required this.name,
    required this.sampleValue,
    this.dropdownList,
    this.dropdownFormula,
    this.isRequired = false,
    this.description,
  });
}

/// Validation error encountered during Excel template parsing.
class TemplateValidationError {
  final int rowIndex;
  final String columnName;
  final String message;
  final dynamic invalidValue;

  const TemplateValidationError({
    required this.rowIndex,
    required this.columnName,
    required this.message,
    this.invalidValue,
  });

  @override
  String toString() =>
      'Row $rowIndex [$columnName]: $message (value: $invalidValue)';
}

/// Structured result of an Excel template import operation.
class TemplateImportResult {
  final List<Map<String, dynamic>> records;
  final List<TemplateValidationError> errors;
  final List<String> warnings;
  final List<String> detectedHeaders;
  final bool isValid;

  const TemplateImportResult({
    required this.records,
    this.errors = const [],
    this.warnings = const [],
    this.detectedHeaders = const [],
    required this.isValid,
  });

  int get totalRows => records.length;
  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Service for generating data-entry Excel workbooks and parsing uploaded/imported workbooks.
class ExcelTemplateService {
  static final Logger _log = Logger('ExcelTemplateService');

  /// Generates a binary OpenXML (.xlsx) data-entry template workbook.
  Future<List<int>> generateXlsxTemplate({
    required List<ExcelTemplateColumn> columns,
    String sheetName = 'Data Entry',
    String? instructions,
    Map<String, List<String>>? lookupLists,
  }) async {
    _log.info('Generating XLSX template with ${columns.length} columns');
    final xio.Workbook workbook = xio.Workbook();

    // 1. Instructions Sheet
    if (instructions != null && instructions.isNotEmpty) {
      final xio.Worksheet instructSheet = workbook.worksheets[0];
      instructSheet.name = 'Instructions';
      instructSheet.getRangeByIndex(1, 1).setText('Data Entry Instructions');
      instructSheet.getRangeByIndex(1, 1).cellStyle.fontSize = 14;
      instructSheet.getRangeByIndex(1, 1).cellStyle.bold = true;
      instructSheet.getRangeByIndex(1, 1).cellStyle.fontColor = '#1565C0';

      instructSheet.getRangeByIndex(3, 1).setText(instructions);
      instructSheet.getRangeByIndex(3, 1).cellStyle.fontSize = 10;
      instructSheet.autoFitColumn(1);
    }

    // 2. Data Entry Sheet
    final xio.Worksheet dataSheet =
        instructions != null && instructions.isNotEmpty
        ? workbook.worksheets.addWithName(sheetName)
        : workbook.worksheets[0];
    if (instructions == null || instructions.isEmpty) {
      dataSheet.name = sheetName;
    }

    // Headers
    for (int col = 0; col < columns.length; col++) {
      final c = columns[col];
      final headerCell = dataSheet.getRangeByIndex(1, col + 1);
      final title = c.isRequired ? '${c.name} *' : c.name;
      headerCell.setText(title);
      headerCell.cellStyle.bold = true;
      headerCell.cellStyle.fontSize = 10;
      headerCell.cellStyle.backColor = '#1565C0';
      headerCell.cellStyle.fontColor = '#FFFFFF';
      headerCell.cellStyle.hAlign = xio.HAlignType.center;

      // Sample row
      final sampleCell = dataSheet.getRangeByIndex(2, col + 1);
      final numVal = num.tryParse(c.sampleValue);
      if (numVal != null) {
        sampleCell.setNumber(numVal.toDouble());
      } else {
        sampleCell.setText(c.sampleValue);
      }
      sampleCell.cellStyle.italic = true;
      sampleCell.cellStyle.fontColor = '#555555';

      dataSheet.autoFitColumn(col + 1);
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    return bytes;
  }

  /// Generates a template payload (preserves compatibility with JSON-based tests).
  Future<List<int>> generateTemplate({
    required List<ExcelTemplateColumn> columns,
    Map<String, List<String>>? lookupLists,
  }) async {
    final Map<String, dynamic> doc = {
      'columns': columns
          .map(
            (c) => {
              'name': c.name,
              'sample': c.sampleValue,
              'dropdown': c.dropdownList,
              'formula': c.dropdownFormula,
              'required': c.isRequired,
            },
          )
          .toList(),
      'lookups': lookupLists ?? {},
    };

    return utf8.encode(jsonEncode(doc));
  }

  /// Generates and automatically triggers download of the template.
  Future<void> generateAndDownloadTemplate({
    required List<ExcelTemplateColumn> columns,
    Map<String, List<String>>? lookupLists,
    required String filename,
    String? instructions,
    bool isBinaryXlsx = true,
  }) async {
    final bytes = isBinaryXlsx
        ? await generateXlsxTemplate(
            columns: columns,
            lookupLists: lookupLists,
            instructions: instructions,
          )
        : await generateTemplate(columns: columns, lookupLists: lookupLists);

    final fullFilename = filename.endsWith('.xlsx')
        ? filename
        : '$filename.xlsx';
    final downloader = FileDownloader();
    await downloader.downloadFile(
      bytes,
      fullFilename,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  /// Parses input Excel bytes (both binary .xlsx or JSON payloads) into structured records with validation.
  TemplateImportResult importExcelBytes(
    List<int> bytes, {
    List<ExcelTemplateColumn>? expectedColumns,
  }) {
    _log.info('Importing Excel bytes: ${bytes.length} bytes');

    // 1. Attempt JSON decode first for fast test/backward-compatibility
    try {
      final str = utf8.decode(bytes);
      if (str.trim().startsWith('{') && str.contains('columns')) {
        final records = parseExcelBytes(bytes);
        return TemplateImportResult(
          records: records,
          detectedHeaders: records.isNotEmpty
              ? records.first.keys.toList()
              : [],
          isValid: true,
        );
      }
    } catch (_) {}

    // 2. Parse binary .xlsx via excel_plus
    try {
      final excel = ep.Excel.decodeBytes(bytes);
      final List<Map<String, dynamic>> records = [];
      final List<TemplateValidationError> errors = [];
      final List<String> warnings = [];

      // Find the appropriate data sheet (skipping Instructions)
      String? targetSheetName;
      int maxMatches = -1;

      for (final tableName in excel.tables.keys) {
        if (tableName.toLowerCase() == 'instructions') continue;
        final epSheet = excel.tables[tableName];
        if (epSheet == null || epSheet.rows.isEmpty) continue;

        final headerRow = epSheet.rows.first;
        final sheetHeaders = headerRow
            .map((c) => c?.value?.toString().replaceAll('*', '').trim() ?? '')
            .where((h) => h.isNotEmpty)
            .toList();

        int matches = 0;
        if (expectedColumns != null) {
          for (final exp in expectedColumns) {
            if (sheetHeaders.any(
              (h) => h.toLowerCase() == exp.name.toLowerCase(),
            )) {
              matches++;
            }
          }
        } else {
          matches = sheetHeaders.length;
        }

        if (matches > maxMatches) {
          maxMatches = matches;
          targetSheetName = tableName;
        }
      }

      if (targetSheetName == null && excel.tables.isNotEmpty) {
        targetSheetName = excel.tables.keys.first;
      }

      final epSheet = targetSheetName != null
          ? excel.tables[targetSheetName]
          : null;
      if (epSheet == null || epSheet.rows.isEmpty) {
        return const TemplateImportResult(records: [], isValid: true);
      }

      final headerRow = epSheet.rows.first;
      final headers = headerRow
          .map((c) => c?.value?.toString().replaceAll('*', '').trim() ?? '')
          .where((h) => h.isNotEmpty)
          .toList();

      // Check required columns
      if (expectedColumns != null) {
        for (final exp in expectedColumns.where((c) => c.isRequired)) {
          if (!headers.any((h) => h.toLowerCase() == exp.name.toLowerCase())) {
            errors.add(
              TemplateValidationError(
                rowIndex: 1,
                columnName: exp.name,
                message:
                    'Required column "${exp.name}" is missing in the imported sheet.',
              ),
            );
          }
        }
      }

      // Process data rows
      for (int r = 1; r < epSheet.rows.length; r++) {
        final row = epSheet.rows[r];
        if (row.isEmpty) continue;

        final Map<String, dynamic> record = {};
        bool hasData = false;

        for (int c = 0; c < headers.length && c < row.length; c++) {
          final colName = headers[c];
          final cellVal = row[c]?.value;

          if (cellVal != null) {
            final cellStr = cellVal.toString().trim();
            if (cellStr.isNotEmpty) {
              hasData = true;
              record[colName] = _autoType(cellStr);
            } else {
              record[colName] = null;
            }
          } else {
            record[colName] = null;
          }
        }

        if (hasData) {
          records.add(record);
        }
      }

      return TemplateImportResult(
        records: records,
        errors: errors,
        warnings: warnings,
        detectedHeaders: headers,
        isValid: errors.isEmpty,
      );
    } catch (e) {
      _log.warning('Excel binary import error: $e');
      return TemplateImportResult(
        records: [],
        errors: [
          TemplateValidationError(
            rowIndex: 0,
            columnName: '',
            message: 'Failed to parse Excel file: $e',
          ),
        ],
        isValid: false,
      );
    }
  }

  /// Parses bytes back to a list of records. Retains backward compatibility.
  List<Map<String, dynamic>> parseExcelBytes(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final List cols = decoded['columns'] as List? ?? [];

      if (cols.isEmpty) return [];

      final Map<String, dynamic> record = {};
      for (final c in cols) {
        final name = c['name'] as String? ?? 'col';
        final sample = c['sample']?.toString() ?? '';
        record[name] = _autoType(sample);
      }

      return [record];
    } catch (e) {
      final res = importExcelBytes(bytes);
      return res.records;
    }
  }

  Future<List<Map<String, dynamic>>?> pickAndParseExcel() async {
    _log.info('pickAndParseExcel called');
    return null;
  }

  dynamic _autoType(String value) {
    final val = value.trim();
    if (val.isEmpty) return null;
    if (val.toLowerCase() == 'true') return true;
    if (val.toLowerCase() == 'false') return false;
    final num? n = num.tryParse(val);
    if (n != null) return n;
    return val;
  }
}
