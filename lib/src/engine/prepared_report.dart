import '../models/report_models.dart';
import 'report_column.dart';
import 'report_analysis.dart';

/// Data type of a calculated cell in a prepared report.
enum PreparedCellType {
  text,
  numeric,
  money,
  percentage,
  date,
  dateTime,
  boolean,
  formula,
}

/// A calculated and formatted cell ready for rendering.
class PreparedCell {
  /// Raw underlying typed value (e.g. `num`, `DateTime`, `String`, `bool`).
  final dynamic rawValue;

  /// Human-readable formatted string representation.
  final String formattedText;

  /// Logical data type of this cell.
  final PreparedCellType type;

  /// Currency code or symbol if applicable.
  final String? currencyCode;

  /// Text alignment.
  final ReportColumnAlignment alignment;

  /// Optional formula expression (e.g. `SUM(D2:D10)`).
  final String? formulaExpression;

  const PreparedCell({
    required this.rawValue,
    required this.formattedText,
    this.type = PreparedCellType.text,
    this.currencyCode,
    this.alignment = ReportColumnAlignment.left,
    this.formulaExpression,
  });

  bool get isNumeric =>
      type == PreparedCellType.numeric ||
      type == PreparedCellType.money ||
      type == PreparedCellType.percentage;
  bool get isDate =>
      type == PreparedCellType.date || type == PreparedCellType.dateTime;
  bool get isMoney => type == PreparedCellType.money;
  bool get isPercentage => type == PreparedCellType.percentage;
  bool get isFormula =>
      formulaExpression != null && formulaExpression!.isNotEmpty;
}

/// Column header metadata in a prepared table.
class PreparedColumnHeader {
  final String id;
  final String title;
  final ReportFieldType fieldType;
  final ReportColumnAlignment alignment;
  final double? width;
  final String? currencyCode;

  const PreparedColumnHeader({
    required this.id,
    required this.title,
    this.fieldType = ReportFieldType.text,
    this.alignment = ReportColumnAlignment.left,
    this.width,
    this.currencyCode,
  });
}

/// A row of cells in a prepared table.
class PreparedRow {
  final List<PreparedCell> cells;
  final dynamic rawRecord;
  final bool isGroupHeader;
  final bool isSubtotal;
  final bool isGrandTotal;
  final int groupLevel;
  final String? groupKey;

  const PreparedRow({
    required this.cells,
    this.rawRecord,
    this.isGroupHeader = false,
    this.isSubtotal = false,
    this.isGrandTotal = false,
    this.groupLevel = 0,
    this.groupKey,
  });
}

/// An aggregated group within an analysis.
class PreparedGroup {
  final String key;
  final String label;
  final String dimension;
  final int level;
  final int recordCount;
  final Map<String, dynamic> measureValues;
  final List<Map<String, dynamic>> rawRecords;
  final List<PreparedRow> detailRows;
  final List<PreparedGroup> subGroups;
  final PreparedRow? subtotalRow;

  const PreparedGroup({
    required this.key,
    required this.label,
    required this.dimension,
    this.level = 0,
    this.recordCount = 0,
    this.measureValues = const {},
    this.rawRecords = const [],
    this.detailRows = const [],
    this.subGroups = const [],
    this.subtotalRow,
  });
}

/// A 2D Pivot / Cross-Tabulation matrix ready for rendering.
class PreparedCrossTabMatrix {
  final String rowDimension;
  final String columnDimension;
  final List<String> rowKeys;
  final List<String> columnKeys;
  final Map<String, Map<String, PreparedCell>> matrix;
  final Map<String, PreparedCell> rowTotals;
  final Map<String, PreparedCell> colTotals;
  final PreparedCell grandTotal;

  const PreparedCrossTabMatrix({
    required this.rowDimension,
    required this.columnDimension,
    required this.rowKeys,
    required this.columnKeys,
    required this.matrix,
    required this.rowTotals,
    required this.colTotals,
    required this.grandTotal,
  });
}

/// A category-split sheet definition for Excel / PDF.
class PreparedCategorySheet {
  final String categoryKey;
  final String categoryLabel;
  final String sheetName;
  final List<PreparedColumnHeader> headers;
  final List<PreparedRow> rows;
  final PreparedRow? totalsRow;

  const PreparedCategorySheet({
    required this.categoryKey,
    required this.categoryLabel,
    required this.sheetName,
    required this.headers,
    required this.rows,
    this.totalsRow,
  });
}

/// Prepared calculation data for a single [ReportAnalysis].
class PreparedAnalysis {
  final String id;
  final String title;
  final String? subtitle;
  final ReportAnalysisType type;
  final List<PreparedColumnHeader> headers;
  final List<PreparedRow> rows;
  final List<PreparedGroup> groups;
  final PreparedRow? grandTotalRow;
  final PreparedCrossTabMatrix? crossTabMatrix;
  final List<PreparedCategorySheet>? categorySheets;
  final Map<String, dynamic> summaryMetrics;
  final int recordCount;

  const PreparedAnalysis({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    this.headers = const [],
    this.rows = const [],
    this.groups = const [],
    this.grandTotalRow,
    this.crossTabMatrix,
    this.categorySheets,
    this.summaryMetrics = const {},
    this.recordCount = 0,
  });
}

/// Reconciliation check summary verifying that details reconcile with totals.
class ReconciliationSummary {
  final bool isReconciled;
  final Map<String, num> detailTotals;
  final Map<String, num> groupTotals;
  final Map<String, num> grandTotals;
  final List<String> discrepancies;

  const ReconciliationSummary({
    required this.isReconciled,
    this.detailTotals = const {},
    this.groupTotals = const {},
    this.grandTotals = const {},
    this.discrepancies = const [],
  });
}

/// A fully calculated, validated, and normalized report ready for export.
class PreparedReport {
  /// Report title.
  final String title;

  /// Optional subtitle.
  final String? subtitle;

  /// Visual branding information (logos, contact details).
  final ReportBranding? branding;

  /// Visual theme styling tokens.
  final ReportTheme theme;

  /// Document settings (margins, size, orientation).
  final ReportSettings settings;

  /// All calculated analyses in this report.
  final List<PreparedAnalysis> analyses;

  /// Global summary KPI metrics.
  final Map<String, dynamic> summaryMetrics;

  /// Total count of input records processed.
  final int totalRecordCount;

  /// Count of records after filters were applied.
  final int filteredRecordCount;

  /// Generation timestamp.
  final DateTime generatedAt;

  /// Non-fatal warnings produced during preparation.
  final List<String> warnings;

  /// Reconciliation audit results.
  final ReconciliationSummary reconciliation;

  /// Custom report metadata.
  final Map<String, dynamic> metadata;

  PreparedReport({
    required this.title,
    this.subtitle,
    this.branding,
    ReportTheme? theme,
    ReportSettings? settings,
    required this.analyses,
    this.summaryMetrics = const {},
    required this.totalRecordCount,
    required this.filteredRecordCount,
    DateTime? generatedAt,
    this.warnings = const [],
    required this.reconciliation,
    this.metadata = const {},
  }) : theme = theme ?? ReportTheme.classicBlue(),
       settings = settings ?? ReportSettings(),
       generatedAt = generatedAt ?? DateTime.now();

  /// Checks if any warnings were emitted.
  bool get hasWarnings => warnings.isNotEmpty;

  /// Checks if all totals reconcile.
  bool get isReconciled => reconciliation.isReconciled;
}
