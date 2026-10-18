import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('showcase displays one-page 10x report scenarios', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const EasyReportsShowcase());
    await tester.pumpAndSettle();

    expect(find.text('syncfusion_easy_reports'), findsOneWidget);
    expect(find.text('Tax Invoice & Remittance'), findsOneWidget);
    expect(find.text('Department Payroll'), findsOneWidget);
    expect(find.text('Executive Sales CrossTab'), findsOneWidget);
    expect(find.text('Accounts Receivable Aging'), findsOneWidget);
    expect(find.text('Clinical Health Audit'), findsOneWidget);
    expect(find.text('Export Excel (.xlsx)'), findsOneWidget);
    expect(find.text('Export PDF (PORTRAIT)'), findsOneWidget);
  });

  testWidgets('all use cases can trigger export successfully without errors', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const EasyReportsShowcase());
    await tester.pumpAndSettle();

    // 1. Export Tax Invoice (Excel & PDF)
    final excelBtn = find.text('Export Excel (.xlsx)');
    expect(excelBtn, findsOneWidget);
    await tester.tap(excelBtn);
    await tester.pumpAndSettle();

    final pdfBtn = find.text('Export PDF (PORTRAIT)');
    expect(pdfBtn, findsOneWidget);
    await tester.tap(pdfBtn);
    await tester.pumpAndSettle();

    // 2. Switch to Department Payroll and Export
    final payrollChip = find.text('Department Payroll');
    await tester.ensureVisible(payrollChip);
    await tester.tap(payrollChip);
    await tester.pumpAndSettle();
    expect(
      find.text('Department Payroll & Statutory Deductions'),
      findsWidgets,
    );

    await tester.tap(find.text('Export Excel (.xlsx)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export PDF (PORTRAIT)'));
    await tester.pumpAndSettle();

    // 3. Switch to Sales CrossTab and Export
    final salesChip = find.text('Executive Sales CrossTab');
    await tester.ensureVisible(salesChip);
    await tester.tap(salesChip);
    await tester.pumpAndSettle();
    expect(find.text('Executive Sales & Quarterly Matrix'), findsWidgets);

    await tester.tap(find.text('Export Excel (.xlsx)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export PDF (PORTRAIT)'));
    await tester.pumpAndSettle();

    // 4. Switch to Aging Valuation and Export
    final agingChip = find.text('Accounts Receivable Aging');
    await tester.ensureVisible(agingChip);
    await tester.tap(agingChip);
    await tester.pumpAndSettle();
    expect(find.text('Accounts Receivable & Aging Valuation'), findsWidgets);

    await tester.tap(find.text('Export Excel (.xlsx)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export PDF (PORTRAIT)'));
    await tester.pumpAndSettle();

    // 5. Switch to Clinical Health Audit and Export
    final clinicalChip = find.text('Clinical Health Audit');
    await tester.ensureVisible(clinicalChip);
    await tester.tap(clinicalChip);
    await tester.pumpAndSettle();
    expect(find.text('Hospital Clinical Audit & Care Register'), findsWidgets);

    await tester.tap(find.text('Export Excel (.xlsx)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export PDF (PORTRAIT)'));
    await tester.pumpAndSettle();
  });
}
