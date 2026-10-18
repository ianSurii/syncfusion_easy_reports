// ignore_for_file: avoid_print
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_easy_reports/syncfusion_easy_reports.dart';

void main() => runApp(const EasyReportsShowcase());

class EasyReportsShowcase extends StatefulWidget {
  const EasyReportsShowcase({super.key});

  @override
  State<EasyReportsShowcase> createState() => _EasyReportsShowcaseState();
}

class _EasyReportsShowcaseState extends State<EasyReportsShowcase> {
  // Default to Dark Mode as requested
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'syncfusion_easy_reports — 10x Showcase',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
      ),
      home: ShowcaseHomePage(
        onToggleTheme: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS & PRESETS
// ═══════════════════════════════════════════════════════════════════════════════

enum ReportUseCase {
  invoice,
  payroll,
  salesCrossTab,
  agingValuation,
  clinicalAudit,
}

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.department,
    required this.bank,
    required this.basicPay,
    required this.allowances,
    required this.deductions,
  });

  final String id;
  final String name;
  final String department;
  final String bank;
  final double basicPay;
  final double allowances;
  final double deductions;

  double get netPay => basicPay + allowances - deductions;
}

final List<Employee> _employees = [
  const Employee(
    id: 'EMP-101',
    name: 'Eleanor Vance',
    department: 'Engineering',
    bank: 'Standard Chartered',
    basicPay: 9200,
    allowances: 1200,
    deductions: 850,
  ),
  const Employee(
    id: 'EMP-102',
    name: 'Marcus Brody',
    department: 'Engineering',
    bank: 'Standard Chartered',
    basicPay: 8400,
    allowances: 800,
    deductions: 720,
  ),
  const Employee(
    id: 'EMP-103',
    name: 'Sophia Chen',
    department: 'Marketing',
    bank: 'Citibank',
    basicPay: 7600,
    allowances: 1500,
    deductions: 600,
  ),
  const Employee(
    id: 'EMP-104',
    name: 'Lucas Miller',
    department: 'Marketing',
    bank: 'Citibank',
    basicPay: 6900,
    allowances: 900,
    deductions: 550,
  ),
  const Employee(
    id: 'EMP-105',
    name: 'Amara Okafor',
    department: 'Sales',
    bank: 'Barclays',
    basicPay: 6500,
    allowances: 3200,
    deductions: 480,
  ),
  const Employee(
    id: 'EMP-106',
    name: 'Julian Hayes',
    department: 'Finance',
    bank: 'JPMorgan Chase',
    basicPay: 8800,
    allowances: 600,
    deductions: 910,
  ),
  const Employee(
    id: 'EMP-107',
    name: 'Zoe Patel',
    department: 'Engineering',
    bank: 'Standard Chartered',
    basicPay: 7800,
    allowances: 950,
    deductions: 880,
  ),
];

final List<Map<String, dynamic>> _invoiceItems = [
  {
    'item': 'Senior Enterprise Architecture & Consulting',
    'category': 'Architecture',
    'hours': 40,
    'rate': 185.0,
    'amount': 7400.0,
  },
  {
    'item': 'Flutter Engine & High-Performance Dart Core',
    'category': 'Core Engine',
    'hours': 35,
    'rate': 130.0,
    'amount': 4550.0,
  },
  {
    'item': 'Automated Multi-Format Export Pipelines',
    'category': 'Data Pipelines',
    'hours': 20,
    'rate': 115.0,
    'amount': 2300.0,
  },
  {
    'item': 'Continuous Integration Security & Compliance',
    'category': 'DevOps',
    'hours': 12,
    'rate': 125.0,
    'amount': 1500.0,
  },
];

final List<Map<String, dynamic>> _salesData = [
  {
    'rep': 'Alice Chen',
    'region': 'North America',
    'product': 'Cloud Suite',
    'quarter': 'Q1',
    'revenue': 42000.0,
  },
  {
    'rep': 'Alice Chen',
    'region': 'North America',
    'product': 'Cloud Suite',
    'quarter': 'Q2',
    'revenue': 58000.0,
  },
  {
    'rep': 'Bob Smith',
    'region': 'EMEA',
    'product': 'DB Core',
    'quarter': 'Q1',
    'revenue': 31000.0,
  },
  {
    'rep': 'Bob Smith',
    'region': 'EMEA',
    'product': 'DB Core',
    'quarter': 'Q2',
    'revenue': 49000.0,
  },
  {
    'rep': 'Carlos Mendez',
    'region': 'LATAM',
    'product': 'AI Analytics',
    'quarter': 'Q1',
    'revenue': 27500.0,
  },
  {
    'rep': 'Carlos Mendez',
    'region': 'LATAM',
    'product': 'AI Analytics',
    'quarter': 'Q2',
    'revenue': 36500.0,
  },
  {
    'rep': 'Diana Prince',
    'region': 'APAC',
    'product': 'Cyber Security',
    'quarter': 'Q1',
    'revenue': 51000.0,
  },
  {
    'rep': 'Diana Prince',
    'region': 'APAC',
    'product': 'Cyber Security',
    'quarter': 'Q2',
    'revenue': 64000.0,
  },
];

final List<Map<String, dynamic>> _agingData = [
  {
    'client': 'Apex Global Ltd',
    'invoice': 'INV-1091',
    'amount': 14250.0,
    'daysOverdue': 15,
    'status': 'Current',
  },
  {
    'client': 'Blue Horizon Tech',
    'invoice': 'INV-1044',
    'amount': 8900.0,
    'daysOverdue': 42,
    'status': '31-60 Days',
  },
  {
    'client': 'Cascade Retail Partners',
    'invoice': 'INV-0988',
    'amount': 22500.0,
    'daysOverdue': 78,
    'status': '60+ Days',
  },
  {
    'client': 'Delta Logistics Hub',
    'invoice': 'INV-1102',
    'amount': 6400.0,
    'daysOverdue': 8,
    'status': 'Current',
  },
  {
    'client': 'Echo Innovations LLC',
    'invoice': 'INV-1015',
    'amount': 11300.0,
    'daysOverdue': 51,
    'status': '31-60 Days',
  },
];

final List<Map<String, dynamic>> _clinicalData = [
  {
    'patientId': 'PT-8801',
    'department': 'Cardiology',
    'physician': 'Dr. Sarah Lin',
    'admissionDays': 4,
    'billAmount': 5400.0,
    'status': 'Discharged',
  },
  {
    'patientId': 'PT-8802',
    'department': 'Cardiology',
    'physician': 'Dr. Sarah Lin',
    'admissionDays': 7,
    'billAmount': 8900.0,
    'status': 'Inpatient',
  },
  {
    'patientId': 'PT-8803',
    'department': 'Neurology',
    'physician': 'Dr. Robert Ross',
    'admissionDays': 3,
    'billAmount': 4200.0,
    'status': 'Discharged',
  },
  {
    'patientId': 'PT-8804',
    'department': 'Orthopedics',
    'physician': 'Dr. Emily Watson',
    'admissionDays': 5,
    'billAmount': 6750.0,
    'status': 'Discharged',
  },
  {
    'patientId': 'PT-8805',
    'department': 'Pediatrics',
    'physician': 'Dr. Michael Chang',
    'admissionDays': 2,
    'billAmount': 2100.0,
    'status': 'Discharged',
  },
];

const List<ReportSignature> _defaultSignatures = [
  ReportSignature(
    title: 'Prepared By',
    name: 'Eleanor Vance (Senior Accountant)',
    date: 'October 04, 2026',
  ),
  ReportSignature(
    title: 'Checked By',
    name: 'Marcus Brody (Finance Lead)',
    date: 'October 04, 2026',
  ),
  ReportSignature(
    title: 'Approved By',
    name: 'Julian Hayes (VP Finance)',
    date: 'October 05, 2026',
  ),
  ReportSignature(
    title: 'Authorized By',
    name: 'Amara Okafor (Managing Director)',
    date: 'October 05, 2026',
  ),
];

