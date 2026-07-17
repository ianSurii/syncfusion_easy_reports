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

class _ReportsHomeScreenState extends State<ReportsHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _logs = [];
  List<Map<String, dynamic>>? _parsedRecords;

  // Generic Dummy Data Generators
  final List<Map<String, dynamic>> _employeeRawData = [
    {'id': 'EMP001', 'name': 'John Doe', 'dept': 'IT', 'salary': 75000.00, 'bonus': 5000.00, 'joined': DateTime(2022, 3, 15)},
    {'id': 'EMP002', 'name': 'Jane Smith', 'dept': 'HR', 'salary': 65000.00, 'bonus': 3000.00, 'joined': DateTime(2021, 6, 20)},
    {'id': 'EMP003', 'name': 'Bob Johnson', 'dept': 'IT', 'salary': 85000.00, 'bonus': 7000.00, 'joined': DateTime(2020, 11, 1)},
    {'id': 'EMP004', 'name': 'Alice Williams', 'dept': 'Finance', 'salary': 90000.00, 'bonus': 8000.00, 'joined': DateTime(2023, 1, 10)},
    {'id': 'EMP005', 'name': 'Charlie Brown', 'dept': 'HR', 'salary': 60000.00, 'bonus': 2000.00, 'joined': DateTime(2024, 2, 5)},
    {'id': 'EMP006', 'name': 'David Miller', 'dept': 'Finance', 'salary': 78000.00, 'bonus': 4000.00, 'joined': DateTime(2022, 8, 18)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _addLog('System initialized. Ready to generate reports.');
  }

  void _addLog(String msg) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().split(' ')[1].substring(0, 8)}] $msg');
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
        headers: ['Employee ID', 'Name', 'Department', 'Base Salary', 'Bonus', 'Joining Date'],
        rows: _employeeRawData.map((e) => [
          e['id'],
          e['name'],
          e['dept'],
          e['salary'],
          e['bonus'],
          e['joined'],
        ]).toList(),
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
          rows: records.map((e) => [e['id'], e['name'], e['salary'], e['bonus']]).toList(),
          currencyColumnIndices: [2, 3],
          currencySymbol: 'USD',
          calculateTotals: true,
        );

        sections.add(
          ReportSection(
            title: '$deptName Department',
            description: 'Staff payroll details for the $deptName division.',
            table: table,
            customData: {
              'Head Count': records.length.toString(),
            },
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
      _addLog('Success: Saved categorized_payroll_report.xlsx (Password: secure_password_123)');
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
        rows: _employeeRawData.map((e) => [
          e['id'],
          e['name'],
          e['dept'],
          e['salary'],
        ]).toList(),
        currencyColumnIndices: [3],
        currencySymbol: 'KES',
        calculateTotals: true,
      );

      final sections = [
        ReportSection(
          title: 'Active Employees Summary',
          description: 'A detailed breakdown of salary expenses across departments.',
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
              ['Chief Financial Officer', 'Signed Off', 'Funds disbursed successfully.'],
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
          dropdownFormula: '=Lookup!\$A\$2:\$A\$7', // References employee lookup column
        ),
        ExcelTemplateColumn(
          name: 'Calculation Type',
          sampleValue: 'FIXED_AMOUNT',
          dropdownList: const ['FIXED_AMOUNT', 'PERCENTAGE_OF_GROSS', 'TIERED_SCHEDULE'],
        ),
        ExcelTemplateColumn(
          name: 'Value Amount',
          sampleValue: '2500.50',
        ),
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
      final List<Map<String, dynamic>>? parsed = await templateService.pickAndParseExcel();

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
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, size: 50),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tech Innovations Ltd',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    Text('Simple Payroll Report', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Generates a single-sheet Excel report with custom blue header branding, KES currencies, and automated totals row calculation.'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _generateSimpleExcel,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Simple Excel'),
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
                    Text('Categorized Multi-Sheet Report', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Splits employees into multiple sheets by department, appends an automated overview index summary sheet at the front, and locks the workbook with password protection ("secure_password_123").'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _generateMultiSheetExcel,
                  icon: const Icon(Icons.lock),
                  label: const Text('Export Password Excel'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[100]),
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
                    Text('Composite PDF Audit Report', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Creates a formatted multi-page PDF document featuring page templates, dynamic page numbers, section headers, styled data grids, vertical executive lists, and authorization footer signatures.'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _generateCompositePdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF Report'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50]),
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
                    Text('Download Entry Template', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Generates an XLSX data collection template with static dropdowns (Calculation Type) and dynamic validation lookups (Employee IDs).'),
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
                    Text('Import & Parse Template', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Pick an XLSX spreadsheet and parse the row values dynamically back to Dart maps. Results are displayed inside the application console below.'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _importAndParseTemplate,
                  icon: const Icon(Icons.file_open),
                  label: const Text('Pick and Parse File'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple[50]),
                ),
              ],
            ),
          ),
        ),
        if (_parsedRecords != null) ...[
          const SizedBox(height: 16),
          Text('Parsed Rows Preview:', style: Theme.of(context).textTheme.titleSmall),
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
              const Text('SYSTEM CONSOLE LOGS', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => setState(() => _logs.clear()),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('Clear', style: TextStyle(color: Colors.redAccent, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) => Text(
                _logs[index],
                style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
