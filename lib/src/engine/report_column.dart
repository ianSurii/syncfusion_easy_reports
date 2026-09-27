/// Defines the data type of a report column.
enum ReportFieldType {
  /// General text string
  text,

  /// General numeric value (integer or decimal)
  number,

  /// Currency amount with formatting and currency symbol/code
  money,

  /// Percentage value (e.g. 0.15 formatted as 15.0%)
  percentage,

  /// Date value (e.g. 2026-09-27)
  date,

  /// Date and time value (e.g. 2026-09-27 14:30)
  dateTime,

  /// Boolean flag (true/false, Yes/No)
  boolean,

  /// Custom or user-formatted object
  custom,
}

/// Text alignment within table cells.
enum ReportColumnAlignment {
  /// Align text to the left
  left,

  /// Align text to the center
  center,

  /// Align text to the right
  right,
}

/// Defines a column in a [ReportDefinition].
///
/// Columns map data from input records to report cells and define presentation,
/// formatting, and alignment.
class ReportColumn<T> {
  /// Unique identifier for this column. Used in analyses and measures.
  final String id;

  /// User-visible title displayed in table headers.
  final String title;

  /// Field data type.
  final ReportFieldType type;

  /// Function to extract the field value from a record.
  final dynamic Function(T item) accessor;

  /// Optional ISO currency code or symbol (e.g. 'USD', 'KES', '$', '€').
  final String? currencyCode;

  /// Decimal precision for numeric/money/percentage fields.
  final int? precision;

  /// Date format pattern (e.g. 'yyyy-MM-dd', 'dd-MMM-yyyy').
  final String? dateFormat;

  /// Text alignment. If null, automatically inferred from [type] (numbers/money right-aligned).
  final ReportColumnAlignment alignment;

  /// Column width hint in points or relative characters.
  final double? width;

  /// Whether this column is visible in detail listings.
  final bool isVisible;

  /// Text to display when a cell value is null.
  final String nullPlaceholder;

  /// Whether this column contains a trusted Excel formula expression.
  final bool isFormula;

  /// Custom value formatter.
  final String Function(dynamic value)? customFormatter;

  const ReportColumn({
    required this.id,
    required this.title,
    required this.accessor,
    this.type = ReportFieldType.text,
    this.currencyCode,
    this.precision,
    this.dateFormat,
    this.alignment = ReportColumnAlignment.left,
    this.width,
    this.isVisible = true,
    this.nullPlaceholder = '-',
    this.isFormula = false,
    this.customFormatter,
  });

  /// Factory for text columns.
  factory ReportColumn.text({
    required String id,
    required String title,
    required dynamic Function(T item) value,
    ReportColumnAlignment alignment = ReportColumnAlignment.left,
    double? width,
    bool isVisible = true,
    String nullPlaceholder = '-',
  }) {
    return ReportColumn<T>(
      id: id,
      title: title,
      accessor: value,
      type: ReportFieldType.text,
      alignment: alignment,
      width: width,
      isVisible: isVisible,
      nullPlaceholder: nullPlaceholder,
    );
  }

  /// Factory for numeric columns.
  factory ReportColumn.number({
    required String id,
    required String title,
    required num? Function(T item) value,
    int? precision,
    ReportColumnAlignment alignment = ReportColumnAlignment.right,
    double? width,
    bool isVisible = true,
    String nullPlaceholder = '-',
  }) {
    return ReportColumn<T>(
      id: id,
      title: title,
      accessor: value,
      type: ReportFieldType.number,
      precision: precision,
      alignment: alignment,
      width: width,
      isVisible: isVisible,
      nullPlaceholder: nullPlaceholder,
    );
  }

  /// Factory for currency / money columns.
  factory ReportColumn.money({
    required String id,
    required String title,
    required num? Function(T item) value,
    String currencyCode = 'USD',
    int precision = 2,
    ReportColumnAlignment alignment = ReportColumnAlignment.right,
    double? width,
    bool isVisible = true,
    String nullPlaceholder = '-',
  }) {
    return ReportColumn<T>(
      id: id,
      title: title,
      accessor: value,
      type: ReportFieldType.money,
      currencyCode: currencyCode,
      precision: precision,
      alignment: alignment,
      width: width,
      isVisible: isVisible,
      nullPlaceholder: nullPlaceholder,
    );
  }

