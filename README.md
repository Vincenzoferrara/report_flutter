# Report Designer Flutter Library

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

Una libreria Flutter completa per creare e visualizzare report/etichette con interfaccia drag-and-drop.

## ✨ Caratteristiche Principali

### 🎨 **Report Builder**
- **Drag-and-drop interface** per creare template personalizzati
- **Elementi multipli**: testo, barcode, QR code, forme, immagini, tabelle
- **Allineamento automatico** con snap e guide visive
- **Proprietà avanzate** per ogni elemento (font, colori, bordi, etc.)
- **Undo/Redo** integrato con shortcut da tastiera
- **Zoom e pan** per precisione nel posizionamento

### 📊 **Schema Dati**
- **Validazione automatica** dei dati contro schemi definiti
- **Type safety** a runtime
- **Campi required/optional** con regole di validazione
- **Schema registry** per schemi riutilizzabili
- **Supporto per tipi complessi** (nested objects, liste)

### 📄 **Report Viewer**
- **Visualizzatore indipendente** per report già creati
- **Supporto paginazione** per report multi-pagina
- **Zoom interattivo** e pan per navigazione
- **Template da file, asset o oggetto diretto**
- **Opzioni di visualizzazione** personalizzabili

### 💾 **Template Format (.rpt)**
- **Formato JSON standardizzato** e versionato
- **Contiene template, schema e metadati** in un unico file
- **Compatibilità cross-platform**
- **Supporto embedding** di dati di esempio

## 🚀 Quick Start

### Installazione
```yaml
dependencies:
  report_designer: ^1.0.0
```

### Utilizzo Base - Report Builder
```dart
import 'package:report_designer/report_designer.dart';

class MyReportBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReportBuilder(
      template: myTemplate,
      sampleData: productData,
      onTemplateChanged: (template) {
        // Callback quando il template cambia
      },
      onSave: (template) {
        // Callback quando si salva
        saveTemplate(template);
      },
    );
  }
}
```

### Utilizzo Base - Report Viewer
```dart
class MyReportViewer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReportViewer(
      templateAsset: 'assets/templates/product_label.rpt',
      data: productList,
      options: ReportViewerOptions(
        scale: 2.0,
        showGrid: true,
      ),
      enablePagination: true,
    );
  }
}
```

### Schema Dati Personalizzato
```dart
class MyProductSchema extends DataSchema {
  @override
  String get name => 'MyProduct';
  
  @override
  String get displayName => 'Prodotto Personalizzato';
  
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
      displayName: 'Nome',
      type: String,
      isRequired: true,
      validationRules: ['minLength:2', 'maxLength:100'],
    ),
    // ... altri campi
  ];
  
  @override
  Map<String, dynamic> get sampleData => {
    'id': 1,
    'name': 'Prodotto di Esempio',
    // ... altri dati
  };
}
```

## 📦 Struttura del Progetto

```
lib/
├── builder/           # Report Builder (drag-and-drop)
├── viewer/            # Report Viewer (visualizzazione)
├── engine/            # Motore di rendering
├── models/            # Modelli dati (template, elementi)
├── schema/            # Schema validazione dati
├── core/              # Utilità e temi
└── formats/           # Gestione file .rpt
```

## 🎯 Elementi Supportati

| Elemento | Descrizione | Proprietà Principali |
|-----------|-------------|---------------------|
| **Text** | Testo statico | font, alignment, color |
| **DynamicField** | Campo dati dinamico | fieldName, format, prefix/suffix |
| **Barcode** | Codice a barre | type (code128, EAN, etc.), showText |
| **QR Code** | QR Code | errorCorrection, content |
| **Image** | Immagini | source (field/asset/url), fit |
| **Shapes** | Linee, rettangoli, cerchi | stroke, fill, dimensions |
| **Table** | Tabelle dati | columns, dataSource, styling |
| **Controls** | Checkbox, textbox | fieldName, validation |

## 🔧 Esempi Pratici

### Etichette Prodotto
```dart
final productLabel = ReportTemplate(
  id: 'product_label',
  name: 'Etichetta Prodotto',
  itemWidth: 50,
  itemHeight: 30,
  dataSchema: ProductSchema(),
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

### Report Documento
```dart
final documentReport = ReportTemplate(
  id: 'invoice',
  name: 'Fattura',
  reportType: ReportType.document,
  pageWidth: 210,
  pageHeight: 297,
  dataSchema: InvoiceSchema(),
  elements: [
    // Intestazione, tabella articoli, totali, etc.
  ],
);
```

## 🧪 Testing

```bash
flutter test
```

## 📱 Demo App

Il progetto include una demo app completa che mostra:
- **Report Builder** con template di esempio
- **Report Viewer** con diversi template
- **Documentazione** ed esempi integrati

```bash
flutter run
```

## 🤝 Contributi

I contributi sono benvenuti! Per favore:

1. **Forka** il repository
2. **Crea un branch** (`git checkout -b feature/amazing-feature`)
3. **Committa** le modifiche (`git commit -m 'Add amazing feature'`)
4. **Pusha** al branch (`git push origin feature/amazing-feature`)
5. **Apri una Pull Request**

## 📄 Licenza

Questo progetto è licenziato sotto MIT License - vedi il file [LICENSE](LICENSE) per dettagli.

## 🔗 Link Utili

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Report Designer API Reference](docs/api.md) (prossimamente)

---

**Creato con ❤️ per la community Flutter**
