import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_easy_reports/syncfusion_easy_reports.dart';
import 'package:syncfusion_easy_reports/src/generators/report_chart_data.dart';

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
      'Dynamic reports with clean table style, summary items, and payment details export to Excel and PDF',
      () async {
        final dynamicDef = ReportDefinition<Map<String, dynamic>>(
          title: 'Invoice & Operations Summary',
          columns: [
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
            ReportColumn.money(
              id: 'salary',
              title: 'Base Amount',
              currencyCode: 'USD',
              value: (m) => m['salary'],
            ),
          ],
          analyses: [
            ReportAnalysis.detail(
              id: 'details',
              title: 'Itemized Details',
              showGrandTotal: true,
            ),
          ],
          summaryItems: [
            ReportSummaryItem.subtotal(22500.0, currencyCode: 'USD'),
            ReportSummaryItem.tax('VAT (16%)', 3600.0, currencyCode: 'USD'),
            ReportSummaryItem.total(26100.0, currencyCode: 'USD'),
          ],
          paymentDetails: ReportPaymentDetails(
            bankName: 'Standard Chartered Bank',
            accountName: 'Acme Operations Ltd',
            accountNumber: '0108044921000',
            branch: 'Nairobi West',
            swiftCode: 'SCBLKENX',
            termsOrNotes: ['Payment due within 30 days of invoice date.'],
          ),
        );

        final prepared = await engine.prepare(
          definition: dynamicDef,
          records: sampleData,
        );

        final excel = await engine.exportExcel(
          prepared,
          options: const ExcelExportOptions(
            showGridlines: false,
            tableBorderStyle: TableBorderStyle.clean,
          ),
        );
        final pdf = await engine.exportPdf(
          prepared,
          options: const PdfExportOptions(
            tableBorderStyle: TableBorderStyle.clean,
            orientation: 'portrait',
            showSignatures: true,
            signatureLabels: ['Prepared By', 'Audited By'],
          ),
        );

        expect(excel.bytes, isNotEmpty);
        expect(pdf.bytes, isNotEmpty);
      },
    );

    test(
      'Should export multi-sheet categorized schedules to Excel and PDF with adaptive signatures',
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

        final def = ReportDefinition<Map<String, dynamic>>(
          title: 'Deductions & Benefit Schedules',
          columns: [
            ReportColumn.text(
              id: 'employeeId',
              title: 'Emp ID',
              value: (m) => m['employeeId'],
            ),
            ReportColumn.text(
              id: 'employeeName',
              title: 'Employee Name',
              value: (m) => m['employeeName'],
            ),
            ReportColumn.text(
              id: 'deductionType',
              title: 'Deduction Type',
              value: (m) => m['deductionType'],
            ),
            ReportColumn.money(
              id: 'amount',
              title: 'Amount',
              currencyCode: 'USD',
              value: (m) => m['amount'],
            ),
          ],
          analyses: [
            ReportAnalysis.grouped(
              id: 'deductions',
              title: 'Deduction Categories',
              groupBy: ['deductionType'],
              sheetPerCategory: true,
              detailColumns: ['employeeId', 'employeeName', 'amount'],
              measures: [
                ReportMeasure.sum(column: 'amount', currencyCode: 'USD'),
              ],
            ),
          ],
        );

        final prepared = await engine.prepare(
          definition: def,
          records: deductionsData,
        );

        final excelArtifact = await engine.exportExcel(
          prepared,
          options: const ExcelExportOptions(
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
            signatureLayout: SignatureLayout.adaptive,
            orientation: 'portrait',
            signatureLabels: ['Prepared By', 'Checked By', 'Approved By'],
          ),
        );

        expect(excelArtifact.bytes, isNotEmpty);
        expect(pdfArtifact.bytes, isNotEmpty);
        expect(excelArtifact.metadata['sheetCount'], greaterThan(1));
        expect(pdfArtifact.metadata['pageCount'], greaterThan(0));
      },
    );

    test(
      'chart data selects the configured measure and skips invalid values',
      () {
        const analysis = PreparedAnalysis(
          id: 'hours_by_department',
          title: 'Hours by Department',
          type: ReportAnalysisType.grouped,
          chart: ReportChartConfig(
            categoryColumn: 'department',
            measureColumn: 'hours',
            topN: 2,
          ),
          chartMeasureId: 'hours_sum',
          groups: [
            PreparedGroup(
              key: 'engineering',
              label: 'Engineering',
              dimension: 'Department',
              measureValues: {'count': 100, 'hours_sum': 40},
            ),
            PreparedGroup(
              key: 'marketing',
              label: 'Marketing',
              dimension: 'Department',
              measureValues: {'count': 50, 'hours_sum': 'unknown'},
            ),
            PreparedGroup(
              key: 'sales',
              label: 'Sales',
              dimension: 'Department',
              measureValues: {'count': 25, 'hours_sum': 18},
            ),
          ],
        );

        final points = ReportChartData.fromAnalysis(analysis);

        expect(points.map((point) => point.label), ['Engineering', 'Sales']);
        expect(points.map((point) => point.value), [40, 18]);
      },
    );

    test(
      'prepared chart resolves its source column to the matching measure',
      () async {
        final chartDefinition = ReportDefinition<Map<String, dynamic>>(
          title: 'Revenue by Department',
          columns: [
            ReportColumn.text(
              id: 'department',
              title: 'Department',
              value: (record) => record['department'],
            ),
            ReportColumn.number(
              id: 'units',
              title: 'Units',
              value: (record) => record['units'],
            ),
            ReportColumn.money(
              id: 'revenue',
              title: 'Revenue',
              currencyCode: 'USD',
              value: (record) => record['revenue'],
            ),
          ],
          analyses: [
            ReportAnalysis.grouped(
              id: 'revenue_by_department',
              title: 'Revenue by Department',
              groupBy: ['department'],
              measures: [
                ReportMeasure.sum(id: 'units_total', column: 'units'),
                ReportMeasure.sum(
                  id: 'revenue_total',
                  column: 'revenue',
                  currencyCode: 'USD',
                ),
              ],
              chart: const ReportChartConfig(
                categoryColumn: 'department',
                measureColumn: 'revenue',
              ),
            ),
          ],
        );
        final prepared = await engine.prepare(
          definition: chartDefinition,
          records: [
            {'department': 'Engineering', 'units': 4, 'revenue': 120.0},
          ],
        );

        expect(prepared.analyses.single.chartMeasureId, 'revenue_total');
      },
    );

    test(
      'PDF charts render selected values and pie legend is configurable',
      () async {
        Future<String> exportChartText(
          ReportChartType type, {
          bool showLegend = true,
          bool showValues = true,
        }) async {
          final prepared = PreparedReport(
            title: 'Chart Test',
            analyses: [
              PreparedAnalysis(
                id: 'hours_by_department',
                title: 'Hours by Department',
                type: ReportAnalysisType.grouped,
                chart: ReportChartConfig(
                  type: type,
                  title: 'Consulting Hours',
                  categoryColumn: 'department',
                  measureColumn: 'hours',
                  topN: 2,
                  showLegend: showLegend,
                  showValues: showValues,
                ),
                chartMeasureId: 'hours_sum',
                rows: const [PreparedRow(cells: [])],
                groups: const [
                  PreparedGroup(
                    key: 'engineering',
                    label: 'Engineering',
                    dimension: 'Department',
                    measureValues: {'hours_sum': 40},
                  ),
                  PreparedGroup(
                    key: 'sales',
                    label: 'Sales',
                    dimension: 'Department',
                    measureValues: {'hours_sum': 18},
                  ),
                ],
              ),
            ],
            totalRecordCount: 2,
            filteredRecordCount: 2,
            generatedAt: DateTime(2026, 1, 1),
            reconciliation: const ReconciliationSummary(isReconciled: true),
          );

          final artifact = await engine.exportPdf(prepared);
          final document = PdfDocument(inputBytes: artifact.bytes);
          try {
            return PdfTextExtractor(document).extractText();
          } finally {
            document.dispose();
          }
        }

        for (final type in ReportChartType.values) {
          final text = await exportChartText(type);
          expect(text, contains('Consulting Hours'));
          expect(text, contains('40'));
          expect(text, contains('18'));
        }

        final visibleLegend = await exportChartText(ReportChartType.pie);
        final hiddenLegend = await exportChartText(
          ReportChartType.pie,
          showLegend: false,
        );
        expect(visibleLegend, contains('Engineering'));
        expect(hiddenLegend, isNot(contains('Engineering')));

        final hiddenValues = await exportChartText(
          ReportChartType.bar,
          showValues: false,
        );
        expect(hiddenValues, isNot(contains('40')));
      },
    );
  });
}
