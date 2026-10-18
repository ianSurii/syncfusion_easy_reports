/// Utility functions for text formatting and case conversions in reports.
library;

/// Converts snake_case, camelCase, or dash-separated strings into Title Case words.
///
/// Handles common financial and reporting abbreviations such as ID, SKU, KPI, VAT, AR, AP,
/// Avg, Min, Max, and Sum.
///
/// Example:
/// - `'count'` -> `'Count'`
/// - `'basic_sum'` -> `'Basic Sum'`
/// - `'net_avg'` -> `'Net Avg'`
/// - `'net_min'` -> `'Net Min'`
/// - `'net_maxs'` -> `'Net Maxs'`
/// - `'basic_salary'` -> `'Basic Salary'`
String toTitleCase(String text) {
  if (text.isEmpty) return text;

  // Insert space between lower and upper case (camelCase -> camel Case)
  final withSpaces = text
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .trim();

  final words = withSpaces.split(RegExp(r'\s+'));
  return words
      .map((w) {
        if (w.isEmpty) return '';
        final lower = w.toLowerCase();
        if (lower == 'id') return 'ID';
        if (lower == 'sku') return 'SKU';
        if (lower == 'kpi') return 'KPI';
        if (lower == 'ar') return 'AR';
        if (lower == 'ap') return 'AP';
        if (lower == 'vat') return 'VAT';
        if (lower == 'avg') return 'Avg';
        if (lower == 'min') return 'Min';
        if (lower == 'max') return 'Max';
        if (lower == 'maxs') return 'Maxs';
        if (lower == 'sum') return 'Sum';
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      })
      .join(' ');
}
