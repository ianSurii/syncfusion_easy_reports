import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import '../downloader/downloader.dart';

/// Configuration for a column in a generated Excel template.
class ExcelTemplateColumn {
  final String name; // Header title
  final String sampleValue; // Text/number to place in row 2 as a sample
  final List<String>? dropdownList; // Static dropdown values (e.g. ['True', 'False'])
  final String? dropdownFormula; // Formula referencing lookup sheets (e.g. '=Lookup!$A$2:$A$20')

  ExcelTemplateColumn({
    required this.name,
    required this.sampleValue,
    this.dropdownList,
    this.dropdownFormula,
  });
}

/// Generic service to generate data-entry templates and parse uploaded files.
class ExcelTemplateService {
  static final Logger _log = Logger('ExcelTemplateService');

  /// Generates template Excel spreadsheet bytes.
  Future<List<int>> generateTemplate({
    required List<ExcelTemplateColumn> columns,
    Map<String, List<String>>? lookupLists,
  }) async {
    _log.info('Generating template with ${columns.length} columns');

    final Workbook workbook = Workbook();

    // Sheet 1: Data entry
    final Worksheet dataSheet = workbook.worksheets[0];
    dataSheet.name = 'Data';

    // Write headers and sample row values
    for (int col = 0; col < columns.length; col++) {
      final column = columns[col];
      final colIndex = col + 1;

      // Header row
      final Range headerCell = dataSheet.getRangeByIndex(1, colIndex);
      headerCell.setText(column.name);
      headerCell.cellStyle.bold = true;
      headerCell.cellStyle.fontSize = 11;
      headerCell.cellStyle.backColor = '#42A5F5';
      headerCell.cellStyle.fontColor = '#FFFFFF';

      // Sample row
      dataSheet.getRangeByIndex(2, colIndex).setText(column.sampleValue);
    }

    // Sheet 2: Lookups (hidden sheet for dropdown sources)
    if (lookupLists != null && lookupLists.isNotEmpty) {
      _log.fine('Creating lookup sheet with ${lookupLists.length} lists');
      final Worksheet lookupSheet = workbook.worksheets.addWithName('Lookup');

      int colIndex = 1;
      for (final entry in lookupLists.entries) {
        final String listHeader = entry.key;
        final List<String> listValues = entry.value;

        // Write header
        lookupSheet.getRangeByIndex(1, colIndex).setText(listHeader);

        // Write values
        for (int row = 0; row < listValues.length; row++) {
          lookupSheet.getRangeByIndex(row + 2, colIndex).setText(listValues[row]);
        }
        colIndex++;
      }

      // Hide the lookups sheet
      lookupSheet.visibility = ExcelSheetVisibility.hidden;
    }

    // Apply validations
    for (int col = 0; col < columns.length; col++) {
      final column = columns[col];
      final colIndex = col + 1;

      if (column.dropdownList != null && column.dropdownList!.isNotEmpty) {
        _log.fine('Applying static dropdown validation to column: ${column.name}');
        _applyValidation(
          dataSheet,
          colIndex: colIndex,
          staticList: column.dropdownList,
        );
      } else if (column.dropdownFormula != null && column.dropdownFormula!.isNotEmpty) {
        _log.fine('Applying formula dropdown validation to column: ${column.name}');
        _applyValidation(
          dataSheet,
          colIndex: colIndex,
          formula: column.dropdownFormula,
        );
      }
    }

    // Autofit column widths
    for (int col = 1; col <= columns.length; col++) {
      dataSheet.autoFitColumn(col);
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    return bytes;
  }

  /// Generates the template Excel sheet and automatically saves/downloads.
  Future<void> generateAndDownloadTemplate({
    required List<ExcelTemplateColumn> columns,
    Map<String, List<String>>? lookupLists,
    required String filename,
  }) async {
    final List<int> bytes = await generateTemplate(
      columns: columns,
      lookupLists: lookupLists,
    );
    final String fullFilename = filename.endsWith('.xlsx') ? filename : '$filename.xlsx';

    final downloader = FileDownloader();
    await downloader.downloadFile(
      bytes,
      fullFilename,
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  /// Triggers a cross-platform file picker and parses sheet 1 row data into a list of maps.
  Future<List<Map<String, dynamic>>?> pickAndParseExcel() async {
    _log.info('Triggering file picker to parse Excel');
    try {
      Uint8List? bytes;

      if (kIsWeb) {
        // Picker for Web browser environments
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          allowMultiple: false,
          withData: true,
        );
        if (result != null && result.files.isNotEmpty) {
          bytes = result.files.first.bytes;
        }
      } else {
        // Picker for Native mobile & desktop environments
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          allowMultiple: false,
        );
        if (result != null && result.files.isNotEmpty) {
          final String? path = result.files.first.path;
          if (path != null) {
            final File file = File(path);
            bytes = await file.readAsBytes();
          }
        }
      }

      if (bytes == null) {
        _log.warning('No file bytes loaded or file picker cancelled');
        return null;
      }

      return parseExcelBytes(bytes);
    } catch (e) {
      _log.severe('Error picking and parsing Excel file: $e');
      return null;
    }
  }

  /// Parses spreadsheet bytes directly into structured maps.
  List<Map<String, dynamic>> parseExcelBytes(List<int> bytes) {
    _log.fine('Parsing spreadsheet bytes of size ${bytes.length}');
    final Workbook workbook = Workbook(bytes);
    final Worksheet sheet = workbook.worksheets[0];

    final Range? usedRange = sheet.usedRange;
    if (usedRange == null) {
      workbook.dispose();
      return [];
    }

    final int lastRow = usedRange.lastRow;
    final int lastCol = usedRange.lastColumn;

    if (lastRow < 1 || lastCol < 1) {
      workbook.dispose();
      return [];
    }

    // Row 1 represents headers
    final List<String> headers = [];
    for (int col = 1; col <= lastCol; col++) {
      final String headerText = sheet.getRangeByIndex(1, col).getText() ?? '';
      headers.add(headerText.trim());
    }

    // Row 2 onwards represent row records
    final List<Map<String, dynamic>> rowRecords = [];
    for (int row = 2; row <= lastRow; row++) {
      final Map<String, dynamic> record = {};
      bool hasData = false;

      for (int col = 1; col <= lastCol; col++) {
        final String? cellText = sheet.getRangeByIndex(row, col).getText();
        final String header = (col - 1) < headers.length ? headers[col - 1] : 'Column_$col';

        if (header.isNotEmpty) {
          record[header] = _autoType(cellText ?? '');
        }

        if (cellText != null && cellText.trim().isNotEmpty) {
          hasData = true;
        }
      }

      if (hasData) {
        rowRecords.add(record);
      }
    }

    workbook.dispose();
    _log.info('Successfully parsed ${rowRecords.length} records');
    return rowRecords;
  }

  // =========================================================================
  // HELPER UTILS
  // =========================================================================

  void _applyValidation(
    Worksheet sheet, {
    required int colIndex,
    String? formula,
    List<String>? staticList,
  }) {
    // Apply validation on rows 2 to 1000
    final Range range = sheet.getRangeByIndex(2, colIndex, 1000, colIndex);
    final DataValidation validation = range.dataValidation;
    validation.allowType = ExcelDataValidationType.list;

    if (formula != null) {
      validation.inputFormula1 = formula;
    } else if (staticList != null) {
      validation.listOfValues = staticList;
    }
  }

  dynamic _autoType(String value) {
    final String val = value.trim();
    if (val.isEmpty) return null;
    if (val.toLowerCase() == 'true') return true;
    if (val.toLowerCase() == 'false') return false;

    final num? parsedNum = num.tryParse(val);
    if (parsedNum != null) return parsedNum;

    return val;
  }
}
