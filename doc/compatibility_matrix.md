# Compatibility Matrix

## Format Support Policy

| Format / Viewer | Support Level | Implementation Notes |
| :--- | :--- | :--- |
| Modern Excel `.xlsx` | **Primary Excel Output** | Generated via Syncfusion Flutter XlsIO OpenXML standard. |
| Legacy Excel `.xls` | *Unsupported* | Not part of Flutter XlsIO OpenXML pipeline. |
| Microsoft 365 / Desktop | **Full Support** | Native number formats, styles, multi-sheets, auto-filters. |
| Excel for Web | **Full Support** | Fully compatible with Excel Online spreadsheet viewer. |
| LibreOffice / Google Sheets | **Best-Effort** | Compatible OpenXML standard structures and formulas. |
| Standard Business PDF | **Primary PDF Output** | Generated via Syncfusion Flutter PDF. |
| Password-Protected PDF | **Supported** | Standard 128-bit encryption with user & owner permissions. |
| Archival PDF/A | **Supported** | PDF/A-1b conformance profile. |

## Security & PDF/A Incompatibility

> **Important Rule:** Under the PDF ISO specification, **PDF/A archival conformance and PDF encryption are mutually exclusive**. The reporting engine will reject configurations requesting both with an explicit `ArgumentError`.

```dart
// Valid: Password protection
const pdfOpts = PdfExportOptions(
  enableEncryption: true,
  userPassword: 'secretPassword',
);

// Invalid: Throws ArgumentError
const invalidOpts = PdfExportOptions(
  enableEncryption: true,
  pdfAConformance: 'PDF/A-1b',
);
```
