import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import '../models/report_models.dart';
import 'report_column.dart';
import 'report_measure.dart';
import 'report_analysis.dart';
import 'report_options.dart';
import 'report_artifact.dart';
import 'prepared_report.dart';
import 'report_definition.dart';
import '../generators/excel_exporter.dart';
import '../generators/pdf_exporter.dart';

/// The core calculation and aggregation engine for [syncfusion_easy_reports].
///
/// Follows the primary design principle: **define the data and analysis once,
/// then render it consistently for Excel or PDF.**
class ReportEngine {
  static final Logger _log = Logger('ReportEngine');

  /// Prepares, validates, aggregates, and calculates a report from a definition and records.
  Future<PreparedReport> prepare<T>({
    required ReportDefinition<T> definition,
    required List<T> records,
  }) async {
    _log.info(
      'Preparing report: "${definition.title}" with ${records.length} records',
    );

    // 1. Validate definition
    final validationErrors = definition.validate();
    if (validationErrors.isNotEmpty) {
      throw ArgumentError(
        'Invalid ReportDefinition:\n${validationErrors.join('\n')}',
      );
    }

    final List<String> warnings = [];

    // 2. Map records to normalized maps
    final List<Map<String, dynamic>> rawRecords = [];
    for (int i = 0; i < records.length; i++) {
      final item = records[i];
      final Map<String, dynamic> rowMap = {};
      for (final col in definition.columns) {
        final dynamic rawVal = col.extractValue(item);
        rowMap[col.id] = _normalizeValue(rawVal, col, i, warnings);
      }
      rawRecords.add(rowMap);
    }

    // 3. Process analyses
    final List<PreparedAnalysis> preparedAnalyses = [];
    final Map<String, num> detailTotals = {};
    final Map<String, num> groupTotals = {};
    final Map<String, num> grandTotals = {};
    final List<String> discrepancies = [];

    int maxFilteredRecords = 0;

    for (final analysis in definition.analyses) {
      // Filter records
      final List<Map<String, dynamic>> filteredRecords = rawRecords.where((
        row,
      ) {
        for (final filter in analysis.filters) {
          final val = row[filter.fieldId];
          if (!filter.matches(val, row)) return false;
        }
        return true;
      }).toList();

      if (filteredRecords.length > maxFilteredRecords) {
        maxFilteredRecords = filteredRecords.length;
      }

      PreparedAnalysis prepAnalysis;
      switch (analysis.type) {
        case ReportAnalysisType.detail:
          prepAnalysis = _prepareDetailAnalysis(
            definition,
            analysis,
            filteredRecords,
            detailTotals,
            grandTotals,
          );
          break;
        case ReportAnalysisType.grouped:
          prepAnalysis = _prepareGroupedAnalysis(
            definition,
            analysis,
            filteredRecords,
            groupTotals,
            grandTotals,
          );
          break;
        case ReportAnalysisType.crossTab:
          prepAnalysis = _prepareCrossTabAnalysis(
            definition,
            analysis,
            filteredRecords,
          );
          break;
        case ReportAnalysisType.summary:
          prepAnalysis = _prepareSummaryAnalysis(
            definition,
            analysis,
            filteredRecords,
          );
          break;
      }
      preparedAnalyses.add(prepAnalysis);
    }

    // 4. Reconciliation audit
    bool isReconciled = true;
    for (final colKey in detailTotals.keys) {
      final dTotal = detailTotals[colKey] ?? 0;
      final gTotal = groupTotals[colKey];
      if (gTotal != null) {
        final diff = (dTotal - gTotal).abs();
        if (diff > 0.001) {
          isReconciled = false;
          discrepancies.add(
            'Detail total ($dTotal) does not match group total ($gTotal) for column "$colKey" (diff: $diff)',
          );
        }
      }
    }

    final reconciliation = ReconciliationSummary(
      isReconciled: isReconciled,
      detailTotals: detailTotals,
      groupTotals: groupTotals,
      grandTotals: grandTotals,
      discrepancies: discrepancies,
    );

    if (!isReconciled) {
      warnings.addAll(discrepancies);
    }

    return PreparedReport(
      title: definition.title,
      subtitle: definition.subtitle,
      branding: definition.branding,
      theme: definition.theme ?? ReportTheme.classicBlue(),
      settings: definition.settings ?? ReportSettings(),
      analyses: preparedAnalyses,
      totalRecordCount: records.length,
      filteredRecordCount: maxFilteredRecords,
      warnings: warnings,
      reconciliation: reconciliation,
      metadata: definition.metadata ?? {},
    );
  }

  /// Exports a prepared report to an Excel OpenXML (.xlsx) artifact.
  Future<ReportArtifact> exportExcel(
    PreparedReport prepared, {
    ExcelExportOptions? options,
  }) async {
    final exporter = ExcelReportExporter();
    return exporter.export(prepared, options: options);
  }

  /// Exports a prepared report to an Adobe PDF (.pdf) artifact.
  Future<ReportArtifact> exportPdf(
    PreparedReport prepared, {
    PdfExportOptions? options,
  }) async {
    final exporter = PdfReportExporter();
    return exporter.export(prepared, options: options);
  }

  /// Direct generation helper: prepares records and exports directly to Excel.
  Future<ReportArtifact> generateExcel<T>({
    required ReportDefinition<T> definition,
    required List<T> records,
    ExcelExportOptions? options,
  }) async {
    final prepared = await prepare(definition: definition, records: records);
    return exportExcel(prepared, options: options ?? definition.excelOptions);
  }

