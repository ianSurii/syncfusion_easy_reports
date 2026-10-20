import 'dart:io' show File;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import '../engine/prepared_report.dart';
import '../engine/report_options.dart';
import '../engine/report_artifact.dart';
import '../engine/report_column.dart';
import '../models/report_models.dart';
import '../utils/image_geometry.dart';
import '../utils/text_utils.dart';
import 'report_chart_data.dart';

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
        if (analysis.rows.isNotEmpty) {
          final summarySheetName = _uniqueSheetName(
            analysis.title,
            usedSheetNames,
            opts.maxSheetNameLength,
          );
          final sheet = sheetIndex == 0
              ? workbook.worksheets[0]
              : workbook.worksheets.addWithName(summarySheetName);
          if (sheetIndex == 0) sheet.name = summarySheetName;
          sheetIndex++;

          _renderAnalysisSheet(sheet, analysis, branding, theme, opts, report);
        }

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

          _renderCategorySheet(sheet, catSheet, branding, theme, opts, report);
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

        _renderAnalysisSheet(sheet, analysis, branding, theme, opts, report);
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
    PreparedReport report,
  ) {
    int currentRow = 1;

    // 1. Branding Header
    if (branding != null) {
      currentRow = _renderBranding(
        sheet,
        branding,
        theme,
        currentRow,
        colCount: analysis.headers.length,
      );
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
      cell.cellStyle.fontName = theme.fontFamily;
      cell.cellStyle.bold = true;
      cell.cellStyle.fontSize = theme.fontSizeHeader;
      cell.cellStyle.backColor = theme.headerBackgroundColor;
      cell.cellStyle.fontColor = theme.headerTextColor;
      cell.cellStyle.hAlign = _toExcelAlign(h.alignment);
      cell.cellStyle.vAlign = VAlignType.center;

      switch (options.tableBorderStyle) {
        case TableBorderStyle.grid:
          cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
          cell.cellStyle.borders.all.color = theme.accentColor;
          break;
        case TableBorderStyle.clean:
        case TableBorderStyle.horizontalOnly:
        case TableBorderStyle.headerAndTotalOnly:
          cell.cellStyle.borders.bottom.lineStyle = LineStyle.medium;
          cell.cellStyle.borders.bottom.color = theme.accentColor;
          break;
        case TableBorderStyle.none:
          break;
      }
    }
    currentRow++;

    // 4. Data Rows
    for (int r = 0; r < analysis.rows.length; r++) {
      final row = analysis.rows[r];
      _renderRow(
        sheet,
        row,
        analysis.headers,
        theme,
        currentRow,
        r % 2 == 0,
        borderStyle: options.tableBorderStyle,
      );
      currentRow++;
    }
    final int dataEndRow = math.max(tableStartRow, currentRow - 1);

    // 5. Grand Total Row
    if (analysis.grandTotalRow != null) {
      _renderTotalRow(
        sheet,
        analysis.grandTotalRow!,
        analysis.headers,
        theme,
        currentRow,
        tableStartRow,
        borderStyle: options.tableBorderStyle,
      );
      currentRow++;
    }

    // 6. Chart Visual Distribution if configured
    if (analysis.chart != null) {
      currentRow += 2;
      currentRow = _renderChartSummaryBlock(
        sheet: sheet,
        chart: analysis.chart!,
        analysis: analysis,
        theme: theme,
        startRow: currentRow,
        totalCols: analysis.headers.length,
      );
    }

    // 7. Summary metrics at bottom if present
    if (analysis.summaryMetrics.isNotEmpty) {
      currentRow += 2;
      currentRow = _renderSummaryCards(
        sheet,
        analysis.summaryMetrics,
        theme,
        currentRow,
      );
    }

    // 8. Bottom Financial Summaries, Payment Details & Signatures
    final summaryItems = options.summaryItems ?? report.summaryItems;
    final paymentDetails = options.paymentDetails ?? report.paymentDetails;
    final paymentPos =
        options.paymentDetailsPosition ??
        paymentDetails?.position ??
        PaymentDetailsPosition.sideBySide;

    if (paymentPos == PaymentDetailsPosition.sideBySide) {
      if ((summaryItems != null && summaryItems.isNotEmpty) ||
          paymentDetails != null) {
        currentRow += 2;
        currentRow = _renderSummaryAndPaymentBlock(
          sheet: sheet,
          startRow: currentRow,
          colCount: analysis.headers.length,
          summaryItems: summaryItems,
          paymentDetails: paymentDetails,
          theme: theme,
        );
      }
      if (options.showSignatures && options.effectiveSignatures.isNotEmpty) {
        currentRow += 3;
        currentRow = _renderSignatures(
          sheet,
          options.effectiveSignatures,
          options.signatureLayout,
          theme,
          currentRow,
          analysis.headers.length,
        );
      }
    } else if (paymentPos == PaymentDetailsPosition.belowSummary) {
      if (summaryItems != null && summaryItems.isNotEmpty) {
        currentRow += 2;
        currentRow = _renderSummaryTotalsOnly(
          sheet: sheet,
          startRow: currentRow,
          colCount: analysis.headers.length,
          summaryItems: summaryItems,
          theme: theme,
        );
      }
      if (paymentDetails != null) {
        currentRow += 2;
        currentRow = _renderPaymentDetailsOnly(
          sheet: sheet,
          startRow: currentRow,
          paymentDetails: paymentDetails,
          theme: theme,
        );
      }
      if (options.showSignatures && options.effectiveSignatures.isNotEmpty) {
        currentRow += 3;
        currentRow = _renderSignatures(
          sheet,
          options.effectiveSignatures,
          options.signatureLayout,
          theme,
          currentRow,
          analysis.headers.length,
        );
      }
    } else if (paymentPos == PaymentDetailsPosition.afterSignatures) {
      if (summaryItems != null && summaryItems.isNotEmpty) {
        currentRow += 2;
        currentRow = _renderSummaryTotalsOnly(
          sheet: sheet,
          startRow: currentRow,
          colCount: analysis.headers.length,
          summaryItems: summaryItems,
          theme: theme,
        );
      }
      if (options.showSignatures && options.effectiveSignatures.isNotEmpty) {
        currentRow += 3;
        currentRow = _renderSignatures(
          sheet,
          options.effectiveSignatures,
          options.signatureLayout,
          theme,
          currentRow,
          analysis.headers.length,
        );
      }
      if (paymentDetails != null) {
        currentRow += 2;
        currentRow = _renderPaymentDetailsOnly(
          sheet: sheet,
          startRow: currentRow,
          paymentDetails: paymentDetails,
          theme: theme,
        );
      }
    }

    // 10. Auto-fit and formatting constraints (strictly bounded to data rows)
    _finalizeSheetLayout(
      sheet,
      analysis.headers.length,
      tableStartRow,
      dataEndRow,
      options,
    );
  }

  void _renderCategorySheet(
    Worksheet sheet,
    PreparedCategorySheet catSheet,
    ReportBranding? branding,
    ReportTheme theme,
    ExcelExportOptions options,
    PreparedReport report,
  ) {
    int currentRow = 1;

    if (branding != null) {
      currentRow = _renderBranding(
        sheet,
        branding,
        theme,
        currentRow,
        colCount: catSheet.headers.length,
      );
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
      cell.cellStyle.fontName = theme.fontFamily;
      cell.cellStyle.bold = true;
      cell.cellStyle.fontSize = theme.fontSizeHeader;
      cell.cellStyle.backColor = theme.headerBackgroundColor;
      cell.cellStyle.fontColor = theme.headerTextColor;
      cell.cellStyle.hAlign = _toExcelAlign(h.alignment);

      switch (options.tableBorderStyle) {
        case TableBorderStyle.grid:
          cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
          cell.cellStyle.borders.all.color = theme.accentColor;
          break;
        case TableBorderStyle.clean:
        case TableBorderStyle.horizontalOnly:
        case TableBorderStyle.headerAndTotalOnly:
          cell.cellStyle.borders.bottom.lineStyle = LineStyle.medium;
          cell.cellStyle.borders.bottom.color = theme.accentColor;
          break;
        case TableBorderStyle.none:
          break;
      }
    }
    currentRow++;

    // Rows
    for (int r = 0; r < catSheet.rows.length; r++) {
      final row = catSheet.rows[r];
      _renderRow(
        sheet,
        row,
        catSheet.headers,
        theme,
        currentRow,
        r % 2 == 0,
        borderStyle: options.tableBorderStyle,
      );
      currentRow++;
    }
    final int dataEndRow = math.max(tableStartRow, currentRow - 1);

    // Totals
    if (catSheet.totalsRow != null) {
      _renderTotalRow(
        sheet,
        catSheet.totalsRow!,
        catSheet.headers,
        theme,
        currentRow,
        tableStartRow,
        borderStyle: options.tableBorderStyle,
      );
      currentRow++;
    }

    // Bottom Financial Summaries, Payment Details & Signatures
    final summaryItems = options.summaryItems ?? report.summaryItems;
    final paymentDetails = options.paymentDetails ?? report.paymentDetails;
    final paymentPos =
        options.paymentDetailsPosition ??
        paymentDetails?.position ??
        PaymentDetailsPosition.sideBySide;

    if (paymentPos == PaymentDetailsPosition.sideBySide) {
      if ((summaryItems != null && summaryItems.isNotEmpty) ||
          paymentDetails != null) {
        currentRow += 2;
        currentRow = _renderSummaryAndPaymentBlock(
          sheet: sheet,
          startRow: currentRow,
          colCount: catSheet.headers.length,
          summaryItems: summaryItems,
          paymentDetails: paymentDetails,
          theme: theme,
        );
      }
      if (options.showSignatures && options.effectiveSignatures.isNotEmpty) {
        currentRow += 3;
        currentRow = _renderSignatures(
          sheet,
          options.effectiveSignatures,
          options.signatureLayout,
          theme,
          currentRow,
          catSheet.headers.length,
        );
      }
    } else if (paymentPos == PaymentDetailsPosition.belowSummary) {
      if (summaryItems != null && summaryItems.isNotEmpty) {
        currentRow += 2;
        currentRow = _renderSummaryTotalsOnly(
          sheet: sheet,
          startRow: currentRow,
          colCount: catSheet.headers.length,
          summaryItems: summaryItems,
          theme: theme,
        );
      }
      if (paymentDetails != null) {
        currentRow += 2;
        currentRow = _renderPaymentDetailsOnly(
          sheet: sheet,
          startRow: currentRow,
          paymentDetails: paymentDetails,
          theme: theme,
        );
      }
      if (options.showSignatures && options.effectiveSignatures.isNotEmpty) {
        currentRow += 3;
        currentRow = _renderSignatures(
          sheet,
          options.effectiveSignatures,
          options.signatureLayout,
          theme,
          currentRow,
          catSheet.headers.length,
        );
      }
    } else if (paymentPos == PaymentDetailsPosition.afterSignatures) {
      if (summaryItems != null && summaryItems.isNotEmpty) {
        currentRow += 2;
        currentRow = _renderSummaryTotalsOnly(
          sheet: sheet,
          startRow: currentRow,
          colCount: catSheet.headers.length,
          summaryItems: summaryItems,
          theme: theme,
        );
      }
      if (options.showSignatures && options.effectiveSignatures.isNotEmpty) {
        currentRow += 3;
        currentRow = _renderSignatures(
          sheet,
          options.effectiveSignatures,
          options.signatureLayout,
          theme,
          currentRow,
          catSheet.headers.length,
        );
      }
      if (paymentDetails != null) {
        currentRow += 2;
        currentRow = _renderPaymentDetailsOnly(
          sheet: sheet,
          startRow: currentRow,
          paymentDetails: paymentDetails,
          theme: theme,
        );
      }
    }

    _finalizeSheetLayout(
      sheet,
      catSheet.headers.length,
      tableStartRow,
      dataEndRow,
      options,
    );
  }

  void _renderRow(
    Worksheet sheet,
    PreparedRow row,
    List<PreparedColumnHeader> headers,
    ReportTheme theme,
    int rowIndex,
    bool isEven, {
    TableBorderStyle borderStyle = TableBorderStyle.clean,
  }) {
    if (row.isGroupHeader) {
      final cell = sheet.getRangeByIndex(rowIndex, 1);
      cell.setText(row.cells.isNotEmpty ? row.cells[0].formattedText : '');
      cell.cellStyle.fontName = theme.fontFamily;
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
        cell.cellStyle.fontName = theme.fontFamily;
        cell.cellStyle.bold = true;
        cell.cellStyle.backColor = theme.groupHeaderBackgroundColor;
        cell.cellStyle.fontColor = theme.groupHeaderTextColor;
        if (borderStyle != TableBorderStyle.none) {
          cell.cellStyle.borders.top.lineStyle = LineStyle.thin;
          cell.cellStyle.borders.bottom.lineStyle = LineStyle.thin;
        }
      }
      return;
    }

    for (int c = 0; c < row.cells.length && c < headers.length; c++) {
      final cell = sheet.getRangeByIndex(rowIndex, c + 1);
      final pCell = row.cells[c];
      _setCellVal(cell, pCell, headers[c]);

      cell.cellStyle.fontName = theme.fontFamily;
      cell.cellStyle.fontSize = theme.fontSizeBody;
      cell.cellStyle.backColor = isEven
          ? theme.zebraLightColor
          : theme.zebraDarkColor;

      switch (borderStyle) {
        case TableBorderStyle.grid:
          cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
          cell.cellStyle.borders.all.color = theme.borderColor;
          break;
        case TableBorderStyle.horizontalOnly:
          cell.cellStyle.borders.bottom.lineStyle = LineStyle.thin;
          cell.cellStyle.borders.bottom.color = theme.borderColor;
          break;
        case TableBorderStyle.clean:
        case TableBorderStyle.headerAndTotalOnly:
        case TableBorderStyle.none:
          break;
      }
    }
  }

  void _renderTotalRow(
    Worksheet sheet,
    PreparedRow totalRow,
    List<PreparedColumnHeader> headers,
    ReportTheme theme,
    int rowIndex,
    int tableStartRow, {
    TableBorderStyle borderStyle = TableBorderStyle.clean,
  }) {
    for (int c = 0; c < totalRow.cells.length && c < headers.length; c++) {
      final cell = sheet.getRangeByIndex(rowIndex, c + 1);
      final pCell = totalRow.cells[c];
      _setCellVal(cell, pCell, headers[c]);

      cell.cellStyle.fontName = theme.fontFamily;
      cell.cellStyle.fontSize = theme.fontSizeTotals;
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = theme.totalsBackgroundColor;
      cell.cellStyle.fontColor = theme.totalsTextColor;

      switch (borderStyle) {
        case TableBorderStyle.grid:
          cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
          cell.cellStyle.borders.all.color = theme.borderColor;
          cell.cellStyle.borders.bottom.lineStyle = LineStyle.double;
          cell.cellStyle.borders.bottom.color = theme.accentColor;
          break;
        case TableBorderStyle.clean:
        case TableBorderStyle.horizontalOnly:
        case TableBorderStyle.headerAndTotalOnly:
          cell.cellStyle.borders.top.lineStyle = LineStyle.thin;
          cell.cellStyle.borders.top.color = theme.borderColor;
          cell.cellStyle.borders.bottom.lineStyle = LineStyle.double;
          cell.cellStyle.borders.bottom.color = theme.accentColor;
          break;
        case TableBorderStyle.none:
          break;
      }
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
    int startRow, {
    int colCount = 4,
  }) {
    final bool hasLogo =
        branding.logoBytes != null && branding.logoBytes!.isNotEmpty;
    final double logoHeight = (branding.logoHeight ?? 50).toDouble();
    final double logoWidth = (branding.logoWidth ?? 90).toDouble();

    // Excel default row height is ~15-18pt.
    // Calculate the rows spanned by the logo with generous safe padding.
    final int logoRows = (logoHeight / 17.0).ceil() + 1;

    int textRows = 0;
    if (branding.companyName != null) textRows++;
    if (branding.address != null && branding.address!.isNotEmpty) textRows++;
    if (branding.phone != null || branding.email != null) textRows++;

    if (!hasLogo) {
      int r = startRow;
      if (branding.companyName != null) {
        final cell = sheet.getRangeByIndex(r, 1);
        cell.setText(branding.companyName!);
        cell.cellStyle.fontSize = 15;
        cell.cellStyle.bold = true;
        cell.cellStyle.fontColor = theme.primaryColor;
        r++;
      }
      if (branding.address != null && branding.address!.isNotEmpty) {
        final cell = sheet.getRangeByIndex(r, 1);
        cell.setText(branding.address!);
        cell.cellStyle.fontSize = 10;
        cell.cellStyle.fontColor = '#555555';
        r++;
      }
      if (branding.phone != null || branding.email != null) {
        final contacts = [
          if (branding.phone != null) 'Tel: ${branding.phone}',
          if (branding.email != null) 'Email: ${branding.email}',
        ].join(' | ');
        final cell = sheet.getRangeByIndex(r, 1);
        cell.setText(contacts);
        cell.cellStyle.fontSize = 9.5;
        cell.cellStyle.fontColor = '#777777';
        r++;
      }
      return r;
    }

    switch (branding.layout) {
      case BrandingLayout.stacked:
        // 1. Draw logo at top (startRow, 1)
        try {
          final Picture picture = sheet.pictures.addStream(
            startRow,
            1,
            branding.logoBytes!,
          );
          _fitPictureWithinBounds(picture, logoWidth, logoHeight);
        } catch (e) {
          _log.warning('Excel picture render exception: $e');
        }

        // 2. Set safe starting row cleanly below the logo
        int r = startRow + logoRows + 1;

        if (branding.companyName != null) {
          final nameCell = sheet.getRangeByIndex(r, 1);
          nameCell.setText(branding.companyName!);
          nameCell.cellStyle.fontSize = 15;
          nameCell.cellStyle.bold = true;
          nameCell.cellStyle.fontColor = theme.primaryColor;
          r++;
        }

        if (branding.address != null && branding.address!.isNotEmpty) {
          final addrCell = sheet.getRangeByIndex(r, 1);
          addrCell.setText(branding.address!);
          addrCell.cellStyle.fontSize = 10;
          addrCell.cellStyle.fontColor = '#555555';
          r++;
        }

        if (branding.phone != null || branding.email != null) {
          final contacts = [
            if (branding.phone != null) 'Tel: ${branding.phone}',
            if (branding.email != null) 'Email: ${branding.email}',
          ].join(' | ');
          final contactCell = sheet.getRangeByIndex(r, 1);
          contactCell.setText(contacts);
          contactCell.cellStyle.fontSize = 9.5;
          contactCell.cellStyle.fontColor = '#777777';
          r++;
        }
        return r;

      case BrandingLayout.sideBySide:
        // Logo in Column 1 (Left), Company details in Column 2 (Right)
        try {
          final Picture picture = sheet.pictures.addStream(
            startRow,
            1,
            branding.logoBytes!,
          );
          _fitPictureWithinBounds(picture, logoWidth, logoHeight);
        } catch (e) {
          _log.warning('Excel picture render exception: $e');
        }

        // Ensure Column 1 accommodates logo width without bleeding into Column 2
        try {
          final colWidthInChars = (logoWidth / 6.5) + 3.0;
          final col = sheet.columns[0];
          if (col != null && col.width < colWidthInChars) {
            col.width = colWidthInChars;
          }
        } catch (_) {}

        int textRow = startRow;
        if (branding.companyName != null) {
          final nameCell = sheet.getRangeByIndex(textRow, 2);
          nameCell.setText(branding.companyName!);
          nameCell.cellStyle.fontSize = 15;
          nameCell.cellStyle.bold = true;
          nameCell.cellStyle.fontColor = theme.primaryColor;
          textRow++;
        }

        if (branding.address != null && branding.address!.isNotEmpty) {
          final addrCell = sheet.getRangeByIndex(textRow, 2);
          addrCell.setText(branding.address!);
          addrCell.cellStyle.fontSize = 10;
          addrCell.cellStyle.fontColor = '#555555';
          textRow++;
        }

        if (branding.phone != null || branding.email != null) {
          final contacts = [
            if (branding.phone != null) 'Tel: ${branding.phone}',
            if (branding.email != null) 'Email: ${branding.email}',
          ].join(' | ');
          final contactCell = sheet.getRangeByIndex(textRow, 2);
          contactCell.setText(contacts);
          contactCell.cellStyle.fontSize = 9.5;
          contactCell.cellStyle.fontColor = '#777777';
          textRow++;
        }

        final maxSpan = math.max(logoRows, textRows);
        return startRow + maxSpan + 1;

      case BrandingLayout.topRightLogo:
        // Text in Column 1, Logo on the top-right column
        int textRow = startRow;
        if (branding.companyName != null) {
          final nameCell = sheet.getRangeByIndex(textRow, 1);
          nameCell.setText(branding.companyName!);
          nameCell.cellStyle.fontSize = 15;
          nameCell.cellStyle.bold = true;
          nameCell.cellStyle.fontColor = theme.primaryColor;
          textRow++;
        }

        if (branding.address != null && branding.address!.isNotEmpty) {
          final addrCell = sheet.getRangeByIndex(textRow, 1);
          addrCell.setText(branding.address!);
          addrCell.cellStyle.fontSize = 10;
          addrCell.cellStyle.fontColor = '#555555';
          textRow++;
        }

        if (branding.phone != null || branding.email != null) {
          final contacts = [
            if (branding.phone != null) 'Tel: ${branding.phone}',
            if (branding.email != null) 'Email: ${branding.email}',
          ].join(' | ');
          final contactCell = sheet.getRangeByIndex(textRow, 1);
          contactCell.setText(contacts);
          contactCell.cellStyle.fontSize = 9.5;
          contactCell.cellStyle.fontColor = '#777777';
          textRow++;
        }

        final int rightCol = math.max(3, colCount);
        try {
          final Picture picture = sheet.pictures.addStream(
            startRow,
            rightCol,
            branding.logoBytes!,
          );
          _fitPictureWithinBounds(picture, logoWidth, logoHeight);
        } catch (e) {
          _log.warning('Excel picture render exception: $e');
        }

        final maxSpan = math.max(logoRows, textRows);
        return startRow + maxSpan + 1;
    }
  }

  void _fitPictureWithinBounds(
    Picture picture,
    double maxWidth,
    double maxHeight,
  ) {
    final size = fitImageWithinBounds(
      imageWidth: picture.width.toDouble(),
      imageHeight: picture.height.toDouble(),
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    picture.width = size.width.round();
    picture.height = size.height.round();
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
      labelCell.setText(toTitleCase(key));
      labelCell.cellStyle.bold = true;
      labelCell.cellStyle.fontSize = 10;
      labelCell.cellStyle.backColor = theme.groupHeaderBackgroundColor;

      final valCell = sheet.getRangeByIndex(row, 2);
      String valStr = value?.toString() ?? '-';
      if (value is num) {
        valStr = NumberFormat('#,##0.##').format(value.toDouble());
      }
      valCell.setText(valStr);
      valCell.cellStyle.fontSize = 10;
      valCell.cellStyle.backColor = theme.zebraLightColor;
      row++;
    });

    return row;
  }

  int _renderChartSummaryBlock({
    required Worksheet sheet,
    required ReportChartConfig chart,
    required PreparedAnalysis analysis,
    required ReportTheme theme,
    required int startRow,
    required int totalCols,
  }) {
    final points = ReportChartData.fromAnalysis(analysis);
    if (points.isEmpty) return startRow;

    int row = startRow;
    final titleCell = sheet.getRangeByIndex(row, 1);
    titleCell.setText(
      '📊 ${chart.title ?? "Analysis Breakdown (${chart.categoryColumn})"}:',
    );
    titleCell.cellStyle.fontName = theme.fontFamily;
    titleCell.cellStyle.bold = true;
    titleCell.cellStyle.fontSize = 11;
    titleCell.cellStyle.fontColor = theme.primaryColor;
    row += 2;

    sheet.getRangeByIndex(row, 1).setText('Category');
    sheet.getRangeByIndex(row, 1).cellStyle.fontName = theme.fontFamily;
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 1).cellStyle.backColor =
        theme.groupHeaderBackgroundColor;
    sheet.getRangeByIndex(row, 2).setText('Amount / Value');
    sheet.getRangeByIndex(row, 2).cellStyle.fontName = theme.fontFamily;
    sheet.getRangeByIndex(row, 2).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 2).cellStyle.backColor =
        theme.groupHeaderBackgroundColor;
    sheet.getRangeByIndex(row, 3).setText('Visual Distribution');
    sheet.getRangeByIndex(row, 3).cellStyle.fontName = theme.fontFamily;
    sheet.getRangeByIndex(row, 3).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 3).cellStyle.backColor =
        theme.groupHeaderBackgroundColor;
    row++;

    final num maxVal = points.fold<num>(
      0,
      (maximum, point) => math.max(maximum, point.value.abs()),
    );
    for (final point in points) {
      final catCell = sheet.getRangeByIndex(row, 1);
      catCell.setText(point.label);
      catCell.cellStyle.fontName = theme.fontFamily;

      final valCell = sheet.getRangeByIndex(row, 2);
      if (chart.showValues) valCell.setText(point.value.toString());
      valCell.cellStyle.fontName = theme.fontFamily;

      final pct = maxVal == 0 ? 0.0 : (point.value.abs() / maxVal);
      final filledBlocks = (pct * 12).round();
      final bar = '█' * filledBlocks + '░' * (12 - filledBlocks);
      final barCell = sheet.getRangeByIndex(row, 3);
      barCell.setText(
        chart.showValues ? '$bar ${(pct * 100).toStringAsFixed(0)}%' : bar,
      );
      barCell.cellStyle.fontName = theme.fontFamily;
      barCell.cellStyle.fontColor = theme.accentColor;
      row++;
    }
    return row + 1;
  }

  int _renderSummaryAndPaymentBlock({
    required Worksheet sheet,
    required int startRow,
    required int colCount,
    List<ReportSummaryItem>? summaryItems,
    ReportPaymentDetails? paymentDetails,
    required ReportTheme theme,
  }) {
    int row = startRow;
    int paymentEndRow = row;
    int summaryEndRow = row;

    // 1. Payment Details & Notes on the Left (Columns 1-2)
    if (paymentDetails != null) {
      int pRow = row;
      final headerCell = sheet.getRangeByIndex(pRow, 1);
      headerCell.setText('Payment & Remittance Instructions:');
      headerCell.cellStyle.fontName = theme.fontFamily;
      headerCell.cellStyle.bold = true;
      headerCell.cellStyle.fontSize = 9.5;
      headerCell.cellStyle.fontColor = theme.primaryColor;
      pRow++;

      if (paymentDetails.bankName != null) {
        final lbl = sheet.getRangeByIndex(pRow, 1);
        lbl.setText('Bank Name:');
        lbl.cellStyle.fontName = theme.fontFamily;
        lbl.cellStyle.fontSize = 9;
        final val = sheet.getRangeByIndex(pRow, 2);
        val.setText(paymentDetails.bankName!);
        val.cellStyle.fontName = theme.fontFamily;
        val.cellStyle.fontSize = 9;
        pRow++;
      }
      if (paymentDetails.accountName != null) {
        final lbl = sheet.getRangeByIndex(pRow, 1);
        lbl.setText('Account Name:');
        lbl.cellStyle.fontName = theme.fontFamily;
        lbl.cellStyle.fontSize = 9;
        final val = sheet.getRangeByIndex(pRow, 2);
        val.setText(paymentDetails.accountName!);
        val.cellStyle.fontName = theme.fontFamily;
        val.cellStyle.fontSize = 9;
        pRow++;
      }
      if (paymentDetails.accountNumber != null) {
        final lbl = sheet.getRangeByIndex(pRow, 1);
        lbl.setText('Account No:');
        lbl.cellStyle.fontName = theme.fontFamily;
        lbl.cellStyle.fontSize = 9;
        final val = sheet.getRangeByIndex(pRow, 2);
        val.setText(paymentDetails.accountNumber!);
        val.cellStyle.fontName = theme.fontFamily;
        val.cellStyle.fontSize = 9;
        val.cellStyle.bold = true;
        pRow++;
      }
      if (paymentDetails.branch != null) {
        final lbl = sheet.getRangeByIndex(pRow, 1);
        lbl.setText('Branch:');
        lbl.cellStyle.fontName = theme.fontFamily;
        lbl.cellStyle.fontSize = 9;
        final val = sheet.getRangeByIndex(pRow, 2);
        val.setText(paymentDetails.branch!);
        val.cellStyle.fontName = theme.fontFamily;
        val.cellStyle.fontSize = 9;
        pRow++;
      }
      if (paymentDetails.swiftCode != null) {
        final lbl = sheet.getRangeByIndex(pRow, 1);
        lbl.setText('SWIFT / BIC:');
        lbl.cellStyle.fontName = theme.fontFamily;
        lbl.cellStyle.fontSize = 9;
        final val = sheet.getRangeByIndex(pRow, 2);
        val.setText(paymentDetails.swiftCode!);
        val.cellStyle.fontName = theme.fontFamily;
        val.cellStyle.fontSize = 9;
        pRow++;
      }
      for (final note in paymentDetails.termsOrNotes) {
        final lbl = sheet.getRangeByIndex(pRow, 1);
        lbl.setText('Note:');
        lbl.cellStyle.fontName = theme.fontFamily;
        lbl.cellStyle.fontSize = 8.5;
        lbl.cellStyle.italic = true;
        final val = sheet.getRangeByIndex(pRow, 2);
        val.setText(note);
        val.cellStyle.fontName = theme.fontFamily;
        val.cellStyle.fontSize = 8.5;
        val.cellStyle.italic = true;
        pRow++;
      }
      paymentEndRow = pRow;
    }

    // 2. Financial Summaries on the Right (Columns colCount - 1 and colCount)
    if (summaryItems != null && summaryItems.isNotEmpty) {
      int sRow = row;
      final int labelCol = math.max(1, colCount - 1);
      final int valCol = colCount;

      for (final item in summaryItems) {
        final labelCell = sheet.getRangeByIndex(sRow, labelCol);
        labelCell.setText(item.label);
        labelCell.cellStyle.fontName = theme.fontFamily;
        labelCell.cellStyle.hAlign = HAlignType.right;
        labelCell.cellStyle.fontSize = item.isEmphasized ? 11 : 9.5;
        labelCell.cellStyle.bold = item.isBold || item.isEmphasized;
        if (item.isEmphasized) {
          labelCell.cellStyle.fontColor = theme.primaryColor;
        }

        final valCell = sheet.getRangeByIndex(sRow, valCol);
        valCell.cellStyle.fontName = theme.fontFamily;
        if (item.value is num) {
          valCell.setNumber((item.value as num).toDouble());
          if (item.currencyCode != null) {
            valCell.numberFormat = '${item.currencyCode} #,##0.00';
          } else {
            valCell.numberFormat = '#,##0.00';
          }
        } else {
          valCell.setText(item.value.toString());
        }
        valCell.cellStyle.hAlign = HAlignType.right;
        valCell.cellStyle.fontSize = item.isEmphasized ? 11 : 9.5;
        valCell.cellStyle.bold = item.isBold || item.isEmphasized;
        if (item.isEmphasized) {
          valCell.cellStyle.fontColor = theme.primaryColor;
        }

        if (item.showTopBorder) {
          labelCell.cellStyle.borders.top.lineStyle = LineStyle.thin;
          valCell.cellStyle.borders.top.lineStyle = LineStyle.thin;
          labelCell.cellStyle.borders.top.color = theme.borderColor;
          valCell.cellStyle.borders.top.color = theme.borderColor;
        }
        if (item.showDoubleBottomBorder) {
          labelCell.cellStyle.borders.bottom.lineStyle = LineStyle.double;
          valCell.cellStyle.borders.bottom.lineStyle = LineStyle.double;
          labelCell.cellStyle.borders.bottom.color = theme.accentColor;
          valCell.cellStyle.borders.bottom.color = theme.accentColor;
        }
        sRow++;
      }
      summaryEndRow = sRow;
    }

    return math.max(paymentEndRow, summaryEndRow) + 1;
  }

  int _renderSummaryTotalsOnly({
    required Worksheet sheet,
    required int startRow,
    required int colCount,
    required List<ReportSummaryItem> summaryItems,
    required ReportTheme theme,
  }) {
    int sRow = startRow;
    final int labelCol = math.max(1, colCount - 1);
    final int valCol = colCount;

    for (final item in summaryItems) {
      final labelCell = sheet.getRangeByIndex(sRow, labelCol);
      labelCell.setText(item.label);
      labelCell.cellStyle.fontName = theme.fontFamily;
      labelCell.cellStyle.hAlign = HAlignType.right;
      labelCell.cellStyle.fontSize = item.isEmphasized ? 11 : 9.5;
      labelCell.cellStyle.bold = item.isBold || item.isEmphasized;
      if (item.isEmphasized) {
        labelCell.cellStyle.fontColor = theme.primaryColor;
      }

      final valCell = sheet.getRangeByIndex(sRow, valCol);
      valCell.cellStyle.fontName = theme.fontFamily;
      if (item.value is num) {
        valCell.setNumber((item.value as num).toDouble());
        if (item.currencyCode != null) {
          valCell.numberFormat = '${item.currencyCode} #,##0.00';
        } else {
          valCell.numberFormat = '#,##0.00';
        }
      } else {
        valCell.setText(item.value.toString());
      }
      valCell.cellStyle.hAlign = HAlignType.right;
      valCell.cellStyle.fontSize = item.isEmphasized ? 11 : 9.5;
      valCell.cellStyle.bold = item.isBold || item.isEmphasized;
      if (item.isEmphasized) {
        valCell.cellStyle.fontColor = theme.primaryColor;
      }

      if (item.showTopBorder) {
        labelCell.cellStyle.borders.top.lineStyle = LineStyle.thin;
        valCell.cellStyle.borders.top.lineStyle = LineStyle.thin;
        labelCell.cellStyle.borders.top.color = theme.borderColor;
        valCell.cellStyle.borders.top.color = theme.borderColor;
      }
      if (item.showDoubleBottomBorder) {
        labelCell.cellStyle.borders.bottom.lineStyle = LineStyle.double;
        valCell.cellStyle.borders.bottom.lineStyle = LineStyle.double;
        labelCell.cellStyle.borders.bottom.color = theme.accentColor;
        valCell.cellStyle.borders.bottom.color = theme.accentColor;
      }
      sRow++;
    }
    return sRow;
  }

  int _renderPaymentDetailsOnly({
    required Worksheet sheet,
    required int startRow,
    required ReportPaymentDetails paymentDetails,
    required ReportTheme theme,
  }) {
    int pRow = startRow;
    final headerCell = sheet.getRangeByIndex(pRow, 1);
    final title = paymentDetails.title ?? 'Payment & Remittance Instructions:';
    headerCell.setText(title.endsWith(':') ? title : '$title:');
    headerCell.cellStyle.fontName = theme.fontFamily;
    headerCell.cellStyle.bold = true;
    headerCell.cellStyle.fontSize = 9.5;
    headerCell.cellStyle.fontColor = theme.primaryColor;
    pRow++;

    if (paymentDetails.bankName != null) {
      final lbl = sheet.getRangeByIndex(pRow, 1);
      lbl.setText('Bank Name:');
      lbl.cellStyle.fontName = theme.fontFamily;
      lbl.cellStyle.fontSize = 9;
      final val = sheet.getRangeByIndex(pRow, 2);
      val.setText(paymentDetails.bankName!);
      val.cellStyle.fontName = theme.fontFamily;
      val.cellStyle.fontSize = 9;
      pRow++;
    }
    if (paymentDetails.accountName != null) {
      final lbl = sheet.getRangeByIndex(pRow, 1);
      lbl.setText('Account Name:');
      lbl.cellStyle.fontName = theme.fontFamily;
      lbl.cellStyle.fontSize = 9;
      final val = sheet.getRangeByIndex(pRow, 2);
      val.setText(paymentDetails.accountName!);
      val.cellStyle.fontName = theme.fontFamily;
      val.cellStyle.fontSize = 9;
      pRow++;
    }
    if (paymentDetails.accountNumber != null) {
      final lbl = sheet.getRangeByIndex(pRow, 1);
      lbl.setText('Account No:');
      lbl.cellStyle.fontName = theme.fontFamily;
      lbl.cellStyle.fontSize = 9;
      final val = sheet.getRangeByIndex(pRow, 2);
      val.setText(paymentDetails.accountNumber!);
      val.cellStyle.fontName = theme.fontFamily;
      val.cellStyle.fontSize = 9;
      val.cellStyle.bold = true;
      pRow++;
    }
    if (paymentDetails.branch != null) {
      final lbl = sheet.getRangeByIndex(pRow, 1);
      lbl.setText('Branch:');
      lbl.cellStyle.fontName = theme.fontFamily;
      lbl.cellStyle.fontSize = 9;
      final val = sheet.getRangeByIndex(pRow, 2);
      val.setText(paymentDetails.branch!);
      val.cellStyle.fontName = theme.fontFamily;
      val.cellStyle.fontSize = 9;
      pRow++;
    }
    if (paymentDetails.swiftCode != null) {
      final lbl = sheet.getRangeByIndex(pRow, 1);
      lbl.setText('SWIFT / BIC:');
      lbl.cellStyle.fontName = theme.fontFamily;
      lbl.cellStyle.fontSize = 9;
      final val = sheet.getRangeByIndex(pRow, 2);
      val.setText(paymentDetails.swiftCode!);
      val.cellStyle.fontName = theme.fontFamily;
      val.cellStyle.fontSize = 9;
      pRow++;
    }
    for (final note in paymentDetails.termsOrNotes) {
      final lbl = sheet.getRangeByIndex(pRow, 1);
      lbl.setText('Note:');
      lbl.cellStyle.fontName = theme.fontFamily;
      lbl.cellStyle.fontSize = 8.5;
      lbl.cellStyle.italic = true;
      final val = sheet.getRangeByIndex(pRow, 2);
      val.setText(note);
      val.cellStyle.fontName = theme.fontFamily;
      val.cellStyle.fontSize = 8.5;
      val.cellStyle.italic = true;
      pRow++;
    }
    return pRow;
  }

  int _renderSignatures(
    Worksheet sheet,
    List<ReportSignature> signatures,
    SignatureLayout layout,
    ReportTheme theme,
    int startRow,
    int totalCols,
  ) {
    int row = startRow;

    switch (layout) {
      case SignatureLayout.adaptive:
      case SignatureLayout.horizontal:
        final int spacing = math.max(2, (totalCols ~/ signatures.length));
        int maxBlockRows = 0;

        for (int i = 0; i < signatures.length; i++) {
          final int col = (i * spacing) + 1;
          final sig = signatures[i];
          int r = row;

          if (sig.name != null && sig.name!.isNotEmpty) {
            final nameCell = sheet.getRangeByIndex(r, col);
            nameCell.setText(sig.name!);
            nameCell.cellStyle.fontSize = 10;
            nameCell.cellStyle.italic = true;
            nameCell.cellStyle.bold = true;
            r++;
          }

          final lineCell = sheet.getRangeByIndex(r, col);
          lineCell.setText('______________________');
          lineCell.cellStyle.fontColor = '#888888';
          r++;

          final titleCell = sheet.getRangeByIndex(r, col);
          titleCell.setText(sig.title);
          titleCell.cellStyle.bold = true;
          titleCell.cellStyle.fontSize = 9;
          titleCell.cellStyle.fontColor = theme.primaryColor;
          r++;

          if (sig.date != null && sig.date!.isNotEmpty) {
            final dateCell = sheet.getRangeByIndex(r, col);
            dateCell.setText('Date: ${sig.date!}');
            dateCell.cellStyle.fontSize = 8.5;
            dateCell.cellStyle.fontColor = '#666666';
            r++;
          }

          maxBlockRows = math.max(maxBlockRows, r - row);
        }
        return row + maxBlockRows + 2;

      case SignatureLayout.vertical:
        // Stack all signatures vertically in ONE column (no two columns)
        for (final sig in signatures) {
          if (sig.name != null && sig.name!.isNotEmpty) {
            final nameCell = sheet.getRangeByIndex(row, 1);
            nameCell.setText(sig.name!);
            nameCell.cellStyle.fontSize = 10;
            nameCell.cellStyle.italic = true;
            nameCell.cellStyle.bold = true;
            row++;
          }

          final lineCell = sheet.getRangeByIndex(row, 1);
          lineCell.setText('______________________');
          lineCell.cellStyle.fontColor = '#888888';
          row++;

          final titleCell = sheet.getRangeByIndex(row, 1);
          titleCell.setText(sig.title);
          titleCell.cellStyle.bold = true;
          titleCell.cellStyle.fontSize = 9;
          titleCell.cellStyle.fontColor = theme.primaryColor;
          row++;

          if (sig.date != null && sig.date!.isNotEmpty) {
            final dateCell = sheet.getRangeByIndex(row, 1);
            dateCell.setText('Date: ${sig.date!}');
            dateCell.cellStyle.fontSize = 8.5;
            dateCell.cellStyle.fontColor = '#666666';
            row++;
          }
          row++; // Blank row spacing between signature blocks
        }
        return row + 1;

      case SignatureLayout.split:
        // Split: Left side (Prepared / Date) & Right side (Checked / Approved / Authorized)
        final leftSigs = <ReportSignature>[];
        final rightSigs = <ReportSignature>[];

        for (final sig in signatures) {
          if (sig.isRightAligned) {
            rightSigs.add(sig);
          } else {
            final lower = sig.title.toLowerCase();
            if (lower.contains('checked') ||
                lower.contains('approved') ||
                lower.contains('authorized')) {
              rightSigs.add(sig);
            } else {
              leftSigs.add(sig);
            }
          }
        }

        if (leftSigs.isEmpty || rightSigs.isEmpty) {
          leftSigs.clear();
          rightSigs.clear();
          final half = (signatures.length / 2).ceil();
          leftSigs.addAll(signatures.take(half));
          rightSigs.addAll(signatures.skip(half));
        }

        final int rightCol = math.max(2, totalCols - 1);
        int leftRow = row;
        int rightRow = row;

        for (final sig in leftSigs) {
          if (sig.name != null && sig.name!.isNotEmpty) {
            final nameCell = sheet.getRangeByIndex(leftRow, 1);
            nameCell.setText(sig.name!);
            nameCell.cellStyle.fontSize = 10;
            nameCell.cellStyle.italic = true;
            leftRow++;
          }
          final lineCell = sheet.getRangeByIndex(leftRow, 1);
          lineCell.setText('______________________');
          lineCell.cellStyle.fontColor = '#888888';
          leftRow++;

          final titleCell = sheet.getRangeByIndex(leftRow, 1);
          titleCell.setText(sig.title);
          titleCell.cellStyle.bold = true;
          titleCell.cellStyle.fontSize = 9;
          titleCell.cellStyle.fontColor = theme.primaryColor;
          leftRow++;

          if (sig.date != null && sig.date!.isNotEmpty) {
            final dateCell = sheet.getRangeByIndex(leftRow, 1);
            dateCell.setText('Date: ${sig.date!}');
            dateCell.cellStyle.fontSize = 8.5;
            dateCell.cellStyle.fontColor = '#666666';
            leftRow++;
          }
          leftRow++;
        }

        for (final sig in rightSigs) {
          if (sig.name != null && sig.name!.isNotEmpty) {
            final nameCell = sheet.getRangeByIndex(rightRow, rightCol);
            nameCell.setText(sig.name!);
            nameCell.cellStyle.fontSize = 10;
            nameCell.cellStyle.italic = true;
            rightRow++;
          }
          final lineCell = sheet.getRangeByIndex(rightRow, rightCol);
          lineCell.setText('______________________');
          lineCell.cellStyle.fontColor = '#888888';
          rightRow++;

          final titleCell = sheet.getRangeByIndex(rightRow, rightCol);
          titleCell.setText(sig.title);
          titleCell.cellStyle.bold = true;
          titleCell.cellStyle.fontSize = 9;
          titleCell.cellStyle.fontColor = theme.primaryColor;
          rightRow++;

          if (sig.date != null && sig.date!.isNotEmpty) {
            final dateCell = sheet.getRangeByIndex(rightRow, rightCol);
            dateCell.setText('Date: ${sig.date!}');
            dateCell.cellStyle.fontSize = 8.5;
            dateCell.cellStyle.fontColor = '#666666';
            rightRow++;
          }
          rightRow++;
        }

        return math.max(leftRow, rightRow) + 2;
    }
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
      row = _renderBranding(sheet, branding, theme, row, colCount: 4);
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
    int tableStartRow,
    int dataEndRow,
    ExcelExportOptions options,
  ) {
    // Worksheet gridline visibility
    sheet.showGridlines = options.showGridlines;

    // Auto-fit column widths with safety limits
    for (int c = 1; c <= colCount; c++) {
      try {
        sheet.autoFitColumn(c);
      } catch (_) {}
    }

    // Auto-filter strictly on table data range only (NEVER includes totals, summaries, or signatures)
    if (options.enableAutoFilter &&
        dataEndRow >= tableStartRow + 1 &&
        colCount > 0) {
      try {
        sheet.autoFilters.filterRange = sheet.getRangeByIndex(
          tableStartRow,
          1,
          dataEndRow,
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
