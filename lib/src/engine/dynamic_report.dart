import 'dart:typed_data';
import '../models/report_models.dart';
import 'report_definition.dart';
import 'report_column.dart';
import 'report_measure.dart';
import 'report_analysis.dart';
import 'report_options.dart';
import 'report_artifact.dart';
import 'prepared_report.dart';
import 'report_engine.dart';
import '../saver/report_saver.dart';

/// A super-dynamic, unified reporting engine that generates multi-sheet Excel
/// workbooks and paginated PDF documents from any dataset with zero boilerplate.
///
/// Features:
/// - **Automatic Schema Inference**: Detects money, numbers, dates, booleans, and text.
/// - **On-the-Fly Grouping**: Group by any field(s) with category-split sheets (`sheetPerCategory: true`).
/// - **Auto-Aggregations**: Automatically computes sums, counts, averages, and percentages.
/// - **Dynamic Pivot / CrossTab**: 2D matrices comparing two categorical dimensions.
/// - **Formal Signatures**: Configurable signature lines on Excel worksheets and PDF pages.
/// - **One-Liner Exports**: Direct byte generation and saving without platform lock-in.
class EasyReport {
  static final ReportEngine _engine = ReportEngine();
  static final ReportSaver _saver = ReportSaver();

  final ReportDefinition<Map<String, dynamic>> definition;
  final List<Map<String, dynamic>> data;

  const EasyReport._({
    required this.definition,
    required this.data,
  });

  /// Creates an [EasyReport] instance by auto-analyzing and configuring a list of Maps.
  factory EasyReport.fromMaps({
    required List<Map<String, dynamic>> data,
    String title = 'Business Report',
    String? subtitle,
    ReportBranding? branding,
    String? companyName,
    ReportTheme? theme,

    // Column customizers
    List<String>? visibleColumns,
    List<String>? hiddenColumns,
    Map<String, String>? columnTitles,
    Map<String, ReportFieldType>? columnTypes,
    List<String>? currencyColumns,
    List<String>? dateColumns,
    String currencyCode = 'USD',

    // Grouping & Category Sheets
    dynamic groupBy, // String or List<String>
    bool sheetPerCategory = false,
    List<String>? categoryDetailColumns,
    String missingCategoryLabel = 'Unassigned',

    // Measures & Aggregations
    List<String>? sumColumns,
    List<String>? averageColumns,
    bool autoAggregateNumericColumns = true,
    List<ReportMeasure>? customMeasures,

    // Layout Analyses
    bool includeDetailSheet = true,
    bool includeGroupedSummary = true,
    bool includeCrossTab = false,
    String? crossTabRowDimension,
    String? crossTabColumnDimension,
    String? crossTabMeasureColumn,
    bool includeSummaryCard = false,

    // Signatures & Document Options
    bool showSignatures = false,
    List<String> signatures = const [
      'Prepared By',
      'Checked By',
      'Approved By',
      'Authorized By',
    ],
    ExcelExportOptions? excelOptions,
    PdfExportOptions? pdfOptions,
    Map<String, dynamic>? metadata,
  }) {
    final def = buildDefinitionFromMaps(
      data: data,
      title: title,
      subtitle: subtitle,
      branding: branding,
      companyName: companyName,
      theme: theme,
      visibleColumns: visibleColumns,
      hiddenColumns: hiddenColumns,
      columnTitles: columnTitles,
      columnTypes: columnTypes,
      currencyColumns: currencyColumns,
      dateColumns: dateColumns,
      currencyCode: currencyCode,
      groupBy: groupBy,
      sheetPerCategory: sheetPerCategory,
      categoryDetailColumns: categoryDetailColumns,
      missingCategoryLabel: missingCategoryLabel,
      sumColumns: sumColumns,
      averageColumns: averageColumns,
      autoAggregateNumericColumns: autoAggregateNumericColumns,
      customMeasures: customMeasures,
      includeDetailSheet: includeDetailSheet,
      includeGroupedSummary: includeGroupedSummary,
      includeCrossTab: includeCrossTab,
      crossTabRowDimension: crossTabRowDimension,
      crossTabColumnDimension: crossTabColumnDimension,
      crossTabMeasureColumn: crossTabMeasureColumn,
      includeSummaryCard: includeSummaryCard,
      showSignatures: showSignatures,
      signatures: signatures,
      excelOptions: excelOptions,
      pdfOptions: pdfOptions,
      metadata: metadata,
    );

    return EasyReport._(definition: def, data: data);
  }

