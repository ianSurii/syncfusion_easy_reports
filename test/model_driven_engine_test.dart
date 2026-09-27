import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_easy_reports/syncfusion_easy_reports.dart';

// Sample Custom Dart Model
class EmployeeTestModel {
  final String id;
  final String name;
  final String department;
  final String bank;
  final double basicPay;
  final double bonus;
  final double deductions;
  final DateTime joinedDate;
  final int performanceRating;
  final bool isActive;

  EmployeeTestModel({
    required this.id,
    required this.name,
    required this.department,
    required this.bank,
    required this.basicPay,
    this.bonus = 0.0,
    this.deductions = 0.0,
    required this.joinedDate,
    this.performanceRating = 3,
    this.isActive = true,
  });

  double get netPay => basicPay + bonus - deductions;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleEmployees = [
    EmployeeTestModel(
      id: 'EMP001',
      name: 'Alice Smith',
      department: 'Engineering',
      bank: 'Chase',
      basicPay: 8000.0,
      bonus: 1000.0,
      deductions: 500.0,
      joinedDate: DateTime(2022, 1, 15),
      performanceRating: 5,
    ),
    EmployeeTestModel(
      id: 'EMP002',
      name: 'Bob Jones',
      department: 'Engineering',
      bank: 'Chase',
      basicPay: 7000.0,
      bonus: 500.0,
      deductions: 300.0,
      joinedDate: DateTime(2023, 4, 10),
      performanceRating: 4,
    ),
    EmployeeTestModel(
      id: 'EMP003',
      name: 'Charlie Brown',
      department: 'Marketing',
      bank: 'Citi',
      basicPay: 6000.0,
      bonus: 800.0,
      deductions: 400.0,
      joinedDate: DateTime(2021, 8, 20),
      performanceRating: 3,
    ),
    EmployeeTestModel(
      id: 'EMP004',
      name: 'Diana Prince',
      department: 'Marketing',
      bank: 'Citi',
      basicPay: 6500.0,
      bonus: 1200.0,
      deductions: 600.0,
      joinedDate: DateTime(2020, 11, 5),
      performanceRating: 5,
    ),
    EmployeeTestModel(
      id: 'EMP005',
      name: 'Evan Wright',
      department: 'Sales',
      bank: 'Wells Fargo',
      basicPay: 5000.0,
      bonus: 2500.0,
      deductions: 200.0,
      joinedDate: DateTime(2024, 2, 1),
      performanceRating: 4,
    ),
  ];

  group('Model-Driven Reporting Engine & Calculation Tests', () {
    late ReportEngine engine;

    setUp(() {
      engine = ReportEngine();
    });

    test(
      'Should prepare typed custom model report with detail and grouped analyses',
      () async {
        final definition = ReportDefinition<EmployeeTestModel>(
          title: 'Monthly Compensation Audit',
          subtitle: 'Confidential Internal Review',
          columns: [
            ReportColumn.text(id: 'id', title: 'ID', value: (e) => e.id),
            ReportColumn.text(
              id: 'name',
              title: 'Full Name',
              value: (e) => e.name,
            ),
            ReportColumn.text(
              id: 'department',
              title: 'Department',
              value: (e) => e.department,
            ),
            ReportColumn.text(id: 'bank', title: 'Bank', value: (e) => e.bank),
            ReportColumn.money(
              id: 'basicPay',
              title: 'Basic Pay',
              currencyCode: 'USD',
              value: (e) => e.basicPay,
            ),
            ReportColumn.money(
              id: 'bonus',
              title: 'Bonus',
              currencyCode: 'USD',
              value: (e) => e.bonus,
            ),
            ReportColumn.money(
              id: 'deductions',
              title: 'Deductions',
              currencyCode: 'USD',
              value: (e) => e.deductions,
            ),
            ReportColumn.money(
              id: 'netPay',
              title: 'Net Pay',
              currencyCode: 'USD',
              value: (e) => e.netPay,
            ),
            ReportColumn.date(
              id: 'joined',
              title: 'Joined',
              value: (e) => e.joinedDate,
            ),
          ],
          analyses: [
            ReportAnalysis.detail(
              id: 'register',
              title: 'Employee Register',
              showGrandTotal: true,
            ),
            ReportAnalysis.grouped(
              id: 'dept_summary',
              title: 'Department Summary',
              groupBy: ['department'],
              measures: [
                ReportMeasure.count(id: 'headcount', title: 'Headcount'),
                ReportMeasure.sum(column: 'basicPay', currencyCode: 'USD'),
                ReportMeasure.sum(column: 'netPay', currencyCode: 'USD'),
                ReportMeasure.average(
                  column: 'netPay',
                  title: 'Avg Net Pay',
                  currencyCode: 'USD',
                ),
                ReportMeasure.min(
                  column: 'netPay',
                  title: 'Min Net Pay',
                  currencyCode: 'USD',
                ),
                ReportMeasure.max(
                  column: 'netPay',
                  title: 'Max Net Pay',
                  currencyCode: 'USD',
                ),
              ],
              showGrandTotal: true,
            ),
          ],
        );

        final prepared = await engine.prepare(
          definition: definition,
          records: sampleEmployees,
        );

        expect(prepared.title, 'Monthly Compensation Audit');
        expect(prepared.totalRecordCount, 5);
        expect(prepared.analyses.length, 2);

        // Verify Detail Analysis
        final detailAnalysis = prepared.analyses[0];
        expect(detailAnalysis.type, ReportAnalysisType.detail);
        expect(detailAnalysis.rows.length, 5);
        expect(detailAnalysis.grandTotalRow, isNotNull);

        // Verify Grouped Analysis
        final groupedAnalysis = prepared.analyses[1];
        expect(groupedAnalysis.type, ReportAnalysisType.grouped);
        expect(
          groupedAnalysis.groups.length,
          3,
        ); // Engineering, Marketing, Sales

        final engGroup = groupedAnalysis.groups.firstWhere(
          (g) => g.key == 'Engineering',
        );
        expect(engGroup.recordCount, 2);
        expect(engGroup.measureValues['headcount'], 2);
        expect(engGroup.measureValues['basicPay_sum'], 15000.0);
        expect(
          engGroup.measureValues['netPay_sum'],
          15700.0,
        ); // (8000+1000-500) + (7000+500-300) = 8500 + 7200 = 15700
        expect(engGroup.measureValues['netPay_avg'], 7850.0);

        // Verify Reconciliation
        expect(prepared.isReconciled, isTrue);
      },
    );

    test('Should support multi-level nested grouping and subtotals', () async {
      final definition = ReportDefinition<EmployeeTestModel>(
        title: 'Department and Bank Grouping',
        columns: [
          ReportColumn.text(
            id: 'dept',
            title: 'Department',
            value: (e) => e.department,
          ),
          ReportColumn.text(id: 'bank', title: 'Bank', value: (e) => e.bank),
          ReportColumn.money(
            id: 'netPay',
            title: 'Net Pay',
            value: (e) => e.netPay,
          ),
        ],
        analyses: [
          ReportAnalysis.grouped(
            id: 'dept_bank',
            title: 'Dept & Bank Summary',
            groupBy: ['dept', 'bank'],
            measures: [
              ReportMeasure.count(id: 'count', title: 'Employees'),
              ReportMeasure.sum(column: 'netPay'),
            ],
            showSubtotals: true,
            showGrandTotal: true,
          ),
        ],
      );

      final prepared = await engine.prepare(
        definition: definition,
        records: sampleEmployees,
      );

      final groupedAnalysis = prepared.analyses.first;
      expect(groupedAnalysis.groups.length, 3);
      final engGroup = groupedAnalysis.groups.firstWhere(
        (g) => g.key == 'Engineering',
      );
      expect(engGroup.subGroups.length, 1); // Chase
      expect(engGroup.subGroups.first.key, 'Chase');
    });

    test(
      'Should calculate weighted average, distinct count, and percentage of total',
      () async {
        final definition = ReportDefinition<EmployeeTestModel>(
          title: 'Performance & Weight Metrics',
          columns: [
            ReportColumn.text(
              id: 'dept',
              title: 'Department',
              value: (e) => e.department,
            ),
            ReportColumn.text(id: 'bank', title: 'Bank', value: (e) => e.bank),
            ReportColumn.number(
              id: 'rating',
              title: 'Rating',
              value: (e) => e.performanceRating,
            ),
            ReportColumn.number(
              id: 'weight',
              title: 'Basic Pay',
              value: (e) => e.basicPay,
            ),
          ],
          analyses: [
            ReportAnalysis.grouped(
              id: 'dept_metrics',
              title: 'Dept Metrics',
              groupBy: ['dept'],
              measures: [
                ReportMeasure.distinctCount(
                  column: 'bank',
                  id: 'distinct_banks',
                ),
                ReportMeasure.weightedAverage(
                  column: 'rating',
                  weightedBy: 'weight',
                  id: 'weighted_rating',
                ),
                ReportMeasure.percentageOfTotal(
                  column: 'weight',
                  id: 'pay_share',
                ),
              ],
            ),
          ],
        );

        final prepared = await engine.prepare(
          definition: definition,
          records: sampleEmployees,
        );

        final eng = prepared.analyses.first.groups.firstWhere(
          (g) => g.key == 'Engineering',
        );
        expect(eng.measureValues['distinct_banks'], 1); // Only Chase
        expect(eng.measureValues['weighted_rating'], isNotNull);
        expect(eng.measureValues['pay_share'], isNotNull);
      },
    );

    test('Should support derived formula measures with dependencies', () async {
      final definition = ReportDefinition<EmployeeTestModel>(
        title: 'Derived Measures Report',
        columns: [
          ReportColumn.text(
            id: 'dept',
            title: 'Dept',
            value: (e) => e.department,
          ),
          ReportColumn.money(
            id: 'basicPay',
            title: 'Basic',
            value: (e) => e.basicPay,
          ),
          ReportColumn.money(
            id: 'bonus',
            title: 'Bonus',
            value: (e) => e.bonus,
          ),
        ],
        analyses: [
          ReportAnalysis.grouped(
            id: 'dept_bonus_ratio',
            title: 'Dept Bonus Ratio',
            groupBy: ['dept'],
            measures: [
              ReportMeasure.sum(column: 'basicPay', id: 'total_basic'),
              ReportMeasure.sum(column: 'bonus', id: 'total_bonus'),
              ReportMeasure.formula(
                id: 'bonus_percentage',
                title: 'Bonus % of Base',
                dependsOn: ['total_basic', 'total_bonus'],
                calculate: (values) {
                  final base = values['total_basic'] ?? 0;
                  final bonus = values['total_bonus'] ?? 0;
                  return base > 0 ? (bonus / base) * 100 : 0;
                },
              ),
            ],
          ),
        ],
      );

      final prepared = await engine.prepare(
        definition: definition,
        records: sampleEmployees,
      );

      final eng = prepared.analyses.first.groups.firstWhere(
        (g) => g.key == 'Engineering',
      );
      final double bonusPct = eng.measureValues['bonus_percentage'];
      expect(bonusPct, closeTo(10.0, 0.1)); // 1500 bonus / 15000 base = 10%
    });

    test('Should detect circular dependencies in derived measures', () {
      final definition = ReportDefinition<Map<String, dynamic>>(
        title: 'Circular Dependency Test',
        columns: [
          ReportColumn.text(id: 'dept', title: 'Dept', value: (m) => m['dept']),
        ],
        analyses: [
          ReportAnalysis.grouped(
            id: 'circular',
            title: 'Circular',
            groupBy: ['dept'],
            measures: [
              ReportMeasure.formula(
                id: 'm1',
                title: 'M1',
                dependsOn: ['m2'],
                calculate: (v) => (v['m2'] ?? 0) + 1,
              ),
              ReportMeasure.formula(
                id: 'm2',
                title: 'M2',
                dependsOn: ['m1'],
                calculate: (v) => (v['m1'] ?? 0) + 1,
              ),
            ],
          ),
        ],
      );

      final errors = definition.validate();
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.contains('circular dependency')), isTrue);
    });

    test('Should handle custom aging category buckets', () async {
      final invoiceData = [
        {'inv': 'INV01', 'days': 10, 'amount': 1000.0},
        {'inv': 'INV02', 'days': 45, 'amount': 2500.0},
        {'inv': 'INV03', 'days': 80, 'amount': 4000.0},
        {'inv': 'INV04', 'days': 120, 'amount': 7000.0},
      ];

      final agingDef = FinanceReportPresets.accountsReceivableAging();
      final prepared = await engine.prepare(
        definition: agingDef,
        records: invoiceData,
      );

      final agingAnalysis = prepared.analyses.firstWhere(
        (a) => a.id == 'aging_summary',
      );
      expect(agingAnalysis.groups.length, 4);
      expect(
        agingAnalysis.groups.map((g) => g.label),
        containsAll([
          'Current (0-30 Days)',
          '31-60 Days',
          '61-90 Days',
          '90+ Days (High Risk)',
        ]),
      );
    });

    test('Should handle Top-N ranking with Other combined row', () async {
      final salesData = [
        {'rep': 'Rep A', 'sales': 10000.0},
        {'rep': 'Rep B', 'sales': 8000.0},
        {'rep': 'Rep C', 'sales': 6000.0},
        {'rep': 'Rep D', 'sales': 4000.0},
        {'rep': 'Rep E', 'sales': 2000.0},
      ];

      final definition = ReportDefinition<Map<String, dynamic>>(
        title: 'Top Sales Reps',
        columns: [
          ReportColumn.text(id: 'rep', title: 'Rep', value: (m) => m['rep']),
          ReportColumn.money(
            id: 'sales',
            title: 'Sales',
            value: (m) => m['sales'],
          ),
        ],
        analyses: [
          ReportAnalysis.grouped(
            id: 'top_reps',
            title: 'Top 2 Reps',
            groupBy: ['rep'],
            measures: [ReportMeasure.sum(column: 'sales', id: 'total_sales')],
            topN: const ReportTopN(
              count: 2,
              rankBy: 'total_sales',
              otherLabel: 'All Other Reps',
            ),
          ),
        ],
      );

      final prepared = await engine.prepare(
        definition: definition,
        records: salesData,
      );

      final analysis = prepared.analyses.first;
      expect(analysis.groups.length, 3); // Rep A, Rep B, All Other Reps
      expect(analysis.groups[0].label, 'Rep A');
      expect(analysis.groups[1].label, 'Rep B');
      expect(analysis.groups[2].label, 'All Other Reps');
      expect(
        analysis.groups[2].measureValues['total_sales'],
        12000.0,
      ); // 6000 + 4000 + 2000
    });

