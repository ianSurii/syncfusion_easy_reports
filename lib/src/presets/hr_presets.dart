import '../engine/report_definition.dart';
import '../engine/report_column.dart';
import '../engine/report_analysis.dart';
import '../engine/report_measure.dart';
import '../models/report_models.dart';

/// Pre-built report presets for Human Resources management.
class HrReportPresets {
  /// Employee Register report definition for Map-based or custom records.
  static ReportDefinition<Map<String, dynamic>> employeeRegister({
    String title = 'Employee Register',
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
          title: 'Full Name',
          value: (m) => m['name'],
        ),
        ReportColumn.text(
          id: 'department',
          title: 'Department',
          value: (m) => m['department'] ?? m['dept'],
        ),
        ReportColumn.text(
          id: 'designation',
          title: 'Job Title',
          value: (m) => m['designation'] ?? m['title'] ?? m['role'],
        ),
        ReportColumn.text(
          id: 'status',
          title: 'Status',
          value: (m) => m['status'] ?? 'Active',
        ),
        ReportColumn.date(
          id: 'joinedDate',
          title: 'Joined Date',
          value: (m) => m['joinedDate'] is DateTime
              ? m['joinedDate']
              : (m['joined'] is DateTime ? m['joined'] : null),
        ),
      ],
      analyses: [
        ReportAnalysis.detail(
          id: 'register',
          title: 'All Employees',
          showGrandTotal: false,
        ),
        ReportAnalysis.grouped(
          id: 'by_dept',
          title: 'Headcount by Department',
          groupBy: ['department'],
          measures: [ReportMeasure.count(id: 'headcount', title: 'Headcount')],
        ),
      ],
    );
  }

  /// Headcount and demographic distribution report.
  static ReportDefinition<Map<String, dynamic>> headcountSummary({
    String title = 'Headcount & Department Summary',
    String? companyName,
    ReportTheme? theme,
  }) {
    return ReportDefinition<Map<String, dynamic>>(
      title: title,
      branding: ReportBranding(companyName: companyName),
      theme: theme ?? ReportTheme.corporateDark(),
      columns: [
        ReportColumn.text(
          id: 'department',
          title: 'Department',
          value: (m) => m['department'] ?? m['dept'],
        ),
        ReportColumn.text(
          id: 'location',
          title: 'Location',
          value: (m) => m['location'] ?? 'HQ',
        ),
        ReportColumn.text(
          id: 'status',
          title: 'Employment Status',
          value: (m) => m['status'] ?? 'Full-Time',
        ),
      ],
      analyses: [
        ReportAnalysis.grouped(
          id: 'dept_location',
          title: 'Department & Location Breakdown',
          groupBy: ['department', 'location'],
          measures: [ReportMeasure.count(id: 'headcount', title: 'Employees')],
          showSubtotals: true,
          showGrandTotal: true,
        ),
      ],
    );
  }
}
