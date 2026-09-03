import 'dart:io' show File;
import 'dart:ui' show Offset, Rect;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../downloader/downloader.dart';
import '../models/report_models.dart';

/// Service to generate professional PDF reports from [ReportData].
class PdfReportGenerator {
  static final Logger _log = Logger('PdfReportGenerator');

  /// Generates the PDF document and returns raw bytes.
  Future<List<int>> generate(ReportData reportData) async {
    _log.info('Starting PDF generation for: "${reportData.title}"');

    final PdfDocument document = PdfDocument();

    final theme = reportData.theme ?? ReportTheme.classicBlue();
    final settings = reportData.settings ?? ReportSettings();

    // 1. Page settings configurations
    _configurePageSettings(document, settings);

    // Pre-resolve branding logo
    List<int>? logoBytes;
    if (reportData.branding != null) {
      logoBytes = await _resolveLogo(reportData.branding!);
    }

    final ReportBranding? resolvedBranding =
        reportData.branding != null && logoBytes != null
        ? reportData.branding!.copyWithBytes(logoBytes)
        : reportData.branding;

    // 2. Add header and footer templates
    _addHeader(document, resolvedBranding, theme);
    _addFooter(document, theme);

    // 3. Create first page
    PdfPage page = document.pages.add();
    double y = 0;
    final double pageWidth = page.getClientSize().width;
    final double pageHeight = page.getClientSize().height;

    // Fonts setup
    final titleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      theme.fontSizeTitle,
      style: PdfFontStyle.bold,
    );
    final sectionTitleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      theme.fontSizeTitle - 4,
      style: PdfFontStyle.bold,
    );
    final headerFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      theme.fontSizeHeader,
      style: PdfFontStyle.bold,
    );
    final bodyFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      theme.fontSizeBody,
    );

    // Draw Report Title
    page.graphics.drawString(
      reportData.title,
      titleFont,
      brush: PdfSolidBrush(
        _parseHexColor(theme.primaryColor, PdfColor(21, 101, 192)),
      ),
      bounds: Rect.fromLTWH(0, y, pageWidth, 30),
    );
    y += theme.fontSizeTitle + 15;

    // Draw Global Custom Data (Header properties)
    if (reportData.customData != null && reportData.customData!.isNotEmpty) {
      y = _drawKeyValuePairs(
        page,
        reportData.customData!,
        Rect.fromLTWH(0, y, pageWidth, 0),
        theme,
        isHeaderData: true,
      );
      y += 15;
    }

    // 4. Render sections
    for (final section in reportData.sections) {
      // Check page overflow before rendering section title
      if (y > pageHeight - 80) {
        page = document.pages.add();
        y = 0;
      }

      // Section title
      if (section.title != null) {
        page.graphics.drawString(
          section.title!,
          sectionTitleFont,
          brush: PdfSolidBrush(
            _parseHexColor(theme.accentColor, PdfColor(13, 71, 161)),
          ),
          bounds: Rect.fromLTWH(0, y, pageWidth, 25),
        );
        y += theme.fontSizeTitle - 4 + 10;
      }

      // Section description
      if (section.description != null) {
        page.graphics.drawString(
          section.description!,
          bodyFont,
          bounds: Rect.fromLTWH(0, y, pageWidth, 20),
        );
        y += theme.fontSizeBody + 10;
      }

      // Section metadata custom fields
      if (section.customData != null && section.customData!.isNotEmpty) {
        y = _drawKeyValuePairs(
          page,
          section.customData!,
          Rect.fromLTWH(0, y, pageWidth, 0),
          theme,
        );
        y += 10;
      }

      // Draw section table or list
      if (section.table != null) {
        if (section.orientation == ReportSectionOrientation.horizontal) {
          // Grid table drawing
          final PdfGrid grid = PdfGrid();
          grid.columns.add(count: section.table!.headers.length);

          // Configure widths
          if (section.table!.columnWidths != null) {
            for (
              int col = 0;
              col < section.table!.columnWidths!.length;
              col++
            ) {
              if (col < grid.columns.count) {
                grid.columns[col].width = section.table!.columnWidths![col];
              }
            }
          }

          // Headers
          if (section.table!.showHeaders) {
            final PdfGridRow headerRow = grid.headers.add(1)[0];
            for (int col = 0; col < section.table!.headers.length; col++) {
              headerRow.cells[col].value = section.table!.headers[col];

              if (section.table!.columnAlignments != null &&
                  section.table!.columnAlignments!.containsKey(col)) {
                headerRow.cells[col].stringFormat = PdfStringFormat(
                  alignment: _parseTextAlignment(
                    section.table!.columnAlignments![col]!,
                  ),
                );
              }
            }

            headerRow.style.font = headerFont;
            headerRow.style.backgroundBrush = PdfSolidBrush(
              _parseHexColor(
                theme.headerBackgroundColor,
                PdfColor(21, 101, 192),
              ),
            );
            headerRow.style.textBrush = PdfSolidBrush(
              _parseHexColor(theme.headerTextColor, PdfColor(255, 255, 255)),
            );
          }

          // Data Rows
          int rIndex = 0;
          for (final row in section.table!.rows) {
            final PdfGridRow pdfRow = grid.rows.add();

            final bool isGroupHeader =
                section.table!.groupHeaderIndices?.contains(rIndex) ?? false;
            final bool isGroupTotal =
                section.table!.groupTotalIndices?.contains(rIndex) ?? false;

            if (isGroupHeader) {
              pdfRow.cells[0].columnSpan = grid.columns.count;
              pdfRow.cells[0].value = row.isNotEmpty
                  ? row[0]?.toString() ?? ''
                  : '';

              pdfRow.style.font = headerFont;
              pdfRow.style.backgroundBrush = PdfSolidBrush(
                _parseHexColor(
                  theme.groupHeaderBackgroundColor,
                  PdfColor(227, 242, 253),
                ),
              );
              pdfRow.style.textBrush = PdfSolidBrush(
                _parseHexColor(
                  theme.groupHeaderTextColor,
                  PdfColor(13, 71, 161),
                ),
              );
            } else if (isGroupTotal) {
              for (int col = 0; col < row.length; col++) {
                final value = row[col];
                pdfRow.cells[col].value = _getFormattedValue(
                  value,
                  col,
                  section.table!,
                );

                if (col == 0) {
                  pdfRow.cells[col].stringFormat = PdfStringFormat(
                    alignment: PdfTextAlignment.left,
                  );
                } else if (section.table!.columnAlignments != null &&
                    section.table!.columnAlignments!.containsKey(col)) {
                  pdfRow.cells[col].stringFormat = PdfStringFormat(
                    alignment: _parseTextAlignment(
                      section.table!.columnAlignments![col]!,
                    ),
                  );
                }
              }
              pdfRow.style.font = headerFont;
              pdfRow.style.backgroundBrush = PdfSolidBrush(
                _parseHexColor(
                  theme.groupHeaderBackgroundColor,
                  PdfColor(227, 242, 253),
                ),
              );
              pdfRow.style.textBrush = PdfSolidBrush(
                _parseHexColor(
                  theme.groupHeaderTextColor,
                  PdfColor(13, 71, 161),
                ),
              );
            } else {
              // Regular row values
              for (int col = 0; col < row.length; col++) {
                final value = row[col];
                pdfRow.cells[col].value = _getFormattedValue(
                  value,
                  col,
                  section.table!,
                );
                pdfRow.cells[col].style.font = bodyFont;

                if (section.table!.columnAlignments != null &&
                    section.table!.columnAlignments!.containsKey(col)) {
                  pdfRow.cells[col].stringFormat = PdfStringFormat(
                    alignment: _parseTextAlignment(
                      section.table!.columnAlignments![col]!,
                    ),
                  );
                }
              }

              // Alternating backgrounds (zebra striping)
              if (rIndex % 2 == 0) {
                pdfRow.style.backgroundBrush = PdfSolidBrush(
                  _parseHexColor(
                    theme.zebraLightColor,
                    PdfColor(245, 245, 245),
                  ),
                );
              } else {
                pdfRow.style.backgroundBrush = PdfSolidBrush(
                  _parseHexColor(theme.zebraDarkColor, PdfColor(255, 255, 255)),
                );
              }
            }
            rIndex++;
          }

          // Dynamic Totals Row
          List<String>? totals = section.table!.totalsRow;
          if (totals == null && section.table!.calculateTotals) {
            totals = _calculateTotals(section.table!);
          }

          if (totals != null) {
            final PdfGridRow totalRow = grid.rows.add();
            for (int col = 0; col < totals.length; col++) {
              totalRow.cells[col].value = totals[col];

              if (col == 0) {
                totalRow.cells[col].stringFormat = PdfStringFormat(
                  alignment: PdfTextAlignment.left,
                );
              } else {
                totalRow.cells[col].stringFormat = PdfStringFormat(
                  alignment: _parseTextAlignment(theme.totalsAlignment),
                );
              }
            }

            totalRow.style.font = headerFont;
            totalRow.style.backgroundBrush = PdfSolidBrush(
              _parseHexColor(
                theme.totalsBackgroundColor,
                PdfColor(255, 249, 196),
              ),
            );
            totalRow.style.textBrush = PdfSolidBrush(
              _parseHexColor(theme.totalsTextColor, PdfColor(0, 0, 0)),
            );
          }

          // Cells Padding settings
          grid.style.cellPadding = PdfPaddings(
            left: theme.cellPadding,
            top: theme.cellPadding,
            right: theme.cellPadding,
            bottom: theme.cellPadding,
          );

          // Borders rendering configuration
          if (!section.table!.showBorders) {
            for (int i = 0; i < grid.headers.count; i++) {
              for (int j = 0; j < grid.headers[i].cells.count; j++) {
                grid.headers[i].cells[j].style.borders.all =
                    PdfPens.transparent;
              }
            }
            for (int i = 0; i < grid.rows.count; i++) {
              for (int j = 0; j < grid.rows[i].cells.count; j++) {
                grid.rows[i].cells[j].style.borders.all = PdfPens.transparent;
              }
            }
          } else {
            // Apply theme border color
            final borderPen = PdfPen(
              _parseHexColor(theme.borderColor, PdfColor(189, 189, 189)),
              width: 0.5,
            );
            for (int i = 0; i < grid.rows.count; i++) {
              for (int j = 0; j < grid.rows[i].cells.count; j++) {
                grid.rows[i].cells[j].style.borders.all = borderPen;
              }
            }
          }

          // Draw the grid
          final PdfLayoutResult? result = grid.draw(
            page: page,
            bounds: Rect.fromLTWH(0, y, pageWidth, pageHeight - y),
            format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
          );

          if (result != null) {
            y = result.bounds.bottom;
            page = result.page;
          }
        } else {
          // Vertical property-sheet drawing
          for (final row in section.table!.rows) {
            if (y > pageHeight - 80) {
              page = document.pages.add();
              y = 0;
            }

            final PdfGrid grid = PdfGrid();
            grid.columns.add(count: 2);
            grid.columns[0].width = pageWidth * 0.35; // 35% for Key labels

            for (int col = 0; col < section.table!.headers.length; col++) {
              if (col >= row.length) break;

              final PdfGridRow pdfRow = grid.rows.add();
              // Key Header
              pdfRow.cells[0].value = section.table!.headers[col];
              pdfRow.cells[0].style.font = headerFont;

              // Value formatted
              pdfRow.cells[1].value = _getFormattedValue(
                row[col],
                col,
                section.table!,
              );
              pdfRow.cells[1].style.font = bodyFont;
            }

            grid.style.cellPadding = PdfPaddings(
              left: theme.cellPadding,
              top: theme.cellPadding,
              right: theme.cellPadding,
              bottom: theme.cellPadding,
            );

            // Borders setup
            if (!section.table!.showBorders) {
              for (int i = 0; i < grid.rows.count; i++) {
                for (int j = 0; j < grid.rows[i].cells.count; j++) {
                  grid.rows[i].cells[j].style.borders.all = PdfPens.transparent;
                }
              }
            } else {
              final borderPen = PdfPen(
                _parseHexColor(theme.borderColor, PdfColor(189, 189, 189)),
                width: 0.5,
              );
              for (int i = 0; i < grid.rows.count; i++) {
                for (int j = 0; j < grid.rows[i].cells.count; j++) {
                  grid.rows[i].cells[j].style.borders.all = borderPen;
                }
              }
            }

            final PdfLayoutResult? result = grid.draw(
              page: page,
              bounds: Rect.fromLTWH(0, y, pageWidth, pageHeight - y),
              format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
            );

            if (result != null) {
              y = result.bounds.bottom + theme.itemSpacing;
              page = result.page;
            }
          }
        }
      }

      y += theme.sectionSpacing;
    }

    // 5. Draw Footer fields signatures
    if (reportData.footerData != null && reportData.footerData!.isNotEmpty) {
      if (y > pageHeight - 80) {
        page = document.pages.add();
        y = 0;
      } else {
        y += 10;
      }

      y = _drawKeyValuePairs(
        page,
        reportData.footerData!,
        Rect.fromLTWH(0, y, pageWidth, 0),
        theme,
        isFooterData: true,
      );
    }

    // Apply security passwords
    _applySecurity(document, settings);

    // Save PDF
    final List<int> bytes = await document.save();
    document.dispose();

    _log.info('PDF file generated: ${bytes.length} bytes');
    return bytes;
  }

  /// Generates the PDF report and automatically triggers file save/download.
  Future<void> generateAndDownload(
    ReportData reportData,
    String filename,
  ) async {
    final List<int> bytes = await generate(reportData);
    final String fullFilename = filename.endsWith('.pdf')
        ? filename
        : '$filename.pdf';

    final downloader = FileDownloader();
    await downloader.downloadFile(
      bytes,
      fullFilename,
      mimeType: 'application/pdf',
    );
  }

  // =========================================================================
  // DOCUMENT PROTECTION & HELPERS
  // =========================================================================

  void _configurePageSettings(PdfDocument document, ReportSettings settings) {
    switch (settings.pageSize.toUpperCase()) {
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
    }

    if (settings.orientation.toLowerCase() == 'landscape') {
      document.pageSettings.orientation = PdfPageOrientation.landscape;
    } else {
      document.pageSettings.orientation = PdfPageOrientation.portrait;
    }

    document.pageSettings.margins.all = settings.margin;
  }

  void _addHeader(
    PdfDocument document,
    ReportBranding? branding,
    ReportTheme theme,
  ) {
    if (branding == null) return;

    final double width = document.pageSettings.size.width;
    final PdfPageTemplateElement header = PdfPageTemplateElement(
      Rect.fromLTWH(0, 0, width, 85),
    );

    // Draw logo image
    if (branding.logoBytes != null) {
      try {
        final PdfBitmap image = PdfBitmap(
          Uint8List.fromList(branding.logoBytes!),
        );
        header.graphics.drawImage(
          image,
          Rect.fromLTWH(
            0,
            0,
            (branding.logoWidth ?? 60).toDouble(),
            (branding.logoHeight ?? 60).toDouble(),
          ),
        );
      } catch (e) {
        _log.warning('Failed to render logo bitmap in PDF: $e');
      }
    }

    double textX = branding.logoBytes != null
        ? (branding.logoWidth ?? 60) + 15
        : 0;
    double y = 0;

    final bodyFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      theme.fontSizeBody - 1,
    );
    final compColor = _parseHexColor(
      theme.primaryColor,
      PdfColor(21, 101, 192),
    );

    if (branding.companyName != null) {
      header.graphics.drawString(
        branding.companyName!,
        PdfStandardFont(
          PdfFontFamily.helvetica,
          theme.fontSizeHeader + 3,
          style: PdfFontStyle.bold,
        ),
        brush: PdfSolidBrush(compColor),
        bounds: Rect.fromLTWH(textX, y, width - textX, 20),
      );
      y += 18;
    }

    if (branding.address != null) {
      header.graphics.drawString(
        branding.address!,
        bodyFont,
        bounds: Rect.fromLTWH(textX, y, width - textX, 15),
      );
      y += 13;
    }

    if (branding.email != null) {
      header.graphics.drawString(
        'Email: ${branding.email}',
        bodyFont,
        bounds: Rect.fromLTWH(textX, y, width - textX, 15),
      );
      y += 13;
    }

    if (branding.phone != null) {
      header.graphics.drawString(
        'Phone: ${branding.phone}',
        bodyFont,
        bounds: Rect.fromLTWH(textX, y, width - textX, 15),
      );
    }

    document.template.top = header;
  }

  void _addFooter(PdfDocument document, ReportTheme theme) {
    final double width = document.pageSettings.size.width;
    final PdfPageTemplateElement footer = PdfPageTemplateElement(
      Rect.fromLTWH(0, 0, width, 40),
    );

    final font = PdfStandardFont(
      PdfFontFamily.helvetica,
      theme.fontSizeBody - 2,
    );

    footer.graphics.drawString(
      'Generated by Easy Reports Wrapper',
      font,
      bounds: Rect.fromLTWH(0, 10, width, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Page Number details
    PdfCompositeField(
      text: 'Page {0} of {1}',
      fields: [
        PdfPageNumberField(font: font),
        PdfPageCountField(font: font),
      ],
    ).draw(footer.graphics, Offset(width - 80, 10));

    document.template.bottom = footer;
  }

  void _applySecurity(PdfDocument document, ReportSettings settings) {
    final userPass = settings.userPassword;
    final ownerPass = settings.ownerPassword;

    if ((userPass != null && userPass.isNotEmpty) ||
        (ownerPass != null && ownerPass.isNotEmpty)) {
      final PdfSecurity security = document.security;
      security.userPassword = userPass ?? '';
      if (ownerPass != null) {
        security.ownerPassword = ownerPass;
      }
      security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
    }
  }

  // =========================================================================
  // VAL RESOLUTION & CALC HELPERS
  // =========================================================================

  Future<List<int>?> _resolveLogo(ReportBranding branding) async {
    if (branding.logoBytes != null && branding.logoBytes!.isNotEmpty) {
      return branding.logoBytes;
    }

    if (branding.logoUrl != null && branding.logoUrl!.isNotEmpty) {
      _log.fine('PDF: Fetching network logo: ${branding.logoUrl}');
      try {
        final response = await http.get(Uri.parse(branding.logoUrl!));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } catch (e) {
        _log.warning('PDF: Network logo download exception: $e');
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
          if (await file.exists()) {
            return await file.readAsBytes();
          }
        } catch (_) {}
      }
    }
    return null;
  }

  double _drawKeyValuePairs(
    PdfPage page,
    Map<String, String> data,
    Rect bounds,
    ReportTheme theme, {
    bool isHeaderData = false,
    bool isFooterData = false,
  }) {
    double y = bounds.top;
    final double x = bounds.left;
    final double width = bounds.width;

    // Determine typography sizes and colors
    final double keySize = isHeaderData
        ? theme.fontSizeCustomDataHeader
        : isFooterData
        ? theme.fontSizeFooterDataHeader
        : theme.fontSizeBody;
    final double valSize = isHeaderData
        ? theme.fontSizeCustomDataValue
        : isFooterData
        ? theme.fontSizeFooterDataValue
        : theme.fontSizeBody;

    final PdfFont keyFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      keySize,
      style: PdfFontStyle.bold,
    );
    final PdfFont valueFont = PdfStandardFont(PdfFontFamily.helvetica, valSize);

    final String kColor = isHeaderData
        ? theme.customDataHeaderColor
        : isFooterData
        ? theme.footerDataHeaderColor
        : '#000000';
    final String vColor = isHeaderData
        ? theme.customDataValueColor
        : isFooterData
        ? theme.footerDataValueColor
        : '#333333';

    final PdfBrush keyBrush = PdfSolidBrush(
      _parseHexColor(kColor, PdfColor(0, 0, 0)),
    );
    final PdfBrush valueBrush = PdfSolidBrush(
      _parseHexColor(vColor, PdfColor(0, 0, 0)),
    );

    final double itemSpacing = theme.itemSpacing;

    for (final entry in data.entries) {
      // Key label (Left column - 35% width)
      page.graphics.drawString(
        '${entry.key}:',
        keyFont,
        brush: keyBrush,
        bounds: Rect.fromLTWH(x, y, width * 0.35, 18),
      );

      // Value (Right column - 65% width)
      page.graphics.drawString(
        entry.value,
        valueFont,
        brush: valueBrush,
        bounds: Rect.fromLTWH(x + (width * 0.35), y, width * 0.65, 18),
      );

      y += keySize + itemSpacing + 2;
    }

    return y;
  }

  String _getFormattedValue(dynamic value, int colIndex, ReportTable table) {
    final String symbol = table.currencySymbol ?? '';
    final bool isCurrency =
        table.currencyColumnIndices?.contains(colIndex) ?? false;
    final bool isNumber =
        table.numberColumnIndices?.contains(colIndex) ?? false;

    if (value is num) {
      if (isCurrency) {
        final formatter = NumberFormat.currency(
          symbol: symbol,
          decimalDigits: 2,
        );
        return formatter.format(value);
      } else if (isNumber) {
        final formatter = NumberFormat.decimalPattern();
        return formatter.format(value);
      } else {
        return value.toStringAsFixed(2);
      }
    } else if (value is DateTime) {
      return DateFormat('dd-MMM-yyyy').format(value);
    } else if (value is bool) {
      return value ? 'Yes' : 'No';
    } else {
      return value?.toString() ?? '';
    }
  }

  List<String> _calculateTotals(ReportTable table) {
    final List<double> sums = List.filled(table.headers.length, 0.0);
    final List<bool> shouldSum = List.filled(table.headers.length, false);

    // Identify summation indices
    if (table.summationColumnIndices != null) {
      for (final index in table.summationColumnIndices!) {
        if (index < shouldSum.length) shouldSum[index] = true;
      }
    }
    if (table.currencyColumnIndices != null) {
      for (final index in table.currencyColumnIndices!) {
        if (index < shouldSum.length) shouldSum[index] = true;
      }
    }

    for (final row in table.rows) {
      for (int i = 0; i < row.length; i++) {
        if (i < shouldSum.length && shouldSum[i] && row[i] is num) {
          sums[i] += (row[i] as num).toDouble();
        }
      }
    }

    final List<String> totals = [];
    for (int i = 0; i < table.headers.length; i++) {
      if (i == 0) {
        totals.add('Total');
      } else if (shouldSum[i]) {
        totals.add(_getFormattedValue(sums[i], i, table));
      } else {
        totals.add('');
      }
    }

    return totals;
  }

  PdfTextAlignment _parseTextAlignment(String alignment) {
    switch (alignment.toLowerCase()) {
      case 'center':
        return PdfTextAlignment.center;
      case 'right':
        return PdfTextAlignment.right;
      case 'left':
      default:
        return PdfTextAlignment.left;
    }
  }

  PdfColor _parseHexColor(String hexString, PdfColor defaultColor) {
    try {
      String cleanHex = hexString.replaceAll('#', '');
      if (cleanHex.length == 6) {
        final int r = int.parse(cleanHex.substring(0, 2), radix: 16);
        final int g = int.parse(cleanHex.substring(2, 4), radix: 16);
        final int b = int.parse(cleanHex.substring(4, 6), radix: 16);
        return PdfColor(r, g, b);
      } else if (cleanHex.length == 8) {
        final int r = int.parse(cleanHex.substring(2, 4), radix: 16);
        final int g = int.parse(cleanHex.substring(4, 6), radix: 16);
        final int b = int.parse(cleanHex.substring(6, 8), radix: 16);
        return PdfColor(r, g, b);
      }
    } catch (_) {}
    return defaultColor;
  }
}