  /// Builds a super-dynamic [ReportDefinition] from raw Map records.
  static ReportDefinition<Map<String, dynamic>> buildDefinitionFromMaps({
    required List<Map<String, dynamic>> data,
    String title = 'Business Report',
    String? subtitle,
    ReportBranding? branding,
    String? companyName,
    ReportTheme? theme,

    // Column customizers
    List<String>? visibleColumns,
    List<String>? hiddenColumns,
    Map<String, String>? columnTitles,
    Map<String, ReportFieldType>? columnTypes,
    List<String>? currencyColumns,
    List<String>? dateColumns,
    String currencyCode = 'USD',

    // Grouping & Category Sheets
    dynamic groupBy, // String or List<String>
    bool sheetPerCategory = false,
    List<String>? categoryDetailColumns,
    String missingCategoryLabel = 'Unassigned',

    // Measures & Aggregations
    List<String>? sumColumns,
    List<String>? averageColumns,
    bool autoAggregateNumericColumns = true,
    List<ReportMeasure>? customMeasures,

    // Layout Analyses
    bool includeDetailSheet = true,
    bool includeGroupedSummary = true,
    bool includeCrossTab = false,
    String? crossTabRowDimension,
    String? crossTabColumnDimension,
    String? crossTabMeasureColumn,
    bool includeSummaryCard = false,

    // Signatures & Document Options
    bool showSignatures = false,
    List<String> signatures = const [
      'Prepared By',
      'Checked By',
      'Approved By',
      'Authorized By',
    ],
    ExcelExportOptions? excelOptions,
    PdfExportOptions? pdfOptions,
    Map<String, dynamic>? metadata,
  }) {
    // 1. Discover all unique keys in the dataset
    final Set<String> allKeys = {};
    for (final row in data) {
      allKeys.addAll(row.keys);
    }

    // Determine target columns
    List<String> activeKeys = visibleColumns ?? allKeys.toList();
    if (hiddenColumns != null) {
      activeKeys = activeKeys.where((k) => !hiddenColumns.contains(k)).toList();
    }

    // 2. Auto-infer column schemas
    final List<ReportColumn<Map<String, dynamic>>> columns = [];
    final Set<String> moneyKeys = (currencyColumns ?? []).toSet();
    final Set<String> customDateKeys = (dateColumns ?? []).toSet();

    for (final key in activeKeys) {
      final customType = columnTypes?[key];
      final colTitle = columnTitles?[key] ?? _beautifyTitle(key);

      if (customType != null) {
        columns.add(
          _createTypedColumn(
            key,
            colTitle,
            customType,
            currencyCode,
          ),
        );
        continue;
      }

      if (moneyKeys.contains(key) || _isMoneyKey(key, data)) {
        columns.add(
          ReportColumn.money(
            id: key,
            title: colTitle,
            currencyCode: currencyCode,
            value: (m) => m[key],
          ),
        );
      } else if (customDateKeys.contains(key) || _isDateKey(key, data)) {
        columns.add(
          ReportColumn.date(
            id: key,
            title: colTitle,
            value: (m) => _parseDate(m[key]),
          ),
        );
      } else if (_isBooleanKey(key, data)) {
        columns.add(
          ReportColumn.boolean(
            id: key,
            title: colTitle,
            value: (m) => m[key],
          ),
        );
      } else if (_isNumericKey(key, data)) {
        columns.add(
          ReportColumn.number(
            id: key,
            title: colTitle,
            value: (m) => m[key],
          ),
        );
      } else {
        columns.add(
          ReportColumn.text(
            id: key,
            title: colTitle,
            value: (m) => m[key],
          ),
        );
      }
    }

    // 3. Resolve grouping columns
    final List<String> groupByList = [];
    if (groupBy is String && groupBy.isNotEmpty) {
      groupByList.add(groupBy);
    } else if (groupBy is List<String>) {
      groupByList.addAll(groupBy.where((g) => g.isNotEmpty));
    }

    // 4. Resolve measures
    final List<ReportMeasure> measures = [];
    if (customMeasures != null && customMeasures.isNotEmpty) {
      measures.addAll(customMeasures);
    } else {
      measures.add(ReportMeasure.count(id: 'count', title: 'Count'));

      final Set<String> targetSumKeys = {};
      if (sumColumns != null) {
        targetSumKeys.addAll(sumColumns);
      } else if (autoAggregateNumericColumns) {
        for (final col in columns) {
          if ((col.type == ReportFieldType.money ||
                  col.type == ReportFieldType.number) &&
              !groupByList.contains(col.id)) {
            targetSumKeys.add(col.id);
          }
        }
      }

      for (final sumKey in targetSumKeys) {
        final col = columns.firstWhere(
          (c) => c.id == sumKey,
          orElse: () => ReportColumn.forMap(key: sumKey),
        );
        measures.add(
          ReportMeasure.sum(
            column: sumKey,
            title: 'Total ${col.title}',
            currencyCode: col.type == ReportFieldType.money ? currencyCode : null,
          ),
        );
      }

      if (averageColumns != null) {
        for (final avgKey in averageColumns) {
          final col = columns.firstWhere(
            (c) => c.id == avgKey,
            orElse: () => ReportColumn.forMap(key: avgKey),
          );
          measures.add(
            ReportMeasure.average(
              column: avgKey,
              title: 'Avg ${col.title}',
              currencyCode: col.type == ReportFieldType.money ? currencyCode : null,
            ),
          );
        }
      }
    }

    // 5. Build Analyses
    final List<ReportAnalysis> analyses = [];

    // Analysis A: Overview Summary Card
    if (includeSummaryCard && measures.isNotEmpty) {
      analyses.add(
        ReportAnalysis.summary(
          id: 'summary_kpis',
          title: 'Executive KPIs',
          measures: measures,
        ),
      );
    }

    // Analysis B: Grouped Aggregation & Category Sheets
    if (includeGroupedSummary && groupByList.isNotEmpty) {
      final groupTitles = groupByList.map((g) => _beautifyTitle(g)).join(' & ');
      analyses.add(
        ReportAnalysis.grouped(
          id: 'grouped_summary',
          title: 'Summary by $groupTitles',
          subtitle: sheetPerCategory
              ? 'Consolidated summary with dedicated category schedules'
              : 'Categorized breakdown and subtotals',
          groupBy: groupByList,
          measures: measures,
          sheetPerCategory: sheetPerCategory,
          detailColumns: categoryDetailColumns ?? activeKeys,
          missingCategoryLabel: missingCategoryLabel,
          showSubtotals: true,
          showGrandTotal: true,
        ),
      );
    }

    // Analysis C: 2D CrossTab Matrix
    if (includeCrossTab && groupByList.length >= 2) {
      final rDim = crossTabRowDimension ?? groupByList[0];
      final cDim = crossTabColumnDimension ?? groupByList[1];
      final mKey = crossTabMeasureColumn ??
          (measures.length > 1 && measures[1].column != null
              ? measures[1].column!
              : (columns.any((c) => c.type == ReportFieldType.money)
                  ? columns.firstWhere((c) => c.type == ReportFieldType.money).id
                  : (columns.any((c) => c.type == ReportFieldType.number)
                      ? columns.firstWhere((c) => c.type == ReportFieldType.number).id
                      : activeKeys.last)));

      analyses.add(
        ReportAnalysis.crossTab(
          id: 'crosstab_matrix',
          title: '${_beautifyTitle(rDim)} by ${_beautifyTitle(cDim)} Matrix',
          rowDimension: rDim,
          columnDimension: cDim,
          measure: ReportMeasure.sum(
            column: mKey,
            title: _beautifyTitle(mKey),
            currencyCode: columns.any((c) => c.id == mKey && c.type == ReportFieldType.money)
                ? currencyCode
                : null,
          ),
        ),
      );
    }

    // Analysis D: Detail Listing
    if (includeDetailSheet || analyses.isEmpty) {
      analyses.insert(
        0,
        ReportAnalysis.detail(
          id: 'detail_ledger',
          title: '$title Register',
          subtitle: 'Complete itemized record listing',
          columns: activeKeys,
          showGrandTotal: true,
        ),
      );
    }

    // 6. Branding & Themes
    final resolvedBranding = branding ??
        (companyName != null ? ReportBranding(companyName: companyName) : null);
    final resolvedTheme = theme ?? ReportTheme.classicBlue();

    // 7. Security & Signature Options
    final resolvedExcelOpts = excelOptions ??
        ExcelExportOptions(
          includeSummarySheet: analyses.length > 1,
          showSignatures: showSignatures,
          signatureLabels: signatures,
        );

    final resolvedPdfOpts = pdfOptions ??
        PdfExportOptions(
          showPageNumbers: true,
          repeatHeaders: true,
          showSignatures: showSignatures,
          signatureLabels: signatures,
        );

    return ReportDefinition<Map<String, dynamic>>(
      title: title,
      subtitle: subtitle,
      branding: resolvedBranding,
      theme: resolvedTheme,
      columns: columns,
      analyses: analyses,
      excelOptions: resolvedExcelOpts,
      pdfOptions: resolvedPdfOpts,
      metadata: metadata,
    );
  }

  // ===========================================================================
  // EXECUTION HELPERS
  // ===========================================================================

  /// Prepares the report for rendering.
  Future<PreparedReport> prepare() => _engine.prepare(
        definition: definition,
        records: data,
      );

  /// Generates Excel OpenXML (.xlsx) artifact bytes.
  Future<ReportArtifact> toExcel({ExcelExportOptions? options}) async {
    final prepared = await prepare();
    return _engine.exportExcel(prepared, options: options ?? definition.excelOptions);
  }

  /// Generates Adobe PDF (.pdf) artifact bytes.
  Future<ReportArtifact> toPdf({PdfExportOptions? options}) async {
    final prepared = await prepare();
    return _engine.exportPdf(prepared, options: options ?? definition.pdfOptions);
  }

  /// Generates and automatically downloads/saves the Excel workbook.
  Future<void> saveExcel({ExcelExportOptions? options}) async {
    final artifact = await toExcel(options: options);
    await _saver.save(artifact);
  }

  /// Generates and automatically downloads/saves the PDF document.
  Future<void> savePdf({PdfExportOptions? options}) async {
    final artifact = await toPdf(options: options);
    await _saver.save(artifact);
  }

  // ===========================================================================
  // ONE-LINER STATIC HELPERS
  // ===========================================================================

  /// Quick one-liner helper to export a Map list directly to Excel bytes.
  static Future<Uint8List> excelBytes({
    required List<Map<String, dynamic>> data,
    String title = 'Report',
    dynamic groupBy,
    bool sheetPerCategory = false,
    String currencyCode = 'USD',
    bool showSignatures = false,
  }) async {
    final report = EasyReport.fromMaps(
      data: data,
      title: title,
      groupBy: groupBy,
      sheetPerCategory: sheetPerCategory,
      currencyCode: currencyCode,
      showSignatures: showSignatures,
    );
    final artifact = await report.toExcel();
    return Uint8List.fromList(artifact.bytes);
  }

  /// Quick one-liner helper to export a Map list directly to PDF bytes.
  static Future<Uint8List> pdfBytes({
    required List<Map<String, dynamic>> data,
    String title = 'Report',
    dynamic groupBy,
    bool sheetPerCategory = false,
    String currencyCode = 'USD',
    bool showSignatures = false,
  }) async {
    final report = EasyReport.fromMaps(
      data: data,
      title: title,
      groupBy: groupBy,
      sheetPerCategory: sheetPerCategory,
      currencyCode: currencyCode,
      showSignatures: showSignatures,
    );
    final artifact = await report.toPdf();
    return Uint8List.fromList(artifact.bytes);
  }

  // ===========================================================================
  // TYPE INFERENCE & UTILITIES
  // ===========================================================================

