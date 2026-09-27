import 'dart:io' show File;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import '../engine/prepared_report.dart';
import '../engine/report_options.dart';
import '../engine/report_artifact.dart';
import '../engine/report_column.dart';
import '../models/report_models.dart';

/// Renders a [PreparedReport] into an Excel OpenXML (.xlsx) document.
class ExcelReportExporter {
  static final Logger _log = Logger('ExcelReportExporter');

  /// Exports the prepared report to a [ReportArtifact].
  Future<ReportArtifact> export(
    PreparedReport report, {
    ExcelExportOptions? options,
  }) async {
    _log.info('Exporting Excel report: "${report.title}"');
    final opts = options ?? const ExcelExportOptions();

    final Workbook workbook = Workbook();
    final theme = report.theme;

    // Pre-resolve branding logo bytes
    List<int>? logoBytes;
    if (report.branding != null) {
      logoBytes = await _resolveLogo(report.branding!);
    }
    final ReportBranding? branding =
        report.branding != null && logoBytes != null
        ? report.branding!.copyWithBytes(logoBytes)
        : report.branding;

    final Set<String> usedSheetNames = {};
    int sheetIndex = 0;

    // Optional Overview sheet first
    final bool shouldAddOverview =
        opts.includeSummarySheet && report.analyses.length > 1;
    Worksheet? overviewSheet;
    if (shouldAddOverview) {
      overviewSheet = workbook.worksheets[0];
      overviewSheet.name = 'Overview';
      usedSheetNames.add('Overview');
      sheetIndex++;
    }

    // Render analyses
    for (final analysis in report.analyses) {
      if (analysis.categorySheets != null &&
          analysis.categorySheets!.isNotEmpty) {
        // Render each category as a separate sheet
        for (final catSheet in analysis.categorySheets!) {
          final rawName = '${analysis.title} - ${catSheet.categoryLabel}';
          final sheetName = _uniqueSheetName(
            rawName,
            usedSheetNames,
            opts.maxSheetNameLength,
          );
          final sheet = sheetIndex == 0
              ? workbook.worksheets[0]
              : workbook.worksheets.addWithName(sheetName);
          if (sheetIndex == 0) sheet.name = sheetName;
          sheetIndex++;

          _renderCategorySheet(sheet, catSheet, branding, theme, opts);
        }
      } else {
        final sheetName = _uniqueSheetName(
          analysis.title,
          usedSheetNames,
          opts.maxSheetNameLength,
        );
        final sheet = sheetIndex == 0
            ? workbook.worksheets[0]
            : workbook.worksheets.addWithName(sheetName);
        if (sheetIndex == 0) sheet.name = sheetName;
        sheetIndex++;

        _renderAnalysisSheet(sheet, analysis, branding, theme, opts);
      }
    }

    // Populate overview sheet if added
    if (overviewSheet != null) {
      _populateOverviewSheet(overviewSheet, workbook, report, branding, theme);
    }

    // Apply security options
    _applySecurity(workbook, opts);

    // Save workbook bytes
    final int sheetCount = workbook.worksheets.count;
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final cleanFilename =
        '${report.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.xlsx';

    return ReportArtifact(
      bytes: bytes,
      filename: cleanFilename,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      format: ExportFormat.excel,
      warnings: report.warnings,
      metadata: {
        'sheetCount': sheetCount,
        'recordCount': report.totalRecordCount,
        'title': report.title,
      },
      generatedAt: report.generatedAt,
    );
  }