    test('Should handle empty datasets without throwing exception', () async {
      final definition = ReportDefinition<EmployeeTestModel>(
        title: 'Empty Dataset Report',
        columns: [
          ReportColumn.text(id: 'name', title: 'Name', value: (e) => e.name),
          ReportColumn.money(id: 'pay', title: 'Pay', value: (e) => e.netPay),
        ],
        analyses: [
          ReportAnalysis.detail(id: 'detail', title: 'Detail'),
          ReportAnalysis.grouped(
            id: 'grouped',
            title: 'Grouped',
            groupBy: ['name'],
            measures: [ReportMeasure.sum(column: 'pay')],
          ),
        ],
      );

      final prepared = await engine.prepare(
        definition: definition,
        records: <EmployeeTestModel>[],
      );

      expect(prepared.totalRecordCount, 0);
      expect(prepared.analyses[0].rows, isEmpty);
      expect(prepared.analyses[1].groups, isEmpty);
    });

    test('Should handle null category values using fallback label', () async {
      final records = [
        {'id': 1, 'dept': null, 'amount': 100.0},
        {'id': 2, 'dept': '  ', 'amount': 200.0},
        {'id': 3, 'dept': 'IT', 'amount': 300.0},
      ];

      final definition = ReportDefinition<Map<String, dynamic>>(
        title: 'Missing Category Test',
        columns: [
          ReportColumn.text(
            id: 'dept',
            title: 'Department',
            value: (m) => m['dept'],
          ),
          ReportColumn.money(
            id: 'amount',
            title: 'Amount',
            value: (m) => m['amount'],
          ),
        ],
        analyses: [
          ReportAnalysis.grouped(
            id: 'summary',
            title: 'Summary',
            groupBy: ['dept'],
            missingCategoryLabel: 'Unassigned',
            measures: [ReportMeasure.sum(column: 'amount')],
          ),
        ],
      );

      final prepared = await engine.prepare(
        definition: definition,
        records: records,
      );

      final groups = prepared.analyses.first.groups;
      expect(groups.any((g) => g.label == 'Unassigned'), isTrue);
      final unassigned = groups.firstWhere((g) => g.label == 'Unassigned');
      expect(unassigned.recordCount, 2);
      expect(unassigned.measureValues['amount_sum'], 300.0);
    });

