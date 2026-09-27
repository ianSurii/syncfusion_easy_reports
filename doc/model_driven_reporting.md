# Model-Driven Reporting Guide

## Concept
The model-driven reporting API separates **data definition** from **rendering**. You define columns, calculations, and grouping rules once, and the reporting engine produces a validated `PreparedReport` that renders identically to Excel and PDF.

## Column Types & Factories

```dart
// Text Column
ReportColumn.text(
  id: 'name',
  title: 'Employee Name',
  value: (e) => e.name,
);

// Currency / Money Column
ReportColumn.money(
  id: 'salary',
  title: 'Basic Salary',
  currencyCode: 'USD',
  precision: 2,
  value: (e) => e.salary,
);

// Percentage Column
ReportColumn.percentage(
  id: 'margin',
  title: 'Gross Margin',
  precision: 1,
  value: (e) => e.margin,
);

// Date & DateTime Columns
ReportColumn.date(
  id: 'joined',
  title: 'Date Joined',
  dateFormat: 'yyyy-MM-dd',
  value: (e) => e.joinedDate,
);

// Boolean Column
ReportColumn.boolean(
  id: 'isActive',
  title: 'Active',
  trueLabel: 'Yes',
  falseLabel: 'No',
  value: (e) => e.isActive,
);

// Key-based Map Column
ReportColumn.forMap(
  key: 'department',
  title: 'Dept',
  type: ReportFieldType.text,
);
```