  void _renderAnalysisSheet(
    Worksheet sheet,
    PreparedAnalysis analysis,
    ReportBranding? branding,
    ReportTheme theme,
    ExcelExportOptions options,
  ) {
    int currentRow = 1;

    // 1. Branding Header
    if (branding != null) {
      currentRow = _renderBranding(sheet, branding, theme, currentRow);
      currentRow += 2;
    }

    // 2. Section Title & Subtitle
    final titleCell = sheet.getRangeByIndex(currentRow, 1);
    titleCell.setText(analysis.title);
    titleCell.cellStyle.fontSize = 14;
    titleCell.cellStyle.bold = true;
    titleCell.cellStyle.fontColor = theme.accentColor;
    currentRow++;

    if (analysis.subtitle != null && analysis.subtitle!.isNotEmpty) {
      final subCell = sheet.getRangeByIndex(currentRow, 1);
      subCell.setText(analysis.subtitle!);
      subCell.cellStyle.fontSize = 10;
      subCell.cellStyle.italic = true;
      currentRow++;
    }
    currentRow++;

    final int tableStartRow = currentRow;

    // 3. Headers
    for (int col = 0; col < analysis.headers.length; col++) {
      final h = analysis.headers[col];
      final cell = sheet.getRangeByIndex(currentRow, col + 1);
      cell.setText(h.title);
      cell.cellStyle.bold = true;
      cell.cellStyle.fontSize = theme.fontSizeHeader;
      cell.cellStyle.backColor = theme.headerBackgroundColor;
      cell.cellStyle.fontColor = theme.headerTextColor;
      cell.cellStyle.hAlign = _toExcelAlign(h.alignment);
      cell.cellStyle.vAlign = VAlignType.center;
      cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
      cell.cellStyle.borders.all.color = theme.accentColor;
    }
    currentRow++;

    // 4. Data Rows
    for (int r = 0; r < analysis.rows.length; r++) {
      final row = analysis.rows[r];
      _renderRow(sheet, row, analysis.headers, theme, currentRow, r % 2 == 0);
      currentRow++;
    }

    // 5. Grand Total Row
    if (analysis.grandTotalRow != null) {
      _renderTotalRow(
        sheet,
        analysis.grandTotalRow!,
        analysis.headers,
        theme,
        currentRow,
        tableStartRow,
      );
      currentRow++;
    }

    // 6. Summary metrics at bottom if present
    if (analysis.summaryMetrics.isNotEmpty) {
      currentRow += 2;
      currentRow = _renderSummaryCards(
        sheet,
        analysis.summaryMetrics,
        theme,
        currentRow,
      );
    }

    // 7. Signature blocks if requested
    if (options.showSignatures && options.signatureLabels.isNotEmpty) {
      currentRow += 2;
      currentRow = _renderSignatures(
        sheet,
        options.signatureLabels,
        theme,
        currentRow,
        analysis.headers.length,
      );
    }

    // 8. Auto-fit and formatting constraints
    _finalizeSheetLayout(
      sheet,
      analysis.headers.length,
      currentRow,
      tableStartRow,
      options,
    );
  }

  void _renderCategorySheet(
    Worksheet sheet,
    PreparedCategorySheet catSheet,
    ReportBranding? branding,
    ReportTheme theme,
    ExcelExportOptions options,
  ) {
    int currentRow = 1;

    if (branding != null) {
      currentRow = _renderBranding(sheet, branding, theme, currentRow);
      currentRow += 2;
    }

    final titleCell = sheet.getRangeByIndex(currentRow, 1);
    titleCell.setText(catSheet.categoryLabel);
    titleCell.cellStyle.fontSize = 14;
    titleCell.cellStyle.bold = true;
    titleCell.cellStyle.fontColor = theme.accentColor;
    currentRow += 2;

    final int tableStartRow = currentRow;

    // Headers
    for (int col = 0; col < catSheet.headers.length; col++) {
      final h = catSheet.headers[col];
      final cell = sheet.getRangeByIndex(currentRow, col + 1);
      cell.setText(h.title);
      cell.cellStyle.bold = true;
      cell.cellStyle.fontSize = theme.fontSizeHeader;
      cell.cellStyle.backColor = theme.headerBackgroundColor;
      cell.cellStyle.fontColor = theme.headerTextColor;
      cell.cellStyle.hAlign = _toExcelAlign(h.alignment);
      cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
      cell.cellStyle.borders.all.color = theme.accentColor;
    }
    currentRow++;

    // Rows
    for (int r = 0; r < catSheet.rows.length; r++) {
      final row = catSheet.rows[r];
      _renderRow(sheet, row, catSheet.headers, theme, currentRow, r % 2 == 0);
      currentRow++;
    }

    // Totals
    if (catSheet.totalsRow != null) {
      _renderTotalRow(
        sheet,
        catSheet.totalsRow!,
        catSheet.headers,
        theme,
        currentRow,
        tableStartRow,
      );
      currentRow++;
    }

    // Signatures if requested
    if (options.showSignatures && options.signatureLabels.isNotEmpty) {
      currentRow += 2;
      currentRow = _renderSignatures(
        sheet,
        options.signatureLabels,
        theme,
        currentRow,
        catSheet.headers.length,
      );
    }

    _finalizeSheetLayout(
      sheet,
      catSheet.headers.length,
      currentRow,
      tableStartRow,
      options,
    );
  }

