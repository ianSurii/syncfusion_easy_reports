import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_easy_reports/syncfusion_easy_reports.dart';
import 'package:syncfusion_easy_reports/src/utils/image_geometry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fitImageWithinBounds preserves logo aspect ratio', () {
    final squareLogo = fitImageWithinBounds(
      imageWidth: 512,
      imageHeight: 512,
      maxWidth: 90,
      maxHeight: 45,
    );
    final wideLogo = fitImageWithinBounds(
      imageWidth: 300,
      imageHeight: 100,
      maxWidth: 90,
      maxHeight: 45,
    );

    expect(squareLogo.width, 45);
    expect(squareLogo.height, 45);
    expect(wideLogo.width, 90);
    expect(wideLogo.height, 30);
  });

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

    test(
      'ReportTheme default and pre-defined factories should construct correctly',
      () {
        final def = ReportTheme.classicBlue();
        expect(def.primaryColor, '#1565C0');

        final green = ReportTheme.forestGreen();
        expect(green.primaryColor, '#2E7D32');

        final dark = ReportTheme.corporateDark();
        expect(dark.primaryColor, '#37474F');

        final slate = ReportTheme.slateGrey();
        expect(slate.primaryColor, '#455A64');
      },
    );
  });

  group('Excel & PDF Generator Core Tests', () {
    test(
      'ExcelReportGenerator should build sheet bytes without exception',
      () async {
        final excelGen = ExcelReportGenerator();

        final table = ReportTable(
          headers: ['Name', 'Salary'],
          rows: const [
            ['John Doe', 5000.00],
            ['Jane Smith', 6000.00],
          ],
          currencyColumnIndices: const [1],
          currencySymbol: r'$',
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
      },
    );

    test(
      'PdfReportGenerator should build PDF document bytes without exception',
      () async {
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
      },
    );
  });

  group('Excel Template Service Tests', () {
    test(
      'ExcelTemplateService should generate template and parse it back correctly',
      () async {
        final templateService = ExcelTemplateService();

        final columns = [
          ExcelTemplateColumn(name: 'ID', sampleValue: 'EMP001'),
          ExcelTemplateColumn(
            name: 'Is Married',
            sampleValue: 'true',
            dropdownList: const ['true', 'false'],
          ),
          ExcelTemplateColumn(name: 'Performance Score', sampleValue: '95.5'),
        ];

        // Generate template bytes
        final bytes = await templateService.generateTemplate(columns: columns);
        expect(bytes, isNotEmpty);

        // Parse the generated template bytes back to Dart structures
        final List<Map<String, dynamic>> records = templateService
            .parseExcelBytes(bytes);

        // We expect 1 record (the sample value row)
        expect(records, isNotEmpty);
        expect(records.length, 1);

        final firstRecord = records.first;
        expect(firstRecord['ID'], 'EMP001');
        expect(firstRecord['Is Married'], true); // Autotyped to boolean
        expect(firstRecord['Performance Score'], 95.5); // Autotyped to double
      },
    );
  });

  group('BrandingLayout & Dynamic Signature Tests', () {
    final sampleData = [
      {
        'id': 'EMP01',
        'name': 'Alice Smith',
        'dept': 'Engineering',
        'salary': 8500.0,
      },
      {'id': 'EMP02', 'name': 'Bob Jones', 'dept': 'Sales', 'salary': 6200.0},
      {
        'id': 'EMP03',
        'name': 'Carol White',
        'dept': 'Marketing',
        'salary': 5900.0,
      },
    ];

    test(
      'EasyReport generates Excel and PDF with stacked branding and split signatures',
      () async {
        final report = EasyReport.fromMaps(
          data: sampleData,
          title: 'Monthly Compensation',
          branding: ReportBranding(
            companyName: 'Acme Global Corp',
            address: '742 Evergreen Terrace, Springfield, OR',
            phone: '+1 555-0199',
            email: 'finance@acme.com',
            layout: BrandingLayout.stacked,
          ),
          showSignatures: true,
          signatureLayout: SignatureLayout.split,
          signatureBlocks: [
            ReportSignature(
              title: 'Prepared By',
              name: 'Eleanor Vance',
              date: 'October 04, 2026',
            ),
            ReportSignature(
              title: 'Approved By',
              name: 'Julian Hayes',
              date: 'October 05, 2026',
              isRightAligned: true,
            ),
          ],
        );

        final excelArtifact = await report.toExcel();
        expect(excelArtifact.bytes, isNotEmpty);
        expect(
          excelArtifact.mimeType,
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );

        final pdfArtifact = await report.toPdf();
        expect(pdfArtifact.bytes, isNotEmpty);
        expect(pdfArtifact.mimeType, 'application/pdf');
      },
    );

    test(
      'EasyReport generates Excel with side-by-side branding and vertical transposed signatures',
      () async {
        final report = EasyReport.fromMaps(
          data: sampleData,
          title: 'Department Payroll',
          branding: ReportBranding(
            companyName: 'Acme Global Corp',
            address: '100 Silicon Way, Tech City, CA',
            layout: BrandingLayout.sideBySide,
          ),
          showSignatures: true,
          signatureLayout: SignatureLayout.vertical,
          signatureBlocks: [
            ReportSignature.filled(
              title: 'Prepared By',
              name: 'John Doe',
              date: '2026-10-04',
            ),
            ReportSignature.blank('Checked By'),
            ReportSignature.filled(
              title: 'Approved By',
              name: 'Jane Smith',
              date: '2026-10-05',
            ),
          ],
        );

        final excel = await report.toExcel();
        expect(excel.bytes, isNotEmpty);
      },
    );

    test(
      'EasyReport generates Excel with topRightLogo branding and horizontal signatures',
      () async {
        final report = EasyReport.fromMaps(
          data: sampleData,
          title: 'Executive Summary',
          branding: ReportBranding(
            companyName: 'Acme Global Corp',
            address: '42 Wallaby Way, Sydney',
            phone: '+61 2 9999 9999',
            layout: BrandingLayout.topRightLogo,
          ),
          showSignatures: true,
          signatureLayout: SignatureLayout.horizontal,
        );

        final excel = await report.toExcel();
        expect(excel.bytes, isNotEmpty);

        final pdf = await report.toPdf();
        expect(pdf.bytes, isNotEmpty);
      },
    );

    test(
      'toTitleCase correctly formats underscore-separated keys and acronyms',
      () {
        expect(toTitleCase('count'), 'Count');
        expect(toTitleCase('basic_sum'), 'Basic Sum');
        expect(toTitleCase('net_avg'), 'Net Avg');
        expect(toTitleCase('net_min'), 'Net Min');
        expect(toTitleCase('net_maxs'), 'Net Maxs');
        expect(toTitleCase('tax_vat_amount'), 'Tax VAT Amount');
        expect(toTitleCase('user_id'), 'User ID');
        expect(toTitleCase('total_kpi_score'), 'Total KPI Score');
      },
    );

    test(
      'PdfExportOptions and ReportSettings support landscape customization',
      () {
        final portraitOpts = PdfExportOptions(
          orientation: 'portrait',
          pageOrientation: PdfPageOrientation.portrait,
        );
        expect(portraitOpts.isLandscape, isFalse);
        expect(portraitOpts.effectiveOrientation, PdfPageOrientation.portrait);

        final landscapeOpts = PdfExportOptions(
          pageOrientation: PdfPageOrientation.landscape,
        );
        expect(landscapeOpts.isLandscape, isTrue);
        expect(
          landscapeOpts.effectiveOrientation,
          PdfPageOrientation.landscape,
        );

        final strLandscapeOpts = PdfExportOptions(orientation: 'landscape');
        expect(strLandscapeOpts.isLandscape, isTrue);
        expect(
          strLandscapeOpts.effectiveOrientation,
          PdfPageOrientation.landscape,
        );
      },
    );

    test(
      'PaymentDetailsPosition and vertical signatures export successfully to PDF and Excel',
      () async {
        const payment = ReportPaymentDetails(
          position: PaymentDetailsPosition.belowSummary,
          bankName: 'Standard Chartered',
          accountName: 'Antigravity Ltd',
          accountNumber: '0108044921000',
          termsOrNotes: ['Net 30 days'],
        );

        final summaryItems = [
          ReportSummaryItem.subtotal(1000.0, currencyCode: 'USD'),
          ReportSummaryItem.tax('Tax / VAT (16%)', 160.0, currencyCode: 'USD'),
          ReportSummaryItem.total(1160.0, currencyCode: 'USD'),
          ReportSummaryItem.balanceDue(1160.0, currencyCode: 'USD'),
        ];

        final signatures = [
          ReportSignature(
            title: 'Prepared By',
            name: 'Eleanor Vance',
            date: '2026-10-04',
          ),
          ReportSignature(
            title: 'Checked By',
            name: 'Marcus Brody',
            date: '2026-10-04',
          ),
          ReportSignature(
            title: 'Approved By',
            name: 'Julian Hayes',
            date: '2026-10-05',
          ),
          ReportSignature(
            title: 'Authorized By',
            name: 'Amara Okafor',
            date: '2026-10-05',
          ),
        ];

        // Test belowSummary position
        final reportBelow = EasyReport.fromMaps(
          data: sampleData,
          title: 'Invoice Below Summary',
          paymentDetails: payment,
          paymentDetailsPosition: PaymentDetailsPosition.belowSummary,
          summaryItems: summaryItems,
          showSignatures: true,
          signatureLayout: SignatureLayout.vertical,
        );

        final pdfBelow = await reportBelow.exportPdf(
          options: PdfExportOptions(
            pageOrientation: PdfPageOrientation.landscape,
            paymentDetailsPosition: PaymentDetailsPosition.belowSummary,
            signatureLayout: SignatureLayout.vertical,
            signatures: signatures,
          ),
        );
        expect(pdfBelow.bytes, isNotEmpty);

        final excelBelow = await reportBelow.exportExcel(
          options: ExcelExportOptions(
            paymentDetailsPosition: PaymentDetailsPosition.belowSummary,
            signatureLayout: SignatureLayout.vertical,
            signatures: signatures,
          ),
        );
        expect(excelBelow.bytes, isNotEmpty);

        // Test afterSignatures position
        final reportAfter = EasyReport.fromMaps(
          data: sampleData,
          title: 'Invoice After Signatures',
          paymentDetails: payment.copyWith(
            position: PaymentDetailsPosition.afterSignatures,
          ),
          paymentDetailsPosition: PaymentDetailsPosition.afterSignatures,
          summaryItems: summaryItems,
          showSignatures: true,
          signatureLayout: SignatureLayout.vertical,
        );

        final pdfAfter = await reportAfter.exportPdf(
          options: PdfExportOptions(
            pageOrientation: PdfPageOrientation.portrait,
            paymentDetailsPosition: PaymentDetailsPosition.afterSignatures,
            signatureLayout: SignatureLayout.vertical,
            signatures: signatures,
          ),
        );
        expect(pdfAfter.bytes, isNotEmpty);

        final excelAfter = await reportAfter.exportExcel(
          options: ExcelExportOptions(
            paymentDetailsPosition: PaymentDetailsPosition.afterSignatures,
            signatureLayout: SignatureLayout.vertical,
            signatures: signatures,
          ),
        );
        expect(excelAfter.bytes, isNotEmpty);
      },
    );
  });
}
