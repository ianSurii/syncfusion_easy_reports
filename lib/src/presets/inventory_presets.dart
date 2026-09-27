import '../engine/report_definition.dart';
import '../engine/report_column.dart';
import '../engine/report_analysis.dart';
import '../engine/report_measure.dart';
import '../models/report_models.dart';

/// Pre-built report presets for Inventory Management, Stock Movements, and Valuation.
class InventoryReportPresets {
  /// Inventory Valuation and Reorder Level report.
  static ReportDefinition<Map<String, dynamic>> stockValuation({
    String title = 'Inventory Valuation & Reorder Status',
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
          id: 'sku',
          title: 'SKU',
          value: (m) => m['sku'] ?? m['id'],
        ),
        ReportColumn.text(
          id: 'name',
          title: 'Item Name',
          value: (m) => m['name'] ?? m['title'],
        ),
        ReportColumn.text(
          id: 'category',
          title: 'Category',
          value: (m) => m['category'],
        ),
        ReportColumn.text(
          id: 'warehouse',
          title: 'Warehouse',
          value: (m) => m['warehouse'] ?? 'Main',
        ),
        ReportColumn.number(
          id: 'stockOnHand',
          title: 'On Hand',
          precision: 0,
          value: (m) => m['stockOnHand'] ?? m['quantity'] ?? 0,
        ),
        ReportColumn.number(
          id: 'reorderLevel',
          title: 'Reorder Point',
          precision: 0,
          value: (m) => m['reorderLevel'] ?? 10,
        ),
        ReportColumn.money(
          id: 'unitCost',
          title: 'Unit Cost',
          currencyCode: currencyCode,
          value: (m) => m['unitCost'] ?? m['cost'] ?? 0,
        ),
        ReportColumn.money(
          id: 'totalValuation',
          title: 'Total Value',
          currencyCode: currencyCode,
          value: (m) {
            final num qty = m['stockOnHand'] ?? m['quantity'] ?? 0;
            final num cost = m['unitCost'] ?? m['cost'] ?? 0;
            return qty * cost;
          },
        ),
      ],
      analyses: [
        ReportAnalysis.detail(
          id: 'inventory_register',
          title: 'Stock Inventory Register',
          showGrandTotal: true,
        ),
        ReportAnalysis.grouped(
          id: 'category_valuation',
          title: 'Valuation by Category',
          groupBy: ['category'],
          measures: [
            ReportMeasure.count(id: 'skus', title: 'SKU Count'),
            ReportMeasure.sum(column: 'stockOnHand', title: 'Total Units'),
            ReportMeasure.sum(
              column: 'totalValuation',
              title: 'Total Value',
              currencyCode: currencyCode,
            ),
            ReportMeasure.average(
              column: 'unitCost',
              title: 'Avg Unit Cost',
              currencyCode: currencyCode,
            ),
            ReportMeasure.percentageOfTotal(
              column: 'totalValuation',
              title: '% of Inventory Value',
            ),
          ],
          showGrandTotal: true,
        ),
      ],
    );
  }
}
