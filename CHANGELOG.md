## 0.0.1

* Initial release of `syncfusion_easy_reports` with complete model-driven and table-based reporting architecture.
* **Model-Driven Reporting Engine:** Added `ReportDefinition<T>`, `ReportColumn<T>`, `ReportAnalysis`, `ReportMeasure`, and `ReportEngine`.
* **Multi-Analysis Support:** Generate detail registers, multi-level grouped summaries, 2D cross-tabulation pivot tables, and KPI metric cards from a single dataset.
* **Data Categorization:** Support single/multi-field grouping, date-interval grouping (Day, Month, Quarter, Year with fiscal offsets), custom category buckets (e.g. AR aging tiers), and Top-N ranking with "Other" grouping.
* **Accuracy & Financial Reconciliation:** Integrated calculation and validation engine with high-precision decimal rounding and cross-format reconciliation auditing.
* **Excel OpenXML Exporter:** Multi-sheet generation, overview Table of Contents, auto-filters, freeze headers, formula generation, and worksheet/workbook password protection.
* **PDF Exporter:** Paginated grid tables, repeated headers across page breaks, dynamic "Page X of Y" pagination, customizable margins, signature placeholders, and PDF encryption.
* **Security & Safe Handling:** Added formula injection protection against spreadsheet injection vulnerabilities; enforced ISO PDF/A and encryption mutual exclusivity.
* **Pre-Built Domain Presets:** Added enterprise presets for Human Resources, Payroll, Sales, Finance & Aging, Inventory Valuation, and Project Timesheets.
* **Template Generation & Parsing:** Added `ExcelTemplateService` with genuine `.xlsx` template generation and structured error validation for imported spreadsheets.
* **Cross-Platform Savers:** Standalone `ReportArtifact` bytes generation with zero UI dependencies, accompanied by `ReportSaver` and modern web/desktop/mobile file handling.
