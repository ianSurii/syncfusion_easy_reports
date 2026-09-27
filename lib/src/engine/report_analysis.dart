import 'report_measure.dart';

/// Type of analysis layout and processing.
enum ReportAnalysisType {
  /// Detailed flat table of individual records.
  detail,

  /// Aggregated summary grouped by one or more dimensions.
  grouped,

  /// Two-dimensional matrix / cross-tabulation (Pivot-style).
  crossTab,

  /// High-level single-row or key-value summary card.
  summary,
}

/// Date intervals for time-based grouping.
enum ReportDateInterval {
  /// Group by exact calendar day (e.g. 2026-09-27)
  day,

  /// Group by calendar month (e.g. 2026-09 or Sep 2026)
  month,

  /// Group by quarter (e.g. Q1 2026)
  quarter,

  /// Group by calendar or fiscal year (e.g. FY2026 or 2026)
  year,
}

/// Configuration for date-based grouping.
class ReportDateGrouping {
  /// Column identifier containing the date or dateTime value.
  final String columnId;

  /// Interval to group by (day, month, quarter, year).
  final ReportDateInterval interval;

  /// Starting month of the fiscal year (1 = January, 7 = July, etc.). Default is 1.
  final int fiscalYearStartMonth;

  /// Optional custom date label formatter.
  final String Function(DateTime date, ReportDateInterval interval)?
  labelFormatter;

  const ReportDateGrouping({
    required this.columnId,
    this.interval = ReportDateInterval.month,
    this.fiscalYearStartMonth = 1,
    this.labelFormatter,
  });
}

/// Custom value bucket for categorization (e.g. Aging 0-30, 31-60, 61-90, 90+ days, or Salary bands).
class ReportCategoryBucket {
  /// User-visible category name.
  final String label;

  /// Minimum numeric boundary (inclusive). Null means unbounded lower.
  final num? min;

  /// Maximum numeric boundary (exclusive or inclusive based on [isMaxInclusive]). Null means unbounded upper.
  final num? max;

  /// Whether the upper bound is inclusive. Default is false (min <= x < max).
  final bool isMaxInclusive;

  const ReportCategoryBucket({
    required this.label,
    this.min,
    this.max,
    this.isMaxInclusive = false,
  });

  /// Checks if a value falls within this bucket.
  bool contains(num value) {
    if (min != null && value < min!) return false;
    if (max != null) {
      if (isMaxInclusive) {
        if (value > max!) return false;
      } else {
        if (value >= max!) return false;
      }
    }
    return true;
  }
}

/// Configuration for Top-N ranking analysis with an optional combined "Other" row.
class ReportTopN {
  /// Number of top categories/records to include.
  final int count;

  /// Measure or column ID used to rank the items.
  final String rankBy;

  /// Whether to sort in ascending order (lowest first) instead of descending (highest first).
  final bool isAscending;

  /// Label for the aggregate row combining remaining items. If null, remaining items are excluded.
  final String? otherLabel;

  const ReportTopN({
    required this.count,
    required this.rankBy,
    this.isAscending = false,
    this.otherLabel = 'Other',
  });
}

/// Sort rule for ordering categories, measures, or records.
class ReportSort {
  /// Column ID or Measure ID to sort by.
  final String fieldId;

  /// Whether to sort in ascending order. Default is true.
  final bool isAscending;

  const ReportSort({required this.fieldId, this.isAscending = true});

  factory ReportSort.asc(String fieldId) =>
      ReportSort(fieldId: fieldId, isAscending: true);
  factory ReportSort.desc(String fieldId) =>
      ReportSort(fieldId: fieldId, isAscending: false);
}

/// Comparison operators for filtering.
enum ReportFilterOperator {
  equals,
  notEquals,
  contains,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  inList,
  between,
  isNull,
  isNotNull,
}

/// Pre-aggregation or post-aggregation filter criteria.
class ReportFilter {
  /// Target column or measure ID.
  final String fieldId;

  /// Filter operator.
  final ReportFilterOperator operator;

  /// Comparison target value.
  final dynamic value;

  /// Second comparison target value for [ReportFilterOperator.between].
  final dynamic secondaryValue;

  /// Custom predicate callback for arbitrary Dart conditions.
  final bool Function(dynamic itemValue, dynamic fullRecord)? customPredicate;

  const ReportFilter({
    required this.fieldId,
    this.operator = ReportFilterOperator.equals,
    this.value,
    this.secondaryValue,
    this.customPredicate,
  });

  /// Evaluates whether a record value passes the filter.
  bool matches(dynamic itemValue, dynamic fullRecord) {
    if (customPredicate != null) {
      return customPredicate!(itemValue, fullRecord);
    }

    switch (operator) {
      case ReportFilterOperator.equals:
        return itemValue?.toString().toLowerCase() ==
            value?.toString().toLowerCase();
      case ReportFilterOperator.notEquals:
        return itemValue?.toString().toLowerCase() !=
            value?.toString().toLowerCase();
      case ReportFilterOperator.contains:
        if (itemValue == null || value == null) return false;
        return itemValue.toString().toLowerCase().contains(
          value.toString().toLowerCase(),
        );
      case ReportFilterOperator.greaterThan:
        if (itemValue is num && value is num) return itemValue > value;
        return false;
      case ReportFilterOperator.greaterThanOrEqual:
        if (itemValue is num && value is num) return itemValue >= value;
        return false;
      case ReportFilterOperator.lessThan:
        if (itemValue is num && value is num) return itemValue < value;
        return false;
      case ReportFilterOperator.lessThanOrEqual:
        if (itemValue is num && value is num) return itemValue <= value;
        return false;
      case ReportFilterOperator.inList:
        if (value is Iterable) return (value as Iterable).contains(itemValue);
        return false;
      case ReportFilterOperator.between:
        if (itemValue is num && value is num && secondaryValue is num) {
          return itemValue >= value && itemValue <= (secondaryValue as num);
        }
        return false;
      case ReportFilterOperator.isNull:
        return itemValue == null;
      case ReportFilterOperator.isNotNull:
        return itemValue != null;
    }
  }
}

/// Defines a specific analysis or slice of the report dataset.
///
/// A single [ReportDefinition] can contain multiple analyses, each rendered as
/// a distinct sheet in Excel or a section in PDF.
class ReportAnalysis {
  /// Unique identifier for this analysis.
  final String id;

  /// User-visible title (used as sheet name in Excel and section header in PDF).
  final String title;

  /// Subtitle or narrative description.
  final String? subtitle;

  /// Analysis type.
  final ReportAnalysisType type;

  /// List of column IDs to group by (e.g. `['department', 'bank']`).
  final List<String> groupBy;

  /// Column IDs to include in a detail analysis. If empty, all columns are included.
  final List<String>? detailColumns;

  /// Date grouping configuration.
  final ReportDateGrouping? dateGrouping;

  /// Custom category buckets keyed by column ID (e.g. for aging or salary tiers).
  final Map<String, List<ReportCategoryBucket>>? categoryBuckets;

  /// Measures and metrics to calculate for each group.
  final List<ReportMeasure> measures;

  /// Row dimension column for cross-tabulation analysis.
  final String? rowDimension;

  /// Column dimension for cross-tabulation analysis.
  final String? columnDimension;

  /// Value measure to populate cross-tabulation cells.
  final ReportMeasure? crossTabMeasure;

  /// Pre-filters applied to records before grouping and aggregation.
  final List<ReportFilter> filters;

  /// Sorting configuration for groups or records.
  final List<ReportSort> sort;

  /// Top-N ranking configuration.
  final ReportTopN? topN;

  /// Whether to display subtotals for nested groups.
  final bool showSubtotals;

  /// Whether to display a grand totals row at the bottom.
  final bool showGrandTotal;

  /// Whether to split each top-level category into its own Excel sheet or PDF sub-section.
  final bool sheetPerCategory;

  /// Label used when a grouping category is null or empty.
  final String missingCategoryLabel;

  /// Additional metadata or KPI cards attached to this analysis.
  final Map<String, dynamic>? customData;

