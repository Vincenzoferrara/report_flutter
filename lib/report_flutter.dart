/// Report Flutter - complete toolkit to design, view and print reports and labels.
library;

// Core - models and base utilities
export 'models/report_element.dart';
export 'models/report_template.dart';
export 'core/data_extractor.dart';
export 'theme/theme.dart';

// Schema - data definition and validation
export 'schema/schema.dart';

// Builder - drag-and-drop template editor
export 'builder/builder.dart';

// Viewer - standalone report viewer
export 'viewer/viewer.dart';

// Engine - rendering and processing engine
export 'engine/engine.dart';

// Formats - .rpt file handling
export 'formats/formats.dart';

// Import - data import from CSV/JSON
export 'import/import.dart';

// Export - PDF export
export 'export/pdf_exporter.dart';

// Print - Templates, paper formats, print center and PDF printing
export 'print/print.dart';

// Translations of the library screens
export 'l10n/report_l10n.dart';
