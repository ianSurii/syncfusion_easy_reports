import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_easy_reports/syncfusion_easy_reports.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Report Configuration & Theme Tests', () {
    test('ReportBranding should correctly construct and clone with bytes', () {
      final branding = ReportBranding(
        companyName: 'Test Corp',
        address: '123 Test Rd',
        email: 'test@corp.com',
      );

      expect(branding.companyName, 'Test Corp');
      expect(branding.address, '123 Test Rd');
      expect(branding.email, 'test@corp.com');
      expect(branding.logoBytes, isNull);

      final cloned = branding.copyWithBytes([1, 2, 3]);
      expect(cloned.companyName, 'Test Corp');
      expect(cloned.logoBytes, isNotNull);
      expect(cloned.logoBytes!.length, 3);
    });

    test('ReportTheme default and pre-defined factories should construct correctly', () {
      final def = ReportTheme.classicBlue();
      expect(def.primaryColor, '#1565C0');

      final green = ReportTheme.forestGreen();
      expect(green.primaryColor, '#2E7D32');

      final dark = ReportTheme.corporateDark();
      expect(dark.primaryColor, '#37474F');

      final slate = ReportTheme.slateGrey();
      expect(slate.primaryColor, '#455A64');
    });
  });

  group('Excel & PDF Generator Core Tests', () {
    test('ExcelReportGenerator should build sheet bytes without exception', () async {
      final excelGen = ExcelReportGenerator();

      final table = ReportTable(
        headers: ['Name', 'Salary'],
        rows: const [
          ['John Doe', 5000.00],
          ['Jane Smith', 6000.00],
        ],
        currencyColumnIndices: const [1],
        currencySymbol: '$',
        calculateTotals: true,
      );

      final section = ReportSection(
        title: 'Payroll',
        description: 'Monthly payroll records',
        table: table,
      );

      final data = ReportData(
        title: 'Monthly Business Audit',
        sections: [section],
        branding: ReportBranding(companyName: 'Test Company'),
      );

      final bytes = await excelGen.generate(data);
      expect(bytes, isNotEmpty);
    });

    test('PdfReportGenerator should build PDF document bytes without exception', () async {
      final pdfGen = PdfReportGenerator();

      final table = ReportTable(
        headers: ['Property', 'Value'],
        rows: const [
          ['Status', 'Active'],
          ['Records Count', 10],
        ],
      );

      final section = ReportSection(
        title: 'Overview',
        description: 'System Status overview',
        table: table,
      );

      final data = ReportData(
        title: 'Quarterly Audit Report',
        sections: [section],
        branding: ReportBranding(companyName: 'Test Company'),
      );

      final bytes = await pdfGen.generate(data);
      expect(bytes, isNotEmpty);
    });
  });

  group('Excel Template Service Tests', () {
    test('ExcelTemplateService should generate template and parse it back correctly', () async {
      final templateService = ExcelTemplateService();

      final columns = [
        ExcelTemplateColumn(
          name: 'ID',
          sampleValue: 'EMP001',
        ),
        ExcelTemplateColumn(
          name: 'Is Married',
          sampleValue: 'true',
          dropdownList: const ['true', 'false'],
        ),
        ExcelTemplateColumn(
          name: 'Performance Score',
          sampleValue: '95.5',
        ),
      ];

      // Generate template bytes
      final bytes = await templateService.generateTemplate(columns: columns);
      expect(bytes, isNotEmpty);

      // Parse the generated template bytes back to Dart structures
      final List<Map<String, dynamic>> records = templateService.parseExcelBytes(bytes);

      // We expect 1 record (the sample value row)
      expect(records, isNotEmpty);
      expect(records.length, 1);

      final firstRecord = records.first;
      expect(firstRecord['ID'], 'EMP001');
      expect(firstRecord['Is Married'], true); // Autotyped to boolean
      expect(firstRecord['Performance Score'], 95.5); // Autotyped to double
    });
  });
}
