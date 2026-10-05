# Report Charts Design

## Goal

Complete the report chart feature so `ReportChartConfig` produces a chart matching its configured type in both PDF and Excel exports. Keep the report API and the example aligned, and use the Syncfusion PDF and XLSX APIs already present in the package rather than adding a chart dependency.

## Behavior

- Support distinct bar, column, pie, and line visualizations for grouped-analysis output.
- Use group labels as categories and the configured `measureColumn` as values. Include at most `topN` groups, preserving the analysis order.
- Honor the configured title, height, `showValues`, and `showLegend` where supported by the export format.
- PDF output uses vector graphics. Excel output uses a native chart so users can continue editing it in a spreadsheet.
- If chart values are unavailable or non-numeric, omit the chart rather than failing the report export. Empty grouped results remain valid.

## Integration

- Keep chart configuration on the existing grouped report analysis path; do not introduce a separate chart-only API.
- Update the example to use the current public API and demonstrate the configured chart in PDF and Excel.
- Add focused tests that prepare grouped report data and verify chart exports remain valid for each chart type and honor the top-N input.
- Correct example compilation errors encountered in this touched workflow, without changing unrelated report features.

## Non-Goals

- No charting dependency, interactive charts, or chart previews in the Flutter UI.
- No changes to generated web demo assets, presets, or other pending worktree changes.
- No redesign of report grouping, aggregation, or export layout beyond placing the configured chart.