  /// Direct generation helper: prepares records and exports directly to PDF.
  Future<ReportArtifact> generatePdf<T>({
    required ReportDefinition<T> definition,
    required List<T> records,
    PdfExportOptions? options,
  }) async {
    final prepared = await prepare(definition: definition, records: records);
    return exportPdf(prepared, options: options ?? definition.pdfOptions);
  }

  // =========================================================================
  // TYPE NORMALIZATION & VALUE PARSING
  // =========================================================================

  dynamic _normalizeValue<T>(
    dynamic raw,
    ReportColumn<T> col,
    int rowIndex,
    List<String> warnings,
  ) {
    if (raw == null) return null;

    switch (col.type) {
      case ReportFieldType.number:
      case ReportFieldType.money:
      case ReportFieldType.percentage:
        if (raw is num) return raw;
        if (raw is String) {
          final clean = raw.replaceAll(RegExp(r'[^0-9.-]'), '');
          final parsed = num.tryParse(clean);
          if (parsed != null) return parsed;
        }
        warnings.add(
          'Row $rowIndex: Invalid numeric value "$raw" in column "${col.id}"',
        );
        return null;

      case ReportFieldType.date:
      case ReportFieldType.dateTime:
        if (raw is DateTime) return raw;
        if (raw is String) {
          final parsed = DateTime.tryParse(raw);
          if (parsed != null) return parsed;
        }
        warnings.add(
          'Row $rowIndex: Invalid date value "$raw" in column "${col.id}"',
        );
        return null;

      case ReportFieldType.boolean:
        if (raw is bool) return raw;
        if (raw is String) {
          final lower = raw.trim().toLowerCase();
          if (lower == 'true' || lower == 'yes' || lower == '1') return true;
          if (lower == 'false' || lower == 'no' || lower == '0') return false;
        }
        return raw != null;

      case ReportFieldType.text:
      case ReportFieldType.custom:
        return raw;
    }
  }

  // =========================================================================
  // DETAIL ANALYSIS PREPARATION
  // =========================================================================

  PreparedAnalysis _prepareDetailAnalysis<T>(
    ReportDefinition<T> definition,
    ReportAnalysis analysis,
    List<Map<String, dynamic>> records,
    Map<String, num> detailTotals,
    Map<String, num> grandTotals,
  ) {
    // Determine active columns
    final List<ReportColumn<T>> activeCols = [];
    if (analysis.detailColumns != null && analysis.detailColumns!.isNotEmpty) {
      for (final colId in analysis.detailColumns!) {
        final col = definition.getColumn(colId);
        if (col != null) activeCols.add(col);
      }
    } else {
      activeCols.addAll(definition.columns.where((c) => c.isVisible));
    }

    final headers = activeCols
        .map(
          (col) => PreparedColumnHeader(
            id: col.id,
            title: col.title,
            fieldType: col.type,
            alignment: col.alignment,
            width: col.width,
            currencyCode: col.currencyCode,
          ),
        )
        .toList();

    // Sort records if specified
    final sortedRecords = List<Map<String, dynamic>>.from(records);
    if (analysis.sort.isNotEmpty) {
      sortedRecords.sort((a, b) {
        for (final s in analysis.sort) {
          final valA = a[s.fieldId];
          final valB = b[s.fieldId];
          final cmp = _compareValues(valA, valB);
          if (cmp != 0) {
            return s.isAscending ? cmp : -cmp;
          }
        }
        return 0;
      });
    }

    // Build rows
    final List<PreparedRow> rows = [];
    final Map<String, num> sums = {};

    for (final rowMap in sortedRecords) {
      final List<PreparedCell> cells = [];
      for (final col in activeCols) {
        final raw = rowMap[col.id];
        final cell = _formatCell(raw, col);
        cells.add(cell);

        if (raw is num) {
          sums[col.id] = (sums[col.id] ?? 0) + raw;
        }
      }
      rows.add(PreparedRow(cells: cells, rawRecord: rowMap));
    }

    // Record detail totals for reconciliation
    detailTotals.addAll(sums);

    // Build grand totals row if requested
    PreparedRow? grandTotalRow;
    if (analysis.showGrandTotal && rows.isNotEmpty) {
      final List<PreparedCell> totalCells = [];
      for (int i = 0; i < activeCols.length; i++) {
        final col = activeCols[i];
        if (i == 0) {
          totalCells.add(
            const PreparedCell(
              rawValue: 'Total',
              formattedText: 'Total',
              type: PreparedCellType.text,
              alignment: ReportColumnAlignment.left,
            ),
          );
        } else if (sums.containsKey(col.id)) {
          final totalNum = sums[col.id]!;
          grandTotals[col.id] = totalNum;
          totalCells.add(_formatCell(totalNum, col));
        } else {
          totalCells.add(
            const PreparedCell(
              rawValue: '',
              formattedText: '',
              type: PreparedCellType.text,
            ),
          );
        }
      }
      grandTotalRow = PreparedRow(cells: totalCells, isGrandTotal: true);
    }

    return PreparedAnalysis(
      id: analysis.id,
      title: analysis.title,
      subtitle: analysis.subtitle,
      type: ReportAnalysisType.detail,
      headers: headers,
      rows: rows,
      grandTotalRow: grandTotalRow,
      recordCount: records.length,
      summaryMetrics: analysis.customData ?? {},
    );
  }

  // =========================================================================
  // GROUPED ANALYSIS PREPARATION
  // =========================================================================

