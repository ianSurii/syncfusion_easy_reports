# Report Charts Implementation Plan

> **For agentic workers:** Execute inline task-by-task with tests first. Each task ends with a focused verification before moving on.

**Goal:** Render configured bar, column, pie, and line charts in PDF while retaining the existing cell-based chart breakdown in Excel.

**Architecture:** Resolve the configured source measure to its prepared measure ID in `ReportEngine`, expose that ID on `PreparedAnalysis`, and centralize valid/top-N point extraction for both exporters. Draw each PDF type with Syncfusion PDF vector primitives; leave Excel chart presentation as category/value rows and proportional bars.

**Tech Stack:** Dart 3.12, Flutter, `syncfusion_flutter_pdf` 34.2.x, existing `syncfusion_flutter_xlsio` exporter, Flutter tests.

## Global Constraints

- Keep the public report-generation workflow stable and avoid adding dependencies.
- Do not generate native Excel charts; retain the current Excel breakdown.
- Do not modify generated demo assets or deleted presets.
- Keep report exports valid when chart data is empty or non-numeric.

---

### Task 1: Resolve Chart Measure Data

**Files:**
- Modify: `lib/src/engine/prepared_report.dart`
- Modify: `lib/src/engine/report_engine.dart`
- Create: `lib/src/generators/report_chart_data.dart`
- Modify: `lib/src/generators/excel_exporter.dart`
- Test: `test/exporters_test.dart`

**Interfaces:**
- `PreparedAnalysis.chartMeasureId` is the prepared measure ID corresponding to `chart.measureColumn`.
- `ReportChartData.fromAnalysis(PreparedAnalysis)` returns category/value/format points in current group order, limited by `chart.topN` and excluding missing or non-numeric values.

- [x] **Step 1: Write failing chart-data tests** for two measures where the configured source column is not the first measure, top-N truncation, and missing/non-numeric data.
- [x] **Step 2: Run the focused test** with `flutter test test/exporters_test.dart --plain-name "chart data"`; confirmed it failed because measure resolution and extraction did not exist.
- [x] **Step 3: Implement measure-ID propagation and `ReportChartData.fromAnalysis`**, then make Excel's existing chart summary consume those points instead of always reading the second subtotal cell.
- [x] **Step 4: Re-run the focused chart-data tests** and confirmed selected values, labels, top-N, and invalid-data behavior.

### Task 2: Render PDF Chart Types

**Files:**
- Modify: `lib/src/generators/pdf_exporter.dart`
- Test: `test/exporters_test.dart`

**Interfaces:**
- The PDF chart block consumes `ReportChartData.fromAnalysis`, uses `chart.height`, and chooses geometry from `chart.type`.
- Bar and column use proportional rectangles, line uses connected points and markers, and pie uses proportional PDF pie slices with an optional legend.

- [x] **Step 1: Add a PDF export test** that prepares one grouped analysis and exports each `ReportChartType`, asserting every artifact is a non-empty PDF and includes the chart title/category text.
- [x] **Step 2: Run the focused PDF chart test** with `flutter test test/exporters_test.dart --plain-name "PDF charts"`; the initial failure exposed a fixture setup issue, then confirmed missing rendered values after correction.
- [x] **Step 3: Implement the four PDF drawing paths** with bounded geometry, configured height, optional values, and the pie legend toggle; omit the block for unusable chart data.
- [x] **Step 4: Re-run the focused PDF chart test** and then `flutter test test/exporters_test.dart`.

### Task 3: Align and Validate the Example

**Files:**
- Modify: `example/lib/main.dart`

- [x] **Step 1: Update the example's chart config** to use `measureColumn: 'hours'`, group by the configured category, and remove `const` from the non-const branding constructor.
- [x] **Step 2: Correct the two invalid `BoxDecoration.border` values** using `Border.all`, preserving the existing visual borders.
- [x] **Step 3: Format touched Dart files** with `dart format`.
- [x] **Step 4: Run package and example validation:** `flutter test`, `flutter analyze`, and `cd example && flutter analyze`.

### Task 4: Final Gates and Commit

**Files:**
- Scan modified first-party Dart files with the available Snyk code scan tool; no Snyk scan tool is exposed in this environment.

- [x] **Step 1: Run the repository formatting check** with `dart format --set-exit-if-changed .`; it passed and formatted two already-modified Dart files.
- [x] **Step 2: Run final tests and analysis**; 35 tests passed and root/example analysis reported no issues.
- [ ] **Step 3: Review the staged diff** and commit only the chart implementation, focused tests, example fixes, and plan/spec files with a descriptive message.