// ═══════════════════════════════════════════════════════════════════════════════
// ONE-PAGE SHOWCASE HOME
// ═══════════════════════════════════════════════════════════════════════════════

class ShowcaseHomePage extends StatefulWidget {
  const ShowcaseHomePage({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  final VoidCallback onToggleTheme;
  final bool isDark;

  @override
  State<ShowcaseHomePage> createState() => _ShowcaseHomePageState();
}

class _ShowcaseHomePageState extends State<ShowcaseHomePage> {
  ReportUseCase _selectedCase = ReportUseCase.invoice;
  bool _busy = false;
  String? _statusMessage;
  ReportArtifact? _lastArtifact;

  // Customization controls
  TableBorderStyle _borderStyle = TableBorderStyle.clean;
  PdfPageOrientation _pdfOrientation = PdfPageOrientation.portrait;
  PaymentDetailsPosition _paymentPosition = PaymentDetailsPosition.belowSummary;
  SignatureLayout _sigLayout = SignatureLayout.vertical;
  bool _showSignatures = true;
  bool _showPaymentDetails = true;
  bool _showExcelGridlines = false;
  bool _includeChart = true;
  bool _sheetPerDept = true;
  bool _isCrossTab = true;

  ReportBranding _getBrandingForCurrentUseCase() {
    switch (_selectedCase) {
      case ReportUseCase.invoice:
        return ReportBranding(
          companyName: 'Apex Innovations Global',
          address: '100 Enterprise Way, Suite 400, Tech District, CA 94016',
          phone: '+1 (800) 555-0199',
          email: 'billing@apexinnovations.com',
          taxId: 'US-EIN-98-7654321',
          logoPath: 'assets/logo.png',
          layout: BrandingLayout.topRightLogo,
        );
      case ReportUseCase.payroll:
        return ReportBranding(
          companyName: 'Acme Enterprise Corporation',
          address: '450 Silicon Boulevard, Tower A, Austin, TX 78701',
          phone: '+1 (888) 420-1000',
          email: 'payroll@acme-corp.internal',
          taxId: 'US-EIN-54-3210987',
          logoPath: 'assets/logo.png',
          layout: BrandingLayout.topRightLogo,
        );
      case ReportUseCase.salesCrossTab:
        return ReportBranding(
          companyName: 'Global Strategic Holdings LLC',
          address: '1 Wall Street Plaza, 28th Floor, New York, NY 10005',
          phone: '+1 (212) 555-7800',
          email: 'finance@globalstrategic.com',
          taxId: 'US-EIN-12-3456789',
          logoPath: 'assets/logo.png',
          layout: BrandingLayout.topRightLogo,
        );
      case ReportUseCase.agingValuation:
        return ReportBranding(
          companyName: 'Summit Financial Risk Advisors',
          address: '200 Financial Center, Suite 1200, Chicago, IL 60606',
          phone: '+1 (312) 555-9920',
          email: 'ar-risk@summitfinancial.com',
          taxId: 'US-EIN-88-1122334',
          logoPath: 'assets/logo.png',
          layout: BrandingLayout.topRightLogo,
        );
      case ReportUseCase.clinicalAudit:
        return ReportBranding(
          companyName: 'St. Jude Metropolitan Health System',
          address: '777 Medical Park Way, West Pavilion, Boston, MA 02115',
          phone: '+1 (617) 555-4321',
          email: 'audit@stjudehealth.org',
          taxId: 'US-EIN-77-9988776',
          logoPath: 'assets/logo.png',
          layout: BrandingLayout.topRightLogo,
        );
    }
  }

  Future<void> _exportReport(bool isPdf) async {
    setState(() {
      _busy = true;
      _statusMessage =
          'Compiling and exporting ${isPdf ? "PDF" : "Excel"} report…';
    });

    try {
      final ReportArtifact artifact = isPdf
          ? await _generatePdfArtifact()
          : await _generateExcelArtifact();

      if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
        try {
          await ReportSaver().save(artifact);
        } catch (_) {}
      }

      setState(() {
        _lastArtifact = artifact;
        _statusMessage =
            'Successfully exported ${artifact.filename} (${artifact.formattedSize})';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Exported ${artifact.filename} (${artifact.formattedSize})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e, st) {
      print('Export error: $e\n$st');
      setState(() => _statusMessage = 'Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            content: Text('Export failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<ReportArtifact> _generatePdfArtifact() async {
    final pdfOptions = PdfExportOptions(
      pageOrientation: _pdfOrientation,
      tableBorderStyle: _borderStyle,
      showSignatures: _showSignatures,
      signatureLayout: _sigLayout,
      paymentDetailsPosition: _paymentPosition,
      signatures: _showSignatures ? _defaultSignatures : const [],
    );

    final engine = ReportEngine();

    switch (_selectedCase) {
      case ReportUseCase.invoice:
        return _buildInvoiceReport().exportPdf(options: pdfOptions);

      case ReportUseCase.payroll:
        final def = _buildPayrollDefinition();
        final prep = await engine.prepare(definition: def, records: _employees);
        return engine.exportPdf(prep, options: pdfOptions);

      case ReportUseCase.salesCrossTab:
        final def = _buildSalesDefinition();
        final prep = await engine.prepare(definition: def, records: _salesData);
        return engine.exportPdf(prep, options: pdfOptions);

      case ReportUseCase.agingValuation:
        final def = _buildAgingDefinition();
        final prep = await engine.prepare(definition: def, records: _agingData);
        return engine.exportPdf(prep, options: pdfOptions);

      case ReportUseCase.clinicalAudit:
        final def = _buildClinicalDefinition();
        final prep = await engine.prepare(
          definition: def,
          records: _clinicalData,
        );
        return engine.exportPdf(prep, options: pdfOptions);
    }
  }

  Future<ReportArtifact> _generateExcelArtifact() async {
    final excelOptions = ExcelExportOptions(
      showGridlines: _showExcelGridlines,
      tableBorderStyle: _borderStyle,
      showSignatures: _showSignatures,
      signatureLayout: _sigLayout,
      paymentDetailsPosition: _paymentPosition,
      signatures: _showSignatures ? _defaultSignatures : const [],
    );

    final engine = ReportEngine();

    switch (_selectedCase) {
      case ReportUseCase.invoice:
        return _buildInvoiceReport().exportExcel(options: excelOptions);

      case ReportUseCase.payroll:
        final def = _buildPayrollDefinition();
        final prep = await engine.prepare(definition: def, records: _employees);
        return engine.exportExcel(prep, options: excelOptions);

      case ReportUseCase.salesCrossTab:
        final def = _buildSalesDefinition();
        final prep = await engine.prepare(definition: def, records: _salesData);
        return engine.exportExcel(prep, options: excelOptions);

      case ReportUseCase.agingValuation:
        final def = _buildAgingDefinition();
        final prep = await engine.prepare(definition: def, records: _agingData);
        return engine.exportExcel(prep, options: excelOptions);

      case ReportUseCase.clinicalAudit:
        final def = _buildClinicalDefinition();
        final prep = await engine.prepare(
          definition: def,
          records: _clinicalData,
        );
        return engine.exportExcel(prep, options: excelOptions);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REPORT DEFINITIONS WITH FULL COMPANY BRANDING
  // ═══════════════════════════════════════════════════════════════════════════

  EasyReport _buildInvoiceReport() {
    final branding = _getBrandingForCurrentUseCase();
    return EasyReport.fromMaps(
      data: _invoiceItems,
      title: 'Commercial Tax Invoice & Remittance',
      subtitle: 'Invoice #INV-2026-0891 • Issue Date: October 05, 2026',
      branding: branding,
      tableBorderStyle: _borderStyle,
      showGridlines: _showExcelGridlines,
      pdfPageOrientation: _pdfOrientation,
      paymentDetailsPosition: _paymentPosition,
      includeChart: _includeChart,
      groupBy: 'category',
      chartConfig: _includeChart
          ? const ReportChartConfig(
              type: ReportChartType.bar,
              title: 'Consulting Practice Breakdown',
              categoryColumn: 'category',
              measureColumn: 'hours',
              topN: 4,
            )
          : null,
      summaryItems: [
        ReportSummaryItem.subtotal(15750.0, currencyCode: 'USD'),
        ReportSummaryItem.tax('Tax / VAT (16%)', 2520.0, currencyCode: 'USD'),
        const ReportSummaryItem(
          label: 'Processing & Delivery',
          value: 150.0,
          currencyCode: 'USD',
        ),
        ReportSummaryItem.total(18420.0, currencyCode: 'USD'),
        ReportSummaryItem.balanceDue(18420.0, currencyCode: 'USD'),
      ],
      paymentDetails: _showPaymentDetails
          ? ReportPaymentDetails(
              position: _paymentPosition,
              bankName: 'Standard Chartered Bank',
              accountName: 'Antigravity Enterprise Solutions Ltd',
              accountNumber: '0108044921000',
              branch: 'Westlands Commercial Hub',
              swiftCode: 'SCBLKENX',
              termsOrNotes: const [
                'Payment terms: Net 30 days from date of invoice.',
                'Please quote invoice number as payment reference.',
              ],
            )
          : null,
      showSignatures: _showSignatures,
      signatureBlocks: _showSignatures ? _defaultSignatures : const [],
      signatureLayout: _sigLayout,
      currencyCode: 'USD',
      currencyColumns: const ['rate', 'amount'],
    );
  }

  ReportDefinition<Employee> _buildPayrollDefinition() {
    final branding = _getBrandingForCurrentUseCase();
    return ReportDefinition<Employee>(
      title: 'Corporate Payroll & Benefits Register',
      subtitle: 'Monthly Executive Compensation & Statutory Schedule',
      branding: branding,
      theme: ReportTheme.classicBlue(),
      paymentDetails: _showPaymentDetails
          ? ReportPaymentDetails(
              position: _paymentPosition,
              bankName: 'Citibank N.A.',
              accountName: 'Acme Enterprise Corporate Payroll',
              accountNumber: '88392019941',
              branch: 'Corporate HQ Banking Division',
              termsOrNotes: const [
                'Statutory payroll taxes remitted under EIN 54-3210987.',
                'Direct deposit settlement on the 28th of each calendar month.',
              ],
            )
          : null,
      columns: [
        ReportColumn<Employee>(
          id: 'id',
          title: 'Employee ID',
          accessor: (e) => e.id,
        ),
        ReportColumn<Employee>(
          id: 'name',
          title: 'Full Name',
          accessor: (e) => e.name,
        ),
        ReportColumn<Employee>(
          id: 'department',
          title: 'Department',
          accessor: (e) => e.department,
        ),
        ReportColumn<Employee>(
          id: 'basicPay',
          title: 'Basic Salary',
          accessor: (e) => e.basicPay,
          type: ReportFieldType.money,
          currencyCode: 'USD',
        ),
        ReportColumn<Employee>(
          id: 'allowances',
          title: 'Allowances',
          accessor: (e) => e.allowances,
          type: ReportFieldType.money,
          currencyCode: 'USD',
        ),
        ReportColumn<Employee>(
          id: 'deductions',
          title: 'Deductions',
          accessor: (e) => e.deductions,
          type: ReportFieldType.money,
          currencyCode: 'USD',
        ),
        ReportColumn<Employee>(
          id: 'netPay',
          title: 'Net Salary',
          accessor: (e) => e.netPay,
          type: ReportFieldType.money,
          currencyCode: 'USD',
        ),
      ],
      analyses: [
        ReportAnalysis(
          id: 'dept_payroll',
          title: 'Employee Salary Schedule',
          groupBy: const ['department'],
          sheetPerCategory: _sheetPerDept,
          measures: [
            ReportMeasure.sum(
              column: 'basicPay',
              currencyCode: 'USD',
              title: 'Basic Sum',
            ),
            ReportMeasure.sum(
              column: 'allowances',
              currencyCode: 'USD',
              title: 'Allowances Sum',
            ),
            ReportMeasure.sum(
              column: 'deductions',
              currencyCode: 'USD',
              title: 'Deductions Sum',
            ),
            ReportMeasure.sum(
              column: 'netPay',
              currencyCode: 'USD',
              title: 'Net Sum',
            ),
            ReportMeasure.count(id: 'count', title: 'Headcount'),
          ],
          showGrandTotal: true,
          showSubtotals: true,
        ),
      ],
    );
  }

  ReportDefinition<Map<String, dynamic>> _buildSalesDefinition() {
    final branding = _getBrandingForCurrentUseCase();
    return ReportDefinition<Map<String, dynamic>>(
      title: 'Executive Sales & Revenue Performance',
      subtitle: 'Global Operations Performance Matrix',
      branding: branding,
      theme: ReportTheme.corporateDark(),
      paymentDetails: _showPaymentDetails
          ? ReportPaymentDetails(
              position: _paymentPosition,
              bankName: 'JPMorgan Chase & Co.',
              accountName: 'Global Strategic Holdings LLC',
              accountNumber: '994018274410',
              branch: 'Global Operations Banking Hub',
            )
          : null,
      columns: [
        ReportColumn<Map<String, dynamic>>(
          id: 'rep',
          title: 'Sales Representative',
          accessor: (m) => m['rep'],
        ),
        ReportColumn<Map<String, dynamic>>(
          id: 'region',
          title: 'Region',
          accessor: (m) => m['region'],
        ),
        ReportColumn<Map<String, dynamic>>(
          id: 'product',
          title: 'Product Line',
          accessor: (m) => m['product'],
        ),
        ReportColumn<Map<String, dynamic>>(
          id: 'quarter',
          title: 'Fiscal Quarter',
          accessor: (m) => m['quarter'],
        ),
        ReportColumn<Map<String, dynamic>>(
          id: 'revenue',
          title: 'Revenue',
          accessor: (m) => m['revenue'],
          type: ReportFieldType.money,
          currencyCode: 'USD',
        ),
      ],
      analyses: [
        if (_isCrossTab)
          ReportAnalysis.crossTab(
            id: 'sales_matrix',
            title: 'Quarterly Regional Matrix',
            rowDimension: 'region',
            columnDimension: 'quarter',
            measure: ReportMeasure.sum(
              column: 'revenue',
              currencyCode: 'USD',
              title: 'Revenue',
            ),
            showGrandTotal: true,
          )
        else
          ReportAnalysis(
            id: 'sales_detail',
            title: 'Sales Performance Detail',
            groupBy: const ['region'],
            measures: [
              ReportMeasure.sum(
                column: 'revenue',
                currencyCode: 'USD',
                title: 'Total Revenue',
              ),
              ReportMeasure.average(
                column: 'revenue',
                currencyCode: 'USD',
                title: 'Average Deal',
              ),
              ReportMeasure.countNonNull(column: 'rep', title: 'Deal Count'),
            ],
            showGrandTotal: true,
          ),
      ],
    );
  }

  ReportDefinition<Map<String, dynamic>> _buildAgingDefinition() {
    final branding = _getBrandingForCurrentUseCase();
    return ReportDefinition<Map<String, dynamic>>(
      title: 'Accounts Receivable & Aging Valuation',
      subtitle: 'Portfolio Risk Schedule & Outstanding Claims',
      branding: branding,
      theme: ReportTheme.slateGrey(),
      paymentDetails: _showPaymentDetails
          ? ReportPaymentDetails(
              position: _paymentPosition,
              bankName: 'Northern Trust Banking Group',
              accountName: 'Summit Financial Escrow Account',
              accountNumber: '44018274991',
              branch: 'Chicago Financial District',
              termsOrNotes: const [
                'Late interest of 1.5% applied after 60 days overdue.',
              ],
            )
          : null,
      columns: [
        ReportColumn<Map<String, dynamic>>(
          id: 'client',
          title: 'Client Name',
          accessor: (m) => m['client'],
        ),
        ReportColumn<Map<String, dynamic>>(
          id: 'invoice',
          title: 'Invoice Number',
          accessor: (m) => m['invoice'],
        ),
        ReportColumn<Map<String, dynamic>>(
          id: 'status',
          title: 'Aging Category',
          accessor: (m) => m['status'],
        ),
        ReportColumn<Map<String, dynamic>>(
          id: 'daysOverdue',
          title: 'Days Overdue',
          accessor: (m) => m['daysOverdue'],
          type: ReportFieldType.number,
        ),
        ReportColumn<Map<String, dynamic>>(
          id: 'amount',
          title: 'Outstanding Balance',
          accessor: (m) => m['amount'],
          type: ReportFieldType.money,
          currencyCode: 'USD',
        ),
      ],
      analyses: [
        ReportAnalysis(
          id: 'ar_aging',
          title: 'Portfolio Schedule by Aging Bracket',
          groupBy: const ['status'],
          measures: [
            ReportMeasure.sum(
              column: 'amount',
              currencyCode: 'USD',
              title: 'Bracket Total',
            ),
            ReportMeasure.average(
              column: 'daysOverdue',
              title: 'Average Overdue Days',
            ),
            ReportMeasure.countNonNull(
              column: 'invoice',
              title: 'Invoice Count',
            ),
          ],
          showGrandTotal: true,
          showSubtotals: true,
        ),
      ],
    );
  }

  ReportDefinition<Map<String, dynamic>> _buildClinicalDefinition() {
    final branding = _getBrandingForCurrentUseCase();
    return ReportDefinition<Map<String, dynamic>>(
      title: 'Hospital Clinical Audit & Care Register',
      subtitle: 'Inpatient Census & Departmental Care Valuation',
      branding: branding,
      theme: ReportTheme.forestGreen(),
      paymentDetails: _showPaymentDetails
          ? ReportPaymentDetails(
              position: _paymentPosition,
              bankName: 'Bank of America Healthcare Services',
              accountName: 'St. Jude Metropolitan Health System',
              accountNumber: '33019844201',
              branch: 'Boston Medical Pavilion',
              termsOrNotes: const [
                'Inpatient claims certified compliant with HIPAA and CMS.',
              ],
            )
          : null,
      columns: [
        ReportColumn<Map<String, dynamic>>(
          id: 'patientId',
          title: 'Patient ID',
          accessor: (m) => m['patientId'],
        ),
        ReportColumn<Map<String, dynamic>>(
          id: 'department',
          title: 'Clinical Ward',
          accessor: (m) => m['department'],
        ),
        ReportColumn<Map<String, dynamic>>(
          id: 'physician',
          title: 'Attending Physician',
          accessor: (m) => m['physician'],
        ),
        ReportColumn<Map<String, dynamic>>(
          id: 'admissionDays',
          title: 'Stay Days',
          accessor: (m) => m['admissionDays'],
          type: ReportFieldType.number,
        ),
        ReportColumn<Map<String, dynamic>>(
          id: 'billAmount',
          title: 'Care Charges',
          accessor: (m) => m['billAmount'],
          type: ReportFieldType.money,
          currencyCode: 'USD',
        ),
        ReportColumn<Map<String, dynamic>>(
          id: 'status',
          title: 'Discharge Status',
          accessor: (m) => m['status'],
        ),
      ],
      analyses: [
        ReportAnalysis(
          id: 'ward_summary',
          title: 'Ward Operations & Stay Analysis',
          groupBy: const ['department'],
          measures: [
            ReportMeasure.sum(
              column: 'billAmount',
              currencyCode: 'USD',
              title: 'Ward Total Cost',
            ),
            ReportMeasure.average(
              column: 'admissionDays',
              title: 'Avg Stay Duration',
            ),
            ReportMeasure.countNonNull(
              column: 'patientId',
              title: 'Total Patients',
            ),
          ],
          showGrandTotal: true,
          showSubtotals: true,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI & LAYOUT (THEME ADAPTIVE & 10x UX)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.assessment_rounded, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'syncfusion_easy_reports',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '10x Production Reporting Engine • Pure Dart • 100% Offline',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.isDark
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildScenarioSelector(),
          Expanded(
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioSelector() {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _scenarioChip(
              useCase: ReportUseCase.invoice,
              icon: Icons.receipt_long,
              title: 'Tax Invoice & Remittance',
              subtitle: 'Borders • Remittance • Signatures',
            ),
            const SizedBox(width: 10),
            _scenarioChip(
              useCase: ReportUseCase.payroll,
              icon: Icons.badge,
              title: 'Department Payroll',
              subtitle: 'Multi-Column Sums • Category Tabs',
            ),
            const SizedBox(width: 10),
            _scenarioChip(
              useCase: ReportUseCase.salesCrossTab,
              icon: Icons.pivot_table_chart,
              title: 'Executive Sales CrossTab',
              subtitle: 'Matrix Pivot • Charts • Title Case',
            ),
            const SizedBox(width: 10),
            _scenarioChip(
              useCase: ReportUseCase.agingValuation,
              icon: Icons.account_balance_wallet,
              title: 'Accounts Receivable Aging',
              subtitle: 'Aging Brackets • Subtotals • Valuation',
            ),
            const SizedBox(width: 10),
            _scenarioChip(
              useCase: ReportUseCase.clinicalAudit,
              icon: Icons.local_hospital,
              title: 'Clinical Health Audit',
              subtitle: 'Ward Census • Patient Charges • Care Audit',
            ),
          ],
        ),
      ),
    );
  }

  Widget _scenarioChip({
    required ReportUseCase useCase,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedCase == useCase;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _selectedCase = useCase),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer.withValues(
                            alpha: 0.8,
                          )
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Rail: Interactive Controls & Actions
        SizedBox(
          width: 440,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildExportActionBar(),
              const SizedBox(height: 14),
              _buildConfigurationCard(),
              const SizedBox(height: 14),
              _buildCodeSnippetCard(),
            ],
          ),
        ),
        const VerticalDivider(width: 1),

        // Right Rail: Live Document Preview
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [_buildLivePreviewCard()],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildExportActionBar(),
        const SizedBox(height: 14),
        _buildConfigurationCard(),
        const SizedBox(height: 14),
        _buildLivePreviewCard(),
        const SizedBox(height: 14),
        _buildCodeSnippetCard(),
      ],
    );
  }

  Widget _buildExportActionBar() {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'One-Click Export Hub',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E7E34),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.table_view, size: 20),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Export Excel (.xlsx)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    onPressed: _busy ? null : () => _exportReport(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf, size: 20),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Export PDF (${_pdfOrientation.name.toUpperCase()})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    onPressed: _busy ? null : () => _exportReport(true),
                  ),
                ),
              ],
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _statusMessage!.startsWith('Error')
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _statusMessage!.startsWith('Error')
                        ? Colors.red.shade400
                        : Colors.green.shade400,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusMessage!.startsWith('Error')
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      size: 16,
                      color: _statusMessage!.startsWith('Error')
                          ? Colors.red.shade400
                          : Colors.green.shade400,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _statusMessage!.startsWith('Error')
                              ? (widget.isDark
                                    ? Colors.red.shade200
                                    : Colors.red.shade900)
                              : (widget.isDark
                                    ? Colors.green.shade200
                                    : Colors.green.shade900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_lastArtifact != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.attachment,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ready: ${_lastArtifact!.filename} (${_lastArtifact!.formattedSize})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Layout & Presentation Options',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // PDF Orientation
            DropdownButtonFormField<PdfPageOrientation>(
              isExpanded: true,
              initialValue: _pdfOrientation,
              decoration: const InputDecoration(
                labelText: 'PDF Page Orientation',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.screen_rotation_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: PdfPageOrientation.portrait,
                  child: Text(
                    'Portrait (Default layout)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: PdfPageOrientation.landscape,
                  child: Text(
                    'Landscape (Wide tables)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _pdfOrientation = val);
              },
            ),
            const SizedBox(height: 12),

            // Table Border Style
            DropdownButtonFormField<TableBorderStyle>(
              isExpanded: true,
              initialValue: _borderStyle,
              decoration: const InputDecoration(
                labelText: 'Table Border Style',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.border_style),
              ),
              items: const [
                DropdownMenuItem(
                  value: TableBorderStyle.clean,
                  child: Text(
                    'Clean / Modern',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: TableBorderStyle.horizontalOnly,
                  child: Text(
                    'Horizontal Dividers Only',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: TableBorderStyle.grid,
                  child: Text(
                    'Full Classic Grid',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: TableBorderStyle.headerAndTotalOnly,
                  child: Text(
                    'Header & Total Lines Only',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: TableBorderStyle.none,
                  child: Text(
                    'None (Minimalist Borderless)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _borderStyle = val);
              },
            ),
            const SizedBox(height: 12),

            // Optional Signatures Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.draw_outlined),
              title: const Text(
                'Include Signatures Block',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Renders preparation & approval sign-offs',
                style: TextStyle(fontSize: 11),
              ),
              value: _showSignatures,
              onChanged: (val) => setState(() => _showSignatures = val),
            ),

            if (_showSignatures) ...[
              const SizedBox(height: 6),
              DropdownButtonFormField<SignatureLayout>(
                isExpanded: true,
                initialValue: _sigLayout,
                decoration: const InputDecoration(
                  labelText: 'Signature Block Layout',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.view_agenda_outlined),
                  helperText: 'Vertical stacks all signatures in ONE column',
                ),
                items: const [
                  DropdownMenuItem(
                    value: SignatureLayout.vertical,
                    child: Text(
                      'Vertical Stack (1 Column)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: SignatureLayout.horizontal,
                    child: Text(
                      'Horizontal (Side-by-side)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: SignatureLayout.split,
                    child: Text(
                      'Split (Left Prepared / Right Approved)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: SignatureLayout.adaptive,
                    child: Text(
                      'Adaptive (Auto-stacked)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _sigLayout = val);
                },
              ),
            ],
            const SizedBox(height: 10),

            // Optional Payment Instructions Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.payments_outlined),
              title: const Text(
                'Include Payment & Remittance',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Wire transfer, bank accounts & terms',
                style: TextStyle(fontSize: 11),
              ),
              value: _showPaymentDetails,
              onChanged: (val) => setState(() => _showPaymentDetails = val),
            ),

            if (_showPaymentDetails) ...[
              const SizedBox(height: 6),
              DropdownButtonFormField<PaymentDetailsPosition>(
                isExpanded: true,
                initialValue: _paymentPosition,
                decoration: const InputDecoration(
                  labelText: 'Payment Instructions Position',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vertical_align_bottom_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: PaymentDetailsPosition.belowSummary,
                    child: Text(
                      'Below Summary (After Balance Due)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: PaymentDetailsPosition.afterSignatures,
                    child: Text(
                      'After Signatures (Bottom of Document)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: PaymentDetailsPosition.sideBySide,
                    child: Text(
                      'Side by Side (Classic Format)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _paymentPosition = val);
                },
              ),
            ],
            const SizedBox(height: 10),

            // Scenario-Specific Controls
            if (_selectedCase == ReportUseCase.invoice) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.grid_off_outlined),
                title: const Text(
                  'Excel Worksheet Gridlines',
                  style: TextStyle(fontSize: 13),
                ),
                value: _showExcelGridlines,
                onChanged: (val) => setState(() => _showExcelGridlines = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.bar_chart),
                title: const Text(
                  'Include Visual Chart Breakdown',
                  style: TextStyle(fontSize: 13),
                ),
                value: _includeChart,
                onChanged: (val) => setState(() => _includeChart = val),
              ),
            ] else if (_selectedCase == ReportUseCase.payroll) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.tab),
                title: const Text(
                  'Dedicated Sheet Per Department',
                  style: TextStyle(fontSize: 13),
                ),
                subtitle: const Text(
                  'Exports department category tabs in Excel',
                  style: TextStyle(fontSize: 11),
                ),
                value: _sheetPerDept,
                onChanged: (val) => setState(() => _sheetPerDept = val),
              ),
            ] else if (_selectedCase == ReportUseCase.salesCrossTab) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.table_chart),
                title: const Text(
                  'Matrix CrossTab Pivot',
                  style: TextStyle(fontSize: 13),
                ),
                subtitle: const Text(
                  'Cross-tabulates Regions across Quarters',
                  style: TextStyle(fontSize: 11),
                ),
                value: _isCrossTab,
                onChanged: (val) => setState(() => _isCrossTab = val),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME-ADAPTIVE DOCUMENT CANVAS PREVIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLivePreviewCard() {
    final isDark = widget.isDark;
    final branding = _getBrandingForCurrentUseCase();

    // Semantic, high-contrast palette perfectly tuned for both Light and Dark modes
    final paperBg = isDark ? const Color(0xFF1E222D) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFCBD5E1);
    final primaryAccent = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF1565C0);
    final textPrimary = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF0F172A);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cardBorder, width: 1.2),
      ),
      color: paperBg,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Header Badge & Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: primaryAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live Document Visualizer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryAccent,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${_pdfOrientation.name.toUpperCase()} • ${_borderStyle.name}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: primaryAccent,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: cardBorder),

            // Document Header: Company Logo, Address, and Contacts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Name, Full Address, Phone, Email, Tax ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branding.companyName ?? 'Enterprise Reporting Ltd',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        branding.address ?? '100 Enterprise Way, Suite 400',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                      Text(
                        'Tel: ${branding.phone ?? "+1 (800) 555-0199"} • Email: ${branding.email ?? "billing@apex.com"}',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                      if (branding.taxId != null)
                        Text(
                          'Tax ID / EIN: ${branding.taxId}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Company Logo / Corporate Badge
                Container(
                  height: 48,
                  width: 96,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF262D3D)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cardBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.business,
                        color: primaryAccent,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Report Title & Subtitle Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryAccent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _scenarioTitle(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    _scenarioSubtitle(),
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Data Table Preview with Multi-Column Sums Aligned Under Columns
            _buildSampleTablePreview(
              isDark,
              cardBorder,
              primaryAccent,
              textPrimary,
              textMuted,
            ),
            const SizedBox(height: 18),

            // Financial Summary, Optional Remittance Box & Signatures Layout
            _buildBottomSectionsPreview(
              isDark,
              cardBorder,
              primaryAccent,
              textPrimary,
              textMuted,
            ),
          ],
        ),
      ),
    );
  }

  String _scenarioTitle() {
    switch (_selectedCase) {
      case ReportUseCase.invoice:
        return 'Commercial Tax Invoice & Remittance';
      case ReportUseCase.payroll:
        return 'Department Payroll & Statutory Deductions';
      case ReportUseCase.salesCrossTab:
        return 'Executive Sales & Quarterly Matrix';
      case ReportUseCase.agingValuation:
        return 'Accounts Receivable & Aging Valuation';
      case ReportUseCase.clinicalAudit:
        return 'Hospital Clinical Audit & Care Register';
    }
  }

  String _scenarioSubtitle() {
    switch (_selectedCase) {
      case ReportUseCase.invoice:
        return 'Invoice #INV-2026-0891 • Issue Date: October 05, 2026';
      case ReportUseCase.payroll:
        return 'Internal Salary Schedule • Period Ending Oct 2026';
      case ReportUseCase.salesCrossTab:
        return 'Quarterly Revenue Performance by Region & Line';
      case ReportUseCase.agingValuation:
        return 'Aging Analysis & Risk Exposure Portfolio';
      case ReportUseCase.clinicalAudit:
        return 'Inpatient Census & Departmental Care Valuation';
    }
  }

  Widget _buildSampleTablePreview(
    bool isDark,
    Color cardBorder,
    Color primaryAccent,
    Color textPrimary,
    Color textMuted,
  ) {
    final headerBg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFE3F2FD);
    final headerTextColor = isDark
        ? const Color(0xFF93C5FD)
        : const Color(0xFF0D47A1);
    final totalsBg = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFFFF9C4);
    final totalsTextColor = isDark
        ? const Color(0xFFFDE047)
        : const Color(0xFF1E293B);

    switch (_selectedCase) {
      case ReportUseCase.invoice:
        return Table(
          border: _resolveTableBorder(cardBorder, primaryAccent),
          columnWidths: const {
            0: FlexColumnWidth(4),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(1.8),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerBg),
              children: [
                _th('Service Description', headerTextColor),
                _th('Category', headerTextColor),
                _th('Hours', headerTextColor, align: TextAlign.right),
                _th('Rate', headerTextColor, align: TextAlign.right),
                _th('Amount', headerTextColor, align: TextAlign.right),
              ],
            ),
            for (final item in _invoiceItems)
              TableRow(
                children: [
                  _td(item['item'] as String, textPrimary),
                  _td(item['category'] as String, textPrimary),
                  _td('${item['hours']}', textPrimary, align: TextAlign.right),
                  _td(
                    '\$${(item['rate'] as num).toStringAsFixed(2)}',
                    textPrimary,
                    align: TextAlign.right,
                  ),
                  _td(
                    '\$${(item['amount'] as num).toStringAsFixed(2)}',
                    textPrimary,
                    align: TextAlign.right,
                    isBold: true,
                  ),
                ],
              ),
            // Multi-column sums directly placed under respective columns!
            TableRow(
              decoration: BoxDecoration(color: totalsBg),
              children: [
                _td('Subtotal', totalsTextColor, isBold: true),
                _td('', totalsTextColor),
                _td(
                  '107 Hrs',
                  totalsTextColor,
                  align: TextAlign.right,
                  isBold: true,
                ),
                _td('', totalsTextColor),
                _td(
                  '\$15,750.00',
                  totalsTextColor,
                  align: TextAlign.right,
                  isBold: true,
                ),
              ],
            ),
          ],
        );

      case ReportUseCase.payroll:
        return Table(
          border: _resolveTableBorder(cardBorder, primaryAccent),
          columnWidths: const {
            0: FlexColumnWidth(1.4),
            1: FlexColumnWidth(2.6),
            2: FlexColumnWidth(2.0),
            3: FlexColumnWidth(1.8),
            4: FlexColumnWidth(1.8),
            5: FlexColumnWidth(1.8),
            6: FlexColumnWidth(2.0),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerBg),
              children: [
                _th('ID', headerTextColor),
                _th('Full Name', headerTextColor),
                _th('Department', headerTextColor),
                _th('Basic', headerTextColor, align: TextAlign.right),
                _th('Allow.', headerTextColor, align: TextAlign.right),
                _th('Deduct.', headerTextColor, align: TextAlign.right),
                _th('Net Pay', headerTextColor, align: TextAlign.right),
              ],
            ),
            for (final emp in _employees)
              TableRow(
                children: [
                  _td(emp.id, textPrimary),
                  _td(emp.name, textPrimary),
                  _td(emp.department, textPrimary),
                  _td(
                    '\$${emp.basicPay.toStringAsFixed(0)}',
                    textPrimary,
                    align: TextAlign.right,
                  ),
                  _td(
                    '\$${emp.allowances.toStringAsFixed(0)}',
                    textPrimary,
                    align: TextAlign.right,
                  ),
                  _td(
                    '\$${emp.deductions.toStringAsFixed(0)}',
                    textPrimary,
                    align: TextAlign.right,
                  ),
                  _td(
                    '\$${emp.netPay.toStringAsFixed(0)}',
                    textPrimary,
                    align: TextAlign.right,
                    isBold: true,
                  ),
                ],
              ),
            // Multi-column sums: Basic, Allowances, Deductions, and Net all summed under their own columns!
            TableRow(
              decoration: BoxDecoration(color: totalsBg),
              children: [
                _td('Grand Total', totalsTextColor, isBold: true),
                _td('7 Staff', totalsTextColor, isBold: true),
                _td('', totalsTextColor),
                _td(
                  '\$55,200',
                  totalsTextColor,
                  align: TextAlign.right,
                  isBold: true,
                ),
                _td(
                  '\$9,150',
                  totalsTextColor,
                  align: TextAlign.right,
                  isBold: true,
                ),
                _td(
                  '\$4,990',
                  totalsTextColor,
                  align: TextAlign.right,
                  isBold: true,
                ),
                _td(
                  '\$59,360',
                  totalsTextColor,
                  align: TextAlign.right,
                  isBold: true,
                ),
              ],
            ),
          ],
        );

      case ReportUseCase.salesCrossTab:
        return Table(
          border: _resolveTableBorder(cardBorder, primaryAccent),
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerBg),
              children: [
                _th('Region', headerTextColor),
                _th('Q1 Revenue', headerTextColor, align: TextAlign.right),
                _th('Q2 Revenue', headerTextColor, align: TextAlign.right),
                _th('Total Revenue', headerTextColor, align: TextAlign.right),
              ],
            ),
            TableRow(
              children: [
                _td('North America', textPrimary),
                _td('\$42,000', textPrimary, align: TextAlign.right),
                _td('\$58,000', textPrimary, align: TextAlign.right),
                _td(
                  '\$100,000',
                  textPrimary,
                  align: TextAlign.right,
                  isBold: true,
                ),
              ],
            ),
            TableRow(
              children: [
                _td('EMEA', textPrimary),
                _td('\$31,000', textPrimary, align: TextAlign.right),
                _td('\$49,000', textPrimary, align: TextAlign.right),
                _td(
                  '\$80,000',
                  textPrimary,
                  align: TextAlign.right,
                  isBold: true,
                ),
              ],
            ),
            TableRow(
              children: [
                _td('LATAM', textPrimary),
                _td('\$27,500', textPrimary, align: TextAlign.right),
                _td('\$36,500', textPrimary, align: TextAlign.right),
                _td(
                  '\$64,000',
                  textPrimary,
                  align: TextAlign.right,
                  isBold: true,
                ),
              ],
            ),
            TableRow(
              children: [
                _td('APAC', textPrimary),
                _td('\$51,000', textPrimary, align: TextAlign.right),
                _td('\$64,000', textPrimary, align: TextAlign.right),
                _td(
                  '\$115,000',
                  textPrimary,
                  align: TextAlign.right,
                  isBold: true,
                ),
              ],
            ),
            TableRow(
              decoration: BoxDecoration(color: totalsBg),
              children: [
                _td('Grand Total', totalsTextColor, isBold: true),
                _td(
                  '\$151,500',
                  totalsTextColor,
                  align: TextAlign.right,
                  isBold: true,
                ),
                _td(
                  '\$207,500',
                  totalsTextColor,
                  align: TextAlign.right,
                  isBold: true,
                ),
                _td(
                  '\$359,000',
                  totalsTextColor,
                  align: TextAlign.right,
                  isBold: true,
                ),
              ],
            ),
          ],
        );

      case ReportUseCase.agingValuation:
        return Table(
          border: _resolveTableBorder(cardBorder, primaryAccent),
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerBg),
              children: [
                _th('Client Name', headerTextColor),
                _th('Invoice', headerTextColor),
                _th('Aging Bracket', headerTextColor),
                _th('Days', headerTextColor, align: TextAlign.right),
                _th('Balance Due', headerTextColor, align: TextAlign.right),
              ],
            ),
            for (final row in _agingData)
              TableRow(
                children: [
                  _td(row['client'] as String, textPrimary),
                  _td(row['invoice'] as String, textPrimary),
                  _td(row['status'] as String, textPrimary),
                  _td(
                    '${row['daysOverdue']}',
                    textPrimary,
                    align: TextAlign.right,
                  ),
                  _td(
                    '\$${(row['amount'] as num).toStringAsFixed(2)}',
                    textPrimary,
                    align: TextAlign.right,
                    isBold: true,
                  ),
                ],
              ),
            TableRow(
              decoration: BoxDecoration(color: totalsBg),
              children: [
                _td('Total Portfolio', totalsTextColor, isBold: true),
                _td('5 Invoices', totalsTextColor),
                _td('All Brackets', totalsTextColor),
                _td(
                  '38 Avg',
                  totalsTextColor,
                  align: TextAlign.right,
                  isBold: true,
                ),
                _td(
                  '\$63,350.00',
                  totalsTextColor,
                  align: TextAlign.right,
                  isBold: true,
                ),
              ],
            ),
          ],
        );

      case ReportUseCase.clinicalAudit:
        return Table(
          border: _resolveTableBorder(cardBorder, primaryAccent),
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerBg),
              children: [
                _th('Patient ID', headerTextColor),
                _th('Ward', headerTextColor),
                _th('Attending Physician', headerTextColor),
                _th('Days', headerTextColor, align: TextAlign.right),
                _th('Care Charges', headerTextColor, align: TextAlign.right),
              ],
            ),
            for (final row in _clinicalData)
              TableRow(
                children: [
                  _td(row['patientId'] as String, textPrimary),
                  _td(row['department'] as String, textPrimary),
                  _td(row['physician'] as String, textPrimary),
                  _td(
                    '${row['admissionDays']}',
                    textPrimary,
                    align: TextAlign.right,
                  ),
                  _td(
                    '\$${(row['billAmount'] as num).toStringAsFixed(2)}',
                    textPrimary,
                    align: TextAlign.right,
                    isBold: true,
                  ),
                ],
              ),
            TableRow(
              decoration: BoxDecoration(color: totalsBg),
              children: [
                _td('Ward Total', totalsTextColor, isBold: true),
                _td('4 Wards', totalsTextColor),
                _td('All Clinicians', totalsTextColor),
                _td(
                  '21 Days',
                  totalsTextColor,
                  align: TextAlign.right,
                  isBold: true,
                ),
                _td(
                  '\$27,350.00',
                  totalsTextColor,
                  align: TextAlign.right,
                  isBold: true,
                ),
              ],
            ),
          ],
        );
    }
  }

  TableBorder? _resolveTableBorder(Color cardBorder, Color primaryAccent) {
    switch (_borderStyle) {
      case TableBorderStyle.grid:
        return TableBorder.all(color: cardBorder, width: 0.8);
      case TableBorderStyle.horizontalOnly:
        return TableBorder(
          horizontalInside: BorderSide(color: cardBorder, width: 0.8),
          bottom: BorderSide(color: cardBorder, width: 1.0),
        );
      case TableBorderStyle.clean:
        return TableBorder(
          top: BorderSide(color: primaryAccent, width: 1.5),
          bottom: BorderSide(color: primaryAccent, width: 2.0),
        );
      case TableBorderStyle.headerAndTotalOnly:
        return TableBorder(
          top: BorderSide(color: cardBorder, width: 1.0),
          bottom: BorderSide(color: cardBorder, width: 1.5),
        );
      case TableBorderStyle.none:
        return null;
    }
  }

  Widget _th(String text, Color color, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }

  Widget _td(
    String text,
    Color color, {
    TextAlign align = TextAlign.left,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBottomSectionsPreview(
    bool isDark,
    Color cardBorder,
    Color primaryAccent,
    Color textPrimary,
    Color textMuted,
  ) {
    if (_selectedCase == ReportUseCase.invoice) {
      if (_paymentPosition == PaymentDetailsPosition.sideBySide) {
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showPaymentDetails)
                  Expanded(
                    flex: 5,
                    child: _buildRemittancePreviewCard(
                      isDark,
                      cardBorder,
                      primaryAccent,
                      textPrimary,
                      textMuted,
                    ),
                  ),
                if (_showPaymentDetails) const SizedBox(width: 20),
                Expanded(
                  flex: 4,
                  child: _buildFinancialSummaryStack(
                    isDark,
                    cardBorder,
                    primaryAccent,
                    textPrimary,
                  ),
                ),
              ],
            ),
            if (_showSignatures) ...[
              const SizedBox(height: 18),
              _buildSignaturesPreview(
                isDark,
                cardBorder,
                primaryAccent,
                textPrimary,
                textMuted,
              ),
            ],
          ],
        );
      } else if (_paymentPosition == PaymentDetailsPosition.belowSummary) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 280,
                child: _buildFinancialSummaryStack(
                  isDark,
                  cardBorder,
                  primaryAccent,
                  textPrimary,
                ),
              ),
            ),
            if (_showPaymentDetails) ...[
              const SizedBox(height: 16),
              _buildRemittancePreviewCard(
                isDark,
                cardBorder,
                primaryAccent,
                textPrimary,
                textMuted,
              ),
            ],
            if (_showSignatures) ...[
              const SizedBox(height: 18),
              _buildSignaturesPreview(
                isDark,
                cardBorder,
                primaryAccent,
                textPrimary,
                textMuted,
              ),
            ],
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 280,
                child: _buildFinancialSummaryStack(
                  isDark,
                  cardBorder,
                  primaryAccent,
                  textPrimary,
                ),
              ),
            ),
            if (_showSignatures) ...[
              const SizedBox(height: 18),
              _buildSignaturesPreview(
                isDark,
                cardBorder,
                primaryAccent,
                textPrimary,
                textMuted,
              ),
            ],
            if (_showPaymentDetails) ...[
              const SizedBox(height: 16),
              _buildRemittancePreviewCard(
                isDark,
                cardBorder,
                primaryAccent,
                textPrimary,
                textMuted,
              ),
            ],
          ],
        );
      }
    }

    // Default summaries for other use cases
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showPaymentDetails) ...[
          _buildRemittancePreviewCard(
            isDark,
            cardBorder,
            primaryAccent,
            textPrimary,
            textMuted,
          ),
          const SizedBox(height: 18),
        ],
        if (_showSignatures)
          _buildSignaturesPreview(
            isDark,
            cardBorder,
            primaryAccent,
            textPrimary,
            textMuted,
          ),
      ],
    );
  }

  Widget _buildRemittancePreviewCard(
    bool isDark,
    Color cardBorder,
    Color primaryAccent,
    Color textPrimary,
    Color textMuted,
  ) {
    final remittanceBg = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF8FAFC);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: remittanceBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, size: 16, color: primaryAccent),
              const SizedBox(width: 6),
              Text(
                'Payment & Remittance Instructions:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bank: Standard Chartered Bank • SWIFT: SCBLKENX',
            style: TextStyle(fontSize: 11, color: textPrimary),
          ),
          Text(
            'Account Name: Antigravity Enterprise Solutions Ltd',
            style: TextStyle(fontSize: 11, color: textPrimary),
          ),
          Text(
            'Account No: 0108044921000 • Branch: Westlands Commercial Hub',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Note: Payment terms Net 30 days from date of invoice.',
            style: TextStyle(
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryStack(
    bool isDark,
    Color cardBorder,
    Color primaryAccent,
    Color textPrimary,
  ) {
    return Column(
      children: [
        _summaryRow('Subtotal:', '\$15,750.00', textPrimary),
        _summaryRow('Tax / VAT (16%):', '\$2,520.00', textPrimary),
        _summaryRow('Processing & Delivery:', '\$150.00', textPrimary),
        Divider(height: 12, color: cardBorder),
        _summaryRow('Total:', '\$18,420.00', textPrimary, isBold: true),
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: primaryAccent, width: 2)),
          ),
          padding: const EdgeInsets.only(bottom: 2),
          child: _summaryRow(
            'Balance Due:',
            '\$18,420.00',
            primaryAccent,
            isBold: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSignaturesPreview(
    bool isDark,
    Color cardBorder,
    Color primaryAccent,
    Color textPrimary,
    Color textMuted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.draw, size: 16, color: primaryAccent),
            const SizedBox(width: 6),
            Text(
              'Signatures',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: primaryAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_sigLayout == SignatureLayout.vertical)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final sig in _defaultSignatures) ...[
                _singleSignature(
                  sig.name ?? '',
                  sig.title,
                  sig.date ?? '',
                  cardBorder,
                  primaryAccent,
                  textPrimary,
                  textMuted,
                ),
                const SizedBox(height: 12),
              ],
            ],
          )
        else
          Row(
            children: [
              for (final sig in _defaultSignatures.take(3))
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _singleSignature(
                      sig.name ?? '',
                      sig.title,
                      sig.date ?? '',
                      cardBorder,
                      primaryAccent,
                      textPrimary,
                      textMuted,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _singleSignature(
    String name,
    String title,
    String date,
    Color cardBorder,
    Color primaryAccent,
    Color textPrimary,
    Color textMuted,
  ) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name.isNotEmpty)
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          const SizedBox(height: 3),
          Container(height: 1, width: 200, color: cardBorder),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: primaryAccent,
            ),
          ),
          if (date.isNotEmpty)
            Text(
              'Date: $date',
              style: TextStyle(fontSize: 10, color: textMuted),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeSnippetCard() {
    final theme = Theme.of(context);
    final code = _getConciseCodeSnippet();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.code,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Ready-to-Use Dart Code',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('Copy', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getConciseCodeSnippet() {
    switch (_selectedCase) {
      case ReportUseCase.invoice:
        return '''final report = EasyReport.fromMaps(
  data: invoiceData,
  title: 'Commercial Tax Invoice',
  branding: ReportBranding(
    companyName: 'Apex Innovations Global',
    address: '100 Enterprise Way, Suite 400, Tech District, CA 94016',
    phone: '+1 (800) 555-0199',
    email: 'billing@apexinnovations.com',
    taxId: 'US-EIN-98-7654321',
    logoPath: 'assets/logo.png',
  ),
  pdfPageOrientation: ${_pdfOrientation.toString()},
  tableBorderStyle: ${_borderStyle.toString()},
  showSignatures: $_showSignatures,
  paymentDetails: ${_showPaymentDetails ? "ReportPaymentDetails(...)" : "null"},
);

// One-liner export artifacts:
final pdfArtifact = await report.exportPdf();
final xlsxArtifact = await report.exportExcel();''';

      case ReportUseCase.payroll:
        return '''final definition = ReportDefinition<Employee>(
  title: 'Corporate Payroll & Benefits Register',
  branding: ReportBranding(
    companyName: 'Acme Enterprise Corporation',
    address: '450 Silicon Boulevard, Tower A, Austin, TX 78701',
    logoPath: 'assets/logo.png',
  ),
  columns: [
    ReportColumn(id: 'name', title: 'Name', accessor: (e) => e.name),
    ReportColumn(id: 'department', title: 'Department', accessor: (e) => e.department),
    ReportColumn(id: 'basicPay', title: 'Basic Salary', accessor: (e) => e.basicPay, type: ReportFieldType.money),
    ReportColumn(id: 'allowances', title: 'Allowances', accessor: (e) => e.allowances, type: ReportFieldType.money),
    ReportColumn(id: 'deductions', title: 'Deductions', accessor: (e) => e.deductions, type: ReportFieldType.money),
    ReportColumn(id: 'netPay', title: 'Net Salary', accessor: (e) => e.netPay, type: ReportFieldType.money),
  ],
  analyses: [
    ReportAnalysis(
      id: 'payroll',
      title: 'Department Salary Schedule',
      groupBy: ['department'],
      sheetPerCategory: $_sheetPerDept,
      measures: [
        ReportMeasure.sum(column: 'basicPay', currencyCode: 'USD', title: 'Basic Sum'),
        ReportMeasure.sum(column: 'allowances', currencyCode: 'USD', title: 'Allowances Sum'),
        ReportMeasure.sum(column: 'deductions', currencyCode: 'USD', title: 'Deductions Sum'),
        ReportMeasure.sum(column: 'netPay', currencyCode: 'USD', title: 'Net Sum'),
        ReportMeasure.count(id: 'count', title: 'Headcount'),
      ],
      showGrandTotal: true,
    ),
  ],
);

final prepared = await ReportEngine().prepare(definition: definition, records: employees);
final pdf = await ReportEngine().exportPdf(prepared);
final xlsx = await ReportEngine().exportExcel(prepared);''';

      case ReportUseCase.salesCrossTab:
        return '''final definition = ReportDefinition<Map<String, dynamic>>(
  title: 'Executive Sales & Revenue Performance',
  branding: ReportBranding(companyName: 'Global Strategic Holdings LLC', logoPath: 'assets/logo.png'),
  columns: [...],
  analyses: [
    ReportAnalysis.crossTab(
      id: 'matrix',
      title: 'Quarterly Regional Matrix',
      rowDimension: 'region',
      columnDimension: 'quarter',
      measure: ReportMeasure.sum(column: 'revenue', currencyCode: 'USD'),
      showGrandTotal: true,
    ),
  ],
);

final prepared = await ReportEngine().prepare(definition: definition, records: salesData);
final pdf = await ReportEngine().exportPdf(prepared);''';

      case ReportUseCase.agingValuation:
        return '''final definition = ReportDefinition<Map<String, dynamic>>(
  title: 'Accounts Receivable Aging Schedule',
  branding: ReportBranding(companyName: 'Summit Financial Risk Advisors', logoPath: 'assets/logo.png'),
  columns: [...],
  analyses: [
    ReportAnalysis(
      id: 'aging',
      title: 'Portfolio Schedule by Aging Bracket',
      groupBy: ['status'],
      measures: [
        ReportMeasure.sum(column: 'amount', currencyCode: 'USD'),
        ReportMeasure.average(column: 'daysOverdue'),
      ],
      showGrandTotal: true,
      showSubtotals: true,
    ),
  ],
);''';

      case ReportUseCase.clinicalAudit:
        return '''final definition = ReportDefinition<Map<String, dynamic>>(
  title: 'Hospital Clinical Audit & Care Register',
  branding: ReportBranding(companyName: 'St. Jude Metropolitan Health System', logoPath: 'assets/logo.png'),
  columns: [...],
  analyses: [
    ReportAnalysis(
      id: 'ward_summary',
      title: 'Ward Operations & Stay Analysis',
      groupBy: ['department'],
      measures: [
        ReportMeasure.sum(column: 'billAmount', currencyCode: 'USD'),
        ReportMeasure.average(column: 'admissionDays'),
        ReportMeasure.countNonNull(column: 'patientId'),
      ],
      showGrandTotal: true,
    ),
  ],
);''';
    }
  }
}
