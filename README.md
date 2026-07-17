syncfusion_easy_reports
=======================

Lightweight wrapper utilities and example code for generating professional
Excel and PDF reports in Flutter using Syncfusion libraries. This package
provides opinionated helpers to build tabular reports, multi-sheet payrolls,
and detailed payslips, plus an example app demonstrating interactive report
generation and export.

**Key features**
- Generate Excel workbooks with multiple sheets, group headers, totals, and
  per-sheet configuration (`ReportData`, `ReportSection`, `ReportTable`).
- Export detailed payroll ledgers and categorized deduction sheets (example
  includes an "ABC Bank - Loan Deductions" sheet).
- Produce branded PDF payslips and multi-page reports with headers, footers,
  and signature placeholders.
- Example app with an "Interactive" builder for live JSON previews and
  export buttons for Excel/PDF.
- macOS-safe file saving fallback (uses FilePicker.saveFile when available,
  otherwise writes to `Downloads` and reveals the file).

Getting started
---------------

Prerequisites:
- Flutter SDK (stable) and required platform toolchains

Install dependencies and run the example:

```bash
flutter pub get
flutter analyze
flutter test
cd example
flutter run -d macos   # or -d chrome / -d windows / -d linux
```

Usage
-----

This package exposes a simple API surface for building reports. Example
construction using the `ReportData` model:

```dart
final table = ReportTable(
  headers: ['Employee ID','Name','Net Pay'],
  rows: [[ 'EMP001','John Doe', 1234.56 ]],
  currencyColumnIndices: [2],
  currencySymbol: 'USD',
);

final section = ReportSection(title: 'Payroll', table: table);

final report = ReportData(title: 'Payroll Report', sections: [section]);

await ExcelReportGenerator().generateAndDownload(report, 'payroll_report');
```

See the `example/` app for richer flows (interactive template builder,
advanced payroll export, and payslip PDF sample).

Contributing
------------

Please open issues or pull requests. Run static checks before committing:

```bash
flutter pub get
flutter analyze
dart format --set-exit-if-changed .
flutter test
```

License
-------

See the `LICENSE` file in the repository root.

Maintainers: Please avoid reintroducing legacy code from the `old/` folder
into active sources — it's kept for historical reference only.