  PreparedAnalysis _prepareGroupedAnalysis<T>(
    ReportDefinition<T> definition,
    ReportAnalysis analysis,
    List<Map<String, dynamic>> records,
    Map<String, num> groupTotals,
    Map<String, num> grandTotals,
  ) {
    final List<PreparedColumnHeader> headers = [];

    // 1. Group dimension headers
    for (final groupColId in analysis.groupBy) {
      final col = definition.getColumn(groupColId);
      headers.add(
        PreparedColumnHeader(
          id: groupColId,
          title: col?.title ?? groupColId,
          fieldType: col?.type ?? ReportFieldType.text,
          alignment: col?.alignment ?? ReportColumnAlignment.left,
          width: col?.width,
        ),
      );
    }

    // 2. Measure headers
    for (final measure in analysis.measures) {
      headers.add(
        PreparedColumnHeader(
          id: measure.id,
          title: measure.title,
          fieldType: measure.currencyCode != null
              ? ReportFieldType.money
              : measure.type == ReportMeasureType.percentageOfTotal
              ? ReportFieldType.percentage
              : ReportFieldType.number,
          alignment: ReportColumnAlignment.right,
          currencyCode: measure.currencyCode,
        ),
      );
    }

    // Execute multi-level grouping
    final List<PreparedGroup> groups = _buildGroups(
      records: records,
      groupByColumns: analysis.groupBy,
      measures: analysis.measures,
      dateGrouping: analysis.dateGrouping,
      categoryBuckets: analysis.categoryBuckets,
      missingCategoryLabel: analysis.missingCategoryLabel,
      definition: definition,
      level: 0,
    );

    // Apply Sorting & Top-N
    _sortAndRankGroups(groups, analysis);

    // Flatten groups into table rows
    final List<PreparedRow> rows = [];
    _flattenGroupsToRows(groups, headers, analysis, rows);

    // Calculate Grand Total across all records
    PreparedRow? grandTotalRow;
    if (analysis.showGrandTotal && records.isNotEmpty) {
      final Map<String, dynamic> grandMeasures = _calculateMeasures(
        records,
        analysis.measures,
        null,
      );

      for (final m in analysis.measures) {
        final val = grandMeasures[m.id];
        if (val is num && m.column != null && m.type == ReportMeasureType.sum) {
          groupTotals[m.column!] = val;
          grandTotals[m.id] = val;
        } else if (val is num) {
          grandTotals[m.id] = val;
        }
      }

      final List<PreparedCell> totalCells = [];
      for (int i = 0; i < headers.length; i++) {
        final h = headers[i];
        if (i == 0) {
          totalCells.add(
            const PreparedCell(
              rawValue: 'Grand Total',
              formattedText: 'Grand Total',
              type: PreparedCellType.text,
              alignment: ReportColumnAlignment.left,
            ),
          );
        } else if (i < analysis.groupBy.length) {
          totalCells.add(
            const PreparedCell(
              rawValue: '',
              formattedText: '',
              type: PreparedCellType.text,
            ),
          );
        } else {
          final val = grandMeasures[h.id];
          totalCells.add(_formatMeasureCell(val, h));
        }
      }
      grandTotalRow = PreparedRow(cells: totalCells, isGrandTotal: true);
    }

    // Split category sheets if requested
    List<PreparedCategorySheet>? categorySheets;
    if (analysis.sheetPerCategory && analysis.groupBy.isNotEmpty) {
      categorySheets = _buildCategorySheets(
        groups: groups,
        summaryHeaders: headers,
        analysis: analysis,
        definition: definition,
      );
    }

    return PreparedAnalysis(
      id: analysis.id,
      title: analysis.title,
      subtitle: analysis.subtitle,
      type: ReportAnalysisType.grouped,
      headers: headers,
      rows: rows,
      groups: groups,
      grandTotalRow: grandTotalRow,
      categorySheets: categorySheets,
      recordCount: records.length,
      summaryMetrics: analysis.customData ?? {},
    );
  }

  // =========================================================================
  // CROSS-TABULATION (PIVOT) ANALYSIS PREPARATION
  // =========================================================================