  void _renderRow(
    Worksheet sheet,
    PreparedRow row,
    List<PreparedColumnHeader> headers,
    ReportTheme theme,
    int rowIndex,
    bool isEven,
  ) {
    if (row.isGroupHeader) {
      final cell = sheet.getRangeByIndex(rowIndex, 1);
      cell.setText(row.cells.isNotEmpty ? row.cells[0].formattedText : '');
      cell.cellStyle.bold = true;
      cell.cellStyle.fontSize = theme.fontSizeHeader;
      cell.cellStyle.backColor = theme.groupHeaderBackgroundColor;
      cell.cellStyle.fontColor = theme.groupHeaderTextColor;

      if (headers.length > 1) {
        final mergeRange = sheet.getRangeByIndex(
          rowIndex,
          1,
          rowIndex,
          headers.length,
        );
        mergeRange.merge();
      }
      return;
    }

    if (row.isSubtotal) {
      for (int c = 0; c < row.cells.length && c < headers.length; c++) {
        final cell = sheet.getRangeByIndex(rowIndex, c + 1);
        final pCell = row.cells[c];
        _setCellVal(cell, pCell, headers[c]);
        cell.cellStyle.bold = true;
        cell.cellStyle.backColor = theme.groupHeaderBackgroundColor;
        cell.cellStyle.fontColor = theme.groupHeaderTextColor;
        cell.cellStyle.borders.top.lineStyle = LineStyle.thin;
        cell.cellStyle.borders.bottom.lineStyle = LineStyle.thin;
      }
      return;
    }

    for (int c = 0; c < row.cells.length && c < headers.length; c++) {
      final cell = sheet.getRangeByIndex(rowIndex, c + 1);
      final pCell = row.cells[c];
      _setCellVal(cell, pCell, headers[c]);

      cell.cellStyle.backColor = isEven
          ? theme.zebraLightColor
          : theme.zebraDarkColor;
      cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
      cell.cellStyle.borders.all.color = theme.borderColor;
    }
  }

  void _renderTotalRow(
    Worksheet sheet,
    PreparedRow totalRow,
    List<PreparedColumnHeader> headers,
    ReportTheme theme,
    int rowIndex,
    int tableStartRow,
  ) {
    for (int c = 0; c < totalRow.cells.length && c < headers.length; c++) {
      final cell = sheet.getRangeByIndex(rowIndex, c + 1);
      final pCell = totalRow.cells[c];
      _setCellVal(cell, pCell, headers[c]);

      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = theme.totalsBackgroundColor;
      cell.cellStyle.fontColor = theme.totalsTextColor;
      cell.cellStyle.borders.top.lineStyle = LineStyle.thin;
      cell.cellStyle.borders.bottom.lineStyle = LineStyle.double;
      cell.cellStyle.borders.bottom.color = theme.accentColor;
    }
  }

  void _setCellVal(
    Range cell,
    PreparedCell pCell,
    PreparedColumnHeader header,
  ) {
    final raw = pCell.rawValue;
    cell.cellStyle.hAlign = _toExcelAlign(pCell.alignment);

    if (raw == null) {
      cell.setText(pCell.formattedText.isEmpty ? '-' : pCell.formattedText);
      return;
    }

    if (pCell.isFormula && pCell.formulaExpression != null) {
      cell.setFormula(pCell.formulaExpression!);
      return;
    }

    if (raw is num) {
      cell.setNumber(raw.toDouble());
      if (pCell.isMoney ||
          header.fieldType == ReportFieldType.money ||
          header.currencyCode != null) {
        final sym = header.currencyCode ?? pCell.currencyCode ?? '\$';
        cell.numberFormat =
            '_("$sym"* #,##0.00_);_("$sym"* (#,##0.00);_("$sym"* "-"??_);_(@_)';
      } else if (pCell.isPercentage ||
          header.fieldType == ReportFieldType.percentage) {
        cell.numberFormat = '0.0%';
      } else if (raw is int) {
        cell.numberFormat = '#,##0';
      } else {
        cell.numberFormat = '#,##0.00';
      }
      return;
    }

    if (raw is DateTime) {
      cell.setDateTime(raw);
      cell.numberFormat = 'yyyy-mm-dd';
      return;
    }

    if (raw is bool) {
      cell.setText(raw ? 'Yes' : 'No');
      return;
    }

    // Safe string handling: Escape formula injection prefix
    final strVal = raw.toString();
    if (_isFormulaInjection(strVal)) {
      cell.setText("'$strVal");
    } else {
      cell.setText(strVal);
    }
  }

  bool _isFormulaInjection(String text) {
    if (text.isEmpty) return false;
    final first = text[0];
    return first == '=' || first == '+' || first == '-' || first == '@';
  }

