// Export Model-Driven Reporting Engine & Definitions
export 'src/engine/report_definition.dart';
export 'src/engine/report_column.dart';
export 'src/engine/report_measure.dart';
export 'src/engine/report_analysis.dart';
export 'src/engine/report_options.dart';
export 'src/engine/report_artifact.dart';
export 'src/engine/prepared_report.dart';
export 'src/engine/report_engine.dart';
export 'src/engine/dynamic_report.dart';

// Export Classic Configuration Models (Backwards-Compatible)
export 'src/models/report_models.dart';

// Export Generators & Exporters
export 'src/generators/excel_generator.dart';
export 'src/generators/pdf_generator.dart';
export 'src/generators/excel_exporter.dart';
export 'src/generators/pdf_exporter.dart';

// Export Savers & Platform Downloaders
export 'src/downloader/downloader.dart';
export 'src/saver/report_saver.dart';

// Export Template & Import Services
export 'src/services/excel_template_service.dart';

// Export Utilities
export 'src/utils/text_utils.dart';

// Re-export PDF orientation for convenient report styling
export 'package:syncfusion_flutter_pdf/pdf.dart' show PdfPageOrientation;
