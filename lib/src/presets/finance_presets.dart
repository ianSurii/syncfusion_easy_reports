import '../engine/report_definition.dart';
import '../engine/report_column.dart';
import '../engine/report_analysis.dart';
import '../engine/report_measure.dart';
import '../models/report_models.dart';

/// Pre-built report presets for Finance, Accounting, and Receivables Aging.
class FinanceReportPresets {
  /// Accounts Receivable Aging report with standard 0-30, 31-60, 61-90, and 90+ aging buckets.
  static ReportDefinition<Map<String, dynamic>> accountsReceivableAging({
    String title = 'Accounts Receivable Aging Report',
    String currencyCode = 'USD',
    String? companyName,
    ReportTheme? theme,
  }) {
    return ReportDefinition<Map<String, dynamic>>(
      title: title,
      branding: ReportBranding(companyName: companyName),
      theme: theme ?? ReportTheme.corporateDark(),
      columns: [
        ReportColumn.text(
          id: 'invoiceNumber',
          title: 'Invoice #',
          value: (m) => m['invoiceNumber'] ?? m['invoiceNo'],
        ),
        ReportColumn.text(
          id: 'customer',
          title: 'Customer Name',
          value: (m) => m['customer'] ?? m['client'],
        ),
        ReportColumn.number(
          id: 'daysOverdue',
          title: 'Days Overdue',
          precision: 0,
          value: (m) => m['daysOverdue'] ?? m['days'] ?? 0,
        ),
        ReportColumn.money(
          id: 'amount',
          title: 'Outstanding Amount',
          currencyCode: currencyCode,
          value: (m) => m['amount'],
        ),
        ReportColumn.date(
          id: 'dueDate',
          title: 'Due Date',
          value: (m) => m['dueDate'] is DateTime ? m['dueDate'] : null,
        ),
      ],
      analyses: [
        ReportAnalysis.detail(
          id: 'invoice_details',
          title: 'Outstanding Invoices',
          showGrandTotal: true,
        ),
        ReportAnalysis.grouped(
          id: 'aging_summary',
          title: 'Aging Buckets Summary',
          groupBy: ['daysOverdue'],
          categoryBuckets: {
            'daysOverdue': const [
              ReportCategoryBucket(
                label: 'Current (0-30 Days)',
                min: 0,
                max: 31,
              ),
              ReportCategoryBucket(label: '31-60 Days', min: 31, max: 61),
              ReportCategoryBucket(label: '61-90 Days', min: 61, max: 91),
              ReportCategoryBucket(
                label: '90+ Days (High Risk)',
                min: 91,
                max: null,
              ),
            ],
          },
          measures: [
            ReportMeasure.count(id: 'invoices', title: 'Invoices'),
            ReportMeasure.sum(
              column: 'amount',
              title: 'Total Outstanding',
              currencyCode: currencyCode,
            ),
            ReportMeasure.average(
              column: 'daysOverdue',
              title: 'Avg Days Overdue',
            ),
            ReportMeasure.percentageOfTotal(
              column: 'amount',
              title: '% of Total AR',
            ),
          ],
          showGrandTotal: true,
        ),
      ],
    );
  }

  /// Expense Register grouped by Cost Center and Expense Category.
  static ReportDefinition<Map<String, dynamic>> expenseRegister({
    String title = 'Expense Audit Register',
    String currencyCode = 'USD',
    String? companyName,
    ReportTheme? theme,
  }) {
    return ReportDefinition<Map<String, dynamic>>(
      title: title,
      branding: ReportBranding(companyName: companyName),
      theme: theme ?? ReportTheme.slateGrey(),
      columns: [
        ReportColumn.text(
          id: 'ref',
          title: 'Reference #',
          value: (m) => m['ref'] ?? m['id'],
        ),
        ReportColumn.text(
          id: 'costCenter',
          title: 'Cost Center',
          value: (m) => m['costCenter'] ?? m['dept'],
        ),
        ReportColumn.text(
          id: 'category',
          title: 'Category',
          value: (m) => m['category'],
        ),
        ReportColumn.money(
          id: 'amount',
          title: 'Amount',
          currencyCode: currencyCode,
          value: (m) => m['amount'],
        ),
        ReportColumn.text(
          id: 'approvedBy',
          title: 'Approved By',
          value: (m) => m['approvedBy'],
        ),
        ReportColumn.date(
          id: 'expenseDate',
          title: 'Date',
          value: (m) => m['expenseDate'] is DateTime ? m['expenseDate'] : null,
        ),
      ],
      analyses: [
        ReportAnalysis.detail(
          id: 'expense_register',
          title: 'Expense Register',
          showGrandTotal: true,
        ),
        ReportAnalysis.grouped(
          id: 'cost_center_summary',
          title: 'Expenses by Cost Center',
          groupBy: ['costCenter'],
          measures: [
            ReportMeasure.count(id: 'count', title: 'Transactions'),
            ReportMeasure.sum(
              column: 'amount',
              title: 'Total Spend',
              currencyCode: currencyCode,
            ),
            ReportMeasure.percentageOfTotal(
              column: 'amount',
              title: '% of Spend',
            ),
          ],
          showGrandTotal: true,
        ),
      ],
    );
  }
}
