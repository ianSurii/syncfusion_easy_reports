import '../engine/report_definition.dart';
import '../engine/report_column.dart';
import '../engine/report_analysis.dart';
import '../engine/report_measure.dart';
import '../models/report_models.dart';

/// Pre-built report presets for Payroll, Deductions, and Compensation.
class PayrollReportPresets {
  /// Monthly Payroll Register with Department and Bank summaries.
  static ReportDefinition<Map<String, dynamic>> monthlyPayroll({
    String title = 'Monthly Payroll Register',
    String currencyCode = 'USD',
    String? companyName,
    ReportTheme? theme,
  }) {
    return ReportDefinition<Map<String, dynamic>>(
      title: title,
      branding: ReportBranding(companyName: companyName),
      theme: theme ?? ReportTheme.classicBlue(),
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
          id: 'department',
          title: 'Department',
          value: (m) => m['department'] ?? m['dept'],
        ),
        ReportColumn.text(
          id: 'bank',
          title: 'Bank Name',
          value: (m) => m['bank'] ?? m['bankName'] ?? 'Standard Bank',
        ),
        ReportColumn.money(
          id: 'basicPay',
          title: 'Basic Pay',
          currencyCode: currencyCode,
          value: (m) => m['basicPay'] ?? m['salary'],
        ),
        ReportColumn.money(
          id: 'allowances',
          title: 'Allowances',
          currencyCode: currencyCode,
          value: (m) => m['allowances'] ?? m['bonus'] ?? 0,
        ),
        ReportColumn.money(
          id: 'deductions',
          title: 'Deductions',
          currencyCode: currencyCode,
          value: (m) => m['deductions'] ?? 0,
        ),
        ReportColumn.money(
          id: 'netPay',
          title: 'Net Pay',
          currencyCode: currencyCode,
          value: (m) {
            if (m['netPay'] != null) return m['netPay'];
            final num base = m['basicPay'] ?? m['salary'] ?? 0;
            final num allow = m['allowances'] ?? m['bonus'] ?? 0;
            final num ded = m['deductions'] ?? 0;
            return base + allow - ded;
          },
        ),
      ],
      analyses: [
        ReportAnalysis.detail(
          id: 'payroll_register',
          title: 'Payroll Register',
          showGrandTotal: true,
        ),
        ReportAnalysis.grouped(
          id: 'dept_summary',
          title: 'Department Summary',
          groupBy: ['department'],
          measures: [
            ReportMeasure.count(id: 'emp_count', title: 'Employees'),
            ReportMeasure.sum(column: 'basicPay', currencyCode: currencyCode),
            ReportMeasure.sum(column: 'allowances', currencyCode: currencyCode),
            ReportMeasure.sum(column: 'deductions', currencyCode: currencyCode),
            ReportMeasure.sum(column: 'netPay', currencyCode: currencyCode),
            ReportMeasure.average(
              column: 'netPay',
              title: 'Avg Net Pay',
              currencyCode: currencyCode,
            ),
          ],
          showSubtotals: true,
          showGrandTotal: true,
        ),
        ReportAnalysis.grouped(
          id: 'bank_summary',
          title: 'Bank Payment Schedule',
          groupBy: ['bank'],
          measures: [
            ReportMeasure.count(id: 'payees', title: 'Payees'),
            ReportMeasure.sum(column: 'netPay', currencyCode: currencyCode),
          ],
          showGrandTotal: true,
        ),
      ],
    );
  }

  /// Categorized Deductions & Remittance Schedule Report.
  ///
  /// Splits each deduction type (e.g. KCB Bank Loan, Equity Bank Loan,
  /// Housing Levy, SHA/SHIF, PAYE, Sacco Deductions) into a dedicated Excel
  /// worksheet or PDF section listing all affected employee line items,
  /// along with an overall summary table and department breakdown matrix.
  static ReportDefinition<Map<String, dynamic>> categorizedDeductions({
    String title = 'Payroll Deductions & Remittance Schedule',
    String currencyCode = 'USD',
    String? companyName,
    ReportTheme? theme,
    String deductionKey = 'deductionType',
    String amountKey = 'amount',
    String? employerContributionKey = 'employerContribution',
  }) {
    return ReportDefinition<Map<String, dynamic>>(
      title: title,
      branding: ReportBranding(companyName: companyName),
      theme: theme ?? ReportTheme.classicBlue(),
      columns: [
        ReportColumn.text(
          id: 'employeeId',
          title: 'Employee ID',
          value: (m) => m['employeeId'] ?? m['id'] ?? m['empId'],
        ),
        ReportColumn.text(
          id: 'employeeName',
          title: 'Employee Name',
          value: (m) => m['employeeName'] ?? m['name'],
        ),
        ReportColumn.text(
          id: 'department',
          title: 'Department',
          value: (m) => m['department'] ?? m['dept'],
        ),
        ReportColumn.text(
          id: deductionKey,
          title: 'Deduction Type',
          value: (m) => m[deductionKey] ?? m['category'] ?? 'General',
        ),
        ReportColumn.text(
          id: 'referenceNumber',
          title: 'Ref / Account No',
          value: (m) =>
              m['referenceNumber'] ?? m['refNo'] ?? m['accountNo'] ?? '-',
        ),
        ReportColumn.money(
          id: amountKey,
          title: 'Employee Deduction',
          currencyCode: currencyCode,
          value: (m) => m[amountKey] ?? 0,
        ),
        if (employerContributionKey != null)
          ReportColumn.money(
            id: employerContributionKey,
            title: 'Employer Contribution',
            currencyCode: currencyCode,
            value: (m) => m[employerContributionKey] ?? 0,
          ),
        ReportColumn.money(
          id: 'totalRemittance',
          title: 'Total Remittance',
          currencyCode: currencyCode,
          value: (m) {
            final num emp = m[amountKey] ?? 0;
            final num empyr = employerContributionKey != null
                ? (m[employerContributionKey] ?? 0)
                : 0;
            return emp + empyr;
          },
        ),
        ReportColumn.text(
          id: 'notes',
          title: 'Remarks / Notes',
          value: (m) => m['notes'] ?? m['remarks'] ?? '',
        ),
      ],
      analyses: [
        // 1. Overview Deductions Summary Table
        ReportAnalysis.grouped(
          id: 'deductions_summary',
          title: 'Deductions Summary Overview',
          subtitle:
              'Consolidated breakdown of all payroll deductions and remittances',
          groupBy: [deductionKey],
          measures: [
            ReportMeasure.count(
              id: 'employee_count',
              title: 'Affected Employees',
            ),
            ReportMeasure.sum(
              column: amountKey,
              title: 'Total Employee Deductions',
              currencyCode: currencyCode,
            ),
            if (employerContributionKey != null)
              ReportMeasure.sum(
                column: employerContributionKey,
                title: 'Total Employer Contribution',
                currencyCode: currencyCode,
              ),
            ReportMeasure.sum(
              column: 'totalRemittance',
              title: 'Total Remittance',
              currencyCode: currencyCode,
            ),
            ReportMeasure.percentageOfTotal(
              column: amountKey,
              title: '% of Total Deductions',
            ),
          ],
          showGrandTotal: true,
        ),
        // 2. Dedicated Worksheet / Section per Deduction Category
        ReportAnalysis.grouped(
          id: 'deduction_schedules',
          title: 'Deduction Remittance Schedules',
          subtitle: 'Itemized employee lists by deduction provider/scheme',
          groupBy: [deductionKey],
          sheetPerCategory: true,
          detailColumns: [
            'employeeId',
            'employeeName',
            'department',
            'referenceNumber',
            amountKey,
            ?employerContributionKey,
            'totalRemittance',
            'notes',
          ],
          measures: [
            ReportMeasure.count(id: 'count', title: 'Employees'),
            ReportMeasure.sum(
              column: amountKey,
              title: 'Total Deduction',
              currencyCode: currencyCode,
            ),
          ],
          showGrandTotal: true,
        ),
        // 3. Department Breakdown Matrix
        ReportAnalysis.crossTab(
          id: 'dept_by_deduction',
          title: 'Department by Deduction Matrix',
          subtitle: 'Distribution of deduction amounts across departments',
          rowDimension: 'department',
          columnDimension: deductionKey,
          measure: ReportMeasure.sum(
            column: amountKey,
            currencyCode: currencyCode,
          ),
        ),
      ],
    );
  }

  /// Bank Remittance Schedule Report.
  ///
  /// Groups net salary payments by financial institution (e.g. KCB, Equity Bank,
  /// Chase, Citibank) with dedicated worksheets for each bank's payment batch.
  static ReportDefinition<Map<String, dynamic>> bankRemittanceSchedule({
    String title = 'Bank Disbursement & Remittance Schedule',
    String currencyCode = 'USD',
    String? companyName,
    ReportTheme? theme,
  }) {
    return ReportDefinition<Map<String, dynamic>>(
      title: title,
      branding: ReportBranding(companyName: companyName),
      theme: theme ?? ReportTheme.classicBlue(),
      columns: [
        ReportColumn.text(
          id: 'id',
          title: 'Employee ID',
          value: (m) => m['id'] ?? m['employeeId'],
        ),
        ReportColumn.text(
          id: 'name',
          title: 'Employee Name',
          value: (m) => m['name'] ?? m['employeeName'],
        ),
        ReportColumn.text(
          id: 'bank',
          title: 'Bank Name',
          value: (m) => m['bank'] ?? m['bankName'] ?? 'Standard Bank',
        ),
        ReportColumn.text(
          id: 'accountNumber',
          title: 'Account Number',
          value: (m) => m['accountNumber'] ?? m['accountNo'] ?? '-',
        ),
        ReportColumn.text(
          id: 'branch',
          title: 'Bank Branch',
          value: (m) => m['branch'] ?? m['bankBranch'] ?? 'Main Branch',
        ),
        ReportColumn.money(
          id: 'netPay',
          title: 'Net Amount Payable',
          currencyCode: currencyCode,
          value: (m) => m['netPay'] ?? m['amount'] ?? 0,
        ),
      ],
      analyses: [
        ReportAnalysis.grouped(
          id: 'bank_summary',
          title: 'Bank Payment Overview',
          subtitle: 'Summary of total disbursements per banking partner',
          groupBy: ['bank'],
          measures: [
            ReportMeasure.count(id: 'payees', title: 'Payees Count'),
            ReportMeasure.sum(
              column: 'netPay',
              title: 'Total Transfer Amount',
              currencyCode: currencyCode,
            ),
            ReportMeasure.percentageOfTotal(
              column: 'netPay',
              title: '% of Total Payroll',
            ),
          ],
          showGrandTotal: true,
        ),
        ReportAnalysis.grouped(
          id: 'bank_batches',
          title: 'Bank Payment Schedules',
          subtitle: 'Itemized payee schedule per bank',
          groupBy: ['bank'],
          sheetPerCategory: true,
          detailColumns: ['id', 'name', 'accountNumber', 'branch', 'netPay'],
          measures: [
            ReportMeasure.count(id: 'count', title: 'Payees'),
            ReportMeasure.sum(column: 'netPay', currencyCode: currencyCode),
          ],
          showGrandTotal: true,
        ),
      ],
    );
  }
}
