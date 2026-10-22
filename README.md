[![pub package](https://img.shields.io/pub/v/report_flutter.svg)](https://pub.dev/packages/report_flutter)
[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](https://github.com/Vincenzoferrara/report_flutter/blob/main/LICENSE)

Design, preview and print labels and reports in Flutter: a drag-and-drop
designer, ready-made paper formats, barcodes, QR codes and PDF printing.

- **Platforms:** Android, iOS, Linux, macOS and Windows. Web is not
  supported, because file import and export use `dart:io`.
- **Multilingual:** every screen, designer and viewer included, ships in
  **English** and **Italian** and follows the app locale. See
  [Translations](#translations).
- **License:** GPL-3.0. An app that uses this package and is distributed
  must use a GPL-3.0 compatible license.

![Print preview of a sheet of 24 labels](https://raw.githubusercontent.com/Vincenzoferrara/report_flutter/main/doc/screenshots/preview_sheet.png)

## Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Getting started](#getting-started)
- [Translations](#translations)
- [Usage](#usage)
- [Supported elements](#supported-elements)
- [Additional information](#additional-information)

## Features

- **Print center**: one screen to pick a template, preview it and print
  it, with templates grouped by category.
- **Template designer**: drag-and-drop editor with millimetre rulers,
  alignment guides, snapping, undo/redo, zoom and pan.
- **Paper formats**: adhesive A4 sheets, thermal label rolls and A4, A5
  and A6 pages, plus custom formats.
- **PDF printing**: the PDF uses the same millimetre measures as the
  designer. Text shrinks to fit its box.
- **Barcodes and QR codes**: Code 128, EAN-13, EAN-8, UPC, Code 39 and QR.
- **Your storage**: templates are saved through a `PrintStore` that you
  implement (server, database, files).
- **Data schema**: validate the data of a report against typed fields.
- **Report viewer**: show reports with pagination, zoom and pan.
- **Import and export**: CSV and JSON import; PDF, CSV and Excel export.
- **Template files**: a versioned `.rpt` JSON format that holds the
  template, its schema and its metadata.

## Screenshots

All screenshots come from the
[example app](https://github.com/Vincenzoferrara/report_flutter/tree/main/example).

### Print

Pick a template from the print center:

![Print center with the templates grouped by category](https://raw.githubusercontent.com/Vincenzoferrara/report_flutter/main/doc/screenshots/print_center.png)

Choose how many copies to print and preview the whole sheet:

![Print preview of a sheet of 24 labels](https://raw.githubusercontent.com/Vincenzoferrara/report_flutter/main/doc/screenshots/preview_sheet.png)

Or preview one label at full size:

![Print preview of a single label](https://raw.githubusercontent.com/Vincenzoferrara/report_flutter/main/doc/screenshots/preview_label.png)

Pick the paper format:

![Paper format choice in the print screen](https://raw.githubusercontent.com/Vincenzoferrara/report_flutter/main/doc/screenshots/paper_choice.png)

### Templates

Manage templates, categories and paper formats:

![Templates tab with the template list](https://raw.githubusercontent.com/Vincenzoferrara/report_flutter/main/doc/screenshots/templates.png)

Edit, rename, duplicate, move or delete a template:

![Template menu with edit, rename, duplicate, move and delete](https://raw.githubusercontent.com/Vincenzoferrara/report_flutter/main/doc/screenshots/template_menu.png)

Create a template:

![New template dialog with name, category and paper format](https://raw.githubusercontent.com/Vincenzoferrara/report_flutter/main/doc/screenshots/new_template.png)

### Designer

Drag elements on a canvas with millimetre rulers:

![Template designer with the element palette and the canvas](https://raw.githubusercontent.com/Vincenzoferrara/report_flutter/main/doc/screenshots/designer.png)

Select an element to change its properties:

![Properties panel of a selected data field](https://raw.githubusercontent.com/Vincenzoferrara/report_flutter/main/doc/screenshots/designer_properties.png)

Check the result with sample data in the report viewer:

![Report viewer with filters, parameters and pages](https://raw.githubusercontent.com/Vincenzoferrara/report_flutter/main/doc/screenshots/report_viewer.png)

### Paper formats

Use the ready-made sheets and rolls:

![Paper formats page with adhesive A4 sheets](https://raw.githubusercontent.com/Vincenzoferrara/report_flutter/main/doc/screenshots/paper_formats.png)

Or create your own format:

![New paper format dialog with sizes, columns, rows and margins](https://raw.githubusercontent.com/Vincenzoferrara/report_flutter/main/doc/screenshots/new_paper_format.png)

## Getting started

Add the package:

```bash
flutter pub add report_flutter
```

Import it:

```dart
import 'package:report_flutter/report_flutter.dart';
```

## Translations

The library is multilingual. It ships these languages:

| Language | Locale |
|----------|--------|
| English  | `en`   |
| Italian  | `it`   |

Register `ReportLocalizations.delegate` in your app. The library screens
then follow the app locale. Without the delegate, they are in English.

```dart
MaterialApp(
  supportedLocales: ReportLocalizations.supportedLocales,
  localizationsDelegates: const [
    ReportLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: const HomePage(),
);
```

To force one language, set `locale`, for example `const Locale('en')`.

To add a language, copy `lib/l10n/report_en.arb` to a new file such as
`report_de.arb`, translate it and open a pull request.

## Usage

### Print center

The print center is the main entry point. Give it a `PrintLibrary`, which
stores the templates, and a `PrintDataProvider`, which describes your data.

```dart
final library = PrintLibrary(
  store: InMemoryPrintStore(), // or your own PrintStore
  options: PrintLibraryOptions(
    loadDefaultPaperFormats: true,
    defaultCategories: (_) => const [
      PrintCategory(id: 'labels', name: 'Labels', position: 0),
    ],
  ),
);

class ProductDataProvider extends PrintDataProvider {
  const ProductDataProvider();

  @override
  Map<String, dynamic> sampleData(
    BuildContext context,
    PrintTemplate template,
  ) => const {
    'name': 'Basic cotton T-shirt',
    'price': '€ 29.90',
    'code': '8001234567890',
  };
}

PrintCenter(library: library, dataProvider: const ProductDataProvider());
```

The main classes of the print system:

| Class | Role |
|-------|------|
| `PrintLibrary` | Templates, categories and paper formats on a `PrintStore`. |
| `PrintStore` | Storage you implement. `InMemoryPrintStore` is for demos. |
| `PrintCenter` | Print and Templates tabs, preview and print. |
| `PrintDataProvider` | Sample data, rows to print, designer settings. |
| `PrintJob`, `PrintRow` | Real rows to print, passed as `pendingJob`. |
| `PrintDesign` | Builds millimetre designs in code. |
| `PrintPdfRenderer` | Renders templates to PDF. |

### Templates in code

`PrintDesign` builds a template with measures in millimetres:

```dart
final design = PrintDesign(70, 37)
  ..field('name', 2.5, 2.5, 65, 5.5, size: 3.2, bold: true)
  ..field('price', 2.5, 24, 33, 10, size: 5.6, bold: true)
  ..barcode('code', 37, 21, 30.5, 13.5);

final template = PrintTemplate(
  id: 'price_label',
  name: 'Price label',
  categoryId: 'labels',
  paperFormatId: 'a4_3x8',
  design: design.build(id: 'price_label', name: 'Price label'),
);
```

### Report builder and viewer

`ReportBuilder` is the drag-and-drop editor of a `ReportTemplate`.
`ReportViewer` shows a template filled with data.

```dart
ReportBuilder(
  template: myTemplate,
  sampleData: product,
  onSave: (template) => saveTemplate(template),
);

ReportViewer(
  templateAsset: 'assets/templates/product_label.rpt',
  data: products,
  options: const ReportViewerOptions(scale: 2.0, showGrid: true),
);
```

### Data schema

A `DataSchema` lists the fields of your data and validates them:

```dart
class ProductSchema extends DataSchema {
  @override
  String get name => 'Product';

  @override
  String get displayName => 'Product';

  @override
  String get description => 'Products of the shop';

  @override
  List<FieldDefinition> get fields => [
    FieldDefinition(
      name: 'name',
      displayName: 'Name',
      type: String,
      isRequired: true,
      validationRules: ['minLength:2', 'maxLength:100'],
    ),
  ];

  @override
  Map<String, dynamic> get sampleData => {'name': 'Sample product'};

  @override
  Map<String, dynamic> get metadata => const {};
}

SchemaRegistry.register('Product', () => ProductSchema());
```

## Supported elements

| Element | Description | Main properties |
|---------|-------------|-----------------|
| Text | Static text | font, alignment, color |
| Dynamic field | Value from the data | `fieldName`, `format` |
| Barcode | Code 128, EAN, UPC, Code 39 | `barcodeType`, `showText` |
| QR code | QR code | `errorCorrection` |
| Image | Image from a field, asset or URL | `source`, `fit` |
| Shapes | Line, rectangle, circle | stroke, fill |
| Table | Data table | `columns`, `dataSource` |
| Charts | Pie, bar and line charts | `valueField`, `labelField` |
| Controls | Checkbox, text box | `fieldName` |
| Formula | Excel-like calculation | `formula`, `variables` |
| Markdown | Markdown text | content |

## Additional information

- **Example:** the
  [example app](https://github.com/Vincenzoferrara/report_flutter/tree/main/example)
  opens the print center with a demo label template.
- **Issues and ideas:**
  [GitHub issues](https://github.com/Vincenzoferrara/report_flutter/issues).
- **Contributing:** pull requests are welcome, including new translations.
  Contributions are released under GPL-3.0.
- **Changelog:**
  [CHANGELOG.md](https://github.com/Vincenzoferrara/report_flutter/blob/main/CHANGELOG.md).

### License

Copyright © 2025-2026 Vincenzo Ferrara.

This package is free software under the
[GNU General Public License v3.0](https://github.com/Vincenzoferrara/report_flutter/blob/main/LICENSE).
It comes with no warranty.

The bundled Noto Sans and Noto Serif fonts use the
[SIL Open Font License 1.1](https://github.com/Vincenzoferrara/report_flutter/blob/main/assets/fonts/OFL.txt).