  PreparedAnalysis _prepareCrossTabAnalysis<T>(
    ReportDefinition<T> definition,
    ReportAnalysis analysis,
    List<Map<String, dynamic>> records,
  ) {
    final rowDim =
        analysis.rowDimension ??
        (analysis.groupBy.isNotEmpty ? analysis.groupBy[0] : 'row');
    final colDim =
        analysis.columnDimension ??
        (analysis.groupBy.length > 1 ? analysis.groupBy[1] : 'col');
    final measure =
        analysis.crossTabMeasure ??
        (analysis.measures.isNotEmpty
            ? analysis.measures.first
            : ReportMeasure.count());

    final rowColDef = definition.getColumn(rowDim);
    final colColDef = definition.getColumn(colDim);

    // Extract unique row keys and column keys
    final Set<String> rowKeySet = {};
    final Set<String> colKeySet = {};
    final Map<String, Map<String, List<Map<String, dynamic>>>> buckets = {};

    for (final row in records) {
      final rVal = _resolveCategoryKey(
        row[rowDim],
        rowDim,
        analysis,
        rowColDef,
      );
      final cVal = _resolveCategoryKey(
        row[colDim],
        colDim,
        analysis,
        colColDef,
      );

      rowKeySet.add(rVal);
      colKeySet.add(cVal);

      buckets.putIfAbsent(rVal, () => {}).putIfAbsent(cVal, () => []).add(row);
    }

    final rowKeys = rowKeySet.toList()..sort();
    final colKeys = colKeySet.toList()..sort();

    final Map<String, Map<String, PreparedCell>> matrix = {};
    final Map<String, PreparedCell> rowTotals = {};
    final Map<String, PreparedCell> colTotals = {};

    num grandTotalNum = 0;

    // Calculate cells and row totals
    for (final rKey in rowKeys) {
      matrix[rKey] = {};
      final List<Map<String, dynamic>> allRowRecords = [];

      for (final cKey in colKeys) {
        final cellRecords = buckets[rKey]?[cKey] ?? [];
        allRowRecords.addAll(cellRecords);

        final calcMap = _calculateMeasures(cellRecords, [measure], records);
        final val = calcMap[measure.id];
        final cell = _formatMeasureCell(
          val,
          PreparedColumnHeader(
            id: measure.id,
            title: measure.title,
            currencyCode: measure.currencyCode,
          ),
        );
        matrix[rKey]![cKey] = cell;
      }

      final rowCalc = _calculateMeasures(allRowRecords, [measure], records);
      final rVal = rowCalc[measure.id];
      if (rVal is num) grandTotalNum += rVal;

      rowTotals[rKey] = _formatMeasureCell(
        rVal,
        PreparedColumnHeader(
          id: measure.id,
          title: 'Total',
          currencyCode: measure.currencyCode,
        ),
      );
    }

    // Calculate column totals
    for (final cKey in colKeys) {
      final List<Map<String, dynamic>> allColRecords = [];
      for (final rKey in rowKeys) {
        allColRecords.addAll(buckets[rKey]?[cKey] ?? []);
      }
      final colCalc = _calculateMeasures(allColRecords, [measure], records);
      colTotals[cKey] = _formatMeasureCell(
        colCalc[measure.id],
        PreparedColumnHeader(
          id: measure.id,
          title: 'Total',
          currencyCode: measure.currencyCode,
        ),
      );
    }

    final grandTotalCell = _formatMeasureCell(
      grandTotalNum,
      PreparedColumnHeader(
        id: measure.id,
        title: 'Grand Total',
        currencyCode: measure.currencyCode,
      ),
    );

    final crossTabMatrix = PreparedCrossTabMatrix(
      rowDimension: rowColDef?.title ?? rowDim,
      columnDimension: colColDef?.title ?? colDim,
      rowKeys: rowKeys,
      columnKeys: colKeys,
      matrix: matrix,
      rowTotals: rowTotals,
      colTotals: colTotals,
      grandTotal: grandTotalCell,
    );

    // Build tabular headers and rows representation for export renderers
    final List<PreparedColumnHeader> headers = [
      PreparedColumnHeader(
        id: rowDim,
        title: rowColDef?.title ?? rowDim,
        alignment: ReportColumnAlignment.left,
      ),
      ...colKeys.map(
        (c) => PreparedColumnHeader(
          id: c,
          title: c,
          alignment: ReportColumnAlignment.right,
          currencyCode: measure.currencyCode,
        ),
      ),
      PreparedColumnHeader(
        id: 'total',
        title: 'Total',
        alignment: ReportColumnAlignment.right,
        currencyCode: measure.currencyCode,
      ),
    ];

    final List<PreparedRow> rows = [];
    for (final rKey in rowKeys) {
      final List<PreparedCell> cells = [
        PreparedCell(
          rawValue: rKey,
          formattedText: rKey,
          alignment: ReportColumnAlignment.left,
        ),
        ...colKeys.map((cKey) => matrix[rKey]![cKey]!),
        rowTotals[rKey]!,
      ];
      rows.add(PreparedRow(cells: cells));
    }

    PreparedRow? grandTotalRow;
    if (analysis.showGrandTotal) {
      final List<PreparedCell> totalCells = [
        const PreparedCell(
          rawValue: 'Total',
          formattedText: 'Total',
          alignment: ReportColumnAlignment.left,
        ),
        ...colKeys.map((cKey) => colTotals[cKey]!),
        grandTotalCell,
      ];
      grandTotalRow = PreparedRow(cells: totalCells, isGrandTotal: true);
    }

    return PreparedAnalysis(
      id: analysis.id,
      title: analysis.title,
      subtitle: analysis.subtitle,
      type: ReportAnalysisType.crossTab,
      headers: headers,
      rows: rows,
      grandTotalRow: grandTotalRow,
      crossTabMatrix: crossTabMatrix,
      recordCount: records.length,
      summaryMetrics: analysis.customData ?? {},
    );
  }

  // =========================================================================
  // SUMMARY ANALYSIS PREPARATION
  // =========================================================================

  PreparedAnalysis _prepareSummaryAnalysis<T>(
    ReportDefinition<T> definition,
    ReportAnalysis analysis,
    List<Map<String, dynamic>> records,
  ) {
    final Map<String, dynamic> metricValues = _calculateMeasures(
      records,
      analysis.measures,
      null,
    );

    final List<PreparedColumnHeader> headers = [
      const PreparedColumnHeader(
        id: 'metric',
        title: 'Metric',
        alignment: ReportColumnAlignment.left,
      ),
      const PreparedColumnHeader(
        id: 'value',
        title: 'Value',
        alignment: ReportColumnAlignment.right,
      ),
    ];

    final List<PreparedRow> rows = [];
    for (final m in analysis.measures) {
      final val = metricValues[m.id];
      final valCell = _formatMeasureCell(
        val,
        PreparedColumnHeader(
          id: m.id,
          title: m.title,
          currencyCode: m.currencyCode,
        ),
      );

      rows.add(
        PreparedRow(
          cells: [
            PreparedCell(
              rawValue: m.title,
              formattedText: m.title,
              alignment: ReportColumnAlignment.left,
            ),
            valCell,
          ],
        ),
      );
    }

    final combinedMetrics = <String, dynamic>{
      ...metricValues,
      ...(analysis.customData ?? {}),
    };

    return PreparedAnalysis(
      id: analysis.id,
      title: analysis.title,
      subtitle: analysis.subtitle,
      type: ReportAnalysisType.summary,
      headers: headers,
      rows: rows,
      summaryMetrics: combinedMetrics,
      recordCount: records.length,
    );
  }

