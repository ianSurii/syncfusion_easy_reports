import '../engine/report_definition.dart';
import '../engine/report_column.dart';
import '../engine/report_analysis.dart';
import '../engine/report_measure.dart';
import '../models/report_models.dart';

/// Pre-built report presets for Project Timesheets, Resource Utilization, and Budgeting.
class ProjectReportPresets {
  /// Project Timesheet & Resource Utilization report.
  static ReportDefinition<Map<String, dynamic>> timesheetSummary({
    String title = 'Project Timesheet & Utilization',
    String? companyName,
    ReportTheme? theme,
  }) {
    return ReportDefinition<Map<String, dynamic>>(
      title: title,
      branding: ReportBranding(companyName: companyName),
      theme: theme ?? ReportTheme.corporateDark(),
      columns: [
        ReportColumn.text(
          id: 'project',
          title: 'Project Name',
          value: (m) => m['project'] ?? m['projectName'],
        ),
        ReportColumn.text(
          id: 'employee',
          title: 'Team Member',
          value: (m) => m['employee'] ?? m['name'],
        ),
        ReportColumn.text(
          id: 'task',
          title: 'Task Description',
          value: (m) => m['task'],
        ),
        ReportColumn.number(
          id: 'hours',
          title: 'Logged Hours',
          precision: 1,
          value: (m) => m['hours'] ?? 0,
        ),
        ReportColumn.boolean(
          id: 'billable',
          title: 'Billable',
          value: (m) => m['billable'] ?? true,
        ),
        ReportColumn.date(
          id: 'date',
          title: 'Log Date',
          value: (m) => m['date'] is DateTime ? m['date'] : null,
        ),
      ],
      analyses: [
        ReportAnalysis.detail(
          id: 'timesheet_logs',
          title: 'Timesheet Logs',
          showGrandTotal: true,
        ),
        ReportAnalysis.grouped(
          id: 'project_hours',
          title: 'Hours by Project',
          groupBy: ['project'],
          measures: [
            ReportMeasure.count(id: 'entries', title: 'Log Entries'),
            ReportMeasure.sum(column: 'hours', title: 'Total Hours'),
            ReportMeasure.average(column: 'hours', title: 'Avg Hours / Log'),
            ReportMeasure.percentageOfTotal(
              column: 'hours',
              title: '% of Project Time',
            ),
          ],
          showGrandTotal: true,
        ),
        ReportAnalysis.grouped(
          id: 'resource_hours',
          title: 'Hours by Team Member',
          groupBy: ['employee'],
          measures: [
            ReportMeasure.sum(column: 'hours', title: 'Total Hours'),
            ReportMeasure.percentageOfTotal(
              column: 'hours',
              title: '% Allocation',
            ),
          ],
          showGrandTotal: true,
        ),
      ],
    );
  }
}
