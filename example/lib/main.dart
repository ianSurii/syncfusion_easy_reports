// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:syncfusion_easy_reports/syncfusion_easy_reports.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────
void main() => runApp(const EasyReportsShowcase());

// ─── App shell ────────────────────────────────────────────────────────────────
class EasyReportsShowcase extends StatelessWidget {
  const EasyReportsShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'syncfusion_easy_reports — Full API Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const ShowcaseHome(),
    );
  }
}

// ─── Fictional label ─────────────────────────────────────────────────────────
const _kFictional = '⚠ Fictional data — demo only';

// ─── Typed Dart model ─────────────────────────────────────────────────────────
/// A real Dart class — demonstrates ReportColumn typed accessors.
class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.department,
    required this.bank,
    required this.basicPay,
    required this.allowances,
    required this.deductions,
    required this.joinedDate,
    required this.isActive,
    required this.commissionRate,
  });

  final String id;
  final String name;
  final String department;
  final String bank;
  final double basicPay;
  final double allowances;
  final double deductions;
  final DateTime joinedDate;
  final bool isActive;
  final double commissionRate;

  double get netPay => basicPay + allowances - deductions;
}

// ─── Datasets ─────────────────────────────────────────────────────────────────
final List<Employee> _employees = [
  Employee(
    id: 'E01',
    name: 'Eleanor Vance',
    department: 'Engineering',
    bank: 'Chase Bank',
    basicPay: 9200,
    allowances: 1200,
    deductions: 850,
    joinedDate: DateTime(2021, 3, 15),
    isActive: true,
    commissionRate: 0.05,
  ),
  Employee(
    id: 'E02',
    name: 'Marcus Brody',
    department: 'Engineering',
    bank: 'Chase Bank',
    basicPay: 8400,
    allowances: 800,
    deductions: 720,
    joinedDate: DateTime(2022, 6, 1),
    isActive: true,
    commissionRate: 0.05,
  ),
  Employee(
    id: 'E03',
    name: 'Sophia Chen',
    department: 'Marketing',
    bank: 'Citibank',
    basicPay: 7600,
    allowances: 1500,
    deductions: 600,
    joinedDate: DateTime(2020, 11, 20),
    isActive: true,
    commissionRate: 0.08,
  ),
  Employee(
    id: 'E04',
    name: 'Lucas Miller',
    department: 'Marketing',
    bank: 'Citibank',
    basicPay: 6900,
    allowances: 900,
    deductions: 550,
    joinedDate: DateTime(2023, 1, 10),
    isActive: true,
    commissionRate: 0.08,
  ),
  Employee(
    id: 'E05',
    name: 'Amara Okafor',
    department: 'Sales',
    bank: 'Wells Fargo',
    basicPay: 6500,
    allowances: 3200,
    deductions: 480,
    joinedDate: DateTime(2022, 8, 5),
    isActive: true,
    commissionRate: 0.12,
  ),
  Employee(
    id: 'E06',
    name: 'Julian Hayes',
    department: 'Finance',
    bank: 'Bank of America',
    basicPay: 8800,
    allowances: 600,
    deductions: 910,
    joinedDate: DateTime(2019, 5, 12),
    isActive: false,
    commissionRate: 0.00,
  ),
  Employee(
    id: 'E07',
    name: 'Zoe Patel',
    department: 'Engineering',
    bank: 'Chase Bank',
    basicPay: 7900,
    allowances: 950,
    deductions: 680,
    joinedDate: DateTime(2024, 2, 1),
    isActive: true,
    commissionRate: 0.05,
  ),
  Employee(
    id: 'E08',
    name: 'Liam Connor',
    department: 'Sales',
    bank: 'Wells Fargo',
    basicPay: 6200,
    allowances: 2800,
    deductions: 430,
    joinedDate: DateTime(2023, 9, 18),
    isActive: true,
    commissionRate: 0.12,
  ),
];

final List<Map<String, dynamic>> _deductionsData = [
  {
    'employeeId': 'E01',
    'employeeName': 'Eleanor Vance',
    'department': 'Engineering',
    'deductionType': 'KCB Bank Loan',
    'amount': 350.0,
    'employerContribution': 0.0,
  },
  {
    'employeeId': 'E02',
    'employeeName': 'Marcus Brody',
    'department': 'Engineering',
    'deductionType': 'KCB Bank Loan',
    'amount': 400.0,
    'employerContribution': 0.0,
  },
  {
    'employeeId': 'E03',
    'employeeName': 'Sophia Chen',
    'department': 'Marketing',
    'deductionType': 'Equity Bank Loan',
    'amount': 500.0,
    'employerContribution': 0.0,
  },
  {
    'employeeId': 'E04',
    'employeeName': 'Lucas Miller',
    'department': 'Marketing',
    'deductionType': 'Equity Bank Loan',
    'amount': 450.0,
    'employerContribution': 0.0,
  },
  {
    'employeeId': 'E01',
    'employeeName': 'Eleanor Vance',
    'department': 'Engineering',
    'deductionType': 'Housing Levy',
    'amount': 150.0,
    'employerContribution': 150.0,
  },
  {
    'employeeId': 'E02',
    'employeeName': 'Marcus Brody',
    'department': 'Engineering',
    'deductionType': 'Housing Levy',
    'amount': 130.0,
    'employerContribution': 130.0,
  },
  {
    'employeeId': 'E05',
    'employeeName': 'Amara Okafor',
    'department': 'Sales',
    'deductionType': 'SHA / SHIF',
    'amount': 200.0,
    'employerContribution': 0.0,
  },
  {
    'employeeId': 'E07',
    'employeeName': 'Zoe Patel',
    'department': 'Engineering',
    'deductionType': 'SHA / SHIF',
    'amount': 180.0,
    'employerContribution': 0.0,
  },
  {
    'employeeId': 'E06',
    'employeeName': 'Julian Hayes',
    'department': 'Finance',
    'deductionType': 'PAYE Tax',
    'amount': 910.0,
    'employerContribution': 0.0,
  },
];

final List<Map<String, dynamic>> _salesData = [
  {
    'orderId': 'ORD-1001',
    'salesperson': 'Alice Smith',
    'region': 'North America',
    'category': 'Enterprise Software',
    'quantity': 12,
    'revenue': 48000.0,
    'profit': 28800.0,
    'date': DateTime(2026, 7, 5),
  },
  {
    'orderId': 'ORD-1002',
    'salesperson': 'David Kim',
    'region': 'Asia Pacific',
    'category': 'Cloud Infrastructure',
    'quantity': 5,
    'revenue': 25000.0,
    'profit': 15000.0,
    'date': DateTime(2026, 7, 12),
  },
  {
    'orderId': 'ORD-1003',
    'salesperson': 'Elena Rostova',
    'region': 'Europe',
    'category': 'Enterprise Software',
    'quantity': 8,
    'revenue': 32000.0,
    'profit': 19200.0,
    'date': DateTime(2026, 8, 3),
  },
  {
    'orderId': 'ORD-1004',
    'salesperson': 'Alice Smith',
    'region': 'North America',
    'category': 'Consulting',
    'quantity': 20,
    'revenue': 30000.0,
    'profit': 12000.0,
    'date': DateTime(2026, 8, 15),
  },
  {
    'orderId': 'ORD-1005',
    'salesperson': 'David Kim',
    'region': 'Asia Pacific',
    'category': 'Enterprise Software',
    'quantity': 15,
    'revenue': 60000.0,
    'profit': 36000.0,
    'date': DateTime(2026, 9, 2),
  },
  {
    'orderId': 'ORD-1006',
    'salesperson': 'Elena Rostova',
    'region': 'Europe',
    'category': 'Cloud Infrastructure',
    'quantity': 9,
    'revenue': 45000.0,
    'profit': 27000.0,
    'date': DateTime(2026, 9, 20),
  },
  {
    'orderId': 'ORD-1007',
    'salesperson': 'Alice Smith',
    'region': 'North America',
    'category': 'Enterprise Software',
    'quantity': 6,
    'revenue': 24000.0,
    'profit': 14400.0,
    'date': DateTime(2026, 10, 4),
  },
  {
    'orderId': 'ORD-1008',
    'salesperson': 'David Kim',
    'region': 'Asia Pacific',
    'category': 'Consulting',
    'quantity': 18,
    'revenue': 27000.0,
    'profit': 10800.0,
    'date': DateTime(2026, 10, 9),
  },
];

final List<Map<String, dynamic>> _agingData = [
  {
    'invoiceNumber': 'INV-8801',
    'customer': 'Global Logistics Corp',
    'daysOverdue': 12,
    'amount': 14500.0,
    'dueDate': DateTime(2026, 9, 15),
  },
  {
    'invoiceNumber': 'INV-8802',
    'customer': 'Vertex Digital Media',
    'daysOverdue': 42,
    'amount': 8200.0,
    'dueDate': DateTime(2026, 8, 16),
  },
  {
    'invoiceNumber': 'INV-8803',
    'customer': 'Apex Biotech Inc',
    'daysOverdue': 78,
    'amount': 21400.0,
    'dueDate': DateTime(2026, 7, 11),
  },
  {
    'invoiceNumber': 'INV-8804',
    'customer': 'Starlight Retailers',
    'daysOverdue': 115,
    'amount': 36800.0,
    'dueDate': DateTime(2026, 6, 4),
  },
  {
    'invoiceNumber': 'INV-8805',
    'customer': 'Omni Health Systems',
    'daysOverdue': 5,
    'amount': 9300.0,
    'dueDate': DateTime(2026, 9, 22),
  },
  {
    'invoiceNumber': 'INV-8806',
    'customer': 'Pinnacle Aerospace',
    'daysOverdue': 55,
    'amount': 18700.0,
    'dueDate': DateTime(2026, 8, 3),
  },
];

// ─── Home ─────────────────────────────────────────────────────────────────────
class ShowcaseHome extends StatefulWidget {
  const ShowcaseHome({super.key});
  @override
  State<ShowcaseHome> createState() => _ShowcaseHomeState();
}

class _ShowcaseHomeState extends State<ShowcaseHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _busy = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _status = 'Generating…';
    });
    try {
      await action();
    } catch (e) {
      _status = 'Error: $e';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red.shade700, content: Text('$e')),
        );
        setState(() => _busy = false);
        return;
      }
    }
    if (mounted) setState(() => _busy = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(_status),
        ),
      );
    }
  }

  Future<void> _save(ReportArtifact a) async {
    await ReportSaver().save(a);
    _status = 'Saved: ${a.filename} (${a.formattedSize})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'syncfusion_easy_reports',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              'Full API Showcase',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.model_training), text: 'Typed Models'),
            Tab(icon: Icon(Icons.functions), text: 'All Measures'),
            Tab(icon: Icon(Icons.filter_alt), text: 'Filter & Sort'),
            Tab(icon: Icon(Icons.pivot_table_chart), text: 'CrossTab & Date'),
            Tab(icon: Icon(Icons.bolt), text: 'EasyReport'),
            Tab(icon: Icon(Icons.dashboard), text: 'Presets'),
          ],
        ),
      ),
      body: _busy
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    _status,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabs,
              children: [
                _TypedModelsTab(onRun: _run, onSave: _save),
                _AllMeasuresTab(onRun: _run, onSave: _save),
                _FilterSortTab(onRun: _run, onSave: _save),
                _CrossTabDateTab(onRun: _run, onSave: _save),
                _EasyReportTab(onRun: _run, onSave: _save),
                _PresetsGalleryTab(onRun: _run, onSave: _save),
              ],
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — Typed Models
// Demonstrates: ReportColumn.text/money/date/number/boolean/percentage,
//               generateExcel/generatePdf shorthand, sheetPerCategory
// ═══════════════════════════════════════════════════════════════════════════════
class _TypedModelsTab extends StatelessWidget {
  const _TypedModelsTab({required this.onRun, required this.onSave});
  final Future<void> Function(Future<void> Function()) onRun;
  final Future<void> Function(ReportArtifact) onSave;

