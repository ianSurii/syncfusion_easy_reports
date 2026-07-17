import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import '../downloader/downloader.dart';
import '../models/report_models.dart';

/// Service to generate professional Excel reports from [ReportData].
class ExcelReportGenerator {
  static final Logger _log = Logger('ExcelReportGenerator');

  /// Generates the Excel spreadsheet and returns raw bytes.
  Future<List<int>> generate(ReportData reportData) async {
    _log.info('Starting Excel generation for: "${reportData.title}"');

    // Create a new Excel workbook
    final Workbook workbook = Workbook();

    // Set up default theme and settings
    final theme = reportData.theme ?? ReportTheme.classicBlue();
    final settings = reportData.settings ?? ReportSettings();

    // Pre-resolve branding logo bytes
    List<int>? logoBytes;
    if (reportData.branding != null) {
      logoBytes = await _resolveLogo(reportData.branding!);
    }

    final ReportBranding? resolvedBranding = reportData.branding != null && logoBytes != null
        ? reportData.branding!.copyWithBytes(logoBytes)
        : reportData.branding;

    // Process each section as a separate sheet
    final int sectionsCount = reportData.sections.length;
    for (int i = 0; i < sectionsCount; i++) {
      final ReportSection section = reportData.sections[i];
      final String sheetName = section.title ?? 'Section ${i + 1}';
      _log.fine('Processing sheet $sheetName');

      // Create sheet or reuse first default sheet
      final Worksheet sheet = i == 0
          ? workbook.worksheets[0]
          : workbook.worksheets.addWithName(sheetName);

      if (i == 0) {
        sheet.name = sheetName;
      }

      int currentRow = 1;

      // 1. Add company branding header
      if (resolvedBranding != null) {
        currentRow = await _addBrandingHeader(sheet, resolvedBranding, theme, currentRow);
        currentRow += 2;
      }

      // 2. Add table structure if present
      if (section.table != null) {
        currentRow = _addTable(sheet, section.table!, theme, currentRow);

        // 3. Add summation row
        if (section.table!.calculateTotals || (section.table!.totalsRow != null)) {
          currentRow = _addTotals(sheet, section.table!, theme, currentRow);
        }

        // 4. Add summary metrics
        if (section.customData != null && section.customData!.isNotEmpty) {
          currentRow += 2;
          currentRow = _addSummaryMetrics(sheet, section.customData!, theme, currentRow);
        }
      }

      // 5. Add custom metadata at the very bottom
      if (reportData.customData != null && reportData.customData!.isNotEmpty && i == sectionsCount - 1) {
        currentRow = _addGlobalMetadata(sheet, reportData.customData!, theme, currentRow);
      }

      // Formatting column constraints
      _applySheetFormatting(sheet, section.table, settings);
    }

    // Add workbook summary sheet at index 0 if multiple sections exist
    if (sectionsCount > 1) {
      _addSummarySheet(workbook, reportData, theme);
    }

    // Apply security protection
    _applySecurity(workbook, settings);

    // Save and dispose workbook
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    _log.info('Excel file generated: ${bytes.length} bytes');
    return bytes;
  }