  // =========================================================================
  // GROUPING & MEASURE CALCULATION ALGORITHMS
  // =========================================================================

  List<PreparedGroup> _buildGroups<T>({
    required List<Map<String, dynamic>> records,
    required List<String> groupByColumns,
    required List<ReportMeasure> measures,
    required ReportDateGrouping? dateGrouping,
    required Map<String, List<ReportCategoryBucket>>? categoryBuckets,
    required String missingCategoryLabel,
    required ReportDefinition<T> definition,
    required int level,
  }) {
    if (groupByColumns.isEmpty) return [];

    final String currentDim = groupByColumns[0];
    final colDef = definition.getColumn(currentDim);

    // Group records by current dimension
    final Map<String, List<Map<String, dynamic>>> partitioned = {};

    for (final row in records) {
      final rawVal = row[currentDim];
      final categoryKey = _resolveCategoryKeyForBucket(
        rawVal,
        currentDim,
        dateGrouping,
        categoryBuckets,
        missingCategoryLabel,
        colDef,
      );

      partitioned.putIfAbsent(categoryKey, () => []).add(row);
    }

    final List<PreparedGroup> result = [];
    final remainingDims = groupByColumns.sublist(1);

    for (final entry in partitioned.entries) {
      final groupKey = entry.key;
      final groupRecords = entry.value;

      final Map<String, dynamic> calculatedMeasures = _calculateMeasures(
        groupRecords,
        measures,
        records,
      );

      List<PreparedGroup> subGroups = [];
      if (remainingDims.isNotEmpty) {
        subGroups = _buildGroups(
          records: groupRecords,
          groupByColumns: remainingDims,
          measures: measures,
          dateGrouping: dateGrouping,
          categoryBuckets: categoryBuckets,
          missingCategoryLabel: missingCategoryLabel,
          definition: definition,
          level: level + 1,
        );
      }

      result.add(
        PreparedGroup(
          key: groupKey,
          label: groupKey,
          dimension: colDef?.title ?? currentDim,
          level: level,
          recordCount: groupRecords.length,
          measureValues: calculatedMeasures,
          rawRecords: groupRecords,
          subGroups: subGroups,
        ),
      );
    }

    return result;
  }

  String _resolveCategoryKey(
    dynamic rawVal,
    String colId,
    ReportAnalysis analysis,
    ReportColumn? colDef,
  ) {
    return _resolveCategoryKeyForBucket(
      rawVal,
      colId,
      analysis.dateGrouping,
      analysis.categoryBuckets,
      analysis.missingCategoryLabel,
      colDef,
    );
  }

  String _resolveCategoryKeyForBucket(
    dynamic rawVal,
    String colId,
    ReportDateGrouping? dateGrouping,
    Map<String, List<ReportCategoryBucket>>? categoryBuckets,
    String missingCategoryLabel,
    ReportColumn? colDef,
  ) {
    if (rawVal == null || (rawVal is String && rawVal.trim().isEmpty)) {
      return missingCategoryLabel;
    }

    // 1. Check Date Grouping
    if (dateGrouping != null &&
        dateGrouping.columnId == colId &&
        rawVal is DateTime) {
      return _formatDateGroup(rawVal, dateGrouping);
    }

    // 2. Check Category Buckets
    if (categoryBuckets != null &&
        categoryBuckets.containsKey(colId) &&
        rawVal is num) {
      final buckets = categoryBuckets[colId]!;
      for (final bucket in buckets) {
        if (bucket.contains(rawVal)) {
          return bucket.label;
        }
      }
    }

    // 3. Fallback to standard string representation
    if (colDef?.customFormatter != null) {
      return colDef!.customFormatter!(rawVal);
    }
    return rawVal.toString();
  }

  String _formatDateGroup(DateTime date, ReportDateGrouping grouping) {
    if (grouping.labelFormatter != null) {
      return grouping.labelFormatter!(date, grouping.interval);
    }

    switch (grouping.interval) {
      case ReportDateInterval.day:
        return DateFormat('yyyy-MM-dd').format(date);
      case ReportDateInterval.month:
        return DateFormat('MMM yyyy').format(date);
      case ReportDateInterval.quarter:
        final int q = ((date.month - 1) ~/ 3) + 1;
        return 'Q$q ${date.year}';
      case ReportDateInterval.year:
        if (grouping.fiscalYearStartMonth > 1) {
          final int fiscalYear = date.month >= grouping.fiscalYearStartMonth
              ? date.year + 1
              : date.year;
          return 'FY$fiscalYear';
        }
        return '${date.year}';
    }
  }

