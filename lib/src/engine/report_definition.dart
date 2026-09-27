import '../models/report_models.dart';
import 'report_column.dart';
import 'report_measure.dart';
import 'report_analysis.dart';
import 'report_options.dart';

/// Defines the complete schema, presentation options, and analysis plan for a dataset.
///
/// A [ReportDefinition] is reusable across different lists of records of type [T].
class ReportDefinition<T> {
  /// Report title displayed at the top of exports and covers.
  final String title;

  /// Optional subtitle or report period descriptor.
  final String? subtitle;

  /// Available columns in the dataset.
  final List<ReportColumn<T>> columns;

  /// List of analyses to calculate and render (sheets in Excel, sections in PDF).
  final List<ReportAnalysis> analyses;

  /// Visual branding information (company name, address, logo).
  final ReportBranding? branding;

  /// Visual styling theme (colors, fonts, borders).
  final ReportTheme? theme;

  /// Document layout and page settings.
  final ReportSettings? settings;

  /// Default Excel export options for this report.
  final ExcelExportOptions? excelOptions;

  /// Default PDF export options for this report.
  final PdfExportOptions? pdfOptions;

  /// Optional arbitrary metadata (e.g. author, system version, environment).
  final Map<String, dynamic>? metadata;

  const ReportDefinition({
    required this.title,
    this.subtitle,
    required this.columns,
    this.analyses = const [],
    this.branding,
    this.theme,
    this.settings,
    this.excelOptions,
    this.pdfOptions,
    this.metadata,
  });

  /// Finds a column definition by its unique [id].
  ReportColumn<T>? getColumn(String id) {
    for (final col in columns) {
      if (col.id == id) return col;
    }
    return null;
  }

  /// Validates the definition for consistency and returns any detected validation errors.
  List<String> validate() {
    final List<String> errors = [];
    final Set<String> columnIds = {};

    // Check duplicate column IDs
    for (final col in columns) {
      if (!columnIds.add(col.id)) {
        errors.add('Duplicate column ID: "${col.id}"');
      }
    }

    // Check analyses reference valid columns and measures
    for (final analysis in analyses) {
      for (final groupColId in analysis.groupBy) {
        if (!columnIds.contains(groupColId)) {
          errors.add(
            'Analysis "${analysis.id}" references unknown groupBy column "$groupColId"',
          );
        }
      }

      if (analysis.detailColumns != null) {
        for (final detailColId in analysis.detailColumns!) {
          if (!columnIds.contains(detailColId)) {
            errors.add(
              'Analysis "${analysis.id}" references unknown detail column "$detailColId"',
            );
          }
        }
      }

      // Check measures
      final Set<String> measureIds = {};
      for (final measure in analysis.measures) {
        if (!measureIds.add(measure.id)) {
          errors.add(
            'Analysis "${analysis.id}" contains duplicate measure ID "${measure.id}"',
          );
        }
        if (measure.column != null && !columnIds.contains(measure.column)) {
          errors.add(
            'Measure "${measure.id}" in analysis "${analysis.id}" references unknown column "${measure.column}"',
          );
        }
        if (measure.weightedBy != null &&
            !columnIds.contains(measure.weightedBy)) {
          errors.add(
            'Measure "${measure.id}" in analysis "${analysis.id}" references unknown weightedBy column "${measure.weightedBy}"',
          );
        }
      }

      // Check circular dependencies in derived measures
      _checkCircularDependencies(analysis.measures, errors, analysis.id);
    }

    return errors;
  }

  void _checkCircularDependencies(
    List<ReportMeasure> measures,
    List<String> errors,
    String analysisId,
  ) {
    final Map<String, List<String>> graph = {};
    for (final m in measures) {
      if (m.type == ReportMeasureType.formula) {
        graph[m.id] = m.dependsOn;
      }
    }

    final Set<String> visited = {};
    final Set<String> recursionStack = {};

    bool dfs(String node) {
      visited.add(node);
      recursionStack.add(node);

      final dependencies = graph[node] ?? [];
      for (final dep in dependencies) {
        if (!visited.contains(dep)) {
          if (dfs(dep)) return true;
        } else if (recursionStack.contains(dep)) {
          return true;
        }
      }

      recursionStack.remove(node);
      return false;
    }

    for (final node in graph.keys) {
      if (!visited.contains(node)) {
        if (dfs(node)) {
          errors.add(
            'Analysis "$analysisId" contains circular dependency involving measure "$node"',
          );
        }
      }
    }
  }

  /// Creates a copy of this definition with replaced fields.
  ReportDefinition<T> copyWith({
    String? title,
    String? subtitle,
    List<ReportColumn<T>>? columns,
    List<ReportAnalysis>? analyses,
    ReportBranding? branding,
    ReportTheme? theme,
    ReportSettings? settings,
    ExcelExportOptions? excelOptions,
    PdfExportOptions? pdfOptions,
    Map<String, dynamic>? metadata,
  }) {
    return ReportDefinition<T>(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      columns: columns ?? this.columns,
      analyses: analyses ?? this.analyses,
      branding: branding ?? this.branding,
      theme: theme ?? this.theme,
      settings: settings ?? this.settings,
      excelOptions: excelOptions ?? this.excelOptions,
      pdfOptions: pdfOptions ?? this.pdfOptions,
      metadata: metadata ?? this.metadata,
    );
  }
}
