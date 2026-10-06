import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:typed_data' show Uint8List;
import 'dart:ui' show Offset, Rect;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../engine/prepared_report.dart';
import '../engine/report_options.dart';
import '../engine/report_artifact.dart';
import '../engine/report_column.dart';
import '../models/report_models.dart';
import 'report_chart_data.dart';

/// Renders a [PreparedReport] into an Adobe PDF (.pdf) document.
class PdfReportExporter {
  static final Logger _log = Logger('PdfReportExporter');

  /// Exports the prepared report to a [ReportArtifact].
  Future<ReportArtifact> export(
    PreparedReport report, {
    PdfExportOptions? options,
  }) async {
    _log.info('Exporting PDF report: "${report.title}"');
    final opts = options ?? const PdfExportOptions();

    // 1. Validate options
    opts.validate();

    final PdfDocument document = PdfDocument();
    final theme = report.theme;

    // 2. Configure Page Setup
    _configurePageSettings(document, opts);

    // 3. Pre-resolve logo
    List<int>? logoBytes;
    if (report.branding != null) {
      logoBytes = await _resolveLogo(report.branding!);
    }
    final ReportBranding? branding =
        report.branding != null && logoBytes != null
        ? report.branding!.copyWithBytes(logoBytes)
        : report.branding;

    // 4. Configure Header & Footer templates
    _addHeaderTemplate(document, branding, theme, report.title);
    _addFooterTemplate(document, theme, opts);

    // 5. Render analyses / sections
    for (int i = 0; i < report.analyses.length; i++) {
      final analysis = report.analyses[i];
      if (analysis.categorySheets != null &&
          analysis.categorySheets!.isNotEmpty) {
        if (analysis.rows.isNotEmpty) {
          _renderAnalysisSection(
            document,
            analysis,
            theme,
            opts,
            report,
            isFirst: i == 0,
          );
        }
        for (final catSheet in analysis.categorySheets!) {
          _renderCategorySheetSection(document, catSheet, theme, opts, report);
        }
      } else {
        _renderAnalysisSection(
          document,
          analysis,
          theme,
          opts,
          report,
          isFirst: i == 0,
        );
      }
    }

    // 6. Signatures if requested
    if (opts.showSignatures && opts.effectiveSignatures.isNotEmpty) {
      _renderSignatures(
        document,
        theme,
        opts.effectiveSignatures,
        opts.resolveSignatureLayout(),
      );
    }

    // 7. Configure PDF Security / Encryption
    _configureSecurity(document, opts);

    // 8. Save PDF bytes
    final int pageCount = document.pages.count;
    final List<int> bytes = await document.save();
    document.dispose();

    final cleanFilename =
        '${report.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.pdf';

    return ReportArtifact(
      bytes: bytes,
      filename: cleanFilename,
      mimeType: 'application/pdf',
      format: ExportFormat.pdf,
      warnings: report.warnings,
      metadata: {
        'pageCount': pageCount,
        'title': report.title,
        'recordCount': report.totalRecordCount,
      },
      generatedAt: report.generatedAt,
    );
  }

  void _configurePageSettings(PdfDocument document, PdfExportOptions options) {
    switch (options.pageSize.toUpperCase()) {
      case 'A5':
        document.pageSettings.size = PdfPageSize.a5;
        break;
      case 'LETTER':
        document.pageSettings.size = PdfPageSize.letter;
        break;
      case 'LEGAL':
        document.pageSettings.size = PdfPageSize.legal;
        break;
      case 'A4':
      default:
        document.pageSettings.size = PdfPageSize.a4;
        break;
    }

    if (options.orientation.toLowerCase() == 'landscape') {
      document.pageSettings.orientation = PdfPageOrientation.landscape;
    } else {
      document.pageSettings.orientation = PdfPageOrientation.portrait;
    }

    final top = options.marginTop ?? options.margin;
    final bottom = options.marginBottom ?? options.margin;
    final left = options.marginLeft ?? options.margin;
    final right = options.marginRight ?? options.margin;

    document.pageSettings.margins.all = 0;
    document.pageSettings.margins.top = top;
    document.pageSettings.margins.bottom = bottom;
    document.pageSettings.margins.left = left;
    document.pageSettings.margins.right = right;
  }

  void _addHeaderTemplate(
    PdfDocument document,
    ReportBranding? branding,
    ReportTheme theme,
    String defaultTitle,
  ) {
    if (branding == null) return;

    final double width = document.pageSettings.size.width;
    final bool hasLogo =
        branding.logoBytes != null && branding.logoBytes!.isNotEmpty;
    final double logoW = (branding.logoWidth ?? 90).toDouble();
    final double logoH = (branding.logoHeight ?? 50).toDouble();

    PdfBitmap? logoImage;
    if (hasLogo) {
      try {
        logoImage = PdfBitmap(Uint8List.fromList(branding.logoBytes!));
      } catch (e) {
        _log.warning('Failed to render logo bitmap in PDF: $e');
      }
    }

    double templateHeight = 50;
    if (hasLogo && branding.layout == BrandingLayout.stacked) {
      templateHeight = logoH + 45;
    } else if (hasLogo) {
      templateHeight = math.max(logoH, 35) + 20;
    }

    final headerTemplate = PdfPageTemplateElement(
      Rect.fromLTWH(0, 0, width, templateHeight),
    );

    final compColor = _parseHexColor(
      theme.primaryColor,
      PdfColor(21, 101, 192),
    );
    final titleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      10,
      style: PdfFontStyle.bold,
    );
    final addrFont = PdfStandardFont(PdfFontFamily.helvetica, 8);
    final contactFont = PdfStandardFont(PdfFontFamily.helvetica, 7.5);