  Map<String, dynamic> _calculateMeasures(
    List<Map<String, dynamic>> records,
    List<ReportMeasure> measures,
    List<Map<String, dynamic>>? allRecords,
  ) {
    final Map<String, num> results = {};

    // First pass: Direct aggregations
    for (final m in measures) {
      if (m.type == ReportMeasureType.formula) continue;

      switch (m.type) {
        case ReportMeasureType.count:
          results[m.id] = records.length;
          break;

        case ReportMeasureType.countNonNull:
          if (m.column != null) {
            final count = records.where((r) => r[m.column!] != null).length;
            results[m.id] = count;
          }
          break;

        case ReportMeasureType.distinctCount:
          if (m.column != null) {
            final distinct = records
                .map((r) => r[m.column!])
                .where((v) => v != null)
                .toSet()
                .length;
            results[m.id] = distinct;
          }
          break;

        case ReportMeasureType.sum:
          if (m.column != null) {
            num sum = 0;
            for (final r in records) {
              final v = r[m.column!];
              if (v is num) sum += v;
            }
            results[m.id] = m.precision != null
                ? _round(sum, m.precision!)
                : sum;
          }
          break;

        case ReportMeasureType.average:
          if (m.column != null) {
            num sum = 0;
            int count = 0;
            for (final r in records) {
              final v = r[m.column!];
              if (v is num) {
                sum += v;
                count++;
              }
            }
            final avg = count > 0 ? sum / count : 0;
            results[m.id] = m.precision != null
                ? _round(avg, m.precision!)
                : avg;
          }
          break;

        case ReportMeasureType.weightedAverage:
          if (m.column != null && m.weightedBy != null) {
            num sumWeighted = 0;
            num totalWeight = 0;
            for (final r in records) {
              final v = r[m.column!];
              final w = r[m.weightedBy!];
              if (v is num && w is num) {
                sumWeighted += (v * w);
                totalWeight += w;
              }
            }
            final wAvg = totalWeight > 0 ? sumWeighted / totalWeight : 0;
            results[m.id] = m.precision != null
                ? _round(wAvg, m.precision!)
                : wAvg;
          }
          break;

        case ReportMeasureType.min:
          if (m.column != null) {
            num? minVal;
            for (final r in records) {
              final v = r[m.column!];
              if (v is num) {
                if (minVal == null || v < minVal) minVal = v;
              }
            }
            results[m.id] = minVal ?? 0;
          }
          break;

        case ReportMeasureType.max:
          if (m.column != null) {
            num? maxVal;
            for (final r in records) {
              final v = r[m.column!];
              if (v is num) {
                if (maxVal == null || v > maxVal) maxVal = v;
              }
            }
            results[m.id] = maxVal ?? 0;
          }
          break;

        case ReportMeasureType.percentageOfTotal:
          if (m.column != null && allRecords != null && allRecords.isNotEmpty) {
            num groupSum = 0;
            for (final r in records) {
              final v = r[m.column!];
              if (v is num) groupSum += v;
            }
            num totalSum = 0;
            for (final r in allRecords) {
              final v = r[m.column!];
              if (v is num) totalSum += v;
            }
            final pct = totalSum > 0 ? (groupSum / totalSum) * 100 : 0;
            results[m.id] = m.precision != null
                ? _round(pct, m.precision!)
                : pct;
          }
          break;

        case ReportMeasureType.formula:
          break;
      }
    }

    // Second pass: Derived / formula measures
    for (final m in measures) {
      if (m.type == ReportMeasureType.formula && m.formula != null) {
        final val = m.formula!(results);
        if (val != null) {
          results[m.id] = m.precision != null ? _round(val, m.precision!) : val;
        }
      }
    }

    return results;
  }

  void _sortAndRankGroups(List<PreparedGroup> groups, ReportAnalysis analysis) {
    if (groups.isEmpty) return;

    // Apply sort
    if (analysis.sort.isNotEmpty) {
      groups.sort((a, b) {
        for (final s in analysis.sort) {
          final valA = a.measureValues[s.fieldId] ?? a.label;
          final valB = b.measureValues[s.fieldId] ?? b.label;
          final cmp = _compareValues(valA, valB);
          if (cmp != 0) return s.isAscending ? cmp : -cmp;
        }
        return 0;
      });
    }

    // Apply Top-N truncation with Other
    if (analysis.topN != null && groups.length > analysis.topN!.count) {
      final topN = analysis.topN!;
      groups.sort((a, b) {
        final valA = a.measureValues[topN.rankBy] ?? 0;
        final valB = b.measureValues[topN.rankBy] ?? 0;
        final cmp = _compareValues(valA, valB);
        return topN.isAscending ? cmp : -cmp;
      });

      final topItems = groups.sublist(0, topN.count);
      final remaining = groups.sublist(topN.count);

      if (topN.otherLabel != null && remaining.isNotEmpty) {
        final Map<String, num> otherMeasures = {};
        final List<Map<String, dynamic>> otherRecords = [];
        int otherCount = 0;

        for (final rem in remaining) {
          otherRecords.addAll(rem.rawRecords);
          otherCount += rem.recordCount;
          for (final m in analysis.measures) {
            final val = rem.measureValues[m.id];
            if (val is num) {
              otherMeasures[m.id] = (otherMeasures[m.id] ?? 0) + val;
            }
          }
        }

        topItems.add(
          PreparedGroup(
            key: 'other',
            label: topN.otherLabel!,
            dimension: groups[0].dimension,
            recordCount: otherCount,
            measureValues: otherMeasures,
            rawRecords: otherRecords,
          ),
        );
      }

      groups.clear();
      groups.addAll(topItems);
    }

    // Recursively sort subGroups
    for (final g in groups) {
      if (g.subGroups.isNotEmpty) {
        _sortAndRankGroups(g.subGroups, analysis);
      }
    }
  }

