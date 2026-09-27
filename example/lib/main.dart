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
      title: 'Syncfusion Easy Reports Playground',
      debugShowCheckedModeBanner: false,
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
  final ReportEngine _engine = ReportEngine();
  final ReportSaver _saver = ReportSaver();
  final ExcelTemplateService _templateService = ExcelTemplateService();

  bool _isGenerating = false;
  String? _statusMessage;
  String _activeTabTitle = 'Report Gallery';

  // ---------------------------------------------------------------------------
  // SYNTHETIC REALISTIC DATASETS (Clearly marked fictional)
  // ---------------------------------------------------------------------------
  final List<Map<String, dynamic>> _deductionsData = [
    {
      'employeeId': 'EMP001',
      'employeeName': 'Eleanor Vance',
      'department': 'Engineering',
      'deductionType': 'KCB Bank Loan',
      'referenceNumber': 'KCB-LN-44810',
      'amount': 350.0,
      'employerContribution': 0.0,
      'notes': 'Monthly loan recovery amortized',
    },
    {
      'employeeId': 'EMP002',
      'employeeName': 'Marcus Brody',
      'department': 'Engineering',
      'deductionType': 'KCB Bank Loan',
      'referenceNumber': 'KCB-LN-99120',
      'amount': 400.0,
      'employerContribution': 0.0,
      'notes': 'Staff loan recovery scheme',
    },
    {
      'employeeId': 'EMP003',
      'employeeName': 'Sophia Chen',
      'department': 'Marketing',
      'deductionType': 'Equity Bank Loan',
      'referenceNumber': 'EQ-88210-A',
      'amount': 500.0,
      'employerContribution': 0.0,
      'notes': 'Direct salary checkoff loan',
    },
    {
      'employeeId': 'EMP004',
      'employeeName': 'Lucas Miller',
      'department': 'Marketing',
      'deductionType': 'Equity Bank Loan',
      'referenceNumber': 'EQ-33912-B',
      'amount': 450.0,
      'employerContribution': 0.0,
      'notes': 'Direct salary checkoff loan',
    },
    {
      'employeeId': 'EMP001',
      'employeeName': 'Eleanor Vance',
      'department': 'Engineering',
      'deductionType': 'Housing Levy',
      'referenceNumber': 'HL-2026-001',
      'amount': 150.0,
      'employerContribution': 150.0,
      'notes': '1.5% statutory employee & employer match',
    },
    {
      'employeeId': 'EMP002',
      'employeeName': 'Marcus Brody',
      'department': 'Engineering',
      'deductionType': 'Housing Levy',
      'referenceNumber': 'HL-2026-002',
      'amount': 130.0,
      'employerContribution': 130.0,
      'notes': '1.5% statutory employee & employer match',
    },
    {
      'employeeId': 'EMP005',
      'employeeName': 'Amara Okafor',
      'department': 'Sales',
      'deductionType': 'SHA / SHIF',
      'referenceNumber': 'SHA-77192',
      'amount': 200.0,
      'employerContribution': 0.0,
      'notes': 'Social Health Authority contribution',
    },
    {
      'employeeId': 'EMP007',
      'employeeName': 'Zoe Patel',
      'department': 'Engineering',
      'deductionType': 'SHA / SHIF',
      'referenceNumber': 'SHA-66281',
      'amount': 180.0,
      'employerContribution': 0.0,
      'notes': 'Social Health Authority contribution',
    },
    {
      'employeeId': 'EMP006',
      'employeeName': 'Julian Hayes',
      'department': 'Finance',
      'deductionType': 'PAYE Tax',
      'referenceNumber': 'PAYE-KRA-006',
      'amount': 910.0,
      'employerContribution': 0.0,
      'notes': 'Income tax statutory remittance',
    },
  ];

  final List<Map<String, dynamic>> _payrollData = [
    {
      'id': 'EMP001',
      'name': 'Eleanor Vance',
      'dept': 'Engineering',
      'bank': 'Chase Bank',
      'basicPay': 9200.0,
      'allowances': 1200.0,
      'deductions': 850.0,
      'joined': DateTime(2021, 3, 15),
    },
    {
      'id': 'EMP002',
      'name': 'Marcus Brody',
      'dept': 'Engineering',
      'bank': 'Chase Bank',
      'basicPay': 8400.0,
      'allowances': 800.0,
      'deductions': 720.0,
      'joined': DateTime(2022, 6, 1),
    },
    {
      'id': 'EMP003',
      'name': 'Sophia Chen',
      'dept': 'Marketing',
      'bank': 'Citibank',
      'basicPay': 7600.0,
      'allowances': 1500.0,
      'deductions': 600.0,
      'joined': DateTime(2020, 11, 20),
    },
    {
      'id': 'EMP004',
      'name': 'Lucas Miller',
      'dept': 'Marketing',
      'bank': 'Citibank',
      'basicPay': 6900.0,
      'allowances': 900.0,
      'deductions': 550.0,
      'joined': DateTime(2023, 1, 10),
    },
    {
      'id': 'EMP005',
      'name': 'Amara Okafor',
      'dept': 'Sales',
      'bank': 'Wells Fargo',
      'basicPay': 6500.0,
      'allowances': 3200.0,
      'deductions': 480.0,
      'joined': DateTime(2022, 8, 5),
    },
    {
      'id': 'EMP006',
      'name': 'Julian Hayes',
      'dept': 'Finance',
      'bank': 'Bank of America',
      'basicPay': 8800.0,
      'allowances': 600.0,
      'deductions': 910.0,
      'joined': DateTime(2019, 5, 12),
    },
    {
      'id': 'EMP007',
      'name': 'Zoe Patel',
      'dept': 'Engineering',
      'bank': 'Chase Bank',
      'basicPay': 7900.0,
      'allowances': 950.0,
      'deductions': 680.0,
      'joined': DateTime(2024, 2, 1),
    },
    {
      'id': 'EMP008',
      'name': 'Liam Connor',
      'dept': 'Sales',
      'bank': 'Wells Fargo',
      'basicPay': 6200.0,
      'allowances': 2800.0,
      'deductions': 430.0,
      'joined': DateTime(2023, 9, 18),
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
      'category': 'Consulting & Setup',
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

  final List<Map<String, dynamic>> _inventoryData = [
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

  // ---------------------------------------------------------------------------
  // INTERACTIVE BUILDER STATE
  // ---------------------------------------------------------------------------
  String _builderDataset = 'Payroll';
  final Set<String> _builderSelectedColumns = {
    'id',
    'name',
    'dept',
    'basicPay',
    'allowances',
    'deductions',
    'netPay',
  };
  String _builderGroupBy = 'dept';
  String _builderMeasure = 'netPay';
  String _builderTheme = 'Classic Blue';
  bool _builderSheetPerCategory = true;
  bool _builderShowSignatures = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _activeTabTitle = 'Report Gallery';
            break;
          case 1:
            _activeTabTitle = 'Interactive Builder';
            break;
          case 2:
            _activeTabTitle = 'Multi-Analysis Workspace';
            break;
          case 3:
            _activeTabTitle = 'Developer Playground';
            break;
          case 4:
            _activeTabTitle = 'Template Studio';
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // GENERATION ACTIONS
  // ---------------------------------------------------------------------------
  Future<void> _exportPreset(
    ReportDefinition<Map<String, dynamic>> def,
    List<Map<String, dynamic>> data, {
    required bool isPdf,
  }) async {
    setState(() {
      _isGenerating = true;
      _statusMessage =
          'Preparing and exporting ${isPdf ? "PDF" : "Excel"} report...';
    });

    try {
      final prepared = await _engine.prepare(definition: def, records: data);

      final artifact = isPdf
          ? await _engine.exportPdf(
              prepared,
              options: const PdfExportOptions(
                showPageNumbers: true,
                repeatHeaders: true,
                showSignatures: true,
              ),
            )
          : await _engine.exportExcel(
              prepared,
              options: const ExcelExportOptions(includeSummarySheet: true),
            );

      await _saver.save(artifact);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(
              'Successfully generated ${artifact.filename} (${artifact.formattedSize})',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Export error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Syncfusion Easy Reports',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              _activeTabTitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view), text: 'Gallery'),
            Tab(icon: Icon(Icons.tune), text: 'Builder'),
            Tab(icon: Icon(Icons.analytics), text: 'Multi-Analysis'),
            Tab(icon: Icon(Icons.code), text: 'Playground'),
            Tab(icon: Icon(Icons.table_chart), text: 'Templates'),
          ],
        ),
      ),
      body: _isGenerating
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage ?? 'Generating report...',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGalleryTab(),
                _buildBuilderTab(),
                _buildMultiAnalysisTab(),
                _buildPlaygroundTab(),
                _buildTemplateTab(),
              ],
            ),
    );
  }

  // ===========================================================================
  // TAB 1: REPORT GALLERY
  // ===========================================================================
  Widget _buildGalleryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildNoticeBanner(
          'Sample datasets below contain synthetic, fictional business data for demonstration purposes.',
        ),
        const SizedBox(height: 12),
        _buildGalleryCard(
          title: 'Categorized Payroll Deductions & Remittances',
          category: 'Payroll & Deductions',
          description:
              'Dynamic multi-sheet deduction schedules grouped by deduction scheme (KCB Loan, Equity Loan, Housing Levy, SHA/SHIF, PAYE) with overview totals, detail line items, and signature blocks.',
          icon: Icons.pie_chart_outline,
          color: const Color(0xFF6A1B9A),
          recordCount: _deductionsData.length,
          onExcel: () => _exportPreset(
            PayrollReportPresets.categorizedDeductions(
              companyName: 'Acme Global Corporation',
            ),
            _deductionsData,
            isPdf: false,
          ),
          onPdf: () => _exportPreset(
            PayrollReportPresets.categorizedDeductions(
              companyName: 'Acme Global Corporation',
            ),
            _deductionsData,
            isPdf: true,
          ),
        ),
        _buildGalleryCard(
          title: 'Monthly Payroll Register & Bank Schedule',
          category: 'Payroll & HR',
          description:
              'Comprehensive payroll ledger with basic pay, allowances, deductions, net pay, department totals, and bank transfer schedules.',
          icon: Icons.payments_outlined,
          color: const Color(0xFF1565C0),
          recordCount: _payrollData.length,
          onExcel: () => _exportPreset(
            PayrollReportPresets.monthlyPayroll(
              companyName: 'Acme Corporation',
            ),
            _payrollData,
            isPdf: false,
          ),
          onPdf: () => _exportPreset(
            PayrollReportPresets.monthlyPayroll(
              companyName: 'Acme Corporation',
            ),
            _payrollData,
            isPdf: true,
          ),
        ),
        _buildGalleryCard(
          title: 'Sales Performance & Regional CrossTab',
          category: 'Sales & Revenue',
          description:
              'Executive sales performance report including order listings, salesperson volume, gross margin calculations, and category-by-region pivot matrix.',
          icon: Icons.trending_up,
          color: const Color(0xFF2E7D32),
          recordCount: _salesData.length,
          onExcel: () => _exportPreset(
            SalesReportPresets.salesPerformance(
              companyName: 'Apex Dynamics Inc',
            ),
            _salesData,
            isPdf: false,
          ),
          onPdf: () => _exportPreset(
            SalesReportPresets.salesPerformance(
              companyName: 'Apex Dynamics Inc',
            ),
            _salesData,
            isPdf: true,
          ),
        ),
        _buildGalleryCard(
          title: 'Accounts Receivable Aging Analysis',
          category: 'Finance & Accounting',
          description:
              'Categorized aging report with automated risk buckets: 0-30 days, 31-60 days, 61-90 days, and 90+ days overdue.',
          icon: Icons.account_balance,
          color: const Color(0xFF37474F),
          recordCount: _agingData.length,
          onExcel: () => _exportPreset(
            FinanceReportPresets.accountsReceivableAging(
              companyName: 'Starlight Financials',
            ),
            _agingData,
            isPdf: false,
          ),
          onPdf: () => _exportPreset(
            FinanceReportPresets.accountsReceivableAging(
              companyName: 'Starlight Financials',
            ),
            _agingData,
            isPdf: true,
          ),
        ),
        _buildGalleryCard(
          title: 'Stock Valuation & Low-Inventory Alerts',
          category: 'Inventory & Supply Chain',
          description:
              'Stock tracking register with unit costs, inventory valuation metrics, warehouse location filters, and reorder alerts.',
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFFE65100),
          recordCount: _inventoryData.length,
          onExcel: () => _exportPreset(
            InventoryReportPresets.stockValuation(
              companyName: 'Global Warehouse Logistics',
            ),
            _inventoryData,
            isPdf: false,
          ),
          onPdf: () => _exportPreset(
            InventoryReportPresets.stockValuation(
              companyName: 'Global Warehouse Logistics',
            ),
            _inventoryData,
            isPdf: true,
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryCard({
    required String title,
    required String category,
    required String description,
    required IconData icon,
    required Color color,
    required int recordCount,
    required VoidCallback onExcel,
    required VoidCallback onPdf,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
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
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.table_view,
                    size: 18,
                    color: Colors.green,
                  ),
                  label: const Text('Export Excel (.xlsx)'),
                  onPressed: onExcel,
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Export PDF (.pdf)'),
                  onPressed: onPdf,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: INTERACTIVE REPORT BUILDER
  // ===========================================================================
  Widget _buildBuilderTab() {
    final List<Map<String, dynamic>> activeData =
        _builderDataset == 'Deductions'
        ? _deductionsData
        : _builderDataset == 'Payroll'
        ? _payrollData
        : _builderDataset == 'Sales'
        ? _salesData
        : _inventoryData;

    final availableKeys = activeData.isNotEmpty
        ? activeData.first.keys.toList()
        : <String>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Choose Dataset & Theme',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _builderDataset,
                        decoration: const InputDecoration(
                          labelText: 'Dataset',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'Payroll',
                            child: Text('Payroll Dataset (8 rows)'),
                          ),
                          DropdownMenuItem(
                            value: 'Deductions',
                            child: Text(
                              'Deductions Dataset (${_deductionsData.length} rows)',
                            ),
                          ),
                          const DropdownMenuItem(
                            value: 'Sales',
                            child: Text('Sales Dataset (6 rows)'),
                          ),
                          const DropdownMenuItem(
                            value: 'Inventory',
                            child: Text('Inventory Dataset (5 rows)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _builderDataset = val;
                              _builderSelectedColumns.clear();
                              final data = val == 'Deductions'
                                  ? _deductionsData
                                  : val == 'Payroll'
                                  ? _payrollData
                                  : val == 'Sales'
                                  ? _salesData
                                  : _inventoryData;
                              _builderSelectedColumns.addAll(data.first.keys);
                              _builderGroupBy = val == 'Deductions'
                                  ? 'deductionType'
                                  : data.first.keys.length > 2
                                  ? data.first.keys.elementAt(2)
                                  : data.first.keys.first;
                              _builderMeasure = val == 'Deductions'
                                  ? 'amount'
                                  : data.first.keys.last;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _builderTheme,
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
                        onChanged: (val) {
                          if (val != null) setState(() => _builderTheme = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '2. Select Active Columns',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: availableKeys.map((key) {
                    final isSelected = _builderSelectedColumns.contains(key);
                    return FilterChip(
                      label: Text(key),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _builderSelectedColumns.add(key);
                          } else if (_builderSelectedColumns.length > 1) {
                            _builderSelectedColumns.remove(key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  '3. Grouping Dimension & Aggregation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: availableKeys.contains(_builderGroupBy)
                            ? _builderGroupBy
                            : (availableKeys.isNotEmpty
                                  ? availableKeys.first
                                  : null),
                        decoration: const InputDecoration(
                          labelText: 'Group By Column',
                          border: OutlineInputBorder(),
                        ),
                        items: availableKeys
                            .map(
                              (k) => DropdownMenuItem(value: k, child: Text(k)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _builderGroupBy = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: availableKeys.contains(_builderMeasure)
                            ? _builderMeasure
                            : (availableKeys.isNotEmpty
                                  ? availableKeys.last
                                  : null),
                        decoration: const InputDecoration(
                          labelText: 'Measure Column to Sum',
                          border: OutlineInputBorder(),
                        ),
                        items: availableKeys
                            .map(
                              (k) => DropdownMenuItem(value: k, child: Text(k)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _builderMeasure = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Split Categories into Dedicated Worksheets / Sections',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Creates separate Excel tabs or PDF pages for each category (e.g. each deduction scheme or department) with employee detail records.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _builderSheetPerCategory,
                  onChanged: (val) =>
                      setState(() => _builderSheetPerCategory = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Include Formal Sign-Off Blocks',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Renders "Prepared By", "Checked By", "Approved By", and "Authorized By" signature lines.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _builderShowSignatures,
                  onChanged: (val) =>
                      setState(() => _builderShowSignatures = val),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.table_chart, color: Colors.green),
                      label: const Text('Export Custom Excel'),
                      onPressed: () =>
                          _executeCustomExport(activeData, isPdf: false),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Export Custom PDF'),
                      onPressed: () =>
                          _executeCustomExport(activeData, isPdf: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _executeCustomExport(
    List<Map<String, dynamic>> data, {
    required bool isPdf,
  }) {
    final theme = _builderTheme == 'Forest Green'
        ? ReportTheme.forestGreen()
        : _builderTheme == 'Corporate Dark'
        ? ReportTheme.corporateDark()
        : _builderTheme == 'Slate Grey'
        ? ReportTheme.slateGrey()
        : ReportTheme.classicBlue();

    final List<ReportColumn<Map<String, dynamic>>> cols =
        _builderSelectedColumns.map((key) {
          return ReportColumn.forMap(key: key);
        }).toList();

    final def = ReportDefinition<Map<String, dynamic>>(
      title: 'Custom $_builderDataset Report',
      branding: ReportBranding(companyName: 'Custom Builder Corp'),
      theme: theme,
      columns: cols,
      excelOptions: ExcelExportOptions(
        includeSummarySheet: true,
        showSignatures: _builderShowSignatures,
        signatureLabels: const [
          'Prepared By',
          'Checked By',
          'Approved By',
          'Authorized By',
        ],
      ),
      pdfOptions: PdfExportOptions(
        showSignatures: _builderShowSignatures,
        signatureLabels: const [
          'Prepared By',
          'Checked By',
          'Approved By',
          'Authorized By',
        ],
      ),
      analyses: [
        ReportAnalysis.detail(
          id: 'detail',
          title: 'Detailed Records',
          showGrandTotal: true,
        ),
        ReportAnalysis.grouped(
          id: 'grouped',
          title: 'Summary by $_builderGroupBy',
          groupBy: [_builderGroupBy],
          sheetPerCategory: _builderSheetPerCategory,
          detailColumns: _builderSelectedColumns.toList(),
          measures: [
            ReportMeasure.count(id: 'count', title: 'Record Count'),
            ReportMeasure.sum(
              column: _builderMeasure,
              title: 'Total $_builderMeasure',
            ),
          ],
          showGrandTotal: true,
        ),
      ],
    );

    _exportPreset(def, data, isPdf: isPdf);
  }

  // ===========================================================================
  // TAB 3: MULTI-ANALYSIS WORKSPACE
  // ===========================================================================
  Widget _buildMultiAnalysisTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildNoticeBanner(
          'One dataset producing 4 distinct analyses without duplicating input memory.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Multi-Analysis Specification',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildAnalysisTile(
                  '1. Payroll Register',
                  'Flat detail sheet with all employee line items and grand totals',
                  'Worksheet 1 / PDF Section 1',
                ),
                _buildAnalysisTile(
                  '2. Department Summary',
                  'Grouped aggregation with headcount, basic pay, deductions, and average net pay',
                  'Worksheet 2 / PDF Section 2',
                ),
                _buildAnalysisTile(
                  '3. Bank Payment Schedule',
                  'Grouped aggregation by bank for disbursement routing',
                  'Worksheet 3 / PDF Section 3',
                ),
                _buildAnalysisTile(
                  '4. Dept by Bank CrossTab',
                  '2D Pivot Matrix mapping departments across banking institutions',
                  'Worksheet 4 / PDF Section 4',
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '8 Records Processed',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(
                            Icons.table_chart,
                            color: Colors.green,
                          ),
                          label: const Text('Export 4-Sheet Excel'),
                          onPressed: () => _exportPreset(
                            PayrollReportPresets.monthlyPayroll(
                              companyName: 'Acme Corporation',
                            ),
                            _payrollData,
                            isPdf: false,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export Multi-Section PDF'),
                          onPressed: () => _exportPreset(
                            PayrollReportPresets.monthlyPayroll(
                              companyName: 'Acme Corporation',
                            ),
                            _payrollData,
                            isPdf: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisTile(String title, String desc, String destination) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              destination,
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: DEVELOPER CODE PLAYGROUND
  // ===========================================================================
  Widget _buildPlaygroundTab() {
    const customModelCode = '''
// 1. Define Model & Schema
final definition = ReportDefinition<Employee>(
  title: 'Compensation Audit',
  columns: [
    ReportColumn.text(id: 'id', title: 'ID', value: (e) => e.id),
    ReportColumn.text(id: 'dept', title: 'Dept', value: (e) => e.department),
    ReportColumn.money(id: 'netPay', title: 'Net Pay', currencyCode: 'USD', value: (e) => e.netPay),
  ],
  analyses: [
    ReportAnalysis.grouped(
      id: 'by_dept',
      title: 'Department Summary',
      groupBy: ['dept'],
      measures: [
        ReportMeasure.count(id: 'headcount'),
        ReportMeasure.sum(column: 'netPay'),
      ],
    ),
  ],
);

// 2. Prepare & Export (Bytes-Only, Zero-UI)
final engine = ReportEngine();
final prepared = await engine.prepare(definition: definition, records: employees);
final artifact = await engine.exportExcel(prepared);
await ReportSaver().save(artifact);
''';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildNoticeBanner(
          'The core engine returns standalone ReportArtifact bytes without touching platform UI.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Model-Driven Reporting Code Pattern',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SelectableText(
                    customModelCode,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.lightGreenAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Execute Playground Snippet'),
                    onPressed: () => _exportPreset(
                      PayrollReportPresets.monthlyPayroll(
                        companyName: 'Playground Corp',
                      ),
                      _payrollData,
                      isPdf: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 5: TEMPLATE STUDIO & IMPORTER
  // ===========================================================================
  Widget _buildTemplateTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildNoticeBanner(
          'Generate pre-styled data-entry XLSX templates with instructions and validation.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data-Entry Template Generator',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Creates an Excel workbook (.xlsx) containing instructions and mandatory input headers (Employee ID, Name, Department, Salary).',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Download Data-Entry Template (.xlsx)'),
                    onPressed: () async {
                      final columns = [
                        ExcelTemplateColumn(
                          name: 'Employee ID',
                          sampleValue: 'EMP001',
                          isRequired: true,
                        ),
                        ExcelTemplateColumn(
                          name: 'Full Name',
                          sampleValue: 'John Doe',
                          isRequired: true,
                        ),
                        ExcelTemplateColumn(
                          name: 'Department',
                          sampleValue: 'Engineering',
                          isRequired: true,
                        ),
                        ExcelTemplateColumn(
                          name: 'Salary',
                          sampleValue: '75000',
                          isRequired: true,
                        ),
                      ];

                      await _templateService.generateAndDownloadTemplate(
                        columns: columns,
                        filename: 'Employee_Data_Template.xlsx',
                        instructions:
                            'Please enter employee details. Fields marked with an asterisk (*) are mandatory.',
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Template downloaded successfully!'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeBanner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
