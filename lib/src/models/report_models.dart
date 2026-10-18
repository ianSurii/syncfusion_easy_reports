import 'package:syncfusion_flutter_pdf/pdf.dart' show PdfPageOrientation;

/// Section rendering orientation
enum ReportSectionOrientation {
  /// Renders data as a standard column-based grid table (left-to-right)
  horizontal,

  /// Renders data rows vertically (as stacked key-value pairs)
  vertical,
}

/// Visual layout arrangement for the report branding header
enum BrandingLayout {
  /// Logo on top, followed cleanly by Company Name, Address, and Contacts with safe vertical spacing.
  stacked,

  /// Logo on the left, with Company Name, Address, and Contacts side-by-side to the right.
  sideBySide,

  /// Company Name, Address, and Contacts on the left, with the logo positioned on the top right.
  topRightLogo,
}

/// Branding and contact information displayed in report headers and logos
class ReportBranding {
  final String? companyName;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl; // Network URL to download logo
  final String? logoPath; // Local assets path (e.g. 'assets/logo.png')
  final List<int>? logoBytes; // Direct in-memory image bytes
  final double? logoWidth; // Logo width in points/pixels
  final double? logoHeight; // Logo height in points/pixels
  final String? reportTitle; // Backup title
  final DateTime? reportDate; // Report generation timestamp
  final Map<String, dynamic>? customData; // Extra header key-value fields
  final BrandingLayout layout; // Layout arrangement for logo and text
  final String? taxId; // Tax / VAT registration ID

  ReportBranding({
    this.companyName,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.logoPath,
    this.logoBytes,
    this.logoWidth = 90,
    this.logoHeight = 45,
    this.reportTitle,
    this.reportDate,
    this.customData,
    this.layout = BrandingLayout.stacked,
    this.taxId,
  });

  /// Clone with new bytes
  ReportBranding copyWithBytes(List<int> bytes) {
    return ReportBranding(
      companyName: companyName,
      address: address,
      phone: phone,
      email: email,
      logoUrl: logoUrl,
      logoPath: logoPath,
      logoBytes: bytes,
      logoWidth: logoWidth,
      logoHeight: logoHeight,
      reportTitle: reportTitle,
      reportDate: reportDate,
      customData: customData,
      layout: layout,
    );
  }
}

/// Styling configuration for colors, sizes, paddings, and theme constants
class ReportTheme {
  final String primaryColor;
  final String accentColor;
  final String headerBackgroundColor;
  final String headerTextColor;
  final String groupHeaderBackgroundColor;
  final String groupHeaderTextColor;
  final String totalsBackgroundColor;
  final String totalsTextColor;
  final String customDataHeaderColor;
  final String customDataValueColor;
  final String footerDataHeaderColor;
  final String footerDataValueColor;
  final String zebraLightColor;
  final String zebraDarkColor;
  final String borderColor;
  final String fontFamily;

  final double fontSizeTitle;
  final double fontSizeHeader;
  final double fontSizeBody;
  final double fontSizeTotals;
  final double fontSizeCustomDataHeader;
  final double fontSizeCustomDataValue;
  final double fontSizeFooterDataHeader;
  final double fontSizeFooterDataValue;

  final double cellPadding;
  final double itemSpacing;
  final double sectionSpacing;
  final String totalsAlignment; // 'left', 'center', 'right'

  ReportTheme({
    this.primaryColor = '#1565C0',
    this.accentColor = '#0D47A1',
    this.headerBackgroundColor = '#1565C0',
    this.headerTextColor = '#FFFFFF',
    this.groupHeaderBackgroundColor = '#E3F2FD',
    this.groupHeaderTextColor = '#0D47A1',
    this.totalsBackgroundColor = '#FFF9C4',
    this.totalsTextColor = '#000000',
    this.customDataHeaderColor = '#000000',
    this.customDataValueColor = '#555555',
    this.footerDataHeaderColor = '#000000',
    this.footerDataValueColor = '#555555',
    this.zebraLightColor = '#F5F5F5',
    this.zebraDarkColor = '#FFFFFF',
    this.borderColor = '#BDBDBD',
    this.fontFamily = 'Arial',
    this.fontSizeTitle = 16,
    this.fontSizeHeader = 10,
    this.fontSizeBody = 10,
    this.fontSizeTotals = 10,
    this.fontSizeCustomDataHeader = 10,
    this.fontSizeCustomDataValue = 10,
    this.fontSizeFooterDataHeader = 10,
    this.fontSizeFooterDataValue = 10,
    this.cellPadding = 5.0,
    this.itemSpacing = 5.0,
    this.sectionSpacing = 15.0,
    this.totalsAlignment = 'right',
  });

  /// Predefined Blue Corporate Theme
  factory ReportTheme.classicBlue({String fontFamily = 'Arial'}) =>
      ReportTheme(fontFamily: fontFamily);

