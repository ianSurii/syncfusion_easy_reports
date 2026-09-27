# Security Guidelines & Accuracy Assurance

## Formula Injection (CSV / Excel Injection)
Untrusted strings beginning with `=`, `+`, `-`, or `@` can be interpreted as executable spreadsheet formulas in spreadsheet software. `syncfusion_easy_reports` automatically escapes untrusted string cells with a single quote prefix (`'`) unless a column is explicitly configured as a trusted formula column.

## Excel Protection vs Encryption
- **Worksheet Protection (`sheet.protect()`):** Prevents accidental cell overwrites or edits by users. This is **NOT** file encryption and does not make payroll or confidential data secure.
- **Workbook Protection (`workbook.protect()`):** Locks the workbook structure against adding, removing, or renaming worksheets.
- **PDF Encryption:** Protects document opening with user and owner passwords, controlling printing and content copying.

## Financial Precision & Reconciliation
- Aggregations utilize high-precision decimal arithmetic and round using currency-specific or measure-specific precision.
- Built-in reconciliation engine compares individual detail line sums against group subtotals and grand totals, asserting reconciliation in `prepared.isReconciled`.
