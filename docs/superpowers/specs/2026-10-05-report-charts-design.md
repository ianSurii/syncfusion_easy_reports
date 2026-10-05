# Report Charts Design

## Goal

Complete the report chart feature so `ReportChartConfig` produces a chart matching its configured type in PDF exports. Keep the report API and the example aligned, and use the Syncfusion PDF API already present in the package without adding a chart dependency.

## Behavior

- Support distinct bar, column, pie, and line visualizations in PDF for grouped-analysis output.
- Use group labels as categories and the configured `measureColumn` as values. Include at most `topN` groups, preserving the analysis order.
- Honor the configured title, height, and `showValues` in PDF. Honor `showLegend` for pie charts.
- PDF output uses vector graphics. Excel keeps the existing category/value breakdown with proportional cell bars; it does not embed native charts.
- If chart values are unavailable or non-numeric, omit the chart rather than failing the report export. Empty grouped results remain valid.

## Integration

- Keep chart configuration on the existing grouped report analysis path; do not introduce a separate chart-only API.
- Update the example to use the current public API and demonstrate the configured chart in PDF and the existing breakdown in Excel.
- Add focused tests that prepare grouped report data and verify each PDF chart type renders valid output, selects the configured measure, and honors the top-N input.
- Correct example compilation errors encountered in this touched workflow, without changing unrelated report features.

## Non-Goals

- No native Excel charts, charting dependency, interactive charts, or chart previews in the Flutter UI.
- No changes to generated web demo assets, presets, or other pending worktree changes.
- No redesign of report grouping, aggregation, or export layout beyond placing the configured chart.