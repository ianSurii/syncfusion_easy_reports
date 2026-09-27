# Getting Started with syncfusion_easy_reports

`syncfusion_easy_reports` helps Flutter developers generate professional Excel (.xlsx) and PDF reports from structured application data.

## Installation

Add `syncfusion_easy_reports` to your `pubspec.yaml`:

```yaml
dependencies:
  syncfusion_easy_reports: ^0.0.1
```

Run:

```bash
flutter pub get
```

## Quick Start (Model-Driven API)

```dart
import 'package:syncfusion_easy_reports/syncfusion_easy_reports.dart';

// 1. Define Model
class Employee {
  final String id;
  final String name;
  final String department;
  final double salary;

  Employee({required this.id, required this.name, required this.department, required this.salary});
}

// 2. Define Schema & Analyses
final definition = ReportDefinition<Employee>(
  title: 'Monthly Compensation Audit',
  columns: [
    ReportColumn.text(id: 'id', title: 'Employee ID', value: (e) => e.id),
    ReportColumn.text(id: 'name', title: 'Full Name', value: (e) => e.name),
    ReportColumn.text(id: 'dept', title: 'Department', value: (e) => e.department),
    ReportColumn.money(id: 'salary', title: 'Salary', currencyCode: 'USD', value: (e) => e.salary),
  ],
  analyses: [
    ReportAnalysis.detail(id: 'register', title: 'Payroll Register'),
    ReportAnalysis.grouped(
      id: 'by_dept',
      title: 'Department Summary',
      groupBy: ['dept'],
      measures: [
        ReportMeasure.count(id: 'headcount', title: 'Employees'),
        ReportMeasure.sum(column: 'salary', title: 'Total Spend', currencyCode: 'USD'),
      ],
    ),
  ],
);

// 3. Prepare & Export
final engine = ReportEngine();
final prepared = await engine.prepare(definition: definition, records: employees);

// Returns standalone ReportArtifact containing Uint8List bytes
final excelArtifact = await engine.exportExcel(prepared);
final pdfArtifact = await engine.exportPdf(prepared);

// 4. Save to Disk or Browser
await ReportSaver().save(excelArtifact);
```
