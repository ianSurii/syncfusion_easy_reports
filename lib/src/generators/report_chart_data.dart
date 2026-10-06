import '../engine/prepared_report.dart';

class ReportChartPoint {
  final String label;
  final num value;

  const ReportChartPoint({required this.label, required this.value});
}

class ReportChartData {
  static List<ReportChartPoint> fromAnalysis(PreparedAnalysis analysis) {
    final chart = analysis.chart;
    final measureId = analysis.chartMeasureId ?? chart?.measureColumn;
    if (chart == null || measureId == null || chart.topN <= 0) return const [];

    final points = <ReportChartPoint>[];
    for (final group in analysis.groups) {
      final value = group.measureValues[measureId];
      if (value is! num || !value.isFinite) continue;

      points.add(ReportChartPoint(label: group.label, value: value));
      if (points.length >= chart.topN) break;
    }
    return points;
  }
}