  const ReportAnalysis({
    required this.id,
    required this.title,
    this.subtitle,
    this.type = ReportAnalysisType.grouped,
    this.groupBy = const [],
    this.detailColumns,
    this.dateGrouping,
    this.categoryBuckets,
    this.measures = const [],
    this.rowDimension,
    this.columnDimension,
    this.crossTabMeasure,
    this.filters = const [],
    this.sort = const [],
    this.topN,
    this.showSubtotals = true,
    this.showGrandTotal = true,
    this.sheetPerCategory = false,
    this.missingCategoryLabel = 'Unassigned',
    this.customData,
  });

  /// Factory for creating a flat record detail listing.
  factory ReportAnalysis.detail({
    required String id,
    required String title,
    String? subtitle,
    List<String>? columns,
    List<ReportFilter> filters = const [],
    List<ReportSort> sort = const [],
    bool showGrandTotal = true,
    List<ReportMeasure> grandTotalMeasures = const [],
    Map<String, dynamic>? customData,
  }) {
    return ReportAnalysis(
      id: id,
      title: title,
      subtitle: subtitle,
      type: ReportAnalysisType.detail,
      detailColumns: columns,
      filters: filters,
      sort: sort,
      showGrandTotal: showGrandTotal,
      measures: grandTotalMeasures,
      customData: customData,
    );
  }

  /// Factory for creating a grouped summary table.
  factory ReportAnalysis.grouped({
    required String id,
    required String title,
    String? subtitle,
    required List<String> groupBy,
    required List<ReportMeasure> measures,
    List<String>? detailColumns,
    ReportDateGrouping? dateGrouping,
    Map<String, List<ReportCategoryBucket>>? categoryBuckets,
    List<ReportFilter> filters = const [],
    List<ReportSort> sort = const [],
    ReportTopN? topN,
    bool showSubtotals = true,
    bool showGrandTotal = true,
    bool sheetPerCategory = false,
    String missingCategoryLabel = 'Unassigned',
    Map<String, dynamic>? customData,
  }) {
    return ReportAnalysis(
      id: id,
      title: title,
      subtitle: subtitle,
      type: ReportAnalysisType.grouped,
      groupBy: groupBy,
      detailColumns: detailColumns,
      dateGrouping: dateGrouping,
      categoryBuckets: categoryBuckets,
      measures: measures,
      filters: filters,
      sort: sort,
      topN: topN,
      showSubtotals: showSubtotals,
      showGrandTotal: showGrandTotal,
      sheetPerCategory: sheetPerCategory,
      missingCategoryLabel: missingCategoryLabel,
      customData: customData,
    );
  }

  /// Factory for creating a 2D Pivot / Cross-Tabulation summary.
  factory ReportAnalysis.crossTab({
    required String id,
    required String title,
    String? subtitle,
    required String rowDimension,
    required String columnDimension,
    required ReportMeasure measure,
    List<ReportFilter> filters = const [],
    bool showGrandTotal = true,
    String missingCategoryLabel = 'Unassigned',
    Map<String, dynamic>? customData,
  }) {
    return ReportAnalysis(
      id: id,
      title: title,
      subtitle: subtitle,
      type: ReportAnalysisType.crossTab,
      rowDimension: rowDimension,
      columnDimension: columnDimension,
      crossTabMeasure: measure,
      groupBy: [rowDimension, columnDimension],
      filters: filters,
      showGrandTotal: showGrandTotal,
      missingCategoryLabel: missingCategoryLabel,
      customData: customData,
    );
  }

  /// Factory for creating an executive summary card / metrics overview.
  factory ReportAnalysis.summary({
    required String id,
    required String title,
    String? subtitle,
    required List<ReportMeasure> measures,
    List<ReportFilter> filters = const [],
    Map<String, dynamic>? customData,
  }) {
    return ReportAnalysis(
      id: id,
      title: title,
      subtitle: subtitle,
      type: ReportAnalysisType.summary,
      measures: measures,
      filters: filters,
      customData: customData,
    );
  }
}
