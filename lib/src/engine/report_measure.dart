/// Types of calculations performed on report data.
enum ReportMeasureType {
  /// Counts all records in the group.
  count,

  /// Counts non-null records in the column.
  countNonNull,

  /// Counts unique non-null values in the column.
  distinctCount,

  /// Sum of numeric values in the column.
  sum,

  /// Arithmetic mean of numeric values.
  average,

  /// Weighted average using a separate weight column.
  weightedAverage,

  /// Minimum value in the column.
  min,

  /// Maximum value in the column.
  max,

  /// Percentage of the group or grand total.
  percentageOfTotal,

  /// Derived value computed from other measures.
  formula,
}

/// Defines an aggregation or metric calculation in a [ReportAnalysis].
class ReportMeasure {
  /// Unique identifier for this measure.
  final String id;

  /// User-visible title displayed in summary tables and headers.
  final String title;

  /// Aggregation type.
  final ReportMeasureType type;

  /// Identifier of the target [ReportColumn] to aggregate.
  final String? column;

  /// Identifier of the weighting column for [ReportMeasureType.weightedAverage].
  final String? weightedBy;

  /// Currency code or symbol if formatting as money.
  final String? currencyCode;

  /// Decimal precision for display and calculations.
  final int? precision;

  /// Custom number format string.
  final String? format;

  /// Custom formula callback for [ReportMeasureType.formula].
  /// Receives a map of other calculated measure values keyed by measure ID.
  final num? Function(Map<String, num> values)? formula;

  /// Identifiers of other measures this measure depends on (for dependency ordering).
  final List<String> dependsOn;

  const ReportMeasure({
    required this.id,
    required this.title,
    required this.type,
    this.column,
    this.weightedBy,
    this.currencyCode,
    this.precision,
    this.format,
    this.formula,
    this.dependsOn = const [],
  });

  /// Factory for counting total records in each group.
  factory ReportMeasure.count({String id = 'count', String title = 'Count'}) {
    return ReportMeasure(
      id: id,
      title: title,
      type: ReportMeasureType.count,
      precision: 0,
    );
  }

  /// Factory for counting non-null values in a column.
  factory ReportMeasure.countNonNull({
    String? id,
    required String column,
    String? title,
  }) {
    return ReportMeasure(
      id: id ?? '${column}_count',
      title: title ?? 'Count of $column',
      type: ReportMeasureType.countNonNull,
      column: column,
      precision: 0,
    );
  }

  /// Factory for counting unique non-null values.
  factory ReportMeasure.distinctCount({
    String? id,
    required String column,
    String? title,
  }) {
    return ReportMeasure(
      id: id ?? '${column}_distinct',
      title: title ?? 'Distinct $column',
      type: ReportMeasureType.distinctCount,
      column: column,
      precision: 0,
    );
  }

  /// Factory for summing a numeric or money column.
  factory ReportMeasure.sum({
    String? id,
    required String column,
    String? title,
    String? currencyCode,
    int? precision,
  }) {
    return ReportMeasure(
      id: id ?? '${column}_sum',
      title: title ?? 'Total $column',
      type: ReportMeasureType.sum,
      column: column,
      currencyCode: currencyCode,
      precision: precision ?? (currencyCode != null ? 2 : null),
    );
  }

  /// Factory for calculating the average of a numeric column.
  factory ReportMeasure.average({
    String? id,
    required String column,
    String? title,
    String? currencyCode,
    int precision = 2,
  }) {
    return ReportMeasure(
      id: id ?? '${column}_avg',
      title: title ?? 'Average $column',
      type: ReportMeasureType.average,
      column: column,
      currencyCode: currencyCode,
      precision: precision,
    );
  }

  /// Factory for calculating a weighted average.
  factory ReportMeasure.weightedAverage({
    String? id,
    required String column,
    required String weightedBy,
    String? title,
    int precision = 2,
  }) {
    return ReportMeasure(
      id: id ?? '${column}_weighted_avg',
      title: title ?? 'Weighted Avg $column',
      type: ReportMeasureType.weightedAverage,
      column: column,
      weightedBy: weightedBy,
      precision: precision,
      dependsOn: [column, weightedBy],
    );
  }

  /// Factory for finding the minimum value.
  factory ReportMeasure.min({
    String? id,
    required String column,
    String? title,
    String? currencyCode,
    int? precision,
  }) {
    return ReportMeasure(
      id: id ?? '${column}_min',
      title: title ?? 'Min $column',
      type: ReportMeasureType.min,
      column: column,
      currencyCode: currencyCode,
      precision: precision,
    );
  }

  /// Factory for finding the maximum value.
  factory ReportMeasure.max({
    String? id,
    required String column,
    String? title,
    String? currencyCode,
    int? precision,
  }) {
    return ReportMeasure(
      id: id ?? '${column}_max',
      title: title ?? 'Max $column',
      type: ReportMeasureType.max,
      column: column,
      currencyCode: currencyCode,
      precision: precision,
    );
  }

  /// Factory for calculating percentage of the grand total.
  factory ReportMeasure.percentageOfTotal({
    String? id,
    required String column,
    String? title,
    int precision = 1,
  }) {
    return ReportMeasure(
      id: id ?? '${column}_pct',
      title: title ?? '% of Total $column',
      type: ReportMeasureType.percentageOfTotal,
      column: column,
      precision: precision,
      dependsOn: [column],
    );
  }

  /// Factory for derived or custom calculated measures.
  factory ReportMeasure.formula({
    required String id,
    required String title,
    required num? Function(Map<String, num> values) calculate,
    required List<String> dependsOn,
    String? currencyCode,
    int precision = 2,
  }) {
    return ReportMeasure(
      id: id,
      title: title,
      type: ReportMeasureType.formula,
      formula: calculate,
      dependsOn: dependsOn,
      currencyCode: currencyCode,
      precision: precision,
    );
  }
}