  /// Factory for percentage columns.
  factory ReportColumn.percentage({
    required String id,
    required String title,
    required num? Function(T item) value,
    int precision = 1,
    ReportColumnAlignment alignment = ReportColumnAlignment.right,
    double? width,
    bool isVisible = true,
    String nullPlaceholder = '-',
  }) {
    return ReportColumn<T>(
      id: id,
      title: title,
      accessor: value,
      type: ReportFieldType.percentage,
      precision: precision,
      alignment: alignment,
      width: width,
      isVisible: isVisible,
      nullPlaceholder: nullPlaceholder,
    );
  }

  /// Factory for date columns.
  factory ReportColumn.date({
    required String id,
    required String title,
    required DateTime? Function(T item) value,
    String dateFormat = 'yyyy-MM-dd',
    ReportColumnAlignment alignment = ReportColumnAlignment.center,
    double? width,
    bool isVisible = true,
    String nullPlaceholder = '-',
  }) {
    return ReportColumn<T>(
      id: id,
      title: title,
      accessor: value,
      type: ReportFieldType.date,
      dateFormat: dateFormat,
      alignment: alignment,
      width: width,
      isVisible: isVisible,
      nullPlaceholder: nullPlaceholder,
    );
  }

  /// Factory for date-time columns.
  factory ReportColumn.dateTime({
    required String id,
    required String title,
    required DateTime? Function(T item) value,
    String dateFormat = 'yyyy-MM-dd HH:mm',
    ReportColumnAlignment alignment = ReportColumnAlignment.center,
    double? width,
    bool isVisible = true,
    String nullPlaceholder = '-',
  }) {
    return ReportColumn<T>(
      id: id,
      title: title,
      accessor: value,
      type: ReportFieldType.dateTime,
      dateFormat: dateFormat,
      alignment: alignment,
      width: width,
      isVisible: isVisible,
      nullPlaceholder: nullPlaceholder,
    );
  }

  /// Factory for boolean columns.
  factory ReportColumn.boolean({
    required String id,
    required String title,
    required bool? Function(T item) value,
    String trueLabel = 'Yes',
    String falseLabel = 'No',
    ReportColumnAlignment alignment = ReportColumnAlignment.center,
    double? width,
    bool isVisible = true,
    String nullPlaceholder = '-',
  }) {
    return ReportColumn<T>(
      id: id,
      title: title,
      accessor: value,
      type: ReportFieldType.boolean,
      alignment: alignment,
      width: width,
      isVisible: isVisible,
      nullPlaceholder: nullPlaceholder,
      customFormatter: (val) {
        if (val == null) return nullPlaceholder;
        if (val == true || val == 'true') return trueLabel;
        return falseLabel;
      },
    );
  }

  /// Factory for key-based `Map<String, dynamic>` data.
  static ReportColumn<Map<String, dynamic>> forMap({
    required String key,
    String? title,
    ReportFieldType type = ReportFieldType.text,
    String? currencyCode,
    int? precision,
    String? dateFormat,
    ReportColumnAlignment? alignment,
    double? width,
    bool isVisible = true,
    String nullPlaceholder = '-',
  }) {
    final effectiveAlignment =
        alignment ??
        (type == ReportFieldType.money ||
                type == ReportFieldType.number ||
                type == ReportFieldType.percentage
            ? ReportColumnAlignment.right
            : type == ReportFieldType.date ||
                  type == ReportFieldType.dateTime ||
                  type == ReportFieldType.boolean
            ? ReportColumnAlignment.center
            : ReportColumnAlignment.left);

    return ReportColumn<Map<String, dynamic>>(
      id: key,
      title: title ?? key,
      accessor: (map) => map[key],
      type: type,
      currencyCode: currencyCode,
      precision: precision,
      dateFormat: dateFormat,
      alignment: effectiveAlignment,
      width: width,
      isVisible: isVisible,
      nullPlaceholder: nullPlaceholder,
    );
  }

  /// Extracts and validates the cell value from an item.
  dynamic extractValue(T item) {
    try {
      return accessor(item);
    } catch (_) {
      return null;
    }
  }
}