  int _renderBranding(
    Worksheet sheet,
    ReportBranding branding,
    ReportTheme theme,
    int startRow,
  ) {
    int row = startRow;

    if (branding.logoBytes != null && branding.logoBytes!.isNotEmpty) {
      try {
        final Picture picture = sheet.pictures.addStream(
          row,
          1,
          branding.logoBytes!,
        );
        picture.height = (branding.logoHeight ?? 60).toInt();
        picture.width = (branding.logoWidth ?? 120).toInt();
        row += 4;
      } catch (e) {
        _log.warning('Excel picture render exception: $e');
      }
    }

    if (branding.companyName != null) {
      final nameCell = sheet.getRangeByIndex(row, 1);
      nameCell.setText(branding.companyName!);
      nameCell.cellStyle.fontSize = 16;
      nameCell.cellStyle.bold = true;
      nameCell.cellStyle.fontColor = theme.primaryColor;
      row++;
    }

    if (branding.address != null) {
      sheet.getRangeByIndex(row, 1).setText(branding.address!);
      row++;
    }

    if (branding.phone != null || branding.email != null) {
      final contacts = [
        if (branding.phone != null) 'Tel: ${branding.phone}',
        if (branding.email != null) 'Email: ${branding.email}',
      ].join(' | ');
      sheet.getRangeByIndex(row, 1).setText(contacts);
      row++;
    }

    return row;
  }

  int _renderSummaryCards(
    Worksheet sheet,
    Map<String, dynamic> metrics,
    ReportTheme theme,
    int startRow,
  ) {
    int row = startRow;
    final cardTitle = sheet.getRangeByIndex(row, 1);
    cardTitle.setText('Summary Metrics');
    cardTitle.cellStyle.bold = true;
    cardTitle.cellStyle.fontSize = 11;
    cardTitle.cellStyle.fontColor = theme.primaryColor;
    row++;

    metrics.forEach((key, value) {
      final labelCell = sheet.getRangeByIndex(row, 1);
      labelCell.setText(key);
      labelCell.cellStyle.bold = true;
      labelCell.cellStyle.fontSize = 10;
      labelCell.cellStyle.backColor = theme.groupHeaderBackgroundColor;

      final valCell = sheet.getRangeByIndex(row, 2);
      valCell.setText(value?.toString() ?? '-');
      valCell.cellStyle.fontSize = 10;
      valCell.cellStyle.backColor = theme.zebraLightColor;
      row++;
    });

    return row;
  }

  int _renderSignatures(
    Worksheet sheet,
    List<String> labels,
    ReportTheme theme,
    int startRow,
    int totalCols,
  ) {
    int row = startRow;
    final int spacing = math.max(1, (totalCols ~/ labels.length));

    for (int i = 0; i < labels.length; i++) {
      final int col = (i * spacing) + 1;
      final label = labels[i];

      final lineCell = sheet.getRangeByIndex(row, col);
      lineCell.setText('______________________');
      lineCell.cellStyle.fontColor = '#888888';

      final labelCell = sheet.getRangeByIndex(row + 1, col);
      labelCell.setText(label);
      labelCell.cellStyle.bold = true;
      labelCell.cellStyle.fontSize = 9;
      labelCell.cellStyle.fontColor = theme.primaryColor;
    }

    return row + 3;
  }

  void _populateOverviewSheet(
    Worksheet sheet,
    Workbook workbook,
    PreparedReport report,
    ReportBranding? branding,
    ReportTheme theme,
  ) {
    int row = 1;

    if (branding != null) {
      row = _renderBranding(sheet, branding, theme, row);
      row += 2;
    }

    final titleCell = sheet.getRangeByIndex(row, 1);
    titleCell.setText(report.title);
    titleCell.cellStyle.fontSize = 16;
    titleCell.cellStyle.bold = true;
    titleCell.cellStyle.fontColor = theme.primaryColor;
    row += 2;

    final tocHeader = sheet.getRangeByIndex(row, 1);
    tocHeader.setText('Report Worksheets');
    tocHeader.cellStyle.bold = true;
    tocHeader.cellStyle.fontSize = 12;
    tocHeader.cellStyle.fontColor = theme.accentColor;
    row++;

    // List all other worksheets
    for (int i = 1; i < workbook.worksheets.count; i++) {
      final targetSheet = workbook.worksheets[i];
      final linkCell = sheet.getRangeByIndex(row, 1);
      linkCell.setText('• ${targetSheet.name}');
      linkCell.cellStyle.fontSize = 11;
      linkCell.cellStyle.fontColor = '#1565C0';

      final countCell = sheet.getRangeByIndex(row, 2);
      countCell.setText('Worksheet #$i');
      countCell.cellStyle.italic = true;
      countCell.cellStyle.fontColor = '#666666';
      row++;
    }

    row += 2;
    final metaHeader = sheet.getRangeByIndex(row, 1);
    metaHeader.setText('Report Metadata');
    metaHeader.cellStyle.bold = true;
    metaHeader.cellStyle.fontSize = 12;
    metaHeader.cellStyle.fontColor = theme.accentColor;
    row++;

    sheet
        .getRangeByIndex(row, 1)
        .setText(
          'Generated: ${report.generatedAt.toIso8601String().substring(0, 19)}',
        );
    row++;
    sheet
        .getRangeByIndex(row, 1)
        .setText('Total Records: ${report.totalRecordCount}');
    row++;
    sheet
        .getRangeByIndex(row, 1)
        .setText(
          'Status: ${report.isReconciled ? "Reconciled & Verified" : "Contains Warnings"}',
        );

    sheet.autoFitColumn(1);
    sheet.autoFitColumn(2);
  }

