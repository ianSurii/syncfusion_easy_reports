import 'dart:io' show File;
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
            isFirst: i == 0,
          );
        }
        for (final catSheet in analysis.categorySheets!) {
          _renderCategorySheetSection(document, catSheet, theme, opts);
        }
      } else {
        _renderAnalysisSection(
          document,
          analysis,
          theme,
          opts,
          isFirst: i == 0,
        );
      }
    }

    // 6. Signatures if requested
    if (opts.showSignatures && opts.signatureLabels.isNotEmpty) {
      _renderSignatures(document, theme, opts.signatureLabels);
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

    final headerTemplate = PdfPageTemplateElement(
      Rect.fromLTWH(0, 0, document.pageSettings.size.width, 60),
    );

    headerTemplate.graphics.drawString(
      branding.companyName ?? defaultTitle,
      PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
      brush: PdfSolidBrush(
        _parseHexColor(theme.primaryColor, PdfColor(21, 101, 192)),
      ),
      bounds: const Rect.fromLTWH(15, 5, 300, 15),
    );

    if (branding.address != null) {
      headerTemplate.graphics.drawString(
        branding.address!,
        PdfStandardFont(PdfFontFamily.helvetica, 8),
        brush: PdfSolidBrush(PdfColor(100, 100, 100)),
        bounds: const Rect.fromLTWH(15, 20, 300, 12),
      );
    }

    // Draw thin header rule
    headerTemplate.graphics.drawLine(
      PdfPen(PdfColor(200, 200, 200), width: 0.5),
      const Offset(15, 35),
      Offset(document.pageSettings.size.width - 15, 35),
    );

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
    PdfExportOptions options, {
    required bool isFirst,
  }) {
    final PdfPage page = document.pages.add();
    final double pageWidth = page.getClientSize().width;
    double y = 10;

    // Section Title
    final titleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      14,
      style: PdfFontStyle.bold,
    );
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
      final subFont = PdfStandardFont(
        PdfFontFamily.helvetica,
        9,
        style: PdfFontStyle.italic,
      );
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
        PdfStandardFont(
          PdfFontFamily.helvetica,
          10,
          style: PdfFontStyle.italic,
        ),
        brush: PdfSolidBrush(PdfColor(120, 120, 120)),
        bounds: Rect.fromLTWH(0, y + 10, pageWidth, 25),
      );
      return;
    }

    // Render Table Grid
    if (analysis.headers.isNotEmpty) {
      _drawGrid(
        page: page,
        headers: analysis.headers,
        rows: analysis.rows,
        grandTotalRow: analysis.grandTotalRow,
        theme: theme,
        options: options,
        startY: y,
      );
    }
  }

  void _renderCategorySheetSection(
    PdfDocument document,
    PreparedCategorySheet catSheet,
    ReportTheme theme,
    PdfExportOptions options,
  ) {
    final PdfPage page = document.pages.add();
    final double pageWidth = page.getClientSize().width;
    double y = 10;

    // Category Title
    final titleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      14,
      style: PdfFontStyle.bold,
    );
    page.graphics.drawString(
      catSheet.categoryLabel,
      titleFont,
      brush: PdfSolidBrush(
        _parseHexColor(theme.accentColor, PdfColor(13, 71, 161)),
      ),
      bounds: Rect.fromLTWH(0, y, pageWidth, 20),
    );
    y += 24;

    if (catSheet.headers.isNotEmpty) {
      _drawGrid(
        page: page,
        headers: catSheet.headers,
        rows: catSheet.rows,
        grandTotalRow: catSheet.totalsRow,
        theme: theme,
        options: options,
        startY: y,
      );
    }
  }

  void _drawGrid({
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
          PdfFontFamily.helvetica,
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
      headerRow.cells[c].style.borders.all = PdfPen(
        _parseHexColor(theme.accentColor, PdfColor(13, 71, 161)),
        width: 0.5,
      );
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
            PdfFontFamily.helvetica,
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
              PdfFontFamily.helvetica,
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
            font: PdfStandardFont(PdfFontFamily.helvetica, theme.fontSizeBody),
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
          gridRow.cells[c].style.borders.all = PdfPen(
            _parseHexColor(theme.borderColor, PdfColor(200, 200, 200)),
            width: 0.5,
          );
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
            PdfFontFamily.helvetica,
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
        totRow.cells[c].style.borders.top = PdfPen(
          PdfColor(50, 50, 50),
          width: 1.0,
        );
        totRow.cells[c].style.borders.bottom = PdfPen(
          PdfColor(50, 50, 50),
          width: 1.5,
        );
      }
    }

    // Draw Grid on page
    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, startY, pageWidth, 0),
      format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
    );
  }

  void _renderSignatures(
    PdfDocument document,
    ReportTheme theme,
    List<String> labels,
  ) {
    final PdfPage lastPage = document.pages[document.pages.count - 1];
    final double pageWidth = lastPage.getClientSize().width;
    final double pageHeight = lastPage.getClientSize().height;

    double y = pageHeight - 70;
    if (y < 50) {
      final newPage = document.pages.add();
      y = newPage.getClientSize().height - 70;
    }

    final double boxWidth =
        (pageWidth - ((labels.length - 1) * 20)) / labels.length;

    for (int i = 0; i < labels.length; i++) {
      final double x = i * (boxWidth + 20);
      final label = labels[i];

      lastPage.graphics.drawLine(
        PdfPen(PdfColor(100, 100, 100), width: 1),
        Offset(x, y + 25),
        Offset(x + boxWidth, y + 25),
      );

      lastPage.graphics.drawString(
        label,
        PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(80, 80, 80)),
        bounds: Rect.fromLTWH(x, y + 30, boxWidth, 15),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
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
