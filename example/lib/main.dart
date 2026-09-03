import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:syncfusion_easy_reports/syncfusion_easy_reports.dart';

void main() {
  runApp(const EasyReportsExampleApp());
}

class EasyReportsExampleApp extends StatelessWidget {
  const EasyReportsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Reports Example',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const ReportsHomeScreen(),
    );
  }
}

class ReportsHomeScreen extends StatefulWidget {
  const ReportsHomeScreen({super.key});

  @override
  State<ReportsHomeScreen> createState() => _ReportsHomeScreenState();
}

class _ReportsHomeScreenState extends State<ReportsHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _logs = [];
  List<Map<String, dynamic>>? _parsedRecords;

  // Generic Dummy Data Generators
  final List<Map<String, dynamic>> _employeeRawData = [
    {
      'id': 'EMP001',
      'name': 'John Doe',
      'dept': 'IT',
      'salary': 75000.00,
      'bonus': 5000.00,
      'joined': DateTime(2022, 3, 15),
    },
    {
      'id': 'EMP002',
      'name': 'Jane Smith',
      'dept': 'HR',
      'salary': 65000.00,
      'bonus': 3000.00,
      'joined': DateTime(2021, 6, 20),
    },
    {
      'id': 'EMP003',
      'name': 'Bob Johnson',
      'dept': 'IT',
      'salary': 85000.00,
      'bonus': 7000.00,
      'joined': DateTime(2020, 11, 1),
    },
    {
      'id': 'EMP004',
      'name': 'Alice Williams',
      'dept': 'Finance',
      'salary': 90000.00,
      'bonus': 8000.00,
      'joined': DateTime(2023, 1, 10),
    },
    {
      'id': 'EMP005',
      'name': 'Charlie Brown',
      'dept': 'HR',
      'salary': 60000.00,
      'bonus': 2000.00,
      'joined': DateTime(2024, 2, 5),
    },
    {
      'id': 'EMP006',
      'name': 'David Miller',
      'dept': 'Finance',
      'salary': 78000.00,
      'bonus': 4000.00,
      'joined': DateTime(2022, 8, 18),
    },
  ];

  // Interactive builder state
  int _interactiveEmployeeCount = 6;
  String _interactiveCurrencySymbol = 'KES';
  bool _interactiveCalculateTotals = true;
  String? _interactiveJson;
  List<List<dynamic>> _interactivePreviewRows = [];

  final Map<String, Map<String, dynamic>> _sampleTemplates = {
    'Payroll (Small)': {'employees': 4, 'currency': 'KES', 'totals': true},
    'Payroll (Medium)': {'employees': 8, 'currency': 'USD', 'totals': true},
    'Sales Snapshot': {'employees': 6, 'currency': 'USD', 'totals': false},
  };

  void _interactiveLoadSample(String key) {
    final map = _sampleTemplates[key];
    if (map != null) {
      setState(() {
        _interactiveEmployeeCount =
            map['employees'] as int? ?? _interactiveEmployeeCount;
        _interactiveCurrencySymbol =
            map['currency'] as String? ?? _interactiveCurrencySymbol;
        _interactiveCalculateTotals =
            map['totals'] as bool? ?? _interactiveCalculateTotals;
      });
      _buildInteractiveJson();
    }
  }

  void _buildInteractiveJson() {
    final List<List<dynamic>> rows = List.generate(_interactiveEmployeeCount, (
      i,
    ) {
      final idx = i % _employeeRawData.length;
      final base = _employeeRawData[idx];
      return [
        base['id'] + '_${i + 1}',
        base['name'],
        base['dept'],
        base['salary'] ?? 0.0,
      ];
    });

    final table = ReportTable(
      headers: ['Employee ID', 'Name', 'Department', 'Salary'],
      rows: rows,
      currencyColumnIndices: [3],
      currencySymbol: _interactiveCurrencySymbol,
      calculateTotals: _interactiveCalculateTotals,
    );

    final section = ReportSection(
      title: 'Interactive Payroll',
      description: 'Built from UI controls',
      table: table,
    );

    final data = ReportData(
      title: 'Interactive Report',
      sections: [section],
      branding: ReportBranding(companyName: 'Demo Corp'),
    );

    final enc = JsonEncoder.withIndent('  ');
    setState(() {
      _interactiveJson = enc.convert({
        'title': data.title,
        'sections': data.sections
            .map(
              (s) => {
                'title': s.title,
                'description': s.description,
                'headers': s.table?.headers,
                'rows': s.table?.rows,
              },
            )
            .toList(),
      });

      _interactivePreviewRows = rows.take(100).toList();
    });
  }

  Future<void> _downloadInteractiveTemplate() async {
    final columns = [
      ExcelTemplateColumn(name: 'Employee ID', sampleValue: 'EMP100'),
      ExcelTemplateColumn(name: 'Name', sampleValue: 'Jane Doe'),
      ExcelTemplateColumn(name: 'Department', sampleValue: 'IT'),
      ExcelTemplateColumn(name: 'Salary', sampleValue: '75000'),
    ];

    final service = ExcelTemplateService();
    final bytes = await service.generateTemplate(
      columns: columns,
      lookupLists: {
        'Departments': ['IT', 'HR', 'Finance'],
      },
    );
    // show JSON preview of template
    try {
      final decoded = utf8.decode(bytes);
      _addLog('Interactive template generated (preview shown)');
      setState(() {
        _interactiveJson = decoded;
      });
    } catch (_) {
      _addLog('Interactive template generated');
    }

    // Also trigger a download/save
    await service.generateAndDownloadTemplate(
      columns: columns,
      lookupLists: {
        'Departments': ['IT', 'HR', 'Finance'],
      },
      filename: 'interactive_template',
    );
  }

  Future<void> _generateInteractiveExcel() async {
    _buildInteractiveJson();
    final excelGen = ExcelReportGenerator();

    final rows = _interactivePreviewRows;
    final table = ReportTable(
      headers: ['Employee ID', 'Name', 'Department', 'Salary'],
      rows: rows,
      currencyColumnIndices: [3],
      currencySymbol: _interactiveCurrencySymbol,
      calculateTotals: _interactiveCalculateTotals,
    );

    final section = ReportSection(
      title: 'Interactive Payroll',
      description: 'Generated from UI',
      table: table,
    );
    final data = ReportData(
      title: 'Interactive Export',
      sections: [section],
      branding: ReportBranding(companyName: 'Demo Corp'),
    );

    await excelGen.generateAndDownload(data, 'interactive_payroll_report');
    _addLog('Success: Saved interactive_payroll_report.xlsx');
  }

  Future<void> _generateAdvancedPayrollExcel() async {
    _addLog('Building advanced payroll dataset...');

    // Build detailed payroll rows with computed fields
    final List<List<dynamic>> payrollRows = [];

    for (int i = 0; i < _employeeRawData.length; i++) {
      final e = _employeeRawData[i];
      final basic = (e['salary'] as num).toDouble();
      final allowances = (basic * 0.10);
      final gross = basic + allowances + (e['bonus'] as num).toDouble();
      final tax = (basic * 0.15);
      final bankLoan = (i % 2 == 0) ? 1500.0 : 0.0; // sample loan deduction
      final insurance = (basic * 0.01);
      final totalDeductions = tax + bankLoan + insurance;
      final net = gross - totalDeductions;

      payrollRows.add([
        e['id'],
        e['name'],
        e['dept'],
        basic,
        allowances,
        (e['bonus'] as num).toDouble(),
        gross,
        tax,
        bankLoan,
        insurance,
        totalDeductions,
        net,
        'ACC${1000 + i}',
      ]);
    }

    final payrollTable = ReportTable(
      headers: [
        'Employee ID',
        'Name',
        'Dept',
        'Basic Pay',
        'Allowances',
        'Bonus',
        'Gross Pay',
        'Tax',
        'Bank Loan',
        'Insurance',
        'Total Deductions',
        'Net Pay',
        'Bank Account',
      ],
      rows: payrollRows,
      currencyColumnIndices: [3, 4, 5, 6, 7, 8, 9, 10, 11],
      summationColumnIndices: [3, 6, 10, 11],
      currencySymbol: _interactiveCurrencySymbol,
      calculateTotals: true,
    );

    // Deductions sheet: ABC Bank Loan
    final List<List<dynamic>> loanRows = [];
    for (final row in payrollRows) {
      final loan = row[8] as double;
      if (loan > 0) {
        loanRows.add([row[0], row[1], row[2], loan]);
      }
    }

    final loanTable = ReportTable(
      headers: ['Employee ID', 'Name', 'Dept', 'Loan Amount'],
      rows: loanRows,
      currencyColumnIndices: [3],
      currencySymbol: _interactiveCurrencySymbol,
      calculateTotals: true,
    );

    final sections = <ReportSection>[];
    sections.add(
      ReportSection(
        title: 'Payroll Summary',
        description: 'Full payroll ledger',
        table: payrollTable,
      ),
    );
    sections.add(
      ReportSection(
        title: 'ABC Bank - Loan Deductions',
        description: 'Employees with bank loan deductions',
        table: loanTable,
      ),
    );

    final footer = {
      'Prepared By': '',
      'Prepared Date': '',
      'Authorized By': '',
      'Authorized Date': '',
    };

    final settings = ReportSettings(
      userPassword: 'secure_password_123',
      ownerPassword: 'owner_secret',
    );

    final report = ReportData(
      title: 'Categorized Payroll Report',
      sections: sections,
      branding: ReportBranding(
        companyName: 'Demo Corp',
        reportTitle: 'Payroll Register',
        reportDate: DateTime.now(),
      ),
      footerData: footer,
      settings: settings,
    );

    final excelGen = ExcelReportGenerator();
    await excelGen.generateAndDownload(report, 'categorized_payroll_report');
    _addLog('Success: Saved categorized_payroll_report.xlsx');
  }

  Future<void> _generatePayslipPdf() async {
    _addLog('Generating sample payslip PDF...');

    // Use first employee as example
    final e = _employeeRawData.first;
    final basic = (e['salary'] as num).toDouble();
    final allowances = basic * 0.10;
    final gross = basic + allowances + (e['bonus'] as num).toDouble();
    final tax = basic * 0.15;
    final deductions = 1500.0 + (basic * 0.01);
    final net = gross - tax - deductions;

    final table = ReportTable(
      headers: ['Field', 'Value'],
      rows: [
        ['Employee ID', e['id']],
        ['Name', e['name']],
        ['Department', e['dept']],
        ['Pay Period', '${DateTime.now().month}/${DateTime.now().year}'],
        ['Basic Pay', basic],
        ['Allowances', allowances],
        ['Bonus', (e['bonus'] as num).toDouble()],
        ['Gross Pay', gross],
        ['Tax', tax],
        ['Other Deductions', deductions],
        ['Net Pay', net],
        ['Bank Account', 'ACC1001'],
      ],
      numberColumnIndices: [4, 5, 6, 7, 8, 9, 10],
      currencyColumnIndices: [4, 5, 6, 7, 8, 9, 10],
      currencySymbol: _interactiveCurrencySymbol,
      calculateTotals: false,
    );

    final section = ReportSection(
      title: 'Payslip',
      description: 'Detailed payslip for ${e['name']}',
      table: table,
      orientation: ReportSectionOrientation.vertical,
    );

    final footer = {
      'Prepared By': '',
      'Prepared Date': '',
      'Authorized By': '',
      'Authorized Date': '',
    };

    final report = ReportData(
      title: 'Payslip - ${e['name']}',
      sections: [section],
      branding: ReportBranding(
        companyName: 'Demo Corp',
        reportTitle: 'Payslip',
        reportDate: DateTime.now(),
      ),
      footerData: footer,
      settings: ReportSettings(),
    );

    final pdfGen = PdfReportGenerator();
    await pdfGen.generateAndDownload(report, 'payslip_${e['id']}');
    _addLog('Success: Saved payslip_${e['id']}.pdf');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _addLog('System initialized. Ready to generate reports.');
  }

  void _addLog(String msg) {
    setState(() {
      _logs.insert(
        0,
        '[${DateTime.now().toString().split(' ')[1].substring(0, 8)}] $msg',
      );
    });
  }

  // =========================================================================
  // REPORT TRIGGERS
  // =========================================================================

  Future<void> _generateSimpleExcel() async {
    try {
      _addLog('Generating simple Excel payroll report...');
      final excelGen = ExcelReportGenerator();

      final branding = ReportBranding(
        companyName: 'Tech Innovations Ltd',
        address: '101 Cyber Plaza, Nairobi, Kenya',
        phone: '+254 711 222 333',
        email: 'finance@techinnovations.com',
        logoPath: 'assets/logo.png', // local asset logo!
        reportTitle: 'Consolidated Payroll Summary',
        reportDate: DateTime.now(),
      );

      final table = ReportTable(
        headers: [
          'Employee ID',
          'Name',
          'Department',
          'Base Salary',
          'Bonus',
          'Joining Date',
        ],
        rows: _employeeRawData
            .map(
              (e) => [
                e['id'],
                e['name'],
                e['dept'],
                e['salary'],
                e['bonus'],
                e['joined'],
              ],
            )
            .toList(),
        currencyColumnIndices: [3, 4],
        currencySymbol: 'KES',
        calculateTotals: true,
        columnWidths: [80, 120, 100, 110, 80, 110],
      );

      final section = ReportSection(
        title: 'Monthly Staff Payroll',
        description: 'Consolidated records for Q2 payment calculations.',
        table: table,
      );

      final data = ReportData(
        title: 'Staff Payroll Summary',
        sections: [section],
        branding: branding,
        theme: ReportTheme.classicBlue(),
      );

      await excelGen.generateAndDownload(data, 'simple_payroll_report');
      _addLog('Success: Saved simple_payroll_report.xlsx');
    } catch (e) {
      _addLog('Error: $e');
    }
  }

  Future<void> _generateMultiSheetExcel() async {
    try {
      _addLog('Generating multi-sheet Excel categorized report...');
      final excelGen = ExcelReportGenerator();

      final branding = ReportBranding(
        companyName: 'Tech Innovations Ltd',
        reportTitle: 'Departmental Payroll Audit',
        reportDate: DateTime.now(),
      );

      // Group rows by department
      final Map<String, List<Map<String, dynamic>>> depts = {};
      for (final emp in _employeeRawData) {
        final dept = emp['dept'] as String;
        depts.putIfAbsent(dept, () => []).add(emp);
      }

      final List<ReportSection> sections = [];
      for (final entry in depts.entries) {
        final String deptName = entry.key;
        final List<Map<String, dynamic>> records = entry.value;

        final table = ReportTable(
          headers: ['Emp ID', 'Name', 'Base Salary', 'Bonus'],
          rows: records
              .map((e) => [e['id'], e['name'], e['salary'], e['bonus']])
              .toList(),
          currencyColumnIndices: [2, 3],
          currencySymbol: 'USD',
          calculateTotals: true,
        );

        sections.add(
          ReportSection(
            title: '$deptName Department',
            description: 'Staff payroll details for the $deptName division.',
            table: table,
            customData: {'Head Count': records.length.toString()},
          ),
        );
      }

      final data = ReportData(
        title: 'Departmental Payroll Audit',
        sections: sections,
        branding: branding,
        settings: ReportSettings(
          userPassword: 'secure_password_123', // Encrypted workbook!
        ),
        theme: ReportTheme.forestGreen(),
      );

      await excelGen.generateAndDownload(data, 'categorized_payroll_report');
      _addLog(
        'Success: Saved categorized_payroll_report.xlsx (Password: secure_password_123)',
      );
    } catch (e) {
      _addLog('Error: $e');
    }
  }

  Future<void> _generateCompositePdf() async {
    try {
      _addLog('Generating composite PDF report with page limits...');
      final pdfGen = PdfReportGenerator();

      final branding = ReportBranding(
        companyName: 'Tech Innovations Ltd',
        address: '101 Cyber Plaza, Nairobi, Kenya',
        email: 'hr@techinnovations.com',
        logoPath: 'assets/logo.png', // local asset logo!
        reportTitle: 'Staff Demographics Report',
        reportDate: DateTime.now(),
      );

      final table = ReportTable(
        headers: ['ID', 'Employee Name', 'Department', 'Monthly Salary'],
        rows: _employeeRawData
            .map((e) => [e['id'], e['name'], e['dept'], e['salary']])
            .toList(),
        currencyColumnIndices: [3],
        currencySymbol: 'KES',
        calculateTotals: true,
      );

      final sections = [
        ReportSection(
          title: 'Active Employees Summary',
          description:
              'A detailed breakdown of salary expenses across departments.',
          table: table,
        ),
        ReportSection(
          title: 'Executive Signoff',
          description: 'Verified and authorized by the Board of Directors.',
          orientation: ReportSectionOrientation.vertical,
          table: ReportTable(
            headers: ['Officer', 'Verification Status', 'Notes'],
            rows: [
              ['HR Director', 'Approved', 'Aligned with budget constraints.'],
              [
                'Chief Financial Officer',
                'Signed Off',
                'Funds disbursed successfully.',
              ],
            ],
          ),
        ),
      ];

      final data = ReportData(
        title: 'Quarterly Payroll Audit',
        sections: sections,
        branding: branding,
        footerData: {
          'Prepared By': 'Finance Ops',
          'Verification Date': '17-Jul-2026',
        },
        theme: ReportTheme.slateGrey(),
      );

      await pdfGen.generateAndDownload(data, 'payroll_audit_report');
      _addLog('Success: Saved payroll_audit_report.pdf');
    } catch (e) {
      _addLog('Error: $e');
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      _addLog('Downloading generic data entry template...');
      final templateService = ExcelTemplateService();

      final columns = [
        ExcelTemplateColumn(
          name: 'Employee ID',
          sampleValue: 'EMP100',
          dropdownFormula:
              '=Lookup!\$A\$2:\$A\$7', // References employee lookup column
        ),
        ExcelTemplateColumn(
          name: 'Calculation Type',
          sampleValue: 'FIXED_AMOUNT',
          dropdownList: const [
            'FIXED_AMOUNT',
            'PERCENTAGE_OF_GROSS',
            'TIERED_SCHEDULE',
          ],
        ),
        ExcelTemplateColumn(name: 'Value Amount', sampleValue: '2500.50'),
        ExcelTemplateColumn(
          name: 'Is Active',
          sampleValue: 'true',
          dropdownList: const ['true', 'false'],
        ),
      ];

      final lookups = {
        'Employees': _employeeRawData.map((e) => e['id'] as String).toList(),
      };

      await templateService.generateAndDownloadTemplate(
        columns: columns,
        lookupLists: lookups,
        filename: 'payroll_entry_template',
      );
      _addLog('Success: Saved payroll_entry_template.xlsx');
    } catch (e) {
      _addLog('Error: $e');
    }
  }

  Future<void> _importAndParseTemplate() async {
    try {
      _addLog('Opening Excel file picker to parse records...');
      final templateService = ExcelTemplateService();
      final List<Map<String, dynamic>>? parsed = await templateService
          .pickAndParseExcel();

      if (parsed == null) {
        _addLog('Picker cancelled or parsing failed.');
        return;
      }

      setState(() {
        _parsedRecords = parsed;
      });

      _addLog('Success: Parsed ${parsed.length} rows from sheet.');
    } catch (e) {
      _addLog('Error: $e');
    }
  }

  // =========================================================================
  // VIEW RENDERERS
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Easy Reports Hub'),
        backgroundColor: theme.colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.table_chart), text: 'Excel'),
            Tab(icon: Icon(Icons.picture_as_pdf), text: 'PDF'),
            Tab(icon: Icon(Icons.file_upload), text: 'Templates'),
            Tab(icon: Icon(Icons.build), text: 'Interactive'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Branding Banner at top
            Container(
              padding: const EdgeInsets.all(16.0),
              color: isDark ? Colors.grey[900] : Colors.blue[50],
              child: Row(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.business, size: 50),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tech Innovations Ltd',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Easy Reporting Wrapper Demo Console',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Main Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExcelTab(),
                  _buildPdfTab(),
                  _buildTemplateTab(),
                  _buildInteractiveTab(),
                ],
              ),
            ),
            const Divider(height: 1),
            // Logs Terminal
            _buildLogConsole(),
          ],
        ),
      ),
    );
  }

  Widget _buildExcelTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            // Visual excellence cards
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.table_rows, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Simple Payroll Report',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Generates a single-sheet Excel report with custom blue header branding, KES currencies, and automated totals row calculation.',
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _generateSimpleExcel,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Simple Excel'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _generateAdvancedPayrollExcel,
                  icon: const Icon(Icons.work_outline),
                  label: const Text('Export Advanced Payroll'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[50],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _generatePayslipPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export Payslip (PDF)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[50],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.layers, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Categorized Multi-Sheet Report',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Splits employees into multiple sheets by department, appends an automated overview index summary sheet at the front, and locks the workbook with password protection ("secure_password_123").',
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _generateMultiSheetExcel,
                  icon: const Icon(Icons.lock),
                  label: const Text('Export Password Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[100],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Composite PDF Audit Report',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Creates a formatted multi-page PDF document featuring page templates, dynamic page numbers, section headers, styled data grids, vertical executive lists, and authorization footer signatures.',
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _generateCompositePdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.file_download, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Download Entry Template',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Generates an XLSX data collection template with static dropdowns (Calculation Type) and dynamic validation lookups (Employee IDs).',
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _downloadTemplate,
                  icon: const Icon(Icons.download),
                  label: const Text('Get Template XLSX'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.upload_file, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text(
                      'Import & Parse Template',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pick an XLSX spreadsheet and parse the row values dynamically back to Dart maps. Results are displayed inside the application console below.',
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _importAndParseTemplate,
                  icon: const Icon(Icons.file_open),
                  label: const Text('Pick and Parse File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[50],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_parsedRecords != null) ...[
          const SizedBox(height: 16),
          Text(
            'Parsed Rows Preview:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListView.builder(
              itemCount: _parsedRecords!.length,
              itemBuilder: (context, index) {
                final record = _parsedRecords![index];
                return ListTile(
                  title: Text('Row ${index + 1}: ${record.toString()}'),
                  dense: true,
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInteractiveTab() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Controls
          Expanded(
            flex: 1,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive Report Builder',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Employees:'),
                        Expanded(
                          child: Slider(
                            value: _interactiveEmployeeCount.toDouble(),
                            min: 1,
                            max: 20,
                            divisions: 19,
                            label: '$_interactiveEmployeeCount',
                            onChanged: (v) => setState(
                              () => _interactiveEmployeeCount = v.toInt(),
                            ),
                          ),
                        ),
                        Text('$_interactiveEmployeeCount'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Currency Symbol',
                      ),
                      controller: TextEditingController(
                        text: _interactiveCurrencySymbol,
                      ),
                      onChanged: (v) =>
                          setState(() => _interactiveCurrencySymbol = v),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Calculate Totals'),
                      value: _interactiveCalculateTotals,
                      onChanged: (v) =>
                          setState(() => _interactiveCalculateTotals = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _buildInteractiveJson,
                          child: const Text('Build JSON'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _downloadInteractiveTemplate,
                          child: const Text('Export Template'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _generateInteractiveExcel,
                          child: const Text('Export Excel'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Sample Templates (JSON)'),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children: _sampleTemplates.keys.map((k) {
                          return ListTile(
                            title: Text(k),
                            onTap: () =>
                                setState(() => _interactiveLoadSample(k)),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // JSON + Preview
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Report JSON',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: SelectableText(
                                      _interactiveJson ?? 'No JSON built yet',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Preview',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.4,
                                        ),
                                        child: SingleChildScrollView(
                                          child: DataTable(
                                            columns: const [
                                              DataColumn(
                                                label: Text('Employee ID'),
                                              ),
                                              DataColumn(label: Text('Name')),
                                              DataColumn(
                                                label: Text('Department'),
                                              ),
                                              DataColumn(label: Text('Salary')),
                                            ],
                                            rows: _interactivePreviewRows.map((
                                              r,
                                            ) {
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(r[0].toString()),
                                                  ),
                                                  DataCell(
                                                    Text(r[1].toString()),
                                                  ),
                                                  DataCell(
                                                    Text(r[2].toString()),
                                                  ),
                                                  DataCell(
                                                    Text(r[3].toString()),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogConsole() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SYSTEM CONSOLE LOGS',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _logs.clear()),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.redAccent, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) => Text(
                _logs[index],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
