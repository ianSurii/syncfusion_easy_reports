import 'dart:typed_data';

/// Section rendering orientation
enum ReportSectionOrientation {
  /// Renders data as a standard column-based grid table (left-to-right)
  horizontal,

  /// Renders data rows vertically (as stacked key-value pairs)
  vertical,
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

  ReportBranding({
    this.companyName,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.logoPath,
    this.logoBytes,
    this.logoWidth = 100,
    this.logoHeight = 100,
    this.reportTitle,
    this.reportDate,
    this.customData,
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
    this.fontSizeTitle = 18,
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
  factory ReportTheme.classicBlue() => ReportTheme();

  /// Predefined Clean Green Theme
  factory ReportTheme.forestGreen() => ReportTheme(
        primaryColor: '#2E7D32',
        accentColor: '#1B5E20',
        headerBackgroundColor: '#2E7D32',
        groupHeaderBackgroundColor: '#E8F5E9',
        groupHeaderTextColor: '#1B5E20',
        totalsBackgroundColor: '#E8F5E9',
        borderColor: '#C8E6C9',
      );

  /// Predefined Dark Slate Theme
  factory ReportTheme.corporateDark() => ReportTheme(
        primaryColor: '#37474F',
        accentColor: '#212121',
        headerBackgroundColor: '#37474F',
        groupHeaderBackgroundColor: '#ECEFF1',
        groupHeaderTextColor: '#263238',
        totalsBackgroundColor: '#CFD8DC',
        borderColor: '#B0BEC5',
      );

  /// Predefined Slate Grey Theme
  factory ReportTheme.slateGrey() => ReportTheme(
        primaryColor: '#455A64',
        accentColor: '#37474F',
        headerBackgroundColor: '#455A64',
        groupHeaderBackgroundColor: '#F0F4F8',
        groupHeaderTextColor: '#273238',
        totalsBackgroundColor: '#E1E8ED',
        borderColor: '#CFD8DC',
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
  final double margin;
  final String? userPassword; // For viewing reports
  final String? ownerPassword; // For editing security rules

  ReportSettings({
    this.pageSize = 'A4',
    this.orientation = 'portrait',
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
