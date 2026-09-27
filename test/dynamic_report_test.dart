import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_easy_reports/syncfusion_easy_reports.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dynamicDataset = [
    {
      'employee_id': 'EMP-01',
      'full_name': 'Eleanor Vance',
      'department': 'Engineering',
      'deduction_type': 'KCB Bank Loan',
      'loan_reference': 'KCB-44810',
      'amount': 350.0,
      'is_active': true,
      'hire_date': DateTime(2021, 3, 15),
    },
    {
      'employee_id': 'EMP-02',
      'full_name': 'Marcus Brody',
      'department': 'Engineering',
      'deduction_type': 'KCB Bank Loan',
      'loan_reference': 'KCB-99120',
      'amount': 400.0,
      'is_active': true,
      'hire_date': DateTime(2022, 6, 1),
    },
    {
      'employee_id': 'EMP-03',
      'full_name': 'Sophia Chen',
      'department': 'Marketing',
      'deduction_type': 'Equity Bank Loan',
      'loan_reference': 'EQ-88210',
      'amount': 500.0,
      'is_active': true,
      'hire_date': DateTime(2020, 11, 20),
    },
    {
      'employee_id': 'EMP-04',
      'full_name': 'Lucas Miller',
      'department': 'Marketing',
      'deduction_type': 'Housing Levy',
      'loan_reference': 'HL-2026',
      'amount': 150.0,
      'is_active': false,
      'hire_date': DateTime(2023, 1, 10),
    },
  ];

  group('Super Dynamic EasyReport Engine Tests', () {
    test('Should auto-infer columns, types, and money fields correctly', () {
      final report = EasyReport.fromMaps(
        data: dynamicDataset,
        title: 'Dynamic Payroll Deductions',
      );

      final cols = report.definition.columns;
      expect(cols.length, 8);

      final empIdCol = cols.firstWhere((c) => c.id == 'employee_id');
      expect(empIdCol.title, 'Employee ID');
      expect(empIdCol.type, ReportFieldType.text);

      final amountCol = cols.firstWhere((c) => c.id == 'amount');
      expect(amountCol.title, 'Amount');
      expect(amountCol.type, ReportFieldType.money);

      final dateCol = cols.firstWhere((c) => c.id == 'hire_date');
      expect(dateCol.title, 'Hire Date');
      expect(dateCol.type, ReportFieldType.date);

      final activeCol = cols.firstWhere((c) => c.id == 'is_active');
      expect(activeCol.title, 'Is Active');
      expect(activeCol.type, ReportFieldType.boolean);
    });

    test(
      'Should dynamically group by any field and generate category-split sheets',
      () async {
        final report = EasyReport.fromMaps(
          data: dynamicDataset,
          title: 'Deductions Audit',
          groupBy: 'deduction_type',
          sheetPerCategory: true,
          showSignatures: true,
        );

        final prepared = await report.prepare();
        expect(prepared.analyses.length, 2); // Detail + Grouped

        final groupedAnalysis = prepared.analyses.firstWhere(
          (a) => a.id == 'grouped_summary',
        );
        expect(groupedAnalysis.categorySheets, isNotNull);
        expect(
          groupedAnalysis.categorySheets!.length,
          3,
        ); // KCB Bank Loan, Equity Bank Loan, Housing Levy

        final kcbSheet = groupedAnalysis.categorySheets!.firstWhere(
          (s) => s.categoryLabel == 'KCB Bank Loan',
        );
        expect(kcbSheet.rows.length, 2);
        expect(kcbSheet.totalsRow, isNotNull);
      },
    );

    test('Should dynamically generate 2D CrossTab pivot matrix', () async {
      final report = EasyReport.fromMaps(
        data: dynamicDataset,
        title: 'Department by Scheme Matrix',
        groupBy: ['department', 'deduction_type'],
        includeCrossTab: true,
      );

      final prepared = await report.prepare();
      expect(prepared.analyses.any((a) => a.id == 'crosstab_matrix'), isTrue);

      final pivot = prepared.analyses.firstWhere(
        (a) => a.id == 'crosstab_matrix',
      );
      expect(pivot.type, ReportAnalysisType.crossTab);
      expect(pivot.crossTabMatrix, isNotNull);
      expect(pivot.crossTabMatrix!.rowKeys, containsAll(['Engineering', 'Marketing']));
    });

    test('Should export Excel and PDF with one-liner methods', () async {
      final excelBytes = await EasyReport.excelBytes(
        data: dynamicDataset,
        title: 'One Liner Excel Report',
        groupBy: 'deduction_type',
        sheetPerCategory: true,
        showSignatures: true,
      );

      final pdfBytes = await EasyReport.pdfBytes(
        data: dynamicDataset,
        title: 'One Liner PDF Report',
        groupBy: 'deduction_type',
        showSignatures: true,
      );

      expect(excelBytes, isNotEmpty);
      expect(pdfBytes, isNotEmpty);
      expect(excelBytes.length, greaterThan(100));
      expect(pdfBytes.length, greaterThan(500));
    });
  });
}
