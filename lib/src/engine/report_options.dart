import 'package:syncfusion_flutter_pdf/pdf.dart' show PdfPageOrientation;
import '../models/report_models.dart';

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

  /// Structured signatures with optional names and dates.
  final List<ReportSignature>? signatures;

  /// Layout orientation for signatures (adaptive, horizontal, vertical/transposed, split).
  final SignatureLayout signatureLayout;

  /// Visual border style for data tables (clean, horizontalOnly, headerAndTotalOnly, grid, none).
  final TableBorderStyle tableBorderStyle;

  /// Optional bottom financial summaries (Subtotal, Taxes, Total, Balance Due).
  final List<ReportSummaryItem>? summaryItems;

  /// Optional wire payment / bank remittance details and terms printed below the table.
  final ReportPaymentDetails? paymentDetails;

  /// Optional position override for payment details relative to totals and signatures.
  final PaymentDetailsPosition? paymentDetailsPosition;

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
    this.signatures,
    this.signatureLayout = SignatureLayout.adaptive,
    this.tableBorderStyle = TableBorderStyle.clean,
    this.summaryItems,
    this.paymentDetails,
    this.paymentDetailsPosition,
  });

  /// Resolves the active list of [ReportSignature] items.
  List<ReportSignature> get effectiveSignatures {
    if (signatures != null && signatures!.isNotEmpty) {
      return signatures!;
    }
    return signatureLabels.map((l) => ReportSignature(title: l)).toList();
  }
}

/// Options specific to Adobe PDF (.pdf) exports.
class PdfExportOptions {
  /// Standard page size name: 'A4', 'A5', 'Letter', 'Legal'. Default is 'A4'.
  final String pageSize;

  /// Page orientation string: 'portrait' or 'landscape'.
  final String orientation;

  /// Typed page orientation enum (`PdfPageOrientation.portrait` or `PdfPageOrientation.landscape`).
  /// Takes precedence over [orientation] string when specified.
  final PdfPageOrientation? pageOrientation;

  /// Effective PDF orientation enum.
  PdfPageOrientation get effectiveOrientation =>
      pageOrientation ??
      (orientation.toLowerCase() == 'landscape'
          ? PdfPageOrientation.landscape
          : PdfPageOrientation.portrait);

  /// Whether landscape orientation is active.
  bool get isLandscape => effectiveOrientation == PdfPageOrientation.landscape;

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

  /// Structured signatures with optional names and dates.
  final List<ReportSignature>? signatures;

  /// Layout orientation for signatures (adaptive, horizontal, vertical/transposed, split).
  final SignatureLayout signatureLayout;

  /// Visual border style for data tables (clean, horizontalOnly, headerAndTotalOnly, grid, none).
  final TableBorderStyle tableBorderStyle;

  /// Optional bottom financial summaries (Subtotal, Taxes, Total, Balance Due).
  final List<ReportSummaryItem>? summaryItems;

  /// Optional wire payment / bank remittance details and terms printed below the table.
  final ReportPaymentDetails? paymentDetails;

  /// Optional position override for payment details relative to totals and signatures.
  final PaymentDetailsPosition? paymentDetailsPosition;

  const PdfExportOptions({
    this.pageSize = 'A4',
    this.orientation = 'portrait',
    this.pageOrientation,
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
    this.signatures,
    this.signatureLayout = SignatureLayout.adaptive,
    this.tableBorderStyle = TableBorderStyle.clean,
    this.summaryItems,
    this.paymentDetails,
    this.paymentDetailsPosition,
  });

  /// Resolves the active list of [ReportSignature] items.
  List<ReportSignature> get effectiveSignatures {
    if (signatures != null && signatures!.isNotEmpty) {
      return signatures!;
    }
    return signatureLabels.map((l) => ReportSignature(title: l)).toList();
  }

  /// Resolves the signature layout: if [SignatureLayout.adaptive], automatically
  /// stacks signatures vertically in portrait orientation to prevent page crowding.
  SignatureLayout resolveSignatureLayout() {
    if (signatureLayout != SignatureLayout.adaptive) {
      return signatureLayout;
    }
    if (!isLandscape) {
      return SignatureLayout.vertical; // Stacked in portrait
    }
    return SignatureLayout.split;
  }

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
