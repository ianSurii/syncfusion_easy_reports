/// How wide tables should be handled in PDF rendering.
enum PdfWideTableStrategy {
  /// Keep the current orientation and proportionally shrink column widths to fit the page.
  fitToWidth,

  /// Automatically switch the page to landscape if the table has more than a threshold number of columns.
  autoLandscape,

  /// Split columns into multiple consecutive vertical bands.
  splitColumns,
}

/// Options specific to Microsoft Excel (.xlsx) exports.
class ExcelExportOptions {
  /// Whether to generate a clickable Table of Contents / Overview sheet at index 0.
  final bool includeSummarySheet;

  /// Whether to freeze top header rows so they remain visible while scrolling.
  final bool freezeHeaderRow;

  /// Whether to enable native Excel AutoFilter dropdowns on detail data tables.
  final bool enableAutoFilter;

  /// Whether to output Excel formula expressions (e.g. `=SUM(C2:C10)`) for subtotals and totals.
  final bool useFormulas;

  /// Whether to apply password protection to individual worksheets.
  final bool protectWorksheets;

  /// Password for worksheet protection.
  final String? worksheetPassword;

  /// Whether to protect the entire workbook structure from adding/deleting sheets.
  final bool protectWorkbook;

  /// Password for workbook structure protection.
  final String? workbookPassword;

  /// Whether to show grid lines in worksheets.
  final bool showGridlines;

  /// Maximum length for worksheet names (Excel limit is 31).
  final int maxSheetNameLength;

  /// Custom number format string overrides.
  final Map<String, String>? customNumberFormats;

  /// Whether to render signature placeholders at the bottom of worksheets.
  final bool showSignatures;

  /// Labels for signature blocks (e.g. `['Prepared By', 'Checked By', 'Approved By', 'Authorized By']`).
  final List<String> signatureLabels;

  const ExcelExportOptions({
    this.includeSummarySheet = true,
    this.freezeHeaderRow = true,
    this.enableAutoFilter = true,
    this.useFormulas = true,
    this.protectWorksheets = false,
    this.worksheetPassword,
    this.protectWorkbook = false,
    this.workbookPassword,
    this.showGridlines = true,
    this.maxSheetNameLength = 31,
    this.customNumberFormats,
    this.showSignatures = false,
    this.signatureLabels = const ['Prepared By', 'Approved By'],
  });
}

/// Options specific to Adobe PDF (.pdf) exports.
class PdfExportOptions {
  /// Standard page size name: 'A4', 'A5', 'Letter', 'Legal'. Default is 'A4'.
  final String pageSize;

  /// Page orientation: 'portrait' or 'landscape'.
  final String orientation;

  /// Page margin in points (default: 15.0).
  final double margin;

  /// Left margin override.
  final double? marginLeft;

  /// Top margin override.
  final double? marginTop;

  /// Right margin override.
  final double? marginRight;

  /// Bottom margin override.
  final double? marginBottom;

  /// Whether to repeat table column headers across page breaks.
  final bool repeatHeaders;

  /// Whether to display dynamic "Page X of Y" pagination in the footer.
  final bool showPageNumbers;

  /// Strategy for handling wide tables that exceed the page width.
  final PdfWideTableStrategy wideTableStrategy;

  /// Column count threshold that triggers auto-landscape mode.
  final int autoLandscapeThreshold;

  /// Whether to enable PDF security/encryption.
  final bool enableEncryption;

  /// User password required to open the PDF.
  final String? userPassword;

  /// Owner password required to edit permissions or remove security.
  final String? ownerPassword;

  /// Whether printing is permitted in protected PDFs.
  final bool allowPrinting;

  /// Whether content copying is permitted in protected PDFs.
  final bool allowCopy;

  /// PDF/A archival conformance level (e.g. 'PDF/A-1b').
  /// NOTE: PDF/A and encryption are mutually exclusive under the PDF specification.
  final String? pdfAConformance;

  /// Message displayed when an analysis has 0 records.
  final String emptyStateMessage;

  /// Whether to render signature placeholders at the bottom of the document.
  final bool showSignatures;

  /// Labels for signature blocks (e.g. `['Prepared By', 'Checked By', 'Approved By']`).
  final List<String> signatureLabels;

  const PdfExportOptions({
    this.pageSize = 'A4',
    this.orientation = 'portrait',
    this.margin = 15.0,
    this.marginLeft,
    this.marginTop,
    this.marginRight,
    this.marginBottom,
    this.repeatHeaders = true,
    this.showPageNumbers = true,
    this.wideTableStrategy = PdfWideTableStrategy.autoLandscape,
    this.autoLandscapeThreshold = 6,
    this.enableEncryption = false,
    this.userPassword,
    this.ownerPassword,
    this.allowPrinting = true,
    this.allowCopy = true,
    this.pdfAConformance,
    this.emptyStateMessage =
        'No records found matching the specified criteria.',
    this.showSignatures = false,
    this.signatureLabels = const ['Prepared By', 'Approved By'],
  });

  /// Validates that encryption and PDF/A are not simultaneously requested.
  void validate() {
    if (enableEncryption && pdfAConformance != null) {
      throw ArgumentError(
        'PDF/A conformance ($pdfAConformance) and PDF encryption are incompatible options. '
        'Archival PDF/A documents cannot be encrypted.',
      );
    }
  }
}
