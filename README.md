# report_flutter

[![pub package](https://img.shields.io/pub/v/report_flutter.svg?style=for-the-badge)](https://pub.dev/packages/report_flutter)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue?style=for-the-badge)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-report__flutter-181717?style=for-the-badge&logo=github)](https://github.com/Vincenzoferrara/report_flutter)

A Flutter library to design, preview and print reports and labels, with a drag-and-drop designer, paper formats, barcodes, QR codes and PDF export.

Source code and issues: <https://github.com/Vincenzoferrara/report_flutter>

## ✨ Features

### 🎨 Report builder
- **Drag-and-drop designer** to build custom templates
- **Many elements**: text, data fields, barcodes, QR codes, shapes, images, tables, charts
- **Alignment guides** with snapping
- **Per-element properties** (font, colors, borders, conditional formatting, Markdown)
- **Undo/redo** with keyboard shortcuts
- **Zoom and pan** with millimetre rulers

### 📊 Data schema
- **Validation** of the data against a schema
- **Runtime type checks**
- **Required/optional fields** with validation rules
- **Schema registry** for reusable schemas

### 📄 Report viewer
- **Standalone viewer** for existing templates
- **Pagination** for multi-page reports
- **Interactive zoom and pan**
- Templates from a **file, an asset or an object**

### 🖨️ Print system
- **Template library** with categories, stored wherever the app wants (server, database, files)
- **Ready-made paper formats**: adhesive A4 sheets, thermal rolls, A4/A5/A6 pages
- **Print center** with preview, positions already used on each sheet and rows to print
- **PDF printing** with the same millimetre measures as the designer

### 💾 Template format (.rpt)
- **Versioned JSON format**
- Holds the **template, the schema and the metadata** in a single file
- Can embed **sample data**

## 🚀 Getting started

### Installation

```bash
flutter pub add report_flutter
```

or add it to `pubspec.yaml`:

```yaml
dependencies:
  report_flutter: ^1.0.0
```

### Translations

The library screens are available in English and Italian. Add `ReportLocalizations.delegate` to the app delegates; without it the texts are shown in English.

```dart
MaterialApp(
  supportedLocales: ReportLocalizations.supportedLocales,
  localizationsDelegates: const [
    ReportLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: const MyHomePage(),
);
```

### Report builder

```dart
import 'package:report_flutter/report_flutter.dart';

class MyReportBuilder extends StatelessWidget {
  const MyReportBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBuilder(
      template: myTemplate,
      sampleData: productData,
      onTemplateChanged: (template) {
        // Called on every change of the template
      },
      onSave: (template) => saveTemplate(template),
    );
  }
}
```

### Report viewer

```dart
class MyReportViewer extends StatelessWidget {
  const MyReportViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportViewer(
      templateAsset: 'assets/templates/product_label.rpt',
      data: productList,
      options: const ReportViewerOptions(scale: 2.0, showGrid: true),
      enablePagination: true,
    );
  }
}
```

### Custom data schema

```dart
class MyProductSchema extends DataSchema {
  @override
  String get name => 'MyProduct';

  @override
  String get displayName => 'Custom product';

  @override
  String get description => 'Products of the shop';

  @override
  List<FieldDefinition> get fields => [
        FieldDefinition(
          name: 'id',
          displayName: 'ID',
          type: int,
          isRequired: true,
        ),
        FieldDefinition(
          name: 'name',
          displayName: 'Name',
          type: String,
          isRequired: true,
          validationRules: ['minLength:2', 'maxLength:100'],
        ),
      ];

  @override
  Map<String, dynamic> get sampleData => {'id': 1, 'name': 'Sample product'};

  @override
  Map<String, dynamic> get metadata => const {};
}

SchemaRegistry.register('MyProduct', () => MyProductSchema());
```

## 🖨️ Print system (`lib/print/`)

Manages print templates (labels, signs, reports), paper formats and PDF printing. The app only provides where the templates are stored and its own data.

- **`PrintLibrary`**: manages templates, categories and paper formats on a `PrintStore`, an interface the app implements (server, database, files). Every change goes through the store first. `InMemoryPrintStore` keeps everything in memory for demos and tests.
- **`PrintLibraryOptions`**: `loadDefaultPaperFormats` loads the ready-made paper formats once (`PaperFormatDefaults`); with `false` the formats are created by hand. `defaultTemplates` and `defaultCategories` are the ready-made templates and categories of the app.
- **`PrintCenter`**: screen with the Print and Template tabs. Templates have no types: they all live in one screen, grouped by category, and paper formats apply to all of them. It covers new, rename, duplicate, move and delete for templates and categories, paper format management, an always-visible preview, the positions already used on each sheet and the rows to print.
- **`PrintDataProvider`**: what the app says about its data: sample data, the footer of the reports, which templates accept real rows, how to pick new rows, and extra settings in the designer bar (saved in `PrintTemplate.settings`).
- **`PrintJob` / `PrintRow`**: rows with real data (title, subtitle, fixed quantity, fields for the chosen template), passed to the print center with `pendingJob`.
- **`openPrintTemplateDesigner`**: designer page with the paper format (the canvas takes the size of one cell) and the app settings.
- **`PrintPdfRenderer`**: prints the designer elements with the same millimetre measures; text shrinks to fit its box; tables, barcodes, QR codes and shapes are supported. It uses the bundled Noto fonts for the euro sign.
- **`PrintDesign`**: builder of millimetre designs, to create ready-made templates in code.

```dart
final library = PrintLibrary(
  store: MyServerPrintStore(),
  options: PrintLibraryOptions(
    loadDefaultPaperFormats: true,
    defaultTemplates: (context) => myTemplates(context),
  ),
);

PrintCenter(library: library, dataProvider: MyDataProvider());
```

## 📦 Project structure

```
lib/
├── builder/   # Drag-and-drop report builder
├── viewer/    # Report viewer
├── engine/    # Rendering engine
├── models/    # Data models (templates, elements)
├── schema/    # Data schema and validation
├── core/      # Utilities (formulas, conditional formatting, cache)
├── formats/   # .rpt file handling
├── import/    # CSV/JSON import
├── export/    # PDF, CSV and Excel export
├── print/     # Print system
├── theme/     # Theme of the library screens
└── l10n/      # Translations
```

## 🎯 Supported elements

| Element | Description | Main properties |
|---------|-------------|-----------------|
| **Text** | Static text | font, alignment, color |
| **DynamicField** | Data field | fieldName, format |
| **Barcode** | Barcode | barcodeType (code128, EAN, ...), showText |
| **QR Code** | QR code | errorCorrection, content |
| **Image** | Image | source (field/asset/url), fit |
| **Shapes** | Lines, rectangles, circles | stroke, fill, size |
| **Table** | Data table | columns, dataSource |
| **Charts** | Pie, bar and line charts | dataSource, valueField, labelField |
| **Controls** | Checkbox, textbox | fieldName |
| **Formula** | Excel-like calculation | formula, variables, format |
| **Markdown** | Markdown text | content |

## 🔧 Examples

### Product label

```dart
final productLabel = ReportTemplate(
  id: 'product_label',
  name: 'Product label',
  itemWidth: 50,
  itemHeight: 30,
  dataSchema: MyProductSchema(),
  elements: [
    ReportElement(
      id: 'name',
      type: ReportElementType.dynamicField,
      x: 5, y: 5,
      width: 40, height: 8,
      properties: {'fieldName': 'name', 'fontSize': 8},
    ),
    ReportElement(
      id: 'barcode',
      type: ReportElementType.barcode,
      x: 5, y: 15,
      width: 40, height: 10,
      properties: {'fieldName': 'sku', 'barcodeType': 'code128'},
    ),
  ],
);
```

### Document report

```dart
final invoice = ReportTemplate(
  id: 'invoice',
  name: 'Invoice',
  reportType: ReportType.document,
  pageWidth: 210,
  pageHeight: 297,
  dataSchema: InvoiceSchema(),
  elements: [
    // Header, item table, totals, ...
  ],
);
```

## 📱 Example app

The [`example/`](example) folder contains a demo that opens the print center (`PrintCenter`) on an in-memory store, with one example label template, the default paper formats and sample data.

```bash
cd example
flutter run
```

## 🤝 Contributing

Contributions are welcome and are released under the same license as the project (GPL-3.0). Please open an [issue](https://github.com/Vincenzoferrara/report_flutter/issues) or a pull request on [GitHub](https://github.com/Vincenzoferrara/report_flutter):

1. **Fork** the repository
2. **Create a branch** (`git checkout -b feature/my-feature`)
3. **Commit** your changes
4. **Push** the branch (`git push origin feature/my-feature`)
5. **Open a pull request**

## 📄 License

Copyright © 2025-2026 Vincenzo Ferrara

report_flutter is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License version 3, as published by the Free Software Foundation. The full text is in the [LICENSE](LICENSE) file.

It is distributed in the hope that it will be useful, but **without any warranty**, without even the implied warranty of merchantability or fitness for a particular purpose.

An app that uses this library and is distributed must also be released under a GPL-3.0 compatible license.

The Noto Sans and Noto Serif fonts in `assets/fonts/` are distributed under the SIL Open Font License 1.1 (see [`assets/fonts/OFL.txt`](assets/fonts/OFL.txt)).
