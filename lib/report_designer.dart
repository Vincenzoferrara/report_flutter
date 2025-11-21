/// Report Designer - Sistema completo per creare e visualizzare report/etichette
library report_designer;

// Core - Modelli e utilità base
export 'models/report_element.dart';
export 'models/report_template.dart';
export 'core/data_extractor.dart';
export 'core/report_theme.dart';

// Schema - Definizione e validazione dati
export 'schema/schema.dart';

// Builder - Editor drag-and-drop per template
export 'builder/builder.dart';

// Viewer - Visualizzatore indipendente di report
export 'viewer/viewer.dart';

// Engine - Motore di rendering e processing
export 'engine/engine.dart';

// Formats - Gestione file .rpt
export 'formats/formats.dart';
