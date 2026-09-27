# Dynamic Categorization and Aggregation Guide

## Single & Multi-Field Grouping

Group records across one or multiple dimensions:

```dart
ReportAnalysis.grouped(
  id: 'dept_location',
  title: 'Department & Location Summary',
  groupBy: ['department', 'location'],
  measures: [
    ReportMeasure.count(id: 'count', title: 'Headcount'),
    ReportMeasure.sum(column: 'salary', currencyCode: 'USD'),
    ReportMeasure.average(column: 'salary', title: 'Avg Salary', currencyCode: 'USD'),
  ],
  showSubtotals: true,
  showGrandTotal: true,
);
```

## Date-Based Grouping

Group time-series records by day, month, quarter, or year with fiscal year offsets:

```dart
ReportAnalysis.grouped(
  id: 'monthly_sales',
  title: 'Monthly Sales Volume',
  groupBy: ['saleDate'],
  dateGrouping: const ReportDateGrouping(
    columnId: 'saleDate',
    interval: ReportDateInterval.month,
    fiscalYearStartMonth: 7, // July fiscal year start
  ),
  measures: [
    ReportMeasure.sum(column: 'revenue', currencyCode: 'USD'),
  ],
);
```

## Custom Aging & Amount Buckets

Create discrete numerical tiers (e.g. accounts receivable aging):

```dart
ReportAnalysis.grouped(
  id: 'aging_summary',
  title: 'AR Aging Buckets',
  groupBy: ['daysOverdue'],
  categoryBuckets: {
    'daysOverdue': const [
      ReportCategoryBucket(label: '0-30 Days (Current)', min: 0, max: 31),
      ReportCategoryBucket(label: '31-60 Days', min: 31, max: 61),
      ReportCategoryBucket(label: '61-90 Days', min: 61, max: 91),
      ReportCategoryBucket(label: '90+ Days (Overdue)', min: 91, max: null),
    ],
  },
  measures: [
    ReportMeasure.count(id: 'invoices'),
    ReportMeasure.sum(column: 'amount', currencyCode: 'USD'),
  ],
);
```

## Top-N Analysis with Combined "Other"

Rank top performers and aggregate remaining categories into a single summary row:

```dart
ReportAnalysis.grouped(
  id: 'top_reps',
  title: 'Top 5 Sales Representatives',
  groupBy: ['salesperson'],
  measures: [
    ReportMeasure.sum(column: 'revenue', id: 'total_revenue'),
  ],
  topN: const ReportTopN(
    count: 5,
    rankBy: 'total_revenue',
    otherLabel: 'All Other Salespersons',
  ),
);
```

## Category-Split Multi-Sheet Reports (`sheetPerCategory: true`)

Generate dedicated Excel worksheets or PDF sections for each distinct category (e.g. Payroll Deductions, Bank Payment Schedules, Regional Warehouses):

```dart
// Generates separate sheets for 'KCB Loan', 'Equity Loan', 'Housing Levy', 'SHA', etc.
ReportAnalysis.grouped(
  id: 'deduction_schedules',
  title: 'Deduction Remittance Schedules',
  groupBy: ['deductionType'],
  sheetPerCategory: true,
  detailColumns: [
    'employeeId',
    'employeeName',
    'department',
    'referenceNumber',
    'amount',
    'employerContribution',
    'totalRemittance',
    'notes',
  ],
  measures: [
    ReportMeasure.count(id: 'count', title: 'Employees'),
    ReportMeasure.sum(column: 'amount', title: 'Total Deduction', currencyCode: 'USD'),
  ],
  showGrandTotal: true,
);
```

### Pre-Built Preset: Categorized Deductions

```dart
final def = PayrollReportPresets.categorizedDeductions(
  companyName: 'Acme Global Corporation',
  currencyCode: 'USD',
);

final artifact = await engine.generateExcel(
  definition: def,
  records: deductionsDataset,
  options: const ExcelExportOptions(
    includeSummarySheet: true,
    showSignatures: true,
    signatureLabels: ['Prepared By', 'Checked By', 'Approved By', 'Authorized By'],
  ),
);
```