  /// Predefined Clean Green Theme
  factory ReportTheme.forestGreen({String fontFamily = 'Arial'}) => ReportTheme(
    primaryColor: '#2E7D32',
    accentColor: '#1B5E20',
    headerBackgroundColor: '#2E7D32',
    groupHeaderBackgroundColor: '#E8F5E9',
    groupHeaderTextColor: '#1B5E20',
    totalsBackgroundColor: '#E8F5E9',
    borderColor: '#C8E6C9',
    fontFamily: fontFamily,
  );

  /// Predefined Dark Slate Theme
  factory ReportTheme.corporateDark({String fontFamily = 'Arial'}) =>
      ReportTheme(
        primaryColor: '#37474F',
        accentColor: '#212121',
        headerBackgroundColor: '#37474F',
        groupHeaderBackgroundColor: '#ECEFF1',
        groupHeaderTextColor: '#263238',
        totalsBackgroundColor: '#CFD8DC',
        borderColor: '#B0BEC5',
        fontFamily: fontFamily,
      );

  /// Predefined Slate Grey Theme
  factory ReportTheme.slateGrey({String fontFamily = 'Arial'}) => ReportTheme(
    primaryColor: '#455A64',
    accentColor: '#37474F',
    headerBackgroundColor: '#455A64',
    groupHeaderBackgroundColor: '#F0F4F8',
    groupHeaderTextColor: '#273238',
    totalsBackgroundColor: '#E1E8ED',
    borderColor: '#CFD8DC',
    fontFamily: fontFamily,
  );
}

/// Represents formatted tabular data rows with custom column structures
class ReportTable {
  final List<String> headers;
  final List<List<dynamic>> rows;
  final List<double>? columnWidths; // Point sizes for widths
  final Map<int, String>? columnAlignments; // index -> 'left'/'center'/'right'
  final List<int>? currencyColumnIndices;
  final List<int>? numberColumnIndices;
  final List<int>? summationColumnIndices;
  final String? currencySymbol;
  final bool calculateTotals;
  final List<String>? totalsRow; // Manually forced totals row values
  final bool showHeaders;
  final bool showBorders;
  final List<int>? groupHeaderIndices; // row indices formatted as headers
  final List<int>? groupTotalIndices; // row indices formatted as group totals

  ReportTable({
    required this.headers,
    required this.rows,
    this.columnWidths,
    this.columnAlignments,
    this.currencyColumnIndices,
    this.numberColumnIndices,
    this.summationColumnIndices,
    this.currencySymbol = '',
    this.calculateTotals = false,
    this.totalsRow,
    this.showHeaders = true,
    this.showBorders = true,
    this.groupHeaderIndices,
    this.groupTotalIndices,
  });
}

/// A structured segment of the report
class ReportSection {
  final String? title;
  final String? description;
  final Map<String, String>? customData; // Key-value details for this section
  final ReportTable? table;
  final ReportSectionOrientation orientation;
  final double spacing;

  ReportSection({
    this.title,
    this.description,
    this.customData,
    this.table,
    this.orientation = ReportSectionOrientation.horizontal,
    this.spacing = 15.0,
  });
}

/// Layout and security settings applied at document-level
class ReportSettings {
  final String pageSize; // 'A4', 'A5', 'Letter', 'Legal'
  final String orientation; // 'portrait', 'landscape'
  final PdfPageOrientation? pageOrientation;
  final double margin;
  final String? userPassword; // For viewing reports
  final String? ownerPassword; // For editing security rules

  ReportSettings({
    this.pageSize = 'A4',
    this.orientation = 'portrait',
    this.pageOrientation,
    this.margin = 10.0,
    this.userPassword,
    this.ownerPassword,
  });
}

/// Consolidated package containing all sections, themes, and layouts
class ReportData {
  final String title;
  final List<ReportSection> sections;
  final ReportBranding? branding;
  final Map<String, String>? customData; // Global key-value stats
  final Map<String, String>? footerData; // Signature dates, signoffs
  final ReportSettings? settings;
  final ReportTheme? theme;

  ReportData({
    required this.title,
    required this.sections,
    this.branding,
    this.customData,
    this.footerData,
    this.settings,
    this.theme,
  });
}

/// Orientation / layout mode for signature blocks
enum SignatureLayout {
  /// Adapts layout based on page orientation (vertical/stacked in portrait, horizontal/split in landscape)
  adaptive,

  /// Signatures placed horizontally across columns
  horizontal,

  /// Signatures stacked vertically row-by-row (transposed: rows instead of columns)
  vertical,

  /// Split: Left side (Prepared By & Date), Right side (Checked By & Approved By / Authorized By)
  split,
}

/// Table border styling for clean, professional executive and invoice looks
enum TableBorderStyle {
  /// Clean modern aesthetic: subtle header bottom border, total double-line,
  /// with no vertical lines and clean row whitespace.
  clean,

  /// Horizontal divider borders between rows only, no vertical lines.
  horizontalOnly,

  /// Minimalist: only the header underline and total line, completely borderless body.
  headerAndTotalOnly,

