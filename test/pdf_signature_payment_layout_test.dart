import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_easy_reports/syncfusion_easy_reports.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('portrait PDF keeps signatures below payment instructions', () async {
    const paymentDetails = ReportPaymentDetails(
      position: PaymentDetailsPosition.belowSummary,
      bankName: 'Standard Chartered Bank',
      accountName: 'Antigravity Enterprise Solutions Ltd',
      accountNumber: '0108044921000',
      branch: 'Westlands Commercial Hub',
      swiftCode: 'SCBLKENX',
      termsOrNotes: [
        'Net 30 days from date of invoice.',
        'Please quote invoice number as payment reference.',
      ],
    );
    const signatures = [
      ReportSignature(
        title: 'Prepared By',
        name: 'Eleanor Vance',
        date: '2026-10-04',
      ),
      ReportSignature(
        title: 'Checked By',
        name: 'Marcus Brody',
        date: '2026-10-04',
      ),
      ReportSignature(
        title: 'Approved By',
        name: 'Julian Hayes',
        date: '2026-10-05',
      ),
      ReportSignature(
        title: 'Authorized By',
        name: 'Amara Okafor',
        date: '2026-10-05',
      ),
    ];

    final report = EasyReport.fromMaps(
      data: const [
        {'item': 'Consulting', 'amount': 1000.0},
      ],
      title: 'Portrait Remittance Layout',
      paymentDetails: paymentDetails,
      paymentDetailsPosition: PaymentDetailsPosition.belowSummary,
      showSignatures: true,
      signatureLayout: SignatureLayout.vertical,
    );
    final artifact = await report.exportPdf(
      options: const PdfExportOptions(
        pageOrientation: PdfPageOrientation.portrait,
        paymentDetailsPosition: PaymentDetailsPosition.belowSummary,
        showSignatures: true,
        signatureLayout: SignatureLayout.vertical,
        signatures: signatures,
      ),
    );

    final document = PdfDocument(
      inputBytes: Uint8List.fromList(artifact.bytes),
    );
    try {
      final lines = PdfTextExtractor(document).extractTextLines();
      final paymentLines = lines.where(
        (line) =>
            line.text.contains('Payment & Remittance Instructions') ||
            line.text.startsWith('Bank Name:') ||
            line.text.startsWith('Account Name:') ||
            line.text.startsWith('Account No:') ||
            line.text.startsWith('Branch:') ||
            line.text.startsWith('SWIFT / BIC:') ||
            line.text.startsWith('Note:'),
      );
      final signatureLines = lines.where(
        (line) => signatures.any(
          (signature) =>
              line.text.contains(signature.name!) ||
              line.text.contains(signature.title),
        ),
      );

      expect(paymentLines, isNotEmpty);
      expect(
        paymentLines.any(
          (line) => line.text.contains(
            'Please quote invoice number as payment reference.',
          ),
        ),
        isTrue,
      );
      expect(signatureLines, isNotEmpty);

      final paymentBottomByPage = <int, double>{};
      for (final line in paymentLines) {
        paymentBottomByPage.update(
          line.pageIndex,
          (bottom) => bottom > line.bounds.bottom ? bottom : line.bounds.bottom,
          ifAbsent: () => line.bounds.bottom,
        );
      }
      final signatureTopByPage = <int, double>{};
      for (final line in signatureLines) {
        signatureTopByPage.update(
          line.pageIndex,
          (top) => top < line.bounds.top ? top : line.bounds.top,
          ifAbsent: () => line.bounds.top,
        );
      }

      final lastPaymentPage = paymentBottomByPage.keys.reduce(
        (left, right) => left > right ? left : right,
      );
      final firstSignaturePage = signatureTopByPage.keys.reduce(
        (left, right) => left < right ? left : right,
      );
      expect(firstSignaturePage, greaterThanOrEqualTo(lastPaymentPage));
      if (firstSignaturePage == lastPaymentPage) {
        expect(
          signatureTopByPage[firstSignaturePage]!,
          greaterThanOrEqualTo(paymentBottomByPage[lastPaymentPage]!),
        );
      }
    } finally {
      document.dispose();
    }
  });
}
