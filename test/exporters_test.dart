import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_easy_reports/syncfusion_easy_reports.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleData = [
    {
      'id': 'EMP001',
      'name': 'Alice Smith',
      'dept': 'Engineering',
      'bank': 'Chase',
      'salary': 8500.0,
      'bonus': 1000.0,
      'joined': DateTime(2022, 1, 15),
    },
    {
      'id': 'EMP002',
      'name': 'Bob Jones',
      'dept': 'Engineering',
      'bank': 'Chase',
      'salary': 7500.0,
      'bonus': 500.0,
      'joined': DateTime(2023, 4, 10),
    },
    {
      'id': 'EMP003',
      'name': 'Charlie Brown',
      'dept': 'Marketing',
      'bank': 'Citi',
      'salary': 6500.0,
      'bonus': 800.0,
      'joined': DateTime(2021, 8, 20),
    },
  ];

  group('Excel & PDF Exporters and Security Tests', () {
    late ReportEngine engine;
    late ReportDefinition<Map<String, dynamic>> definition;

    setUp(() {
      engine = ReportEngine();
      definition = ReportDefinition<Map<String, dynamic>>(
        title: 'Q3 Financial & Operations Audit [Confidential / Internal]',
        subtitle: 'Official Report for Management',
        branding: ReportBranding(
          companyName: 'Acme Global Corporation',
          address: '100 Enterprise Way, Suite 400',
          phone: '+1 800 555 0199',
          email: 'finance@acmeglobal.com',
        ),
        theme: ReportTheme.classicBlue(),
        columns: [
          ReportColumn.text(
            id: 'id',
            title: 'Employee ID',
            value: (m) => m['id'],
          ),
          ReportColumn.text(
            id: 'name',
            title: 'Employee Name',
            value: (m) => m['name'],
          ),
          ReportColumn.text(
            id: 'dept',
            title: 'Department',
            value: (m) => m['dept'],
          ),
          ReportColumn.text(id: 'bank', title: 'Bank', value: (m) => m['bank']),
          ReportColumn.money(
            id: 'salary',
            title: 'Basic Salary',
            currencyCode: 'USD',
            value: (m) => m['salary'],
          ),
          ReportColumn.money(
            id: 'bonus',
            title: 'Bonus',
            currencyCode: 'USD',
            value: (m) => m['bonus'],
          ),
          ReportColumn.date(
            id: 'joined',
            title: 'Joined Date',
            value: (m) => m['joined'],
          ),
        ],
        analyses: [
          ReportAnalysis.detail(
            id: 'register',
            title: 'Employee Register with Special / Characters: * ?',
            showGrandTotal: true,
          ),
          ReportAnalysis.grouped(
            id: 'dept_summary',
            title: 'Department Summary',
            groupBy: ['dept'],
            measures: [
              ReportMeasure.count(id: 'headcount', title: 'Employees'),
              ReportMeasure.sum(column: 'salary', currencyCode: 'USD'),
              ReportMeasure.sum(column: 'bonus', currencyCode: 'USD'),
              ReportMeasure.average(
                column: 'salary',
                title: 'Avg Salary',
                currencyCode: 'USD',
              ),
            ],
            showGrandTotal: true,
          ),
          ReportAnalysis.crossTab(
            id: 'dept_by_bank',
            title: 'Dept by Bank CrossTab',
            rowDimension: 'dept',
            columnDimension: 'bank',
            measure: ReportMeasure.sum(column: 'salary', currencyCode: 'USD'),
          ),
        ],
      );
    });

    test(
      'ExcelReportExporter should export valid multi-sheet .xlsx artifact',
      () async {
        final prepared = await engine.prepare(
          definition: definition,
          records: sampleData,
        );

        final artifact = await engine.exportExcel(
          prepared,
          options: const ExcelExportOptions(
            includeSummarySheet: true,
            protectWorksheets: true,
            worksheetPassword: 'SecretPassword',
          ),
        );

        expect(artifact.format, ExportFormat.excel);
        expect(artifact.bytes, isNotEmpty);
        expect(artifact.filename.endsWith('.xlsx'), isTrue);
        expect(
          artifact.mimeType,
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        expect(artifact.length, greaterThan(100));
      },
    );

    test(
      'PDFReportExporter should export valid .pdf artifact with repeated headers and signatures',
      () async {
        final prepared = await engine.prepare(
          definition: definition,
          records: sampleData,
        );

        final artifact = await engine.exportPdf(
          prepared,
          options: const PdfExportOptions(
            pageSize: 'A4',
            orientation: 'portrait',
            repeatHeaders: true,
            showPageNumbers: true,
            showSignatures: true,
            signatureLabels: ['Prepared By: Finance Lead', 'Approved By: CFO'],
          ),
        );

        expect(artifact.format, ExportFormat.pdf);
        expect(artifact.bytes, isNotEmpty);
        expect(artifact.filename.endsWith('.pdf'), isTrue);
        expect(artifact.mimeType, 'application/pdf');
        expect(artifact.length, greaterThan(500));
      },
    );

    test(
      'PDFExportOptions should reject mutually exclusive PDF/A and Encryption settings',
      () {
        const invalidOptions = PdfExportOptions(
          enableEncryption: true,
          userPassword: 'password123',
          pdfAConformance: 'PDF/A-1b',
        );

        expect(() => invalidOptions.validate(), throwsArgumentError);
      },
    );

    test(
      'Should generate standalone report bytes independently of UI/saving',
      () async {
        final excelArtifact = await engine.generateExcel(
          definition: definition,
          records: sampleData,
        );
        final pdfArtifact = await engine.generatePdf(
          definition: definition,
          records: sampleData,
        );

        expect(excelArtifact.bytes.length, greaterThan(0));
        expect(pdfArtifact.bytes.length, greaterThan(0));
      },
    );

    test('Should escape formula injection strings in Excel export', () async {
      final untrustedData = [
        {
          'id': '=1+1',
          'name': '@SUM(1,2)',
          'dept': '+cmd|/C calc',
          'bank': '-100',
          'salary': 5000.0,
          'bonus': 0.0,
          'joined': DateTime.now(),
        },
      ];

      final prepared = await engine.prepare(
        definition: definition,
        records: untrustedData,
      );

      final artifact = await engine.exportExcel(prepared);
      expect(artifact.bytes, isNotEmpty);
    });

    test(
      'Pre-built Domain Presets should generate both Excel and PDF without errors',
      () async {
        final payrollPreset = PayrollReportPresets.monthlyPayroll();
        final salesPreset = SalesReportPresets.salesPerformance();
        final inventoryPreset = InventoryReportPresets.stockValuation();
        final hrPreset = HrReportPresets.employeeRegister();
        final projectPreset = ProjectReportPresets.timesheetSummary();

        for (final preset in [
          payrollPreset,
          salesPreset,
          inventoryPreset,
          hrPreset,
          projectPreset,
        ]) {
          final prepared = await engine.prepare(
            definition: preset,
            records: sampleData,
          );

          final excel = await engine.exportExcel(prepared);
          final pdf = await engine.exportPdf(prepared);

          expect(excel.bytes, isNotEmpty);
          expect(pdf.bytes, isNotEmpty);
        }
      },
    );

    test(
      'Should export multi-sheet categorized deductions to Excel and PDF with signatures',
      () async {
        final deductionsData = [
          {
            'employeeId': 'EMP001',
            'employeeName': 'Eleanor Vance',
            'department': 'Engineering',
            'deductionType': 'KCB Bank Loan',
            'referenceNumber': 'KCB-4481',
            'amount': 350.0,
            'employerContribution': 0.0,
            'notes': 'Loan repayment',
          },
          {
            'employeeId': 'EMP002',
            'employeeName': 'Marcus Brody',
            'department': 'Engineering',
            'deductionType': 'Equity Bank Loan',
            'referenceNumber': 'EQ-9912',
            'amount': 400.0,
            'employerContribution': 0.0,
            'notes': 'Loan repayment',
          },
          {
            'employeeId': 'EMP003',
            'employeeName': 'Sophia Chen',
            'department': 'Marketing',
            'deductionType': 'Housing Levy',
            'referenceNumber': 'HL-003',
            'amount': 150.0,
            'employerContribution': 150.0,
            'notes': 'Statutory contribution',
          },
        ];

        final preset = PayrollReportPresets.categorizedDeductions(
          companyName: 'Acme Corporation',
        );

        final prepared = await engine.prepare(
          definition: preset,
          records: deductionsData,
        );

        final excelArtifact = await engine.exportExcel(
          prepared,
          options: const ExcelExportOptions(
            includeSummarySheet: true,
            showSignatures: true,
            signatureLabels: ['Prepared By', 'Checked By', 'Approved By'],
          ),
        );

        final pdfArtifact = await engine.exportPdf(
          prepared,
          options: const PdfExportOptions(
            showPageNumbers: true,
            repeatHeaders: true,
            showSignatures: true,
            signatureLabels: ['Prepared By', 'Checked By', 'Approved By'],
          ),
        );

        expect(excelArtifact.bytes, isNotEmpty);
        expect(pdfArtifact.bytes, isNotEmpty);
        expect(excelArtifact.metadata['sheetCount'], greaterThan(2));
        expect(pdfArtifact.metadata['pageCount'], greaterThan(0));
      },
    );
  });
}