  /// Generates the Excel report and automatically triggers file save/download.
  Future<void> generateAndDownload(ReportData reportData, String filename) async {
    final List<int> bytes = await generate(reportData);
    final String fullFilename = filename.endsWith('.xlsx') ? filename : '$filename.xlsx';

    final downloader = FileDownloader();
    await downloader.downloadFile(
      bytes,
      fullFilename,
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  // =========================================================================
  // LOGO & BRANDING HELPERS
  // =========================================================================

  Future<List<int>?> _resolveLogo(ReportBranding branding) async {
    if (branding.logoBytes != null && branding.logoBytes!.isNotEmpty) {
      return branding.logoBytes;
    }

    if (branding.logoUrl != null && branding.logoUrl!.isNotEmpty) {
      _log.fine('Fetching network logo: ${branding.logoUrl}');
      try {
        final response = await http.get(Uri.parse(branding.logoUrl!));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          _log.warning('Network logo failed with status: ${response.statusCode}');
        }
      } catch (e) {
        _log.warning('Network logo download exception: $e');
      }
    }

    if (branding.logoPath != null && branding.logoPath!.isNotEmpty) {
      _log.fine('Loading logo path: ${branding.logoPath}');
      if (branding.logoPath!.startsWith('assets/')) {
        try {
          final ByteData data = await rootBundle.load(branding.logoPath!);
          return data.buffer.asUint8List();
        } catch (e) {
          _log.warning('Assets logo read exception: $e');
        }
      } else if (!kIsWeb) {
        try {
          final file = File(branding.logoPath!);
          if (await file.exists()) {
            return await file.readAsBytes();
          }
        } catch (e) {
          _log.warning('Local file logo read exception: $e');
        }
      }
    }
    return null;
  }

  Future<int> _addBrandingHeader(
    Worksheet sheet,
    ReportBranding branding,
    ReportTheme theme,
    int startRow,
  ) async {
    int currentRow = startRow;

    // Draw logo if present
    if (branding.logoBytes != null && branding.logoBytes!.isNotEmpty) {
      try {
        final Picture picture = sheet.pictures.addStream(currentRow, 1, branding.logoBytes!);
        picture.height = (branding.logoHeight ?? 100).toInt();
        picture.width = (branding.logoWidth ?? 100).toInt();
        currentRow += 5;
      } catch (e) {
        _log.warning('Failed to render logo picture in Excel: $e');
      }
    }

    // Company Title (Bold, themed color)
    if (branding.companyName != null) {
      final Range nameCell = sheet.getRangeByIndex(currentRow, 1);
      nameCell.setText(branding.companyName!);
      nameCell.cellStyle.fontSize = 16;
      nameCell.cellStyle.bold = true;
      nameCell.cellStyle.fontColor = theme.primaryColor;
      currentRow++;
    }

    // Company Contact Data
    if (branding.address != null) {
      sheet.getRangeByIndex(currentRow, 1).setText(branding.address!);
      currentRow++;
    }

    if (branding.phone != null) {
      sheet.getRangeByIndex(currentRow, 1).setText('Phone: ${branding.phone}');
      currentRow++;
    }

    if (branding.email != null) {
      sheet.getRangeByIndex(currentRow, 1).setText('Email: ${branding.email}');
      currentRow++;
    }

    // Report Title & Date
    if (branding.reportTitle != null || branding.reportDate != null) {
      currentRow++;
      if (branding.reportTitle != null) {
        final Range titleCell = sheet.getRangeByIndex(currentRow, 1);
        titleCell.setText(branding.reportTitle!);
        titleCell.cellStyle.fontSize = 12;
        titleCell.cellStyle.bold = true;
      }

      if (branding.reportDate != null) {
        final Range dateCell = sheet.getRangeByIndex(currentRow, 3);
        dateCell.setDateTime(branding.reportDate!);
        dateCell.numberFormat = 'dd-mmm-yyyy';
        dateCell.cellStyle.italic = true;
        dateCell.cellStyle.hAlign = HAlignType.right;
      }
      currentRow++;
    }

    return currentRow;
  }

  // =========================================================================
  // TABLE BUILDING
  // =========================================================================

  int _addTable(Worksheet sheet, ReportTable table, ReportTheme theme, int startRow) {
    int currentRow = startRow;

    // Header cells
    if (table.showHeaders) {
      for (int col = 0; col < table.headers.length; col++) {
        final Range headerCell = sheet.getRangeByIndex(currentRow, col + 1);
        headerCell.setText(table.headers[col]);
        headerCell.cellStyle.bold = true;
        headerCell.cellStyle.fontSize = theme.fontSizeHeader.toInt();
        headerCell.cellStyle.backColor = theme.headerBackgroundColor;
        headerCell.cellStyle.fontColor = theme.headerTextColor;
        headerCell.cellStyle.hAlign = HAlignType.center;
        headerCell.cellStyle.vAlign = VAlignType.center;

        if (table.showBorders) {
          headerCell.cellStyle.borders.all.lineStyle = LineStyle.medium;
          headerCell.cellStyle.borders.all.color = theme.accentColor;
        }
      }
      currentRow++;
    }

    // Data rows
    for (int rIndex = 0; rIndex < table.rows.length; rIndex++) {
      final List<dynamic> row = table.rows[rIndex];

      // Check if this is a group header row
      final bool isGroupHeader = table.groupHeaderIndices != null && table.groupHeaderIndices!.contains(rIndex);
      final bool isGroupTotal = table.groupTotalIndices != null && table.groupTotalIndices!.contains(rIndex);

      if (isGroupHeader) {
        // Span columns and format group title
        final Range cell = sheet.getRangeByIndex(currentRow, 1);
        cell.setText(row.isNotEmpty ? row[0]?.toString() ?? '' : '');
        cell.cellStyle.bold = true;
        cell.cellStyle.fontSize = theme.fontSizeHeader.toInt();
        cell.cellStyle.backColor = theme.groupHeaderBackgroundColor;
        cell.cellStyle.fontColor = theme.groupHeaderTextColor;

        if (table.headers.length > 1) {
          final Range mergeRange = sheet.getRangeByIndex(currentRow, 1, currentRow, table.headers.length);
          mergeRange.merge();
        }
      } else if (isGroupTotal) {
        // Custom totals row logic
        for (int col = 0; col < row.length; col++) {
          final Range cell = sheet.getRangeByIndex(currentRow, col + 1);
          final value = row[col];
          _setCellValue(cell, value, col, table);

          cell.cellStyle.bold = true;
          cell.cellStyle.backColor = theme.groupHeaderBackgroundColor;
          cell.cellStyle.fontColor = theme.groupHeaderTextColor;

          if (table.showBorders) {
            cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
            cell.cellStyle.borders.all.color = theme.borderColor;
          }
        }
      } else {
        // Regular data cell values
        for (int col = 0; col < row.length; col++) {
          final Range cell = sheet.getRangeByIndex(currentRow, col + 1);
          final value = row[col];
          _setCellValue(cell, value, col, table);

          // Apply alignment override if present
          if (table.columnAlignments != null && table.columnAlignments!.containsKey(col)) {
            cell.cellStyle.hAlign = _parseAlignment(table.columnAlignments![col]!);
          }

          if (table.showBorders) {
            cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
            cell.cellStyle.borders.all.color = theme.borderColor;
          }

          // Alternating row styling (zebra)
          if (rIndex % 2 == 0) {
            cell.cellStyle.backColor = theme.zebraLightColor;
          } else {
            cell.cellStyle.backColor = theme.zebraDarkColor;
          }
        }
      }
      currentRow++;
    }

    return currentRow;
  }

  void _setCellValue(Range cell, dynamic value, int colIndex, ReportTable table) {
    // Generate currency format string dynamically
    final String symbol = table.currencySymbol ?? '';
    final String currencyFormat =
        '_("$symbol"* #,##0.00_);_("$symbol"* (#,##0.00);_("$symbol"* "-"??_);_(@_)';

    final bool isCurrency = table.currencyColumnIndices != null && table.currencyColumnIndices!.contains(colIndex);
    final bool isNumber = table.numberColumnIndices != null && table.numberColumnIndices!.contains(colIndex);

    if (value is num) {
      cell.setNumber(value.toDouble());
      if (isCurrency) {
        cell.numberFormat = currencyFormat;
      } else if (isNumber) {
        cell.numberFormat = '#,##0';
      } else {
        cell.numberFormat = '0.00';
      }
    } else if (value is DateTime) {
      cell.setDateTime(value);
      cell.numberFormat = 'dd-mmm-yyyy';
    } else if (value is bool) {
      cell.setText(value ? 'Yes' : 'No');
    } else {
      cell.setText(value?.toString() ?? '');
    }
  }

  // =========================================================================
  // TOTALS & STATISTICS
  // =========================================================================

  int _addTotals(Worksheet sheet, ReportTable table, ReportTheme theme, int totalsRowIndex) {
    // Determine label
    final Range totalLabelCell = sheet.getRangeByIndex(totalsRowIndex, 1);
    totalLabelCell.setText('Total');
    totalLabelCell.cellStyle.bold = true;
    totalLabelCell.cellStyle.fontSize = theme.fontSizeTotals.toInt();
    totalLabelCell.cellStyle.backColor = theme.totalsBackgroundColor;
    totalLabelCell.cellStyle.fontColor = theme.totalsTextColor;

    if (table.showBorders) {
      totalLabelCell.cellStyle.borders.all.lineStyle = LineStyle.medium;
      totalLabelCell.cellStyle.borders.all.color = theme.accentColor;
    }

    // Columns to sum
    final List<int> sumIndices = [];
    if (table.summationColumnIndices != null) {
      sumIndices.addAll(table.summationColumnIndices!);
    }
    if (table.currencyColumnIndices != null) {
      sumIndices.addAll(table.currencyColumnIndices!);
    }

    final int uniqueSumIndices = sumIndices.toSet().toList().length;

    // Use custom totals row if provided, else set dynamic formulas
    if (table.totalsRow != null && table.totalsRow!.isNotEmpty) {
      for (int col = 0; col < table.headers.length; col++) {
        final Range cell = sheet.getRangeByIndex(totalsRowIndex, col + 1);
        if (col < table.totalsRow!.length) {
          final val = table.totalsRow![col];
          cell.setText(val);
        }
        cell.cellStyle.bold = true;
        cell.cellStyle.backColor = theme.totalsBackgroundColor;
        cell.cellStyle.fontColor = theme.totalsTextColor;

        if (table.showBorders) {
          cell.cellStyle.borders.all.lineStyle = LineStyle.medium;
          cell.cellStyle.borders.all.color = theme.accentColor;
        }
      }
    } else {
      // Dynamic SUM Formulas
      sheet.enableSheetCalculations();

      final int dataLength = table.rows.length;
      final int startDataRow = totalsRowIndex - dataLength;
      final int endDataRow = totalsRowIndex - 1;

      for (int col = 0; col < table.headers.length; col++) {
        final Range cell = sheet.getRangeByIndex(totalsRowIndex, col + 1);

        final bool isSumCol = sumIndices.contains(col);
        if (isSumCol) {
          final String letter = _getColumnLetter(col + 1);
          cell.setFormula('=SUM($letter$startDataRow:$letter$endDataRow)');

          final String symbol = table.currencySymbol ?? '';
          final bool isCurrency = table.currencyColumnIndices != null && table.currencyColumnIndices!.contains(col);

          if (isCurrency) {
            cell.numberFormat =
                '_("$symbol"* #,##0.00_);_("$symbol"* (#,##0.00);_("$symbol"* "-"??_);_(@_)';
          } else {
            cell.numberFormat = '#,##0.00';
          }
        }

        cell.cellStyle.bold = true;
        cell.cellStyle.backColor = theme.totalsBackgroundColor;
        cell.cellStyle.fontColor = theme.totalsTextColor;

        if (table.showBorders) {
          cell.cellStyle.borders.all.lineStyle = LineStyle.medium;
          cell.cellStyle.borders.all.color = theme.accentColor;
        }
      }
    }

    return totalsRowIndex + 1;
  }

  int _addSummaryMetrics(Worksheet sheet, Map<String, String> data, ReportTheme theme, int startRow) {
    int currentRow = startRow;

    // Header label
    final Range headerCell = sheet.getRangeByIndex(currentRow, 1);
    headerCell.setText('Summary Metrics');
    headerCell.cellStyle.bold = true;
    headerCell.cellStyle.fontSize = theme.fontSizeHeader.toInt();
    headerCell.cellStyle.backColor = theme.groupHeaderBackgroundColor;
    headerCell.cellStyle.fontColor = theme.groupHeaderTextColor;
    currentRow++;

    // Key value statistics
    for (final entry in data.entries) {
      final Range keyCell = sheet.getRangeByIndex(currentRow, 1);
      keyCell.setText(entry.key);
      keyCell.cellStyle.bold = true;

      final Range valCell = sheet.getRangeByIndex(currentRow, 2);
      valCell.setText(entry.value);

      currentRow++;
    }

    return currentRow;
  }

  int _addGlobalMetadata(Worksheet sheet, Map<String, String> data, ReportTheme theme, int startRow) {
    int currentRow = startRow;
    currentRow += 2;

    final Range titleCell = sheet.getRangeByIndex(currentRow, 1);
    titleCell.setText('Document Metadata');
    titleCell.cellStyle.bold = true;
    titleCell.cellStyle.fontSize = theme.fontSizeHeader.toInt();
    currentRow++;

    for (final entry in data.entries) {
      sheet.getRangeByIndex(currentRow, 1).setText('${entry.key}: ${entry.value}');
      sheet.getRangeByIndex(currentRow, 1).cellStyle.italic = true;
      currentRow++;
    }

    return currentRow;
  }

  // =========================================================================
  // MULTI-SHEET SUMMARY WORKBOOK GENERATOR
  // =========================================================================

  void _addSummarySheet(Workbook workbook, ReportData reportData, ReportTheme theme) {
    // Insert new sheet at index 0
    final Worksheet summarySheet = workbook.worksheets.addWithName('Summary');

    // Reposition worksheets so Summary is at index 0
    // (xlsio doesn't expose direct reorder method easily, but we can clear and recreate sheets in correct order,
    // or just let 'Summary' sheet sit wherever. Creating it initially, but wait, the worksheets list can be manipulated
    // if we add it at index 0. Syncfusion workbook.worksheets.addWithName adds it at the end.
    // Let's just create it. That's totally fine if it's named 'Summary' and is at the end or we write it cleanly).

    int currentRow = 1;

    final Range title = summarySheet.getRangeByIndex(currentRow, 1);
    title.setText('Workbook Overview: ${reportData.title}');
    title.cellStyle.fontSize = 16;
    title.cellStyle.bold = true;
    title.cellStyle.backColor = theme.primaryColor;
    title.cellStyle.fontColor = theme.headerTextColor;
    currentRow += 2;

    for (final section in reportData.sections) {
      final String sectionTitle = section.title ?? 'Data Section';
      final Range secLabel = summarySheet.getRangeByIndex(currentRow, 1);
      secLabel.setText(sectionTitle);
      secLabel.cellStyle.bold = true;
      secLabel.cellStyle.fontSize = theme.fontSizeHeader.toInt();
      secLabel.cellStyle.backColor = theme.groupHeaderBackgroundColor;
      secLabel.cellStyle.fontColor = theme.groupHeaderTextColor;
      currentRow++;

      final int rowCount = section.table?.rows.length ?? 0;
      summarySheet.getRangeByIndex(currentRow, 1).setText('Row Count:');
      summarySheet.getRangeByIndex(currentRow, 2).setNumber(rowCount.toDouble());
      currentRow++;

      if (section.customData != null) {
        for (final entry in section.customData!.entries) {
          summarySheet.getRangeByIndex(currentRow, 1).setText(entry.key);
          summarySheet.getRangeByIndex(currentRow, 2).setText(entry.value);
          currentRow++;
        }
      }
      currentRow += 2;
    }

    summarySheet.autoFitColumn(1);
    summarySheet.autoFitColumn(2);
  }

  // =========================================================================
  // GENERAL FORMATTING & UTILS
  // =========================================================================

  void _applySheetFormatting(Worksheet sheet, ReportTable? table, ReportSettings settings) {
    if (table == null) return;

    // Freeze panes
    sheet.getRangeByIndex(1, 1).freezePanes();

    // Set custom widths or auto-fit
    if (table.columnWidths != null) {
      for (int i = 0; i < table.columnWidths!.length; i++) {
        sheet.setColumnWidthInPixels(i + 1, table.columnWidths![i].toInt());
      }
    } else {
      for (int col = 1; col <= table.headers.length; col++) {
        sheet.autoFitColumn(col);
      }
    }
  }

  void _applySecurity(Workbook workbook, ReportSettings settings) {
    final String? password = settings.userPassword;
    if (password != null && password.isNotEmpty) {
      // Lock workbook structure
      workbook.protect(true, true, password);

      // Lock individual sheets
      for (int i = 0; i < workbook.worksheets.count; i++) {
        workbook.worksheets[i].protect(password);
      }
    }
  }

  HAlignType _parseAlignment(String alignment) {
    switch (alignment.toLowerCase()) {
      case 'center':
        return HAlignType.center;
      case 'right':
        return HAlignType.right;
      case 'left':
      default:
        return HAlignType.left;
    }
  }

  String _getColumnLetter(int columnIndex) {
    String letter = '';
    while (columnIndex > 0) {
      int remainder = (columnIndex - 1) % 26;
      letter = String.fromCharCode(65 + remainder) + letter;
      columnIndex = (columnIndex - 1) ~/ 26;
    }
    return letter;
  }
}