    switch (branding.layout) {
      case BrandingLayout.stacked:
        double y = 4;
        if (logoImage != null) {
          headerTemplate.graphics.drawImage(
            logoImage,
            Rect.fromLTWH(15, y, logoW, logoH),
          );
          y += logoH + 5;
        }
        headerTemplate.graphics.drawString(
          branding.companyName ?? defaultTitle,
          titleFont,
          brush: PdfSolidBrush(compColor),
          bounds: Rect.fromLTWH(15, y, width - 30, 14),
        );
        y += 13;
        if (branding.address != null && branding.address!.isNotEmpty) {
          headerTemplate.graphics.drawString(
            branding.address!,
            addrFont,
            brush: PdfSolidBrush(PdfColor(90, 90, 90)),
            bounds: Rect.fromLTWH(15, y, width - 30, 11),
          );
          y += 11;
        }
        if (branding.phone != null || branding.email != null) {
          final contacts = [
            if (branding.phone != null) 'Tel: ${branding.phone}',
            if (branding.email != null) 'Email: ${branding.email}',
          ].join(' | ');
          headerTemplate.graphics.drawString(
            contacts,
            contactFont,
            brush: PdfSolidBrush(PdfColor(120, 120, 120)),
            bounds: Rect.fromLTWH(15, y, width - 30, 10),
          );
          y += 10;
        }
        headerTemplate.graphics.drawLine(
          PdfPen(PdfColor(210, 210, 210), width: 0.5),
          Offset(15, y + 3),
          Offset(width - 15, y + 3),
        );
        break;

      case BrandingLayout.sideBySide:
        double textX = 15;
        if (logoImage != null) {
          headerTemplate.graphics.drawImage(
            logoImage,
            Rect.fromLTWH(15, 5, logoW, logoH),
          );
          textX = 15 + logoW + 12;
        }
        double y = 5;
        headerTemplate.graphics.drawString(
          branding.companyName ?? defaultTitle,
          titleFont,
          brush: PdfSolidBrush(compColor),
          bounds: Rect.fromLTWH(textX, y, width - textX - 15, 14),
        );
        y += 14;
        if (branding.address != null && branding.address!.isNotEmpty) {
          headerTemplate.graphics.drawString(
            branding.address!,
            addrFont,
            brush: PdfSolidBrush(PdfColor(90, 90, 90)),
            bounds: Rect.fromLTWH(textX, y, width - textX - 15, 11),
          );
          y += 11;
        }
        if (branding.phone != null || branding.email != null) {
          final contacts = [
            if (branding.phone != null) 'Tel: ${branding.phone}',
            if (branding.email != null) 'Email: ${branding.email}',
          ].join(' | ');
          headerTemplate.graphics.drawString(
            contacts,
            contactFont,
            brush: PdfSolidBrush(PdfColor(120, 120, 120)),
            bounds: Rect.fromLTWH(textX, y, width - textX - 15, 10),
          );
          y += 10;
        }
        final ruleY = math.max(y, logoH + 6) + 4;
        headerTemplate.graphics.drawLine(
          PdfPen(PdfColor(210, 210, 210), width: 0.5),
          Offset(15, ruleY),
          Offset(width - 15, ruleY),
        );
        break;

      case BrandingLayout.topRightLogo:
        if (logoImage != null) {
          headerTemplate.graphics.drawImage(
            logoImage,
            Rect.fromLTWH(width - 15 - logoW, 5, logoW, logoH),
          );
        }
        double y = 5;
        final maxTextWidth = width - 40 - (logoImage != null ? logoW : 0);
        headerTemplate.graphics.drawString(
          branding.companyName ?? defaultTitle,
          titleFont,
          brush: PdfSolidBrush(compColor),
          bounds: Rect.fromLTWH(15, y, maxTextWidth, 14),
        );
        y += 14;
        if (branding.address != null && branding.address!.isNotEmpty) {
          headerTemplate.graphics.drawString(
            branding.address!,
            addrFont,
            brush: PdfSolidBrush(PdfColor(90, 90, 90)),
            bounds: Rect.fromLTWH(15, y, maxTextWidth, 11),
          );
          y += 11;
        }
        if (branding.phone != null || branding.email != null) {
          final contacts = [
            if (branding.phone != null) 'Tel: ${branding.phone}',
            if (branding.email != null) 'Email: ${branding.email}',
          ].join(' | ');
          headerTemplate.graphics.drawString(
            contacts,
            contactFont,
            brush: PdfSolidBrush(PdfColor(120, 120, 120)),
            bounds: Rect.fromLTWH(15, y, maxTextWidth, 10),
          );
          y += 10;
        }
        final ruleY = math.max(y, logoH + 6) + 4;
        headerTemplate.graphics.drawLine(
          PdfPen(PdfColor(210, 210, 210), width: 0.5),
          Offset(15, ruleY),
          Offset(width - 15, ruleY),
        );
        break;
    }