    test(
      'Should split categories into dedicated sheets with detail rows and subtotals',
      () async {
        final deductionsData = [
          {
            'empId': 'EMP01',
            'name': 'Eleanor',
            'scheme': 'KCB Loan',
            'amount': 300.0,
          },
          {
            'empId': 'EMP02',
            'name': 'Marcus',
            'scheme': 'KCB Loan',
            'amount': 400.0,
          },
          {
            'empId': 'EMP03',
            'name': 'Sophia',
            'scheme': 'Housing Levy',
            'amount': 150.0,
          },
        ];

        final definition = ReportDefinition<Map<String, dynamic>>(
          title: 'Deduction Schedules',
          columns: [
            ReportColumn.text(
              id: 'empId',
              title: 'Employee ID',
              value: (m) => m['empId'],
            ),
            ReportColumn.text(
              id: 'name',
              title: 'Name',
              value: (m) => m['name'],
            ),
            ReportColumn.text(
              id: 'scheme',
              title: 'Scheme',
              value: (m) => m['scheme'],
            ),
            ReportColumn.money(
              id: 'amount',
              title: 'Amount',
              value: (m) => m['amount'],
            ),
          ],
          analyses: [
            ReportAnalysis.grouped(
              id: 'by_scheme',
              title: 'Deductions by Scheme',
              groupBy: ['scheme'],
              sheetPerCategory: true,
              detailColumns: ['empId', 'name', 'amount'],
              measures: [
                ReportMeasure.count(id: 'count', title: 'Employees'),
                ReportMeasure.sum(column: 'amount', title: 'Total Amount'),
              ],
              showGrandTotal: true,
            ),
          ],
        );

        final prepared = await engine.prepare(
          definition: definition,
          records: deductionsData,
        );

        final analysis = prepared.analyses.first;
        expect(analysis.categorySheets, isNotNull);
        expect(analysis.categorySheets!.length, 2); // KCB Loan & Housing Levy

        final kcbSheet = analysis.categorySheets!.firstWhere(
          (s) => s.categoryKey == 'KCB Loan',
        );
        expect(kcbSheet.categoryLabel, 'KCB Loan');
        expect(kcbSheet.rows.length, 2); // 2 employees
        expect(
          kcbSheet.headers.map((h) => h.id),
          containsAll(['empId', 'name', 'amount']),
        );
        expect(kcbSheet.totalsRow, isNotNull);

        final housingSheet = analysis.categorySheets!.firstWhere(
          (s) => s.categoryKey == 'Housing Levy',
        );
        expect(housingSheet.categoryLabel, 'Housing Levy');
        expect(housingSheet.rows.length, 1);
        expect(housingSheet.totalsRow, isNotNull);
      },
    );

    test(
      'PayrollReportPresets.categorizedDeductions generates complete multi-sheet analysis',
      () async {
        final sampleDeductions = [
          {
            'employeeId': 'EMP001',
            'employeeName': 'Eleanor Vance',
            'department': 'Engineering',
            'deductionType': 'KCB Bank Loan',
            'referenceNumber': 'KCB-4481',
            'amount': 350.0,
            'employerContribution': 0.0,
          },
          {
            'employeeId': 'EMP002',
            'employeeName': 'Marcus Brody',
            'department': 'Engineering',
            'deductionType': 'KCB Bank Loan',
            'referenceNumber': 'KCB-9912',
            'amount': 400.0,
            'employerContribution': 0.0,
          },
          {
            'employeeId': 'EMP001',
            'employeeName': 'Eleanor Vance',
            'department': 'Engineering',
            'deductionType': 'Housing Levy',
            'referenceNumber': 'HL-001',
            'amount': 150.0,
            'employerContribution': 150.0,
          },
        ];

        final def = PayrollReportPresets.categorizedDeductions(
          companyName: 'Acme Corp',
        );

        final prepared = await engine.prepare(
          definition: def,
          records: sampleDeductions,
        );

        expect(
          prepared.analyses.length,
          3,
        ); // Summary, Category Schedules, Dept CrossTab
        expect(prepared.analyses[0].id, 'deductions_summary');
        expect(prepared.analyses[1].id, 'deduction_schedules');
        expect(prepared.analyses[1].categorySheets, isNotNull);
        expect(prepared.analyses[1].categorySheets!.length, 2);
        expect(prepared.analyses[2].id, 'dept_by_deduction');
      },
    );
  });
}