  void _finalizeSheetLayout(
    Worksheet sheet,
    int colCount,
    int totalRows,
    int tableStartRow,
    ExcelExportOptions options,
  ) {
    // Auto-fit column widths with safety limits
    for (int c = 1; c <= colCount; c++) {
      try {
        sheet.autoFitColumn(c);
      } catch (_) {}
    }

    // Auto-filter on detail tables
    if (options.enableAutoFilter &&
        totalRows > tableStartRow + 1 &&
        colCount > 0) {
      try {
        sheet.autoFilters.filterRange = sheet.getRangeByIndex(
          tableStartRow,
          1,
          totalRows - 1,
          colCount,
        );
      } catch (_) {}
    }
  }

  void _applySecurity(Workbook workbook, ExcelExportOptions options) {
    if (options.protectWorksheets) {
      final pass = options.worksheetPassword ?? 'EasyReportsProtected';
      for (int i = 0; i < workbook.worksheets.count; i++) {
        final sheet = workbook.worksheets[i];
        sheet.protect(pass);
      }
    }

    if (options.protectWorkbook &&
        options.workbookPassword != null &&
        options.workbookPassword!.isNotEmpty) {
      workbook.protect(true, true, options.workbookPassword!);
    }
  }

  String _uniqueSheetName(
    String baseName,
    Set<String> existingNames,
    int maxLength,
  ) {
    var name = baseName.replaceAll(RegExp(r'[\\/?*\[\]:]'), '_').trim();
    if (name.isEmpty) name = 'Sheet';
    if (name.length > maxLength) name = name.substring(0, maxLength);

    if (!existingNames.contains(name)) {
      existingNames.add(name);
      return name;
    }

    int suffix = 1;
    while (true) {
      final candidateSuffix = '_$suffix';
      final allowedBaseLen = maxLength - candidateSuffix.length;
      final truncated = name.length > allowedBaseLen
          ? name.substring(0, allowedBaseLen)
          : name;
      final candidate = '$truncated$candidateSuffix';
      if (!existingNames.contains(candidate)) {
        existingNames.add(candidate);
        return candidate;
      }
      suffix++;
    }
  }

  HAlignType _toExcelAlign(ReportColumnAlignment align) {
    switch (align) {
      case ReportColumnAlignment.left:
        return HAlignType.left;
      case ReportColumnAlignment.center:
        return HAlignType.center;
      case ReportColumnAlignment.right:
        return HAlignType.right;
    }
  }

  Future<List<int>?> _resolveLogo(ReportBranding branding) async {
    if (branding.logoBytes != null && branding.logoBytes!.isNotEmpty) {
      return branding.logoBytes;
    }
    if (branding.logoUrl != null && branding.logoUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(branding.logoUrl!));
        if (response.statusCode == 200) return response.bodyBytes;
      } catch (e) {
        _log.warning('Logo URL fetch error: $e');
      }
    }
    if (branding.logoPath != null && branding.logoPath!.isNotEmpty) {
      if (branding.logoPath!.startsWith('assets/')) {
        try {
          final ByteData data = await rootBundle.load(branding.logoPath!);
          return data.buffer.asUint8List();
        } catch (_) {}
      } else if (!kIsWeb) {
        try {
          final file = File(branding.logoPath!);
          if (await file.exists()) return await file.readAsBytes();
        } catch (_) {}
      }
    }
    return null;
  }
}