    document.template.top = headerTemplate;
  }

  void _addFooterTemplate(
    PdfDocument document,
    ReportTheme theme,
    PdfExportOptions options,
  ) {
    final footerTemplate = PdfPageTemplateElement(
      Rect.fromLTWH(0, 0, document.pageSettings.size.width, 35),
    );

    // Draw footer line
    footerTemplate.graphics.drawLine(
      PdfPen(PdfColor(200, 200, 200), width: 0.5),
      const Offset(15, 5),
      Offset(document.pageSettings.size.width - 15, 5),
    );

    final String dateStr = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(DateTime.now());
    footerTemplate.graphics.drawString(
      'Generated: $dateStr',
      PdfStandardFont(PdfFontFamily.helvetica, 8),
      brush: PdfSolidBrush(PdfColor(120, 120, 120)),
      bounds: const Rect.fromLTWH(15, 12, 200, 15),
    );

    if (options.showPageNumbers) {
      final pageNumber = PdfPageNumberField(
        font: PdfStandardFont(PdfFontFamily.helvetica, 8),
        brush: PdfSolidBrush(PdfColor(100, 100, 100)),
      );
      final count = PdfPageCountField(
        font: PdfStandardFont(PdfFontFamily.helvetica, 8),
        brush: PdfSolidBrush(PdfColor(100, 100, 100)),
      );
      final composite = PdfCompositeField(
        font: PdfStandardFont(PdfFontFamily.helvetica, 8),
        brush: PdfSolidBrush(PdfColor(100, 100, 100)),
        text: 'Page {0} of {1}',
        fields: [pageNumber, count],
      );

      composite.draw(
        footerTemplate.graphics,
        Offset(document.pageSettings.size.width - 100, 12),
      );
    }

    document.template.bottom = footerTemplate;
  }

  void _renderAnalysisSection(
    PdfDocument document,
    PreparedAnalysis analysis,
    ReportTheme theme,
    PdfExportOptions options,
    PreparedReport report, {
    required bool isFirst,
  }) {
    final PdfPage page = document.pages.add();
    final double pageWidth = page.getClientSize().width;
    double y = 10;

    // Section Title
    final fontFam = _toPdfFontFamily(theme.fontFamily);
    final titleFont = PdfStandardFont(fontFam, 14, style: PdfFontStyle.bold);
    page.graphics.drawString(
      analysis.title,
      titleFont,
      brush: PdfSolidBrush(
        _parseHexColor(theme.accentColor, PdfColor(13, 71, 161)),
      ),
      bounds: Rect.fromLTWH(0, y, pageWidth, 20),
    );
    y += 24;

    // Subtitle
    if (analysis.subtitle != null && analysis.subtitle!.isNotEmpty) {
      final subFont = PdfStandardFont(fontFam, 9, style: PdfFontStyle.italic);
      page.graphics.drawString(
        analysis.subtitle!,
        subFont,
        brush: PdfSolidBrush(PdfColor(100, 100, 100)),
        bounds: Rect.fromLTWH(0, y, pageWidth, 15),
      );
      y += 18;
    }

    // Empty state check
    if (analysis.rows.isEmpty && analysis.headers.isEmpty) {
      page.graphics.drawString(
        options.emptyStateMessage,
        PdfStandardFont(fontFam, 10, style: PdfFontStyle.italic),
        brush: PdfSolidBrush(PdfColor(120, 120, 120)),
        bounds: Rect.fromLTWH(0, y + 10, pageWidth, 25),
      );
      return;
    }

    // Render Table Grid
    PdfLayoutResult? result;
    if (analysis.headers.isNotEmpty) {
      result = _drawGrid(
        page: page,
        headers: analysis.headers,
        rows: analysis.rows,
        grandTotalRow: analysis.grandTotalRow,
        theme: theme,
        options: options,
        startY: y,
      );
    }

    PdfPage targetPage = result?.page ?? page;
    double curY = (result?.bounds.bottom ?? y) + 16;
    final double targetPageHeight = targetPage.getClientSize().height;

    // Render Visual Chart Breakdown if configured
    if (analysis.chart != null) {
      if (curY + analysis.chart!.height + 35 > targetPageHeight - 35) {
        targetPage = document.pages.add();
        curY = 16;
      }
      curY = _renderChartSummaryBlock(
        page: targetPage,
        chart: analysis.chart!,
        analysis: analysis,
        theme: theme,
        startY: curY,
      );
    }

    // Render Bottom Financial Summaries & Payment / Bank Details
    final summaryItems = options.summaryItems ?? report.summaryItems;
    final paymentDetails = options.paymentDetails ?? report.paymentDetails;
    if ((summaryItems != null && summaryItems.isNotEmpty) ||
        paymentDetails != null) {
      if (curY + 120 > targetPageHeight - 35) {
        targetPage = document.pages.add();
        curY = 16;
      }
      curY = _renderSummaryAndPaymentBlock(
        document: document,
        page: targetPage,
        startY: curY,
        summaryItems: summaryItems,
        paymentDetails: paymentDetails,
        theme: theme,
      );
    }
  }

  void _renderCategorySheetSection(
    PdfDocument document,
    PreparedCategorySheet catSheet,
    ReportTheme theme,
    PdfExportOptions options,
    PreparedReport report,
  ) {
    final PdfPage page = document.pages.add();
    final double pageWidth = page.getClientSize().width;
    double y = 10;

    // Category Title
    final fontFam = _toPdfFontFamily(theme.fontFamily);
    final titleFont = PdfStandardFont(fontFam, 14, style: PdfFontStyle.bold);
    page.graphics.drawString(
      catSheet.categoryLabel,
      titleFont,
      brush: PdfSolidBrush(
        _parseHexColor(theme.accentColor, PdfColor(13, 71, 161)),
      ),
      bounds: Rect.fromLTWH(0, y, pageWidth, 20),
    );
    y += 24;

    PdfLayoutResult? result;
    if (catSheet.headers.isNotEmpty) {
      result = _drawGrid(
        page: page,
        headers: catSheet.headers,
        rows: catSheet.rows,
        grandTotalRow: catSheet.totalsRow,
        theme: theme,
        options: options,
        startY: y,
      );
    }

    final summaryItems = options.summaryItems ?? report.summaryItems;
    final paymentDetails = options.paymentDetails ?? report.paymentDetails;
    if ((summaryItems != null && summaryItems.isNotEmpty) ||
        paymentDetails != null) {
      PdfPage targetPage = result?.page ?? page;
      double curY = (result?.bounds.bottom ?? y) + 16;
      if (curY + 120 > targetPage.getClientSize().height - 35) {
        targetPage = document.pages.add();
        curY = 16;
      }
      _renderSummaryAndPaymentBlock(
        document: document,
        page: targetPage,
        startY: curY,
        summaryItems: summaryItems,
        paymentDetails: paymentDetails,
        theme: theme,
      );
    }
  }

  PdfLayoutResult? _drawGrid({
    required PdfPage page,
    required List<PreparedColumnHeader> headers,
    required List<PreparedRow> rows,
    required PreparedRow? grandTotalRow,
    required ReportTheme theme,
    required PdfExportOptions options,
    required double startY,
  }) {
    final double pageWidth = page.getClientSize().width;
    final grid = PdfGrid();
    grid.columns.add(count: headers.length);

    // Repeat header on every page break
    grid.repeatHeader = options.repeatHeaders;

    final borderStyle = options.tableBorderStyle;
    final fontFam = _toPdfFontFamily(theme.fontFamily);
    final transparentPen = PdfPen(PdfColor(0, 0, 0, 0), width: 0);

    // Header row
    final PdfGridRow headerRow = grid.headers.add(1)[0];
    for (int c = 0; c < headers.length; c++) {
      final h = headers[c];
      headerRow.cells[c].value = h.title;
      headerRow.cells[c].stringFormat = PdfStringFormat(
        alignment: _toPdfAlignment(h.alignment),
        lineAlignment: PdfVerticalAlignment.middle,
      );
      headerRow.cells[c].style = PdfGridCellStyle(
        font: PdfStandardFont(
          fontFam,
          theme.fontSizeHeader,
          style: PdfFontStyle.bold,
        ),
        backgroundBrush: PdfSolidBrush(
          _parseHexColor(theme.headerBackgroundColor, PdfColor(21, 101, 192)),
        ),
        textBrush: PdfSolidBrush(
          _parseHexColor(theme.headerTextColor, PdfColor(255, 255, 255)),
        ),
      );

      switch (borderStyle) {
        case TableBorderStyle.grid:
          headerRow.cells[c].style.borders.all = PdfPen(
            _parseHexColor(theme.accentColor, PdfColor(13, 71, 161)),
            width: 0.5,
          );
          break;
        case TableBorderStyle.clean:
        case TableBorderStyle.horizontalOnly:
        case TableBorderStyle.headerAndTotalOnly:
          headerRow.cells[c].style.borders.all = transparentPen;
          headerRow.cells[c].style.borders.bottom = PdfPen(
            _parseHexColor(theme.primaryColor, PdfColor(21, 101, 192)),
            width: 1.2,
          );
          break;
        case TableBorderStyle.none:
          headerRow.cells[c].style.borders.all = transparentPen;
          break;
      }
    }

    // Data Rows
    for (int r = 0; r < rows.length; r++) {
      final row = rows[r];
      final PdfGridRow gridRow = grid.rows.add();

      if (row.isGroupHeader) {
        final groupText = row.cells.isNotEmpty
            ? row.cells[0].formattedText
            : '';
        gridRow.cells[0].value = groupText;
        gridRow.cells[0].columnSpan = headers.length;
        gridRow.cells[0].style = PdfGridCellStyle(
          font: PdfStandardFont(
            fontFam,
            theme.fontSizeHeader,
            style: PdfFontStyle.bold,
          ),
          backgroundBrush: PdfSolidBrush(
            _parseHexColor(
              theme.groupHeaderBackgroundColor,
              PdfColor(227, 242, 253),
            ),
          ),
          textBrush: PdfSolidBrush(
            _parseHexColor(theme.groupHeaderTextColor, PdfColor(13, 71, 161)),
          ),
        );
      } else if (row.isSubtotal) {
        for (int c = 0; c < row.cells.length && c < headers.length; c++) {
          final pCell = row.cells[c];
          gridRow.cells[c].value = pCell.formattedText;
          gridRow.cells[c].stringFormat = PdfStringFormat(
            alignment: _toPdfAlignment(pCell.alignment),
          );
          gridRow.cells[c].style = PdfGridCellStyle(
            font: PdfStandardFont(
              fontFam,
              theme.fontSizeBody,
              style: PdfFontStyle.bold,
            ),
            backgroundBrush: PdfSolidBrush(
              _parseHexColor(
                theme.groupHeaderBackgroundColor,
                PdfColor(227, 242, 253),
              ),
            ),
            textBrush: PdfSolidBrush(
              _parseHexColor(theme.groupHeaderTextColor, PdfColor(13, 71, 161)),
            ),
          );
        }
      } else {
        for (int c = 0; c < row.cells.length && c < headers.length; c++) {
          final pCell = row.cells[c];
          gridRow.cells[c].value = pCell.formattedText;
          gridRow.cells[c].stringFormat = PdfStringFormat(
            alignment: _toPdfAlignment(pCell.alignment),
          );
          gridRow.cells[c].style = PdfGridCellStyle(
            font: PdfStandardFont(fontFam, theme.fontSizeBody),
            backgroundBrush: PdfSolidBrush(
              r % 2 == 0
                  ? _parseHexColor(
                      theme.zebraLightColor,
                      PdfColor(245, 245, 245),
                    )
                  : _parseHexColor(
                      theme.zebraDarkColor,
                      PdfColor(255, 255, 255),
                    ),
            ),
          );

          switch (borderStyle) {
            case TableBorderStyle.grid:
              gridRow.cells[c].style.borders.all = PdfPen(
                _parseHexColor(theme.borderColor, PdfColor(200, 200, 200)),
                width: 0.5,
              );
              break;
            case TableBorderStyle.horizontalOnly:
              gridRow.cells[c].style.borders.all = transparentPen;
              gridRow.cells[c].style.borders.bottom = PdfPen(
                _parseHexColor(theme.borderColor, PdfColor(220, 220, 220)),
                width: 0.5,
              );
              break;
            case TableBorderStyle.clean:
            case TableBorderStyle.headerAndTotalOnly:
            case TableBorderStyle.none:
              gridRow.cells[c].style.borders.all = transparentPen;
              break;
          }
        }
      }
    }

    // Grand Total Row
    if (grandTotalRow != null) {
      final PdfGridRow totRow = grid.rows.add();
      for (
        int c = 0;
        c < grandTotalRow.cells.length && c < headers.length;
        c++
      ) {
        final pCell = grandTotalRow.cells[c];
        totRow.cells[c].value = pCell.formattedText;
        totRow.cells[c].stringFormat = PdfStringFormat(
          alignment: _toPdfAlignment(pCell.alignment),
        );
        totRow.cells[c].style = PdfGridCellStyle(
          font: PdfStandardFont(
            fontFam,
            theme.fontSizeTotals,
            style: PdfFontStyle.bold,
          ),
          backgroundBrush: PdfSolidBrush(
            _parseHexColor(
              theme.totalsBackgroundColor,
              PdfColor(255, 249, 196),
            ),
          ),
          textBrush: PdfSolidBrush(
            _parseHexColor(theme.totalsTextColor, PdfColor(0, 0, 0)),
          ),
        );

        switch (borderStyle) {
          case TableBorderStyle.grid:
            totRow.cells[c].style.borders.all = PdfPen(
              PdfColor(50, 50, 50),
              width: 0.8,
            );
            totRow.cells[c].style.borders.top = PdfPen(
              PdfColor(50, 50, 50),
              width: 1.0,
            );
            totRow.cells[c].style.borders.bottom = PdfPen(
              PdfColor(50, 50, 50),
              width: 1.5,
            );
            break;
          case TableBorderStyle.clean:
          case TableBorderStyle.headerAndTotalOnly:
          case TableBorderStyle.horizontalOnly:
            totRow.cells[c].style.borders.all = transparentPen;
            totRow.cells[c].style.borders.top = PdfPen(
              PdfColor(80, 80, 80),
              width: 0.8,
            );
            totRow.cells[c].style.borders.bottom = PdfPen(
              _parseHexColor(theme.primaryColor, PdfColor(30, 30, 30)),
              width: 1.5,
            );
            break;
          case TableBorderStyle.none:
            totRow.cells[c].style.borders.all = transparentPen;
            break;
        }
      }
    }

    // Draw Grid on page
    return grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, startY, pageWidth, 0),
      format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
    );
  }

  double _renderChartSummaryBlock({
    required PdfPage page,
    required ReportChartConfig chart,
    required PreparedAnalysis analysis,
    required ReportTheme theme,
    required double startY,
  }) {
    final points = ReportChartData.fromAnalysis(analysis);
    if (points.isEmpty) return startY;

    final pageWidth = page.getClientSize().width;
    final availableHeight = math.max(
      60.0,
      page.getClientSize().height - startY - 35,
    );
    final chartHeight = chart.height.clamp(60.0, availableHeight).toDouble();
    final chartTop = startY + 20;
    final fontFam = _toPdfFontFamily(theme.fontFamily);
    final titleFont = PdfStandardFont(fontFam, 10.5, style: PdfFontStyle.bold);
    final labelFont = PdfStandardFont(fontFam, 8.5);
    final valFont = PdfStandardFont(fontFam, 8.5, style: PdfFontStyle.bold);
    final primaryBrush = PdfSolidBrush(
      _parseHexColor(theme.primaryColor, PdfColor(21, 101, 192)),
    );
    final textBrush = PdfSolidBrush(PdfColor(50, 50, 50));
    final barBgBrush = PdfSolidBrush(PdfColor(240, 240, 240));
    final palette = [
      PdfColor(21, 101, 192),
      PdfColor(0, 137, 123),
      PdfColor(239, 108, 0),
      PdfColor(198, 40, 40),
      PdfColor(106, 27, 154),
      PdfColor(85, 139, 47),
      PdfColor(2, 119, 189),
      PdfColor(109, 76, 65),
    ];
    final accentColor = _parseHexColor(
      theme.accentColor,
      PdfColor(66, 165, 245),
    );
    final accentBrush = PdfSolidBrush(accentColor);

    final chartTitle =
        chart.title ?? 'Analysis Breakdown (${chart.categoryColumn})';
    page.graphics.drawString(
      chartTitle,
      titleFont,
      brush: primaryBrush,
      bounds: Rect.fromLTWH(0, startY, pageWidth, 16),
    );

    final maxAbs = points.fold<num>(
      0,
      (maximum, point) => math.max(maximum, point.value.abs()),
    );
    final chartBounds = Rect.fromLTWH(0, chartTop, pageWidth, chartHeight);

    switch (chart.type) {
      case ReportChartType.bar:
        final labelWidth = pageWidth * 0.28;
        final valueWidth = chart.showValues ? 64.0 : 0.0;
        final trackLeft = labelWidth + 8;
        final trackWidth = math.max(
          0.0,
          pageWidth - trackLeft - valueWidth - 8,
        );
        final rowHeight = chartHeight / points.length;
        final barHeight = math.min(10.0, rowHeight * 0.55);

        for (int i = 0; i < points.length; i++) {
          final point = points[i];
          final rowTop = chartTop + i * rowHeight;
          page.graphics.drawString(
            point.label,
            labelFont,
            brush: textBrush,
            bounds: Rect.fromLTWH(0, rowTop, labelWidth, rowHeight),
          );
          page.graphics.drawRectangle(
            brush: barBgBrush,
            bounds: Rect.fromLTWH(
              trackLeft,
              rowTop + (rowHeight - barHeight) / 2,
              trackWidth,
              barHeight,
            ),
          );
          if (maxAbs > 0 && point.value != 0) {
            page.graphics.drawRectangle(
              brush: accentBrush,
              bounds: Rect.fromLTWH(
                trackLeft,
                rowTop + (rowHeight - barHeight) / 2,
                trackWidth * (point.value.abs() / maxAbs),
                barHeight,
              ),
            );
          }
          if (chart.showValues) {
            page.graphics.drawString(
              point.value.toString(),
              valFont,
              brush: textBrush,
              bounds: Rect.fromLTWH(
                pageWidth - valueWidth,
                rowTop,
                valueWidth,
                rowHeight,
              ),
            );
          }
        }
        break;
      case ReportChartType.column:
        final plotBottom = chartTop + chartHeight - 22;
        final plotHeight = math.max(1.0, chartHeight - 42);
        final slotWidth = pageWidth / points.length;
        final barWidth = math.min(36.0, slotWidth * 0.55);
        page.graphics.drawLine(
          PdfPen(PdfColor(180, 180, 180), width: 0.6),
          Offset(0, plotBottom),
          Offset(pageWidth, plotBottom),
        );

        for (int i = 0; i < points.length; i++) {
          final point = points[i];
          final barHeight = maxAbs == 0
              ? 0.0
              : plotHeight * (point.value.abs() / maxAbs);
          final barX = (i + 0.5) * slotWidth - barWidth / 2;
          final barY = plotBottom - barHeight;
          page.graphics.drawRectangle(
            brush: accentBrush,
            bounds: Rect.fromLTWH(barX, barY, barWidth, barHeight),
          );
          page.graphics.drawString(
            point.label,
            labelFont,
            brush: textBrush,
            bounds: Rect.fromLTWH(i * slotWidth, plotBottom + 4, slotWidth, 16),
          );
          if (chart.showValues) {
            page.graphics.drawString(
              point.value.toString(),
              valFont,
              brush: textBrush,
              bounds: Rect.fromLTWH(
                i * slotWidth,
                math.max(chartTop, barY - 14),
                slotWidth,
                14,
              ),
            );
          }
        }
        break;
      case ReportChartType.line:
        final plotLeft = 18.0;
        final plotRight = pageWidth - 18;
        final plotTop = chartTop + 14;
        final plotBottom = chartTop + chartHeight - 22;
        final plotHeight = math.max(1.0, plotBottom - plotTop);
        final pointXs = [
          for (int i = 0; i < points.length; i++)
            points.length == 1
                ? pageWidth / 2
                : plotLeft + (plotRight - plotLeft) * i / (points.length - 1),
        ];
        final pointYs = [
          for (final point in points)
            maxAbs == 0
                ? plotBottom
                : plotBottom - plotHeight * (point.value.abs() / maxAbs),
        ];
        page.graphics.drawLine(
          PdfPen(PdfColor(180, 180, 180), width: 0.6),
          Offset(plotLeft, plotBottom),
          Offset(plotRight, plotBottom),
        );
        for (int i = 0; i < points.length; i++) {
          if (i > 0) {
            page.graphics.drawLine(
              PdfPen(accentColor, width: 1.8),
              Offset(pointXs[i - 1], pointYs[i - 1]),
              Offset(pointXs[i], pointYs[i]),
            );
          }
          page.graphics.drawEllipse(
            Rect.fromLTWH(pointXs[i] - 3, pointYs[i] - 3, 6, 6),
            brush: accentBrush,
          );
          page.graphics.drawString(
            points[i].label,
            labelFont,
            brush: textBrush,
            bounds: Rect.fromLTWH(pointXs[i] - 42, plotBottom + 4, 84, 14),
          );
          if (chart.showValues) {
            page.graphics.drawString(
              points[i].value.toString(),
              valFont,
              brush: textBrush,
              bounds: Rect.fromLTWH(pointXs[i] - 30, pointYs[i] - 17, 60, 14),
            );
          }
        }
        break;
      case ReportChartType.pie:
        final positiveTotal = points.fold<num>(
          0,
          (sum, point) => sum + math.max(0, point.value),
        );
        if (positiveTotal <= 0) break;

        final legendWidth = chart.showLegend ? pageWidth * 0.38 : 0.0;
        final diameter = math.min(chartHeight, pageWidth - legendWidth - 12);
        final pieBounds = Rect.fromLTWH(
          8,
          chartTop + (chartHeight - diameter) / 2,
          diameter,
          diameter,
        );
        double angle = -90;
        for (int i = 0; i < points.length; i++) {
          final point = points[i];
          if (point.value <= 0) continue;
          final sweep = point.value / positiveTotal * 360;
          final sliceColor = palette[i % palette.length];
          page.graphics.drawPie(
            pieBounds,
            angle,
            sweep,
            pen: PdfPen(PdfColor(255, 255, 255), width: 0.7),
            brush: PdfSolidBrush(sliceColor),
          );
          if (chart.showValues) {
            final middleAngle = (angle + sweep / 2) * math.pi / 180;
            final centerX = pieBounds.left + diameter / 2;
            final centerY = pieBounds.top + diameter / 2;
            final labelX = centerX + math.cos(middleAngle) * diameter * 0.2;
            final labelY = centerY + math.sin(middleAngle) * diameter * 0.2;
            page.graphics.drawString(
              point.value.toString(),
              valFont,
              brush: PdfSolidBrush(PdfColor(255, 255, 255)),
              bounds: Rect.fromLTWH(labelX, labelY, 44, 14),
            );
          }
          angle += sweep;
        }
        if (chart.showLegend) {
          final legendLeft = pieBounds.right + 12;
          final legendRowHeight = chartHeight / points.length;
          for (int i = 0; i < points.length; i++) {
            final point = points[i];
            final rowTop = chartTop + i * legendRowHeight;
            page.graphics.drawRectangle(
              brush: PdfSolidBrush(palette[i % palette.length]),
              bounds: Rect.fromLTWH(legendLeft, rowTop + 3, 8, 8),
            );
            final legendText = chart.showValues
                ? '${point.label}: ${point.value}'
                : point.label;
            page.graphics.drawString(
              legendText,
              labelFont,
              brush: textBrush,
              bounds: Rect.fromLTWH(
                legendLeft + 13,
                rowTop,
                pageWidth - legendLeft - 13,
                legendRowHeight,
              ),
            );
          }
        }
        break;
    }

    return chartBounds.bottom + 10;
  }

  double _renderSummaryAndPaymentBlock({
    required PdfDocument document,
    required PdfPage page,
    required double startY,
    List<ReportSummaryItem>? summaryItems,
    ReportPaymentDetails? paymentDetails,
    required ReportTheme theme,
  }) {
    final double pageWidth = page.getClientSize().width;
    final fontFam = _toPdfFontFamily(theme.fontFamily);
    final titleFont = PdfStandardFont(fontFam, 9.5, style: PdfFontStyle.bold);
    final regularFont = PdfStandardFont(fontFam, 8.5);
    final boldFont = PdfStandardFont(fontFam, 8.5, style: PdfFontStyle.bold);
    final italicFont = PdfStandardFont(
      fontFam,
      8.0,
      style: PdfFontStyle.italic,
    );
    final primaryBrush = PdfSolidBrush(
      _parseHexColor(theme.primaryColor, PdfColor(30, 30, 30)),
    );
    final labelBrush = PdfSolidBrush(PdfColor(80, 80, 80));
    final valueBrush = PdfSolidBrush(PdfColor(20, 20, 20));
    final borderPen = PdfPen(
      _parseHexColor(theme.borderColor, PdfColor(200, 200, 200)),
      width: 0.6,
    );
    final accentPen = PdfPen(
      _parseHexColor(theme.accentColor, PdfColor(21, 101, 192)),
      width: 1.0,
    );

    double leftY = startY;
    // 1. Payment Details on the Left (width: 48% of page)
    if (paymentDetails != null) {
      page.graphics.drawString(
        'Remittance / Payment Details',
        titleFont,
        brush: primaryBrush,
        bounds: Rect.fromLTWH(0, leftY, pageWidth * 0.48, 14),
      );
      leftY += 16;

      void drawField(String label, String value, {bool bold = false}) {
        page.graphics.drawString(
          label,
          regularFont,
          brush: labelBrush,
          bounds: Rect.fromLTWH(0, leftY, 90, 13),
        );
        page.graphics.drawString(
          value,
          bold ? boldFont : regularFont,
          brush: valueBrush,
          bounds: Rect.fromLTWH(95, leftY, pageWidth * 0.48 - 95, 13),
        );
        leftY += 14;
      }

      if (paymentDetails.bankName != null) {
        drawField('Bank Name:', paymentDetails.bankName!);
      }
      if (paymentDetails.accountName != null) {
        drawField('Account Name:', paymentDetails.accountName!);
      }
      if (paymentDetails.accountNumber != null) {
        drawField('Account No:', paymentDetails.accountNumber!, bold: true);
      }
      if (paymentDetails.branch != null) {
        drawField('Branch:', paymentDetails.branch!);
      }
      if (paymentDetails.swiftCode != null) {
        drawField('SWIFT / BIC:', paymentDetails.swiftCode!);
      }
      for (final note in paymentDetails.termsOrNotes) {
        page.graphics.drawString(
          'Note: $note',
          italicFont,
          brush: labelBrush,
          bounds: Rect.fromLTWH(0, leftY, pageWidth * 0.48, 13),
        );
        leftY += 13;
      }
    }

    // 2. Financial Summaries on the Right (width: 45% of page)
    double rightY = startY;
    if (summaryItems != null && summaryItems.isNotEmpty) {
      final double rightX = pageWidth * 0.55;
      final double rightWidth = pageWidth * 0.45;
      final double valWidth = 90;
      final double lblWidth = rightWidth - valWidth - 8;

      for (final item in summaryItems) {
        if (item.showTopBorder) {
          page.graphics.drawLine(
            borderPen,
            Offset(rightX, rightY - 3),
            Offset(rightX + rightWidth, rightY - 3),
          );
        }

        final itemFont = item.isEmphasized
            ? PdfStandardFont(fontFam, 10.5, style: PdfFontStyle.bold)
            : (item.isBold ? boldFont : regularFont);
        final itemBrush = item.isEmphasized ? primaryBrush : valueBrush;

        page.graphics.drawString(
          item.label,
          itemFont,
          brush: item.isEmphasized ? primaryBrush : labelBrush,
          bounds: Rect.fromLTWH(rightX, rightY, lblWidth, 14),
          format: PdfStringFormat(alignment: PdfTextAlignment.right),
        );

        String valStr = item.value.toString();
        if (item.value is num) {
          final n = (item.value as num).toDouble();
          final sym = item.currencyCode != null ? '${item.currencyCode} ' : '';
          valStr = '$sym${NumberFormat('#,##0.00').format(n)}';
        }

        page.graphics.drawString(
          valStr,
          itemFont,
          brush: itemBrush,
          bounds: Rect.fromLTWH(rightX + lblWidth + 8, rightY, valWidth, 14),
          format: PdfStringFormat(alignment: PdfTextAlignment.right),
        );

        if (item.showDoubleBottomBorder) {
          page.graphics.drawLine(
            accentPen,
            Offset(rightX, rightY + 16),
            Offset(rightX + rightWidth, rightY + 16),
          );
          page.graphics.drawLine(
            accentPen,
            Offset(rightX, rightY + 18.5),
            Offset(rightX + rightWidth, rightY + 18.5),
          );
          rightY += 6;
        }

        rightY += 16;
      }
    }

    return math.max(leftY, rightY) + 10;
  }

  PdfFontFamily _toPdfFontFamily(String? fontFamily) {
    if (fontFamily == null) return PdfFontFamily.helvetica;
    final f = fontFamily.toLowerCase();
    if (f.contains('times') || f.contains('serif')) {
      return PdfFontFamily.timesRoman;
    }
    if (f.contains('courier') || f.contains('mono')) {
      return PdfFontFamily.courier;
    }
    return PdfFontFamily.helvetica;
  }

  void _renderSignatures(
    PdfDocument document,
    ReportTheme theme,
    List<ReportSignature> signatures,
    SignatureLayout layout,
  ) {
    final PdfPage lastPage = document.pages[document.pages.count - 1];
    final double pageWidth = lastPage.getClientSize().width;
    final double pageHeight = lastPage.getClientSize().height;

    final titleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      8.5,
      style: PdfFontStyle.bold,
    );
    final nameFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      9,
      style: PdfFontStyle.italic,
    );
    final dateFont = PdfStandardFont(PdfFontFamily.helvetica, 8);
    final pen = PdfPen(PdfColor(130, 130, 130), width: 0.8);
    final brush = PdfSolidBrush(
      _parseHexColor(theme.primaryColor, PdfColor(40, 40, 40)),
    );
    final dateBrush = PdfSolidBrush(PdfColor(100, 100, 100));

    switch (layout) {
      case SignatureLayout.horizontal:
        double y = pageHeight - 75;
        if (y < 60) {
          final newPage = document.pages.add();
          y = newPage.getClientSize().height - 75;
        }

        final double boxWidth =
            (pageWidth - ((signatures.length - 1) * 16)) / signatures.length;

        for (int i = 0; i < signatures.length; i++) {
          final double x = i * (boxWidth + 16);
          final sig = signatures[i];
          double curY = y;

          if (sig.name != null && sig.name!.isNotEmpty) {
            lastPage.graphics.drawString(
              sig.name!,
              nameFont,
              brush: brush,
              bounds: Rect.fromLTWH(x, curY, boxWidth, 12),
              format: PdfStringFormat(alignment: PdfTextAlignment.center),
            );
            curY += 14;
          } else {
            curY += 14;
          }

          lastPage.graphics.drawLine(
            pen,
            Offset(x, curY + 6),
            Offset(x + boxWidth, curY + 6),
          );
          curY += 10;

          lastPage.graphics.drawString(
            sig.title,
            titleFont,
            brush: brush,
            bounds: Rect.fromLTWH(x, curY, boxWidth, 12),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
          curY += 12;

          if (sig.date != null && sig.date!.isNotEmpty) {
            lastPage.graphics.drawString(
              'Date: ${sig.date!}',
              dateFont,
              brush: dateBrush,
              bounds: Rect.fromLTWH(x, curY, boxWidth, 11),
              format: PdfStringFormat(alignment: PdfTextAlignment.center),
            );
          }
        }
        break;

      case SignatureLayout.adaptive:
      case SignatureLayout.vertical:
        // Transposed: signatures stacked vertically row-by-row
        final double neededHeight = (signatures.length * 28.0) + 20.0;
        double y = pageHeight - neededHeight;
        PdfPage targetPage = lastPage;
        if (y < 60) {
          targetPage = document.pages.add();
          y = targetPage.getClientSize().height - neededHeight;
        }

        for (final sig in signatures) {
          // Title on left
          targetPage.graphics.drawString(
            '${sig.title}:',
            titleFont,
            brush: brush,
            bounds: Rect.fromLTWH(15, y, 120, 15),
          );

          // Signer name or line in middle
          if (sig.name != null && sig.name!.isNotEmpty) {
            targetPage.graphics.drawString(
              sig.name!,
              nameFont,
              brush: brush,
              bounds: Rect.fromLTWH(145, y, 150, 15),
            );
          }
          targetPage.graphics.drawLine(
            pen,
            Offset(145, y + 14),
            Offset(300, y + 14),
          );

          // Date on right
          if (sig.date != null && sig.date!.isNotEmpty) {
            targetPage.graphics.drawString(
              'Date: ${sig.date!}',
              dateFont,
              brush: dateBrush,
              bounds: Rect.fromLTWH(320, y, 150, 15),
            );
          } else {
            targetPage.graphics.drawString(
              'Date: ____________',
              dateFont,
              brush: dateBrush,
              bounds: Rect.fromLTWH(320, y, 150, 15),
            );
          }
          y += 24;
        }
        break;

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

        final double maxStack = math
            .max(leftSigs.length, rightSigs.length)
            .toDouble();
        final double neededHeight = (maxStack * 38.0) + 20.0;
        double startY = pageHeight - neededHeight;
        PdfPage targetPage = lastPage;
        if (startY < 60) {
          targetPage = document.pages.add();
          startY = targetPage.getClientSize().height - neededHeight;
        }

        final double colWidth = (pageWidth - 60) / 2;

        // Render left side signatures
        double leftY = startY;
        for (final sig in leftSigs) {
          if (sig.name != null && sig.name!.isNotEmpty) {
            targetPage.graphics.drawString(
              sig.name!,
              nameFont,
              brush: brush,
              bounds: Rect.fromLTWH(15, leftY, colWidth, 12),
            );
            leftY += 13;
          }
          targetPage.graphics.drawLine(
            pen,
            Offset(15, leftY + 12),
            Offset(15 + colWidth - 20, leftY + 12),
          );
          leftY += 15;
          targetPage.graphics.drawString(
            sig.title,
            titleFont,
            brush: brush,
            bounds: Rect.fromLTWH(15, leftY, colWidth, 12),
          );
          leftY += 13;
          if (sig.date != null && sig.date!.isNotEmpty) {
            targetPage.graphics.drawString(
              'Date: ${sig.date!}',
              dateFont,
              brush: dateBrush,
              bounds: Rect.fromLTWH(15, leftY, colWidth, 11),
            );
            leftY += 12;
          }
          leftY += 8;
        }

        // Render right side signatures
        double rightY = startY;
        final double rightX = 15 + colWidth + 30;
        for (final sig in rightSigs) {
          if (sig.name != null && sig.name!.isNotEmpty) {
            targetPage.graphics.drawString(
              sig.name!,
              nameFont,
              brush: brush,
              bounds: Rect.fromLTWH(rightX, rightY, colWidth, 12),
            );
            rightY += 13;
          }
          targetPage.graphics.drawLine(
            pen,
            Offset(rightX, rightY + 12),
            Offset(rightX + colWidth - 20, rightY + 12),
          );
          rightY += 15;
          targetPage.graphics.drawString(
            sig.title,
            titleFont,
            brush: brush,
            bounds: Rect.fromLTWH(rightX, rightY, colWidth, 12),
          );
          rightY += 13;
          if (sig.date != null && sig.date!.isNotEmpty) {
            targetPage.graphics.drawString(
              'Date: ${sig.date!}',
              dateFont,
              brush: dateBrush,
              bounds: Rect.fromLTWH(rightX, rightY, colWidth, 11),
            );
            rightY += 12;
          }
          rightY += 8;
        }
        break;
    }
  }

  void _configureSecurity(PdfDocument document, PdfExportOptions options) {
    if (options.enableEncryption) {
      final PdfSecurity security = document.security;
      security.userPassword = options.userPassword ?? '';
      security.ownerPassword =
          options.ownerPassword ?? 'EasyReportsOwnerSecret';
      security.permissions.add(
        options.allowPrinting
            ? PdfPermissionsFlags.print
            : PdfPermissionsFlags.none,
      );
      if (options.allowCopy) {
        security.permissions.add(PdfPermissionsFlags.copyContent);
      }
    }
  }

  PdfTextAlignment _toPdfAlignment(ReportColumnAlignment align) {
    switch (align) {
      case ReportColumnAlignment.left:
        return PdfTextAlignment.left;
      case ReportColumnAlignment.center:
        return PdfTextAlignment.center;
      case ReportColumnAlignment.right:
        return PdfTextAlignment.right;
    }
  }

  PdfColor _parseHexColor(String hex, PdfColor fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        final r = int.parse(clean.substring(0, 2), radix: 16);
        final g = int.parse(clean.substring(2, 4), radix: 16);
        final b = int.parse(clean.substring(4, 6), radix: 16);
        return PdfColor(r, g, b);
      }
    } catch (_) {}
    return fallback;
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
