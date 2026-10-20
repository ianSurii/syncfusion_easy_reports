## 0.0.3

* Added Linux desktop and web support, with CI builds for both targets.
* Updated Syncfusion PDF and Excel dependencies and tightened lower-bound compatibility.
* Preserved logo aspect ratios in PDF and Excel reports, and moved example logos above company details.

## 0.0.2

* Added configurable payment and remittance instructions, financial summary placement, and signature layouts for PDF and Excel exports.
* Expanded report configuration with page orientation, report charts, and richer model-driven analysis options.
* Improved category-sheet generation and report labels, and expanded the interactive example and web demo.

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