  static ReportDefinition<Employee> _definition() {
    return ReportDefinition<Employee>(
      title: 'Monthly Compensation Register',
      subtitle: 'Period: October 2026  |  $_kFictional',
      branding: ReportBranding(
        companyName: 'Acme Global Corporation',
        logoPath: 'assets/logo.png',
      ),
      theme: ReportTheme.classicBlue(),
      columns: [
        ReportColumn.text(
          id: 'id',
          title: 'Emp ID',
          value: (e) => e.id,
          width: 60,
        ),
        ReportColumn.text(id: 'name', title: 'Name', value: (e) => e.name),
        ReportColumn.text(
          id: 'dept',
          title: 'Department',
          value: (e) => e.department,
        ),
        ReportColumn.text(id: 'bank', title: 'Bank', value: (e) => e.bank),
        ReportColumn.money(
          id: 'basic',
          title: 'Basic Pay',
          value: (e) => e.basicPay,
          currencyCode: 'USD',
        ),
        ReportColumn.money(
          id: 'allow',
          title: 'Allowances',
          value: (e) => e.allowances,
          currencyCode: 'USD',
        ),
        ReportColumn.money(
          id: 'deduct',
          title: 'Deductions',
          value: (e) => e.deductions,
          currencyCode: 'USD',
        ),
        ReportColumn.money(
          id: 'net',
          title: 'Net Pay',
          value: (e) => e.netPay,
          currencyCode: 'USD',
        ),
        ReportColumn.percentage(
          id: 'comm',
          title: 'Comm %',
          value: (e) => e.commissionRate * 100,
        ),
        ReportColumn.date(
          id: 'joined',
          title: 'Date Joined',
          value: (e) => e.joinedDate,
          dateFormat: 'dd-MMM-yyyy',
        ),
        ReportColumn.boolean(
          id: 'active',
          title: 'Status',
          value: (e) => e.isActive,
          trueLabel: 'Active',
          falseLabel: 'Inactive',
        ),
      ],
      analyses: [
        // 1. Flat detail register
        ReportAnalysis.detail(
          id: 'payroll_detail',
          title: 'Payroll Register',
          subtitle: 'All employee compensation line items',
          showGrandTotal: true,
          sort: [ReportSort.asc('dept'), ReportSort.asc('name')],
        ),
        // 2. Department summary — sheetPerCategory = one sheet per dept in Excel
        ReportAnalysis.grouped(
          id: 'dept_summary',
          title: 'By Department',
          subtitle: 'Headcount and totals per department',
          groupBy: ['dept'],
          sheetPerCategory: true,
          detailColumns: ['id', 'name', 'basic', 'allow', 'deduct', 'net'],
          measures: [
            ReportMeasure.count(),
            ReportMeasure.sum(
              column: 'basic',
              currencyCode: 'USD',
              title: 'Total Basic',
            ),
            ReportMeasure.sum(
              column: 'net',
              currencyCode: 'USD',
              title: 'Total Net',
            ),
            ReportMeasure.average(
              column: 'net',
              currencyCode: 'USD',
              title: 'Avg Net',
            ),
          ],
          sort: [ReportSort.desc('net_sum')],
          showGrandTotal: true,
        ),
        // 3. Bank payment schedule
        ReportAnalysis.grouped(
          id: 'bank_schedule',
          title: 'Bank Schedule',
          subtitle: 'Net pay grouped by bank for disbursement',
          groupBy: ['bank'],
          measures: [
            ReportMeasure.count(),
            ReportMeasure.sum(
              column: 'net',
              currencyCode: 'USD',
              title: 'Transfer Amount',
            ),
          ],
          showGrandTotal: true,
        ),
      ],
      excelOptions: const ExcelExportOptions(
        includeSummarySheet: true,
        freezeHeaderRow: true,
        enableAutoFilter: true,
        showSignatures: true,
        signatureLabels: [
          'Prepared By',
          'Checked By',
          'Approved By',
          'Authorized By',
        ],
      ),
      pdfOptions: const PdfExportOptions(
        showSignatures: true,
        showPageNumbers: true,
        repeatHeaders: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final def = _definition();
    final engine = ReportEngine();
    return _TabShell(
      feature: 'Typed Dart Models',
      description:
          'Define a report against a typed Dart class (Employee). '
          'Columns use typed lambdas — zero reflection, compile-time safe. '
          'Demonstrates sheetPerCategory (one Excel tab per department).',
      badge: '${_employees.length} employees',
      snippets: const [
        _CodeSnippet(
          label: 'Typed accessor columns',
          code:
              'ReportColumn.money(\n'
              '  id: \'net\', title: \'Net Pay\',\n'
              '  value: (Employee e) => e.netPay,\n'
              '  currencyCode: \'USD\',\n'
              ')\n'
              'ReportColumn.date(\n'
              '  id: \'joined\', title: \'Date Joined\',\n'
              '  value: (e) => e.joinedDate,\n'
              '  dateFormat: \'dd-MMM-yyyy\',\n'
              ')\n'
              'ReportColumn.boolean(\n'
              '  id: \'active\', title: \'Status\',\n'
              '  value: (e) => e.isActive,\n'
              '  trueLabel: \'Active\', falseLabel: \'Inactive\',\n'
              ')',
        ),
        _CodeSnippet(
          label: 'sheetPerCategory — one Excel sheet per group',
          code:
              'ReportAnalysis.grouped(\n'
              '  id: \'dept_summary\',\n'
              '  groupBy: [\'dept\'],\n'
              '  sheetPerCategory: true,  // ← key flag\n'
              '  detailColumns: [\'id\', \'name\', \'net\'],\n'
              '  measures: [\n'
              '    ReportMeasure.count(),\n'
              '    ReportMeasure.sum(column: \'net\'),\n'
              '    ReportMeasure.average(column: \'net\'),\n'
              '  ],\n'
              ')',
        ),
        _CodeSnippet(
          label: 'generateExcel shorthand (prepare + export in 1 call)',
          code:
              'final artifact = await engine.generateExcel(\n'
              '  definition: definition,\n'
              '  records: employees,\n'
              ');\n'
              'await ReportSaver().save(artifact);',
        ),
      ],
      buttons: [
        _ExportButton(
          label: 'Export Excel (register + dept sheets + bank)',
          icon: Icons.table_chart,
          color: Colors.green,
          onTap: () => onRun(() async {
            final a = await engine.generateExcel(
              definition: def,
              records: _employees,
            );
            await onSave(a);
          }),
        ),
        _ExportButton(
          label: 'Export PDF (3 sections + signatures)',
          icon: Icons.picture_as_pdf,
          filled: true,
          onTap: () => onRun(() async {
            final a = await engine.generatePdf(
              definition: def,
              records: _employees,
            );
            await onSave(a);
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — All Measures
// Demonstrates: sum, count, average, min, max, percentageOfTotal,
//               weightedAverage, formula, ReportAnalysis.summary (KPI card)
// ═══════════════════════════════════════════════════════════════════════════════
class _AllMeasuresTab extends StatelessWidget {
  const _AllMeasuresTab({required this.onRun, required this.onSave});
  final Future<void> Function(Future<void> Function()) onRun;
  final Future<void> Function(ReportArtifact) onSave;

  @override
  Widget build(BuildContext context) {
    final engine = ReportEngine();

    final def = ReportDefinition<Employee>(
      title: 'Compensation Analytics — All Measures',
      subtitle: _kFictional,
      branding: ReportBranding(
        companyName: 'Analytics Corp',
        logoPath: 'assets/logo.png',
      ),
      theme: ReportTheme.forestGreen(),
      columns: [
        ReportColumn.text(
          id: 'dept',
          title: 'Department',
          value: (e) => e.department,
        ),
        ReportColumn.text(id: 'bank', title: 'Bank', value: (e) => e.bank),
        ReportColumn.money(
          id: 'basic',
          title: 'Basic Pay',
          value: (e) => e.basicPay,
          currencyCode: 'USD',
        ),
        ReportColumn.money(
          id: 'net',
          title: 'Net Pay',
          value: (e) => e.netPay,
          currencyCode: 'USD',
        ),
        ReportColumn.number(
          id: 'allow',
          title: 'Allowances',
          value: (e) => e.allowances,
        ),
        ReportColumn.percentage(
          id: 'comm',
          title: 'Comm %',
          value: (e) => e.commissionRate * 100,
        ),
      ],
      analyses: [
        // Executive KPI summary card
        ReportAnalysis.summary(
          id: 'kpi_card',
          title: 'Executive KPI Summary',
          subtitle: 'Whole-workforce aggregate metrics',
          measures: [
            ReportMeasure.count(title: 'Total Employees'),
            ReportMeasure.sum(
              column: 'basic',
              currencyCode: 'USD',
              title: 'Total Payroll',
            ),
            ReportMeasure.average(
              column: 'net',
              currencyCode: 'USD',
              title: 'Avg Net Pay',
            ),
            ReportMeasure.min(
              column: 'net',
              currencyCode: 'USD',
              title: 'Lowest Net Pay',
            ),
            ReportMeasure.max(
              column: 'net',
              currencyCode: 'USD',
              title: 'Highest Net Pay',
            ),
          ],
        ),
        // All measure types in a grouped analysis
        ReportAnalysis.grouped(
          id: 'full_measures',
          title: 'All Measures by Department',
          groupBy: ['dept'],
          measures: [
            ReportMeasure.count(),
            ReportMeasure.sum(
              column: 'net',
              currencyCode: 'USD',
              title: 'Total Net',
            ),
            ReportMeasure.average(
              column: 'net',
              currencyCode: 'USD',
              title: 'Avg Net',
            ),
            ReportMeasure.min(
              column: 'net',
              currencyCode: 'USD',
              title: 'Min Net',
            ),
            ReportMeasure.max(
              column: 'net',
              currencyCode: 'USD',
              title: 'Max Net',
            ),
            ReportMeasure.percentageOfTotal(
              column: 'net',
              title: '% of Total Payroll',
            ),
            ReportMeasure.weightedAverage(
              column: 'net',
              weightedBy: 'allow',
              title: 'Weighted Avg Net (by Allowances)',
            ),
            ReportMeasure.formula(
              id: 'surplus_ratio',
              title: 'Surplus Ratio',
              dependsOn: ['net_sum', 'count'],
              calculate: (vals) {
                final total = vals['net_sum'] ?? 0;
                final cnt = vals['count'] ?? 1;
                return cnt > 0 ? total / cnt / 10000 : 0;
              },
              precision: 3,
            ),
          ],
          showGrandTotal: true,
        ),
      ],
      excelOptions: const ExcelExportOptions(includeSummarySheet: true),
    );

    return _TabShell(
      feature: 'All ReportMeasure Types',
      description:
          'Every measure factory in one report: count, sum, average, min, max, '
          'percentageOfTotal, weightedAverage, and custom formula. '
          'Also demonstrates ReportAnalysis.summary for KPI cards.',
      badge: '${_employees.length} records',
      snippets: const [
        _CodeSnippet(
          label: 'ReportAnalysis.summary (KPI card)',
          code:
              'ReportAnalysis.summary(\n'
              '  id: \'kpi_card\',\n'
              '  title: \'Executive KPI Summary\',\n'
              '  measures: [\n'
              '    ReportMeasure.count(title: \'Total Employees\'),\n'
              '    ReportMeasure.sum(column: \'basic\', currencyCode: \'USD\'),\n'
              '    ReportMeasure.average(column: \'net\'),\n'
              '    ReportMeasure.min(column: \'net\'),\n'
              '    ReportMeasure.max(column: \'net\'),\n'
              '  ],\n'
              ')',
        ),
        _CodeSnippet(
          label: 'percentageOfTotal + weightedAverage + formula',
          code:
              'ReportMeasure.percentageOfTotal(column: \'net\', title: \'% of Total\'),\n'
              'ReportMeasure.weightedAverage(\n'
              '  column: \'net\', weightedBy: \'allowances\',\n'
              '),\n'
              'ReportMeasure.formula(\n'
              '  id: \'surplus_ratio\',\n'
              '  dependsOn: [\'net_sum\', \'count\'],\n'
              '  calculate: (vals) =>\n'
              '    vals[\'net_sum\']! / vals[\'count\']! / 10000,\n'
              ')',
        ),
      ],
      buttons: [
        _ExportButton(
          label: 'Export Excel (KPI card + all measures)',
          icon: Icons.table_chart,
          color: Colors.green,
          onTap: () => onRun(() async {
            final a = await engine.generateExcel(
              definition: def,
              records: _employees,
            );
            await onSave(a);
          }),
        ),
        _ExportButton(
          label: 'Export PDF',
          icon: Icons.picture_as_pdf,
          filled: true,
          onTap: () => onRun(() async {
            final a = await engine.generatePdf(
              definition: def,
              records: _employees,
            );
            await onSave(a);
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3 — Filter, Sort, TopN, CategoryBuckets
// ═══════════════════════════════════════════════════════════════════════════════
class _FilterSortTab extends StatefulWidget {
  const _FilterSortTab({required this.onRun, required this.onSave});
  final Future<void> Function(Future<void> Function()) onRun;
  final Future<void> Function(ReportArtifact) onSave;
  @override
  State<_FilterSortTab> createState() => _FilterSortTabState();
}

class _FilterSortTabState extends State<_FilterSortTab> {
  String _filterDept = 'All';
  bool _activeOnly = false;
  String _sortColumn = 'net';
  bool _ascending = false;
  int _topN = 0;

  ReportDefinition<Employee> _buildDef() {
    final filters = <ReportFilter>[
      if (_filterDept != 'All')
        ReportFilter(
          fieldId: 'dept',
          operator: ReportFilterOperator.equals,
          value: _filterDept,
        ),
      if (_activeOnly)
        ReportFilter(
          fieldId: 'active',
          operator: ReportFilterOperator.equals,
          value: true,
        ),
    ];

    return ReportDefinition<Employee>(
      title: 'Filtered Payroll Report',
      subtitle:
          'Dept: $_filterDept  |  Active only: $_activeOnly  |  '
          'Sort: $_sortColumn ${_ascending ? "▲" : "▼"}  |  $_kFictional',
      branding: ReportBranding(
        companyName: 'Filter Demo Corp',
        logoPath: 'assets/logo.png',
      ),
      theme: ReportTheme.slateGrey(),
      columns: [
        ReportColumn.text(id: 'id', title: 'ID', value: (e) => e.id),
        ReportColumn.text(id: 'name', title: 'Name', value: (e) => e.name),
        ReportColumn.text(
          id: 'dept',
          title: 'Department',
          value: (e) => e.department,
        ),
        ReportColumn.money(
          id: 'basic',
          title: 'Basic Pay',
          value: (e) => e.basicPay,
          currencyCode: 'USD',
        ),
        ReportColumn.money(
          id: 'net',
          title: 'Net Pay',
          value: (e) => e.netPay,
          currencyCode: 'USD',
        ),
        ReportColumn.boolean(
          id: 'active',
          title: 'Active',
          value: (e) => e.isActive,
        ),
      ],
      analyses: [
        ReportAnalysis.detail(
          id: 'filtered_detail',
          title: 'Filtered Records',
          filters: filters,
          sort: [ReportSort(fieldId: _sortColumn, isAscending: _ascending)],
          showGrandTotal: true,
        ),
        ReportAnalysis.grouped(
          id: 'ar_aging',
          title: 'AR Aging — Invoices by Overdue Bucket',
          subtitle: 'ReportCategoryBucket demo — $_kFictional',
          groupBy: ['daysOverdue'],
          categoryBuckets: {
            'daysOverdue': const [
              ReportCategoryBucket(
                label: 'Current (0-30 days)',
                min: 0,
                max: 30,
              ),
              ReportCategoryBucket(label: '31-60 Days', min: 30, max: 60),
              ReportCategoryBucket(label: '61-90 Days', min: 60, max: 90),
              ReportCategoryBucket(label: '90+ Days (Critical)', min: 90),
            ],
          },
          measures: [
            ReportMeasure.count(title: 'Invoices'),
            ReportMeasure.sum(
              column: 'amount',
              currencyCode: 'USD',
              title: 'Total Overdue',
            ),
          ],
          showGrandTotal: true,
        ),
        ReportAnalysis.grouped(
          id: 'top_earners',
          title: 'Top${_topN > 0 ? " $_topN" : ""} Depts by Net Pay',
          groupBy: ['dept'],
          measures: [
            ReportMeasure.sum(
              column: 'net',
              currencyCode: 'USD',
              title: 'Total Net',
            ),
            ReportMeasure.count(),
          ],
          topN: _topN > 0
              ? ReportTopN(
                  count: _topN,
                  rankBy: 'net_sum',
                  otherLabel: 'Other Depts',
                )
              : null,
          sort: [ReportSort.desc('net_sum')],
          showGrandTotal: true,
        ),
      ],
      excelOptions: const ExcelExportOptions(includeSummarySheet: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = ReportEngine();
    const depts = ['All', 'Engineering', 'Marketing', 'Sales', 'Finance'];

    return _TabShell(
      feature: 'Filters, Sort, TopN & CategoryBuckets',
      description:
          'Pre-aggregation filters (equals, contains, between, isNull, inList…), '
          'multi-key sorting, Top-N ranking with an "Other" roll-up, '
          'and numeric category buckets (e.g. AR aging tiers).',
      badge:
          '${_employees.length} employees + ${_agingData.length} AR invoices',
      header: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure Filters',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _filterDept,
                      decoration: const InputDecoration(
                        labelText: 'Department filter',
                        border: OutlineInputBorder(),
                      ),
                      items: depts
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _filterDept = v ?? 'All'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _sortColumn,
                      decoration: const InputDecoration(
                        labelText: 'Sort By',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('Name')),
                        DropdownMenuItem(value: 'net', child: Text('Net Pay')),
                        DropdownMenuItem(
                          value: 'basic',
                          child: Text('Basic Pay'),
                        ),
                        DropdownMenuItem(
                          value: 'dept',
                          child: Text('Department'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _sortColumn = v ?? 'net'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _topN,
                      decoration: const InputDecoration(
                        labelText: 'Top-N Depts',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('All departments'),
                        ),
                        DropdownMenuItem(value: 2, child: Text('Top 2')),
                        DropdownMenuItem(value: 3, child: Text('Top 3')),
                      ],
                      onChanged: (v) => setState(() => _topN = v ?? 0),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active employees only'),
                      value: _activeOnly,
                      onChanged: (v) => setState(() => _activeOnly = v),
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ascending order'),
                      value: _ascending,
                      onChanged: (v) => setState(() => _ascending = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      snippets: const [
        _CodeSnippet(
          label: 'ReportFilter — multiple operators available',
          code:
              '// equals, notEquals, contains, greaterThan,\n'
              '// lessThan, between, inList, isNull, isNotNull\n'
              'ReportFilter(\n'
              '  fieldId: \'dept\',\n'
              '  operator: ReportFilterOperator.equals,\n'
              '  value: \'Engineering\',\n'
              ')\n'
              '// Custom predicate\n'
              'ReportFilter(\n'
              '  fieldId: \'net\',\n'
              '  customPredicate: (val, row) => (val as num) > 8000,\n'
              ')',
        ),
        _CodeSnippet(
          label: 'ReportCategoryBucket (AR aging)',
          code:
              'categoryBuckets: {\n'
              '  \'daysOverdue\': [\n'
              '    ReportCategoryBucket(label: \'0-30 days\',  max: 30),\n'
              '    ReportCategoryBucket(label: \'31-60 Days\', min: 30, max: 60),\n'
              '    ReportCategoryBucket(label: \'61-90 Days\', min: 60, max: 90),\n'
              '    ReportCategoryBucket(label: \'90+ Critical\', min: 90),\n'
              '  ],\n'
              '}',
        ),
        _CodeSnippet(
          label: 'ReportTopN',
          code:
              'topN: ReportTopN(\n'
              '  count: 3,\n'
              '  rankBy: \'net_sum\',     // measure ID\n'
              '  otherLabel: \'Other\',   // rolls remaining into one row\n'
              '),\n'
              'sort: [ReportSort.desc(\'net_sum\')],',
        ),
      ],
      buttons: [
        _ExportButton(
          label: 'Export Filtered Excel',
          icon: Icons.table_chart,
          color: Colors.green,
          onTap: () => widget.onRun(() async {
            final def = _buildDef();
            final prepared = await engine.prepare(
              definition: def,
              records: _employees,
            );
            final a = await engine.exportExcel(prepared);
            await widget.onSave(a);
          }),
        ),
        _ExportButton(
          label: 'Export Filtered PDF',
          icon: Icons.picture_as_pdf,
          filled: true,
          onTap: () => widget.onRun(() async {
            final def = _buildDef();
            final prepared = await engine.prepare(
              definition: def,
              records: _employees,
            );
            final a = await engine.exportPdf(prepared);
            await widget.onSave(a);
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 4 — CrossTab & Date Grouping
// ═══════════════════════════════════════════════════════════════════════════════
class _CrossTabDateTab extends StatefulWidget {
  const _CrossTabDateTab({required this.onRun, required this.onSave});
  final Future<void> Function(Future<void> Function()) onRun;
  final Future<void> Function(ReportArtifact) onSave;
  @override
  State<_CrossTabDateTab> createState() => _CrossTabDateTabState();
}

class _CrossTabDateTabState extends State<_CrossTabDateTab> {
  String _interval = 'month';

  @override
  Widget build(BuildContext context) {
    final engine = ReportEngine();
    final interval = _interval == 'quarter'
        ? ReportDateInterval.quarter
        : ReportDateInterval.month;

    final def = ReportDefinition<Map<String, dynamic>>(
      title: 'Sales CrossTab & Monthly Trend',
      subtitle: _kFictional,
      branding: ReportBranding(
        companyName: 'Apex Dynamics Inc',
        logoPath: 'assets/logo.png',
      ),
      theme: ReportTheme.classicBlue(),
      columns: [
        ReportColumn.forMap(key: 'orderId', title: 'Order ID'),
        ReportColumn.forMap(key: 'salesperson', title: 'Salesperson'),
        ReportColumn.forMap(key: 'region', title: 'Region'),
        ReportColumn.forMap(key: 'category', title: 'Category'),
        ReportColumn.forMap(
          key: 'quantity',
          title: 'Qty',
          type: ReportFieldType.number,
        ),
        ReportColumn.forMap(
          key: 'revenue',
          title: 'Revenue',
          type: ReportFieldType.money,
          currencyCode: 'USD',
        ),
        ReportColumn.forMap(
          key: 'profit',
          title: 'Profit',
          type: ReportFieldType.money,
          currencyCode: 'USD',
        ),
        ReportColumn.forMap(
          key: 'date',
          title: 'Date',
          type: ReportFieldType.date,
        ),
      ],
      analyses: [
        // Pivot: salesperson × region
        ReportAnalysis.crossTab(
          id: 'sales_pivot',
          title: 'Revenue: Salesperson x Region',
          subtitle: 'Total revenue per salesperson per region',
          rowDimension: 'salesperson',
          columnDimension: 'region',
          measure: ReportMeasure.sum(
            column: 'revenue',
            currencyCode: 'USD',
            title: 'Revenue',
          ),
          showGrandTotal: true,
        ),
        // Pivot: category × region
        ReportAnalysis.crossTab(
          id: 'profit_pivot',
          title: 'Profit: Category x Region',
          subtitle: 'Total profit per product category per region',
          rowDimension: 'category',
          columnDimension: 'region',
          measure: ReportMeasure.sum(
            column: 'profit',
            currencyCode: 'USD',
            title: 'Profit',
          ),
          showGrandTotal: true,
        ),
        // Date-grouped trend
        ReportAnalysis.grouped(
          id: 'date_trend',
          title:
              'Revenue Trend by ${_interval == "quarter" ? "Quarter" : "Month"}',
          subtitle: 'Orders bucketed into time periods',
          groupBy: ['date'],
          dateGrouping: ReportDateGrouping(
            columnId: 'date',
            interval: interval,
          ),
          measures: [
            ReportMeasure.count(title: 'Orders'),
            ReportMeasure.sum(
              column: 'revenue',
              currencyCode: 'USD',
              title: 'Revenue',
            ),
            ReportMeasure.sum(
              column: 'profit',
              currencyCode: 'USD',
              title: 'Profit',
            ),
          ],
          showGrandTotal: true,
        ),
      ],
      excelOptions: const ExcelExportOptions(includeSummarySheet: true),
    );

    return _TabShell(
      feature: 'CrossTab (Pivot) & Date Grouping',
      description:
          'Build 2D pivot matrices with ReportAnalysis.crossTab. '
          'Group time-series data by month or quarter using ReportDateGrouping. '
          'Works on both typed models and Map datasets.',
      badge: '${_salesData.length} sales orders',
      header: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text(
                'Date Grouping:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('By Month'),
                selected: _interval == 'month',
                onSelected: (_) => setState(() => _interval = 'month'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('By Quarter'),
                selected: _interval == 'quarter',
                onSelected: (_) => setState(() => _interval = 'quarter'),
              ),
            ],
          ),
        ),
      ),
      snippets: const [
        _CodeSnippet(
          label: 'ReportAnalysis.crossTab (2D Pivot)',
          code:
              'ReportAnalysis.crossTab(\n'
              '  id: \'sales_pivot\',\n'
              '  title: \'Revenue: Salesperson x Region\',\n'
              '  rowDimension: \'salesperson\',\n'
              '  columnDimension: \'region\',\n'
              '  measure: ReportMeasure.sum(\n'
              '    column: \'revenue\', currencyCode: \'USD\',\n'
              '  ),\n'
              '  showGrandTotal: true,\n'
              ')',
        ),
        _CodeSnippet(
          label: 'ReportDateGrouping',
          code:
              'ReportAnalysis.grouped(\n'
              '  id: \'monthly_trend\',\n'
              '  groupBy: [\'date\'],\n'
              '  dateGrouping: ReportDateGrouping(\n'
              '    columnId: \'date\',\n'
              '    interval: ReportDateInterval.quarter,\n'
              '    // or .month, .year\n'
              '  ),\n'
              '  measures: [\n'
              '    ReportMeasure.sum(column: \'revenue\'),\n'
              '  ],\n'
              ')',
        ),
        _CodeSnippet(
          label: 'ReportColumn.forMap (schema from Map keys)',
          code:
              '// No typed class needed — pull values by key\n'
              'ReportColumn.forMap(\n'
              '  key: \'revenue\',\n'
              '  title: \'Revenue\',\n'
              '  type: ReportFieldType.money,\n'
              '  currencyCode: \'USD\',\n'
              ')',
        ),
      ],
      buttons: [
        _ExportButton(
          label: 'Export Excel (2 pivots + trend)',
          icon: Icons.table_chart,
          color: Colors.green,
          onTap: () => widget.onRun(() async {
            final a = await engine.generateExcel(
              definition: def,
              records: _salesData,
            );
            await widget.onSave(a);
          }),
        ),
        _ExportButton(
          label: 'Export PDF',
          icon: Icons.picture_as_pdf,
          filled: true,
          onTap: () => widget.onRun(() async {
            final a = await engine.generatePdf(
              definition: def,
              records: _salesData,
            );
            await widget.onSave(a);
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 5 — EasyReport facade
// ═══════════════════════════════════════════════════════════════════════════════
class _EasyReportTab extends StatefulWidget {
  const _EasyReportTab({required this.onRun, required this.onSave});
  final Future<void> Function(Future<void> Function()) onRun;
  final Future<void> Function(ReportArtifact) onSave;
  @override
  State<_EasyReportTab> createState() => _EasyReportTabState();
}

class _EasyReportTabState extends State<_EasyReportTab> {
  String _dataset = 'Deductions';
  String _groupByField = 'deductionType';
  bool _sheetPerCategory = true;
  bool _crossTab = false;
  bool _summaryCard = true;
  bool _signatures = true;
  String _theme = 'Classic Blue';

  List<Map<String, dynamic>> get _data =>
      _dataset == 'Deductions' ? _deductionsData : _salesData;

  List<String> get _fields => _data.isNotEmpty ? _data.first.keys.toList() : [];

  ReportTheme _themeObj() => switch (_theme) {
    'Forest Green' => ReportTheme.forestGreen(),
    'Corporate Dark' => ReportTheme.corporateDark(),
    'Slate Grey' => ReportTheme.slateGrey(),
    _ => ReportTheme.classicBlue(),
  };

  @override
  Widget build(BuildContext context) {
    return _TabShell(
      feature: 'EasyReport — Zero-Boilerplate Facade',
      description:
          'Pass any List<Map<String,dynamic>> — no columns, no analyses, no schema. '
          'EasyReport.fromMaps auto-infers field types from key names and value types, '
          'then generates a professional multi-sheet report.',
      badge: '${_data.length} rows',
      header: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure EasyReport',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _dataset,
                      decoration: const InputDecoration(
                        labelText: 'Dataset',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Deductions',
                          child: Text('Deductions (9 rows)'),
                        ),
                        DropdownMenuItem(
                          value: 'Sales',
                          child: Text('Sales Orders (8 rows)'),
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        _dataset = v ?? 'Deductions';
                        _groupByField = _fields.first;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('$_dataset-$_groupByField'),
                      initialValue: _fields.contains(_groupByField)
                          ? _groupByField
                          : _fields.firstOrNull,
                      decoration: const InputDecoration(
                        labelText: 'Group By',
                        border: OutlineInputBorder(),
                      ),
                      items: _fields
                          .map(
                            (k) => DropdownMenuItem(value: k, child: Text(k)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _groupByField = v ?? _groupByField),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _theme,
                      decoration: const InputDecoration(
                        labelText: 'Theme',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Classic Blue',
                          child: Text('Classic Blue'),
                        ),
                        DropdownMenuItem(
                          value: 'Forest Green',
                          child: Text('Forest Green'),
                        ),
                        DropdownMenuItem(
                          value: 'Corporate Dark',
                          child: Text('Corporate Dark'),
                        ),
                        DropdownMenuItem(
                          value: 'Slate Grey',
                          child: Text('Slate Grey'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _theme = v ?? 'Classic Blue'),
                    ),
                  ),
                ],
              ),
              Wrap(
                children: [
                  _Switch(
                    'Sheet Per Category',
                    _sheetPerCategory,
                    (v) => setState(() => _sheetPerCategory = v),
                  ),
                  _Switch(
                    'Include CrossTab',
                    _crossTab,
                    (v) => setState(() => _crossTab = v),
                  ),
                  _Switch(
                    'Summary Card (KPIs)',
                    _summaryCard,
                    (v) => setState(() => _summaryCard = v),
                  ),
                  _Switch(
                    'Signature Blocks',
                    _signatures,
                    (v) => setState(() => _signatures = v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      snippets: const [
        _CodeSnippet(
          label: 'EasyReport.fromMaps — complete API',
          code:
              'final report = EasyReport.fromMaps(\n'
              '  data: myMaps,\n'
              '  title: \'Deductions Report\',\n'
              '  companyName: \'Acme Corp\',\n'
              '  groupBy: \'deductionType\',\n'
              '  sheetPerCategory: true,\n'
              '  includeCrossTab: true,\n'
              '  includeSummaryCard: true,\n'
              '  showSignatures: true,\n'
              ');\n'
              '\n'
              '// Export options:\n'
              'await report.saveExcel();      // save to disk\n'
              'await report.savePdf();        // save to disk\n'
              'final artifact = await report.toExcel();\n'
              'final bytes = artifact.bytes; // get bytes without saving\n'
              'final bytes = await report.pdfBytes();',
        ),
        _CodeSnippet(
          label: 'Auto-inference rules',
          code:
              '// Key heuristics for auto-typed columns:\n'
              '// "amount","salary","price","cost","pay","revenue"\n'
              '//   + num value  =>  money column\n'
              '// "date","time","joined","created"\n'
              '//   + DateTime   =>  date column\n'
              '// bool value     =>  boolean column\n'
              '// other num      =>  number column\n'
              '// else           =>  text column',
        ),
      ],
      buttons: [
        _ExportButton(
          label: 'Save Excel via EasyReport',
          icon: Icons.table_chart,
          color: Colors.green,
          onTap: () => widget.onRun(() async {
            final r = EasyReport.fromMaps(
              data: _data,
              title: '$_dataset Report',
              subtitle: _kFictional,
              branding: ReportBranding(
                companyName: 'Easy Corp',
                logoPath: 'assets/logo.png',
              ),
              theme: _themeObj(),
              groupBy: _groupByField,
              sheetPerCategory: _sheetPerCategory,
              includeCrossTab: _crossTab,
              includeSummaryCard: _summaryCard,
              showSignatures: _signatures,
            );
            await r.saveExcel();
          }),
        ),
        _ExportButton(
          label: 'Save PDF via EasyReport',
          icon: Icons.picture_as_pdf,
          filled: true,
          onTap: () => widget.onRun(() async {
            final r = EasyReport.fromMaps(
              data: _data,
              title: '$_dataset Report',
              subtitle: _kFictional,
              branding: ReportBranding(
                companyName: 'Easy Corp',
                logoPath: 'assets/logo.png',
              ),
              theme: _themeObj(),
              groupBy: _groupByField,
              sheetPerCategory: _sheetPerCategory,
              includeSummaryCard: _summaryCard,
              showSignatures: _signatures,
            );
            await r.savePdf();
          }),
        ),
        _ExportButton(
          label: 'Get Excel Bytes (no file write)',
          icon: Icons.memory,
          color: Colors.purple,
          onTap: () => widget.onRun(() async {
            final r = EasyReport.fromMaps(
              data: _data,
              title: 'Bytes Demo',
              branding: ReportBranding(
                companyName: 'Easy Corp',
                logoPath: 'assets/logo.png',
              ),
              groupBy: _groupByField,
            );
            final artifact = await r.toExcel();
            print(
              '${artifact.bytes.length} bytes ready — send to API, share, or cache!',
            );
          }),
        ),
      ],
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontSize: 13)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 6 — Presets Gallery
// ═══════════════════════════════════════════════════════════════════════════════
class _PresetsGalleryTab extends StatelessWidget {
  const _PresetsGalleryTab({required this.onRun, required this.onSave});
  final Future<void> Function(Future<void> Function()) onRun;
  final Future<void> Function(ReportArtifact) onSave;

  @override
  Widget build(BuildContext context) {
    final engine = ReportEngine();

    Future<void> run<T>(
      ReportDefinition<T> def,
      List<T> data, {
      required bool pdf,
    }) => onRun(() async {
      final a = pdf
          ? await engine.generatePdf(definition: def, records: data)
          : await engine.generateExcel(definition: def, records: data);
      await onSave(a);
    });

    final inventoryData = <Map<String, dynamic>>[
      {
        'sku': 'SKU-501',
        'name': '4K Pro Display 27"',
        'category': 'Monitors',
        'warehouse': 'North Hub',
        'stockOnHand': 140,
        'reorderLevel': 30,
        'unitCost': 320.0,
      },
      {
        'sku': 'SKU-502',
        'name': 'Ergonomic Mechanical Keyboard',
        'category': 'Peripherals',
        'warehouse': 'Central Depot',
        'stockOnHand': 25,
        'reorderLevel': 40,
        'unitCost': 85.0,
      },
      {
        'sku': 'SKU-503',
        'name': 'Wireless Noise-Canceling Headset',
        'category': 'Audio',
        'warehouse': 'North Hub',
        'stockOnHand': 85,
        'reorderLevel': 20,
        'unitCost': 110.0,
      },
      {
        'sku': 'SKU-504',
        'name': 'USB-C Multi-Port Docking Hub',
        'category': 'Peripherals',
        'warehouse': 'West Logistics',
        'stockOnHand': 210,
        'reorderLevel': 50,
        'unitCost': 45.0,
      },
      {
        'sku': 'SKU-505',
        'name': 'Ultra-Fast NVMe SSD 2TB',
        'category': 'Storage',
        'warehouse': 'Central Depot',
        'stockOnHand': 60,
        'reorderLevel': 25,
        'unitCost': 140.0,
      },
    ];

    final hrData = _employees
        .map(
          (e) =>
              {
                    'id': e.id,
                    'name': e.name,
                    'dept': e.department,
                    'joinedDate': e.joinedDate,
                    'isActive': e.isActive,
                    'basicPay': e.basicPay,
                  }
                  as Map<String, dynamic>,
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _InfoBanner(
          'Domain presets wrap common ReportDefinition patterns. '
          'Pass your data — the schema is pre-configured.',
        ),
        const SizedBox(height: 12),
        _PresetCard(
          title: 'Monthly Payroll Register',
          category: 'Payroll',
          icon: Icons.payments_outlined,
          color: const Color(0xFF1565C0),
          description:
              'Full payroll ledger with basic pay, allowances, deductions, '
              'net pay, department totals, and bank transfer schedule.',
          recordCount: _employees.length,
          apiCall:
              'PayrollReportPresets.monthlyPayroll(\n  companyName: \'Acme Corp\',\n)',
          onExcel: () => run(
            PayrollReportPresets.monthlyPayroll(companyName: 'Acme Corp'),
            _employees,
            pdf: false,
          ),
          onPdf: () => run(
            PayrollReportPresets.monthlyPayroll(companyName: 'Acme Corp'),
            _employees,
            pdf: true,
          ),
        ),
        _PresetCard(
          title: 'Categorized Deductions & Remittances',
          category: 'Payroll',
          icon: Icons.pie_chart_outline,
          color: const Color(0xFF6A1B9A),
          description:
              'Deductions per scheme (KCB Loan, Equity Loan, Housing Levy, '
              'SHA/SHIF, PAYE) — one Excel sheet per type, with totals and signatures.',
          recordCount: _deductionsData.length,
          apiCall:
              'PayrollReportPresets.categorizedDeductions(\n  companyName: \'Acme Corp\',\n)',
          onExcel: () => run(
            PayrollReportPresets.categorizedDeductions(
              companyName: 'Acme Corp',
            ),
            _deductionsData,
            pdf: false,
          ),
          onPdf: () => run(
            PayrollReportPresets.categorizedDeductions(
              companyName: 'Acme Corp',
            ),
            _deductionsData,
            pdf: true,
          ),
        ),
        _PresetCard(
          title: 'Sales Performance & CrossTab',
          category: 'Sales',
          icon: Icons.trending_up,
          color: const Color(0xFF2E7D32),
          description:
              'Order listing, salesperson ranking, gross margin, '
              'and category-by-region pivot matrix.',
          recordCount: _salesData.length,
          apiCall:
              'SalesReportPresets.salesPerformance(\n  companyName: \'Apex Dynamics\',\n)',
          onExcel: () => run(
            SalesReportPresets.salesPerformance(companyName: 'Apex Dynamics'),
            _salesData,
            pdf: false,
          ),
          onPdf: () => run(
            SalesReportPresets.salesPerformance(companyName: 'Apex Dynamics'),
            _salesData,
            pdf: true,
          ),
        ),
        _PresetCard(
          title: 'Accounts Receivable Aging',
          category: 'Finance',
          icon: Icons.account_balance,
          color: const Color(0xFF37474F),
          description:
              'Aging buckets: 0-30, 31-60, 61-90, 90+ days overdue, '
              'with customer-level detail per bucket.',
          recordCount: _agingData.length,
          apiCall:
              'FinanceReportPresets.accountsReceivableAging(\n  companyName: \'Starlight\',\n)',
          onExcel: () => run(
            FinanceReportPresets.accountsReceivableAging(
              companyName: 'Starlight Financials',
            ),
            _agingData,
            pdf: false,
          ),
          onPdf: () => run(
            FinanceReportPresets.accountsReceivableAging(
              companyName: 'Starlight Financials',
            ),
            _agingData,
            pdf: true,
          ),
        ),
        _PresetCard(
          title: 'Stock Valuation & Low-Stock Alerts',
          category: 'Inventory',
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFFE65100),
          description:
              'SKU register with unit costs, stock-on-hand valuation, '
              'warehouse location groups, and reorder alerts.',
          recordCount: inventoryData.length,
          apiCall:
              'InventoryReportPresets.stockValuation(\n  companyName: \'Global Warehouse\',\n)',
          onExcel: () => run(
            InventoryReportPresets.stockValuation(
              companyName: 'Global Warehouse Logistics',
            ),
            inventoryData,
            pdf: false,
          ),
          onPdf: () => run(
            InventoryReportPresets.stockValuation(
              companyName: 'Global Warehouse Logistics',
            ),
            inventoryData,
            pdf: true,
          ),
        ),
        _PresetCard(
          title: 'HR Headcount & Compensation Overview',
          category: 'HR',
          icon: Icons.people_outline,
          color: const Color(0xFF00796B),
          description:
              'Employee roster with tenure, department headcount, '
              'active/inactive status, and compensation ranges.',
          recordCount: hrData.length,
          apiCall:
              'HRReportPresets.headcountOverview(\n  companyName: \'Acme Corp\',\n)',
          onExcel: () => run(
            HrReportPresets.headcountSummary(companyName: 'Acme Corp'),
            hrData,
            pdf: false,
          ),
          onPdf: () => run(
            HrReportPresets.headcountSummary(companyName: 'Acme Corp'),
            hrData,
            pdf: true,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared UI helpers
// ═══════════════════════════════════════════════════════════════════════════════

class _TabShell extends StatelessWidget {
  const _TabShell({
    required this.feature,
    required this.description,
    required this.badge,
    required this.snippets,
    required this.buttons,
    this.header,
  });

  final String feature;
  final String description;
  final String badge;
  final List<_CodeSnippet> snippets;
  final List<_ExportButton> buttons;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(badge, style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _InfoBanner(
          '$_kFictional — generated reports contain synthetic data only.',
        ),
        const SizedBox(height: 10),
        if (header != null) ...[header!, const SizedBox(height: 10)],
        ...snippets,
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: buttons),
      ],
    );
  }
}

class _CodeSnippet extends StatelessWidget {
  const _CodeSnippet({required this.label, required this.code});
  final String label;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                color: Color(0xFF64FFDA),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.title,
    required this.category,
    required this.icon,
    required this.color,
    required this.description,
    required this.recordCount,
    required this.apiCall,
    required this.onExcel,
    required this.onPdf,
  });

  final String title;
  final String category;
  final IconData icon;
  final Color color;
  final String description;
  final int recordCount;
  final String apiCall;
  final VoidCallback onExcel;
  final VoidCallback onPdf;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    '$recordCount rows',
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                apiCall,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Color(0xFF64FFDA),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.table_view,
                    size: 16,
                    color: Colors.green,
                  ),
                  label: const Text('Excel'),
                  onPressed: onExcel,
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('PDF'),
                  onPressed: onPdf,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