  void _flattenGroupsToRows(
    List<PreparedGroup> groups,
    List<PreparedColumnHeader> headers,
    ReportAnalysis analysis,
    List<PreparedRow> rows,
  ) {
    for (final g in groups) {
      if (g.subGroups.isEmpty) {
        // Leaf group row
        final List<PreparedCell> cells = [];
        for (int i = 0; i < headers.length; i++) {
          final h = headers[i];
          if (i == 0) {
            cells.add(
              PreparedCell(
                rawValue: g.label,
                formattedText: g.label,
                alignment: ReportColumnAlignment.left,
              ),
            );
          } else if (i < analysis.groupBy.length) {
            cells.add(const PreparedCell(rawValue: '', formattedText: ''));
          } else {
            final val = g.measureValues[h.id];
            cells.add(_formatMeasureCell(val, h));
          }
        }
        rows.add(
          PreparedRow(cells: cells, groupKey: g.key, groupLevel: g.level),
        );
      } else {
        // Multi-level nested group header
        final List<PreparedCell> headerCells = [
          PreparedCell(
            rawValue: g.label,
            formattedText: g.label,
            alignment: ReportColumnAlignment.left,
          ),
          ...List.filled(
            headers.length - 1,
            const PreparedCell(rawValue: '', formattedText: ''),
          ),
        ];
        rows.add(
          PreparedRow(
            cells: headerCells,
            isGroupHeader: true,
            groupLevel: g.level,
          ),
        );

        _flattenGroupsToRows(g.subGroups, headers, analysis, rows);

        // Subtotal row if enabled
        if (analysis.showSubtotals) {
          final List<PreparedCell> subtotalCells = [];
          for (int i = 0; i < headers.length; i++) {
            final h = headers[i];
            if (i == 0) {
              subtotalCells.add(
                PreparedCell(
                  rawValue: '${g.label} Total',
                  formattedText: '${g.label} Total',
                  alignment: ReportColumnAlignment.left,
                ),
              );
            } else if (i < analysis.groupBy.length) {
              subtotalCells.add(
                const PreparedCell(rawValue: '', formattedText: ''),
              );
            } else {
              final val = g.measureValues[h.id];
              subtotalCells.add(_formatMeasureCell(val, h));
            }
          }
          rows.add(
            PreparedRow(
              cells: subtotalCells,
              isSubtotal: true,
              groupLevel: g.level,
            ),
          );
        }
      }
    }
  }

  List<PreparedCategorySheet> _buildCategorySheets<T>({
    required List<PreparedGroup> groups,
    required List<PreparedColumnHeader> summaryHeaders,
    required ReportAnalysis analysis,
    required ReportDefinition<T> definition,
  }) {
    final List<PreparedCategorySheet> sheets = [];

    // Determine which columns to show in the category sheet detail table
    List<ReportColumn<T>> detailCols = [];
    if (analysis.detailColumns != null && analysis.detailColumns!.isNotEmpty) {
      for (final colId in analysis.detailColumns!) {
        final col = definition.getColumn(colId);
        if (col != null) detailCols.add(col);
      }
    } else {
      detailCols = definition.columns.where((c) => c.isVisible).toList();
    }

    final bool hasDetailCols = detailCols.isNotEmpty;

    final List<PreparedColumnHeader> catHeaders = hasDetailCols
        ? detailCols
              .map(
                (col) => PreparedColumnHeader(
                  id: col.id,
                  title: col.title,
                  fieldType: col.type,
                  alignment: col.alignment,
                  width: col.width,
                  currencyCode: col.currencyCode,
                ),
              )
              .toList()
        : summaryHeaders;

    for (final g in groups) {
      final List<PreparedRow> sheetRows = [];
      final Map<String, num> colSums = {};

      if (hasDetailCols && g.rawRecords.isNotEmpty) {
        for (final rowMap in g.rawRecords) {
          final List<PreparedCell> cells = [];
          for (final col in detailCols) {
            final raw = rowMap[col.id];
            final cell = _formatCell(raw, col);
            cells.add(cell);

            if (raw is num) {
              colSums[col.id] = (colSums[col.id] ?? 0) + raw;
            }
          }
          sheetRows.add(PreparedRow(cells: cells, rawRecord: rowMap));
        }
      } else if (g.subGroups.isNotEmpty) {
        _flattenGroupsToRows(g.subGroups, summaryHeaders, analysis, sheetRows);
      } else {
        final List<PreparedCell> cells = [];
        for (int i = 0; i < summaryHeaders.length; i++) {
          final h = summaryHeaders[i];
          if (i == 0) {
            cells.add(PreparedCell(rawValue: g.label, formattedText: g.label));
          } else {
            final val = g.measureValues[h.id];
            cells.add(_formatMeasureCell(val, h));
          }
        }
        sheetRows.add(PreparedRow(cells: cells));
      }

      PreparedRow? totalsRow;
      if (analysis.showGrandTotal) {
        final List<PreparedCell> totalCells = [];
        if (hasDetailCols && g.rawRecords.isNotEmpty) {
          for (int i = 0; i < detailCols.length; i++) {
            final col = detailCols[i];
            if (i == 0) {
              totalCells.add(
                PreparedCell(
                  rawValue: '${g.label} Total',
                  formattedText: '${g.label} Total',
                  type: PreparedCellType.text,
                  alignment: ReportColumnAlignment.left,
                ),
              );
            } else if (colSums.containsKey(col.id)) {
              final totalNum = colSums[col.id]!;
              totalCells.add(_formatCell(totalNum, col));
            } else {
              totalCells.add(
                const PreparedCell(
                  rawValue: '',
                  formattedText: '',
                  type: PreparedCellType.text,
                ),
              );
            }
          }
        } else {
          for (int i = 0; i < summaryHeaders.length; i++) {
            final h = summaryHeaders[i];
            if (i == 0) {
              totalCells.add(
                PreparedCell(
                  rawValue: '${g.label} Total',
                  formattedText: '${g.label} Total',
                ),
              );
            } else {
              final val = g.measureValues[h.id];
              totalCells.add(_formatMeasureCell(val, h));
            }
          }
        }
        totalsRow = PreparedRow(cells: totalCells, isGrandTotal: true);
      }

      final cleanSheetName = _sanitizeSheetName(g.label);

      sheets.add(
        PreparedCategorySheet(
          categoryKey: g.key,
          categoryLabel: g.label,
          sheetName: cleanSheetName,
          headers: catHeaders,
          rows: sheetRows,
          totalsRow: totalsRow,
        ),
      );
    }

    return sheets;
  }

