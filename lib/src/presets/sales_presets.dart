import '../engine/report_definition.dart';
import '../engine/report_column.dart';
import '../engine/report_analysis.dart';
import '../engine/report_measure.dart';
import '../models/report_models.dart';

/// Pre-built report presets for Sales, Invoicing, and Commercial revenue.
class SalesReportPresets {
  /// Sales Performance Register with Regional, Salesperson, and Category analyses.
  static ReportDefinition<Map<String, dynamic>> salesPerformance({
    String title = 'Sales Performance Report',
    String currencyCode = 'USD',
    String? companyName,
    ReportTheme? theme,
  }) {
    return ReportDefinition<Map<String, dynamic>>(
      title: title,
      branding: ReportBranding(companyName: companyName),
      theme: theme ?? ReportTheme.forestGreen(),
      columns: [
        ReportColumn.text(
          id: 'orderId',
          title: 'Order #',
          value: (m) => m['orderId'] ?? m['id'],
        ),
        ReportColumn.text(
          id: 'salesperson',
          title: 'Salesperson',
          value: (m) => m['salesperson'] ?? m['rep'],
        ),
        ReportColumn.text(
          id: 'region',
          title: 'Region',
          value: (m) => m['region'],
        ),
        ReportColumn.text(
          id: 'category',
          title: 'Product Category',
          value: (m) => m['category'],
        ),
        ReportColumn.number(
          id: 'quantity',
          title: 'Qty Sold',
          precision: 0,
          value: (m) => m['quantity'] ?? m['qty'],
        ),
        ReportColumn.money(
          id: 'revenue',
          title: 'Revenue',
          currencyCode: currencyCode,
          value: (m) => m['revenue'] ?? m['amount'],
        ),
        ReportColumn.money(
          id: 'profit',
          title: 'Gross Profit',
          currencyCode: currencyCode,
          value: (m) => m['profit'],
        ),
        ReportColumn.date(
          id: 'date',
          title: 'Sale Date',
          value: (m) => m['date'] is DateTime ? m['date'] : null,
        ),
      ],
      analyses: [
        ReportAnalysis.detail(
          id: 'sales_register',
          title: 'Sales Register',
          showGrandTotal: true,
        ),
        ReportAnalysis.grouped(
          id: 'regional_summary',
          title: 'Sales by Region',
          groupBy: ['region'],
          measures: [
            ReportMeasure.count(id: 'orders', title: 'Orders'),
            ReportMeasure.sum(column: 'quantity', title: 'Total Qty'),
            ReportMeasure.sum(
              column: 'revenue',
              title: 'Total Revenue',
              currencyCode: currencyCode,
            ),
            ReportMeasure.sum(
              column: 'profit',
              title: 'Total Profit',
              currencyCode: currencyCode,
            ),
            ReportMeasure.average(
              column: 'revenue',
              title: 'Avg Order Value',
              currencyCode: currencyCode,
            ),
            ReportMeasure.percentageOfTotal(
              column: 'revenue',
              title: '% of Sales',
            ),
          ],
          showGrandTotal: true,
        ),
        ReportAnalysis.crossTab(
          id: 'category_by_region',
          title: 'Category by Region Pivot',
          rowDimension: 'category',
          columnDimension: 'region',
          measure: ReportMeasure.sum(
            column: 'revenue',
            currencyCode: currencyCode,
          ),
        ),
      ],
    );
  }
}