  static ReportColumn<Map<String, dynamic>> _createTypedColumn(
    String key,
    String title,
    ReportFieldType type,
    String currencyCode,
  ) {
    switch (type) {
      case ReportFieldType.money:
        return ReportColumn.money(
          id: key,
          title: title,
          currencyCode: currencyCode,
          value: (m) => m[key],
        );
      case ReportFieldType.number:
        return ReportColumn.number(
          id: key,
          title: title,
          value: (m) => m[key],
        );
      case ReportFieldType.date:
        return ReportColumn.date(
          id: key,
          title: title,
          value: (m) => _parseDate(m[key]),
        );
      case ReportFieldType.dateTime:
        return ReportColumn.dateTime(
          id: key,
          title: title,
          value: (m) => _parseDate(m[key]),
        );
      case ReportFieldType.boolean:
        return ReportColumn.boolean(
          id: key,
          title: title,
          value: (m) => m[key],
        );
      case ReportFieldType.percentage:
        return ReportColumn.percentage(
          id: key,
          title: title,
          value: (m) => m[key],
        );
      case ReportFieldType.text:
      case ReportFieldType.custom:
        return ReportColumn.text(
          id: key,
          title: title,
          value: (m) => m[key],
        );
    }
  }

  static bool _isMoneyKey(String key, List<Map<String, dynamic>> data) {
    final lower = key.toLowerCase();
    if (lower.contains('type') ||
        lower.contains('category') ||
        lower.contains('name') ||
        lower.contains('id') ||
        lower.contains('desc') ||
        lower.contains('code') ||
        lower.contains('mode') ||
        lower.contains('status')) {
      return false;
    }

    final hasMoneyKeyword = lower.contains('salary') ||
        lower.contains('pay') ||
        lower.contains('amount') ||
        lower.contains('cost') ||
        lower.contains('price') ||
        lower.contains('revenue') ||
        lower.contains('profit') ||
        lower.contains('bonus') ||
        lower.contains('deduction') ||
        lower.contains('allowance') ||
        lower.contains('fee') ||
        lower.contains('tax') ||
        lower.contains('levy') ||
        lower.contains('remittance') ||
        lower.contains('valuation') ||
        lower.contains('balance');

    if (!hasMoneyKeyword) return false;

    for (final row in data) {
      final val = row[key];
      if (val != null) {
        if (val is num) return true;
        if (val is String) {
          final clean = val.replaceAll(RegExp(r'[^0-9.-]'), '');
          if (clean.isNotEmpty && num.tryParse(clean) != null) return true;
        }
        return false;
      }
    }
    return true;
  }

  static bool _isNumericKey(String key, List<Map<String, dynamic>> data) {
    for (final row in data) {
      final val = row[key];
      if (val != null) {
        if (val is num) return true;
        if (val is String && num.tryParse(val) != null) return true;
        return false;
      }
    }
    return false;
  }

  static bool _isDateKey(String key, List<Map<String, dynamic>> data) {
    final lower = key.toLowerCase();
    if (lower.contains('date') || lower.contains('joined') || lower.contains('time') || lower == 'dob') {
      return true;
    }
    for (final row in data) {
      final val = row[key];
      if (val != null) {
        if (val is DateTime) return true;
        if (val is String && DateTime.tryParse(val) != null) return true;
        return false;
      }
    }
    return false;
  }

  static bool _isBooleanKey(String key, List<Map<String, dynamic>> data) {
    for (final row in data) {
      final val = row[key];
      if (val != null) {
        if (val is bool) return true;
        if (val is String && (val == 'true' || val == 'false')) return true;
        return false;
      }
    }
    return false;
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  static String _beautifyTitle(String key) {
    // Convert camelCase or snake_case or kebab-case to Title Case
    final withSpaces = key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();

    final words = withSpaces.split(RegExp(r'\s+'));
    return words.map((w) {
      if (w.isEmpty) return '';
      if (w.toLowerCase() == 'id') return 'ID';
      if (w.toLowerCase() == 'sku') return 'SKU';
      if (w.toLowerCase() == 'kpi') return 'KPI';
      if (w.toLowerCase() == 'ar') return 'AR';
      if (w.toLowerCase() == 'ap') return 'AP';
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}
