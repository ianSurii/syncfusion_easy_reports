# Migration Guide

## Upgrading from Classic Table API (`ReportData`) to Model-Driven API (`ReportDefinition`)

The classic API (`ReportData`, `ReportSection`, `ReportTable`, `ExcelReportGenerator`, `PdfReportGenerator`) continues to be 100% supported and functional. However, migrating to `ReportDefinition` provides typed selectors, shared calculation reconciliation, dynamic grouping, Top-N ranking, and cross-tabulation.

### Before (Classic Table API):
```dart
final table = ReportTable(
  headers: ['Employee', 'Salary'],
  rows: [
    ['John Doe', 5000.0],
    ['Jane Smith', 6000.0],
  ],
  currencyColumnIndices: [1],
  calculateTotals: true,
);

final section = ReportSection(title: 'Payroll', table: table);
final data = ReportData(title: 'Payroll Audit', sections: [section]);

final bytes = await ExcelReportGenerator().generate(data);
```

### After (Model-Driven API):
```dart
final definition = ReportDefinition<Employee>(
  title: 'Payroll Audit',
  columns: [
    ReportColumn.text(id: 'name', title: 'Employee', value: (e) => e.name),
    ReportColumn.money(id: 'salary', title: 'Salary', value: (e) => e.salary),
  ],
  analyses: [
    ReportAnalysis.detail(id: 'register', title: 'Payroll Register'),
  ],
);

final prepared = await ReportEngine().prepare(definition: definition, records: employees);
final artifact = await ReportEngine().exportExcel(prepared);
```