  /// Full bounding grid around every cell.
  grid,

  /// No borders at all.
  none,
}

/// Dynamic chart / graph visualization types
enum ReportChartType { bar, column, pie, line }

/// Configuration for dynamic charts rendered alongside or within report analyses
class ReportChartConfig {
  final String? title;
  final ReportChartType type;
  final String categoryColumn;
  final String measureColumn;
  final int topN;
  final double height;
  final bool showValues;
  final bool showLegend;

  const ReportChartConfig({
    this.title,
    this.type = ReportChartType.column,
    required this.categoryColumn,
    required this.measureColumn,
    this.topN = 8,
    this.height = 140,
    this.showValues = true,
    this.showLegend = true,
  });
}

/// Individual financial summary line item (e.g. Subtotal, Tax/VAT, Total, Balance Due)
class ReportSummaryItem {
  final String label;
  final dynamic value;
  final String? currencyCode;
  final bool isBold;
  final bool isNegative;
  final bool isEmphasized;
  final bool showTopBorder;
  final bool showDoubleBottomBorder;

  const ReportSummaryItem({
    required this.label,
    required this.value,
    this.currencyCode,
    this.isBold = false,
    this.isNegative = false,
    this.isEmphasized = false,
    this.showTopBorder = false,
    this.showDoubleBottomBorder = false,
  });

  factory ReportSummaryItem.subtotal(num amount, {String? currencyCode}) =>
      ReportSummaryItem(
        label: 'Subtotal',
        value: amount,
        currencyCode: currencyCode,
      );

  factory ReportSummaryItem.tax(
    String label,
    num amount, {
    String? currencyCode,
  }) => ReportSummaryItem(
    label: label,
    value: amount,
    currencyCode: currencyCode,
  );

  factory ReportSummaryItem.total(num amount, {String? currencyCode}) =>
      ReportSummaryItem(
        label: 'Total',
        value: amount,
        currencyCode: currencyCode,
        isBold: true,
        showTopBorder: true,
      );

  factory ReportSummaryItem.balanceDue(num amount, {String? currencyCode}) =>
      ReportSummaryItem(
        label: 'Balance Due',
        value: amount,
        currencyCode: currencyCode,
        isBold: true,
        isEmphasized: true,
        showTopBorder: true,
        showDoubleBottomBorder: true,
      );
}

/// Layout position options for bank remittance / payment instructions relative to financial summaries and signatures.
enum PaymentDetailsPosition {
  /// Side by side with financial summary items (payment instructions on left, totals on right).
  sideBySide,

  /// Full-width block rendered directly after / below the financial summary totals (Subtotal, Tax, Total, Balance Due).
  belowSummary,

  /// Full-width block rendered after / below the signatures block at the bottom of the document.
  afterSignatures,
}

/// Bank remittance, wire payment details, and terms/notes displayed at the bottom of reports
class ReportPaymentDetails {
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? branch;
  final String? swiftCode;
  final String? iban;
  final List<String> termsOrNotes;
  final String? title;
  final PaymentDetailsPosition position;

  const ReportPaymentDetails({
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.branch,
    this.swiftCode,
    this.iban,
    this.termsOrNotes = const [],
    this.title,
    this.position = PaymentDetailsPosition.sideBySide,
  });

  ReportPaymentDetails copyWith({
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? branch,
    String? swiftCode,
    String? iban,
    List<String>? termsOrNotes,
    String? title,
    PaymentDetailsPosition? position,
  }) {
    return ReportPaymentDetails(
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      branch: branch ?? this.branch,
      swiftCode: swiftCode ?? this.swiftCode,
      iban: iban ?? this.iban,
      termsOrNotes: termsOrNotes ?? this.termsOrNotes,
      title: title ?? this.title,
      position: position ?? this.position,
    );
  }
}

/// Represents an individual signature block with optional pre-filled signer name, designation, and date.
class ReportSignature {
  /// The title/role label (e.g. 'Prepared By', 'Checked By', 'Approved By', 'Authorized By', 'Date')
  final String title;

  /// Optional pre-filled signer name (if null, renders as blank line for physical signing)
  final String? name;

  /// Optional date or timestamp string (if null, renders as blank date line or omitted)
  final String? date;

  /// Whether this signature aligns to the right side (used in split layout)
  final bool isRightAligned;

  const ReportSignature({
    required this.title,
    this.name,
    this.date,
    this.isRightAligned = false,
  });

  /// Factory for a blank signature placeholder
  factory ReportSignature.blank(String title, {bool isRightAligned = false}) {
    return ReportSignature(title: title, isRightAligned: isRightAligned);
  }

  /// Factory for a pre-filled signature
  factory ReportSignature.filled({
    required String title,
    required String name,
    String? date,
    bool isRightAligned = false,
  }) {
    return ReportSignature(
      title: title,
      name: name,
      date: date,
      isRightAligned: isRightAligned,
    );
  }
}
