# syncfusion_easy_reports

[![pub package](https://img.shields.io/pub/v/syncfusion_easy_reports.svg)](https://pub.dev/packages/syncfusion_easy_reports)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![CI & Docs](https://github.com/ianSurii/syncfusion_easy_reports/actions/workflows/deploy.yml/badge.svg)](https://github.com/ianSurii/syncfusion_easy_reports/actions/workflows/deploy.yml)

**syncfusion_easy_reports** helps Flutter developers generate professional Excel (`.xlsx`) and PDF reports from structured application data. Define columns, grouping rules, calculations, and branding, then reuse those definitions across detailed reports, categorized worksheets, summaries, and printable documents.

---

## Interactive Demo & Documentation

- 🚀 **[Interactive Web Playground Demo](https://iansurii.github.io/syncfusion_easy_reports/demo/)**
- 📖 **[Documentation & Architecture Portal](https://iansurii.github.io/syncfusion_easy_reports/)**
- 📦 **[Package on pub.dev](https://pub.dev/packages/syncfusion_easy_reports)**
- ⭐ **[GitHub Repository](https://github.com/ianSurii/syncfusion_easy_reports)**

---

## Supported Formats & Capabilities

| Capability / Feature | Excel (`.xlsx`) | PDF (`.pdf`) | Notes |
| :--- | :---: | :---: | :--- |
| **Multi-Sheet / Multi-Section** | ✔ | ✔ | 1 dataset produces multiple worksheets or sections |
| **Model-Driven Typed Mapping** | ✔ | ✔ | Typed selectors for custom Dart objects or Map data |
| **Single & Multi-Field Grouping** | ✔ | ✔ | Nested categorization with subtotals and grand totals |
| **2D Cross-Tabulation (Pivot)** | ✔ | ✔ | Engine-calculated 2D matrix (Row x Col x Measure) |
| **Top-N Analysis with "Other"** | ✔ | ✔ | Top-ranked records with combined remaining bucket |
| **Date-Interval Grouping** | ✔ | ✔ | Group by Day, Month, Quarter, Year with Fiscal offset |
| **Custom Category Buckets** | ✔ | ✔ | Numerical tiering (e.g. AR Aging 0-30, 31-60, 90+ days) |
| **Table of Contents (Overview)** | ✔ | ✔ | Clickable hyperlinked sheet in Excel |
| **Repeated Headers across Pages** | ✔ | ✔ | Automatic header repeating across page breaks |
| **Formulas & Functions** | ✔ | N/A | Native Excel `=SUM()` formulas for totals |
| **Password Protection** | ✔ | ✔ | Worksheet/Workbook protection & encrypted PDFs |
| **Formula Injection Protection** | ✔ | N/A | Sanitizes untrusted strings starting with `=`, `+`, `-`, `@` |

> **Format Support Policy:**
> - **Excel:** Targets modern `.xlsx` workbooks via Syncfusion Flutter XlsIO. Legacy `.xls` and macro `.xlsm` files are out of scope.
> - **PDF:** Standard business PDF and password-protected PDF. **PDF/A archival and encryption are mutually exclusive** per ISO specification.

---

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  syncfusion_easy_reports: ^0.0.1
```

Run:

```bash
flutter pub get
```

---

## Quick Start (Model-Driven API)

```dart
import 'package:syncfusion_easy_reports/syncfusion_easy_reports.dart';

// 1. Define your custom Dart model
class Employee {
  final String id;
  final String name;
  final String department;
  final double basicPay;
  final double bonus;

  Employee({
    required this.id,
    required this.name,
    required this.department,
    required this.basicPay,
    this.bonus = 0.0,
  });

  double get netPay => basicPay + bonus;
}

// 2. Define schema, columns, and analyses
final definition = ReportDefinition<Employee>(
  title: 'Monthly Compensation Audit',
  branding: ReportBranding(
    companyName: 'Acme Corporation',
    address: '100 Enterprise Way, Suite 400',
  ),
  columns: [
    ReportColumn.text(id: 'id', title: 'Employee ID', value: (e) => e.id),
    ReportColumn.text(id: 'name', title: 'Full Name', value: (e) => e.name),
    ReportColumn.text(id: 'dept', title: 'Department', value: (e) => e.department),
    ReportColumn.money(id: 'basicPay', title: 'Basic Pay', currencyCode: 'USD', value: (e) => e.basicPay),
    ReportColumn.money(id: 'netPay', title: 'Net Pay', currencyCode: 'USD', value: (e) => e.netPay),
  ],
  analyses: [
    ReportAnalysis.detail(
      id: 'register',
      title: 'Payroll Register',
      showGrandTotal: true,
    ),
    ReportAnalysis.grouped(
      id: 'dept_summary',
      title: 'Department Summary',
      groupBy: ['dept'],
      measures: [
        ReportMeasure.count(id: 'headcount', title: 'Headcount'),
        ReportMeasure.sum(column: 'basicPay', currencyCode: 'USD'),
        ReportMeasure.sum(column: 'netPay', currencyCode: 'USD'),
        ReportMeasure.average(column: 'netPay', title: 'Avg Net Pay', currencyCode: 'USD'),
      ],
      showGrandTotal: true,
    ),
  ],
);

// 3. Prepare & Export (Bytes-Only, Zero UI)
final engine = ReportEngine();
final prepared = await engine.prepare(
  definition: definition,
  records: employees,
);

final excelArtifact = await engine.exportExcel(prepared);
final pdfArtifact = await engine.exportPdf(prepared);

// 4. Save or Download (Cross-Platform)
await ReportSaver().save(excelArtifact);
```

---

## Multiple Analyses from a Single Dataset

A single dataset can drive multiple independent analyses without duplicating data in memory:

```dart
final definition = ReportDefinition<SaleRecord>(
  title: 'Annual Commercial Sales Audit',
  columns: [
    ReportColumn.text(id: 'salesperson', title: 'Sales Rep', value: (s) => s.rep),
    ReportColumn.text(id: 'region', title: 'Region', value: (s) => s.region),
    ReportColumn.text(id: 'category', title: 'Category', value: (s) => s.category),
    ReportColumn.money(id: 'revenue', title: 'Revenue', currencyCode: 'USD', value: (s) => s.amount),
  ],
  analyses: [
    // 1. Full Detail Register
    ReportAnalysis.detail(id: 'register', title: 'Sales Register'),

    // 2. Summary by Region
    ReportAnalysis.grouped(
      id: 'by_region',
      title: 'Regional Summary',
      groupBy: ['region'],
      measures: [
        ReportMeasure.count(id: 'orders'),
        ReportMeasure.sum(column: 'revenue', currencyCode: 'USD'),
        ReportMeasure.percentageOfTotal(column: 'revenue', title: '% of Sales'),
      ],
    ),

    // 3. 2D Cross-Tabulation Pivot (Category x Region)
    ReportAnalysis.crossTab(
      id: 'pivot_matrix',
      title: 'Category by Region CrossTab',
      rowDimension: 'category',
      columnDimension: 'region',
      measure: ReportMeasure.sum(column: 'revenue', currencyCode: 'USD'),
    ),
  ],
);
```

---

## Excel Export Options

Customize your `.xlsx` workbooks with freeze panes, auto-filters, overview sheets, and protection:

```dart
final excelArtifact = await engine.exportExcel(
  prepared,
  options: const ExcelExportOptions(
    includeSummarySheet: true,     // Clickable Table of Contents sheet at index 0
    enableAutoFilter: true,        // Native Excel filter dropdowns
    protectWorksheets: true,       // Password-protect worksheets from accidental edits
    worksheetPassword: 'ReadonlyPassword',
    showGridlines: true,
  ),
);
```

---

## PDF Export Options

Configure page layouts, security, pagination, and signature placeholders:

```dart
final pdfArtifact = await engine.exportPdf(
  prepared,
  options: const PdfExportOptions(
    pageSize: 'A4',
    orientation: 'portrait',
    repeatHeaders: true,          // Repeated table headers across page breaks
    showPageNumbers: true,        // "Page X of Y" pagination
    showSignatures: true,         // Signature line placeholders at the bottom
    signatureLabels: ['Prepared By: Finance Lead', 'Approved By: CFO'],
    enableEncryption: false,      // User and owner password encryption
  ),
);
```

---

## Pre-Built Domain Report Presets

`syncfusion_easy_reports` includes pre-built, customizable report presets for common enterprise requirements:

- **Human Resources (`HrReportPresets`):** Employee Register, Headcount & Location Breakdown, Attendance.
- **Payroll (`PayrollReportPresets`):** Payroll Register, Department Summary, Bank Payment Schedule, Payslips.
- **Sales (`SalesReportPresets`):** Sales Register, Regional Performance, Category-by-Region CrossTab.
- **Finance (`FinanceReportPresets`):** Expense Ledger, Accounts Receivable Aging (0-30, 31-60, 61-90, 90+ days).
- **Inventory (`InventoryReportPresets`):** Stock Valuation, Warehouse Allocation, Reorder Alerts.
- **Projects (`ProjectReportPresets`):** Timesheets, Resource Utilization, Billable Hours.

```dart
// Use preset directly with Map or JSON data
final def = FinanceReportPresets.accountsReceivableAging(
  companyName: 'Acme Corp',
  currencyCode: 'USD',
);
final prepared = await engine.prepare(definition: def, records: invoiceMaps);
```

---

## Template Generation & Import

Generate data-entry `.xlsx` templates and parse uploaded spreadsheets with structured validation:

```dart
final templateService = ExcelTemplateService();

// Generate data-entry template workbook
final templateBytes = await templateService.generateXlsxTemplate(
  columns: [
    ExcelTemplateColumn(name: 'Employee ID', sampleValue: 'EMP001', isRequired: true),
    ExcelTemplateColumn(name: 'Full Name', sampleValue: 'John Doe', isRequired: true),
    ExcelTemplateColumn(name: 'Salary', sampleValue: '75000', isRequired: true),
  ],
  instructions: 'Please enter employee details. Fields with (*) are mandatory.',
);

// Import and validate uploaded Excel bytes
final result = templateService.importExcelBytes(templateBytes);
if (result.isValid) {
  print('Successfully parsed ${result.totalRows} records!');
} else {
  for (final error in result.errors) {
    print('Validation Error: $error');
  }
}
```

---

## Accuracy & Safe Data Handling

1. **Shared Calculation Core:** A unified preparation pipeline guarantees that calculated sums, averages, and group subtotals match 100% between Excel and PDF.
2. **Formula Injection Sanitization:** Untrusted cell text starting with `=`, `+`, `-`, or `@` is automatically escaped with `'` to prevent spreadsheet injection attacks.
3. **Financial Precision:** Currency arithmetic uses documented precision and rounding boundaries.
4. **Reconciliation Audit:** Compares detail row sums against group totals and flags any discrepancies via `prepared.isReconciled`.

---

## Platform Support

| Platform | Generation (Bytes) | Saving / Download Behavior |
| :--- | :---: | :--- |
| **Web** | ✔ | Instant browser file download via web blob anchor |
| **macOS** | ✔ | Native save dialog with automatic fallback to `~/Downloads` |
| **Windows** | ✔ | Native save dialog with fallback to Downloads / Explorer |
| **Linux** | ✔ | Native save dialog with fallback to Downloads / xdg-open |
| **Android** | ✔ | Scoped storage / Downloads directory without broad permissions |
| **iOS** | ✔ | Application sandbox storage + Native Share Sheet |

---

## State Management Independence

`syncfusion_easy_reports` contains **zero dependencies** on state management libraries. You can freely use it with Vanilla Flutter, Provider, Riverpod, Bloc, GetX, or Signals.

---

## Licensing & Syncfusion Notice

This package is licensed under the [MIT License](LICENSE).

> **Important Syncfusion Licensing Requirement:**
> This package wraps `syncfusion_flutter_pdf` and `syncfusion_flutter_xlsio`. Using Syncfusion Flutter widgets requires a valid Syncfusion Community License (free for eligible individual developers and small businesses) or Commercial License. Visit [Syncfusion License Terms](https://www.syncfusion.com/sales/products) to obtain a license.