  // =========================================================================
  // FORMATTING HELPERS
  // =========================================================================

  PreparedCell _formatCell<T>(dynamic val, ReportColumn<T> col) {
    if (val == null) {
      return PreparedCell(
        rawValue: null,
        formattedText: col.nullPlaceholder,
        type: PreparedCellType.text,
        alignment: col.alignment,
      );
    }

    if (col.customFormatter != null) {
      return PreparedCell(
        rawValue: val,
        formattedText: col.customFormatter!(val),
        type: PreparedCellType.text,
        alignment: col.alignment,
      );
    }

    switch (col.type) {
      case ReportFieldType.money:
        final num n = val is num ? val : 0;
        final sym = col.currencyCode ?? '\$';
        final prec = col.precision ?? 2;
        final f = NumberFormat.currency(symbol: '$sym ', decimalDigits: prec);
        return PreparedCell(
          rawValue: n,
          formattedText: f.format(n),
          type: PreparedCellType.money,
          currencyCode: sym,
          alignment: col.alignment,
        );

      case ReportFieldType.percentage:
        final num n = val is num ? val : 0;
        final prec = col.precision ?? 1;
        return PreparedCell(
          rawValue: n,
          formattedText: '${n.toStringAsFixed(prec)}%',
          type: PreparedCellType.percentage,
          alignment: col.alignment,
        );

      case ReportFieldType.number:
        final num n = val is num ? val : 0;
        final f = col.precision != null
            ? NumberFormat.decimalPatternDigits(decimalDigits: col.precision!)
            : NumberFormat.decimalPattern();
        return PreparedCell(
          rawValue: n,
          formattedText: f.format(n),
          type: PreparedCellType.numeric,
          alignment: col.alignment,
        );

      case ReportFieldType.date:
        if (val is DateTime) {
          final f = DateFormat(col.dateFormat ?? 'yyyy-MM-dd');
          return PreparedCell(
            rawValue: val,
            formattedText: f.format(val),
            type: PreparedCellType.date,
            alignment: col.alignment,
          );
        }
        return PreparedCell(
          rawValue: val,
          formattedText: val.toString(),
          alignment: col.alignment,
        );

      case ReportFieldType.dateTime:
        if (val is DateTime) {
          final f = DateFormat(col.dateFormat ?? 'yyyy-MM-dd HH:mm');
          return PreparedCell(
            rawValue: val,
            formattedText: f.format(val),
            type: PreparedCellType.dateTime,
            alignment: col.alignment,
          );
        }
        return PreparedCell(
          rawValue: val,
          formattedText: val.toString(),
          alignment: col.alignment,
        );

      case ReportFieldType.boolean:
        final bool b = val == true;
        return PreparedCell(
          rawValue: b,
          formattedText: b ? 'Yes' : 'No',
          type: PreparedCellType.boolean,
          alignment: col.alignment,
        );

      case ReportFieldType.text:
      case ReportFieldType.custom:
        return PreparedCell(
          rawValue: val,
          formattedText: val.toString(),
          type: PreparedCellType.text,
          alignment: col.alignment,
        );
    }
  }

  PreparedCell _formatMeasureCell(dynamic val, PreparedColumnHeader header) {
    if (val == null) {
      return const PreparedCell(
        rawValue: null,
        formattedText: '-',
        alignment: ReportColumnAlignment.right,
      );
    }

    if (val is num) {
      if (header.fieldType == ReportFieldType.money ||
          header.currencyCode != null) {
        final sym = header.currencyCode ?? '\$';
        final f = NumberFormat.currency(symbol: '$sym ', decimalDigits: 2);
        return PreparedCell(
          rawValue: val,
          formattedText: f.format(val),
          type: PreparedCellType.money,
          currencyCode: sym,
          alignment: ReportColumnAlignment.right,
        );
      } else if (header.fieldType == ReportFieldType.percentage) {
        return PreparedCell(
          rawValue: val,
          formattedText: '${val.toStringAsFixed(1)}%',
          type: PreparedCellType.percentage,
          alignment: ReportColumnAlignment.right,
        );
      } else {
        final f = NumberFormat.decimalPattern();
        return PreparedCell(
          rawValue: val,
          formattedText: f.format(val),
          type: PreparedCellType.numeric,
          alignment: ReportColumnAlignment.right,
        );
      }
    }

    return PreparedCell(
      rawValue: val,
      formattedText: val.toString(),
      alignment: header.alignment,
    );
  }

  int _compareValues(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    if (a is num && b is num) return a.compareTo(b);
    if (a is DateTime && b is DateTime) return a.compareTo(b);
    return a.toString().toLowerCase().compareTo(b.toString().toLowerCase());
  }

  num _round(num value, int precision) {
    final factor = math.pow(10, precision);
    return (value * factor).round() / factor;
  }

  String _sanitizeSheetName(String name) {
    // Excel forbidden characters: \ / ? * [ ] :
    var clean = name.replaceAll(RegExp(r'[\\/?*\[\]:]'), '_').trim();
    if (clean.isEmpty) clean = 'Sheet';
    if (clean.length > 31) clean = clean.substring(0, 31);
    return clean;
  }
}
