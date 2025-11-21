import 'package:flutter/material.dart';

/// Tipo di elemento che può essere aggiunto al report
enum ReportElementType {
  // Testo
  text,
  dynamicField,

  // Codici
  barcode,
  qrCode,

  // Grafici
  image,
  line,
  rectangle,
  circle,

  // Tabelle
  table,

  // Controlli form
  checkbox,
  textbox,

  // Speciali
  pageNumber,
  date,
  logo,
}

/// Elemento singolo nel template del report
class ReportElement {
  final String id;
  final ReportElementType type;
  double x; // posizione X in mm
  double y; // posizione Y in mm
  double width; // larghezza in mm
  double height; // altezza in mm
  double rotation; // rotazione in gradi
  int zIndex; // ordine di sovrapposizione
  Map<String, dynamic> properties;

  ReportElement({
    required this.id,
    required this.type,
    this.x = 0,
    this.y = 0,
    this.width = 20,
    this.height = 10,
    this.rotation = 0,
    this.zIndex = 0,
    Map<String, dynamic>? properties,
  }) : properties = properties ?? _defaultProperties(type);

  static Map<String, dynamic> _defaultProperties(ReportElementType type) {
    switch (type) {
      case ReportElementType.text:
        return {
          'text': 'Testo',
          'fontSize': 10.0,
          'fontWeight': 'normal',
          'fontStyle': 'normal',
          'alignment': 'left',
          'color': '#000000',
          'backgroundColor': null,
        };
      case ReportElementType.dynamicField:
        return {
          'fieldName': '', // nome del campo dati (es: 'product.name', 'price', 'sku')
          'fontSize': 10.0,
          'fontWeight': 'normal',
          'alignment': 'left',
          'color': '#000000',
          'prefix': '',
          'suffix': '',
          'format': null, // formato opzionale (es: 'currency', 'date', 'number')
          'maxLines': 1,
        };
      case ReportElementType.barcode:
        return {
          'fieldName': 'sku', // campo da cui prendere il valore
          'barcodeType': 'code128', // code128, ean13, ean8, upc, code39
          'showText': true,
          'textSize': 8.0,
        };
      case ReportElementType.qrCode:
        return {
          'fieldName': '', // campo o template per il contenuto
          'errorCorrection': 'M', // L, M, Q, H
        };
      case ReportElementType.image:
        return {
          'source': 'field', // 'field', 'asset', 'url'
          'fieldName': 'image', // se source è 'field'
          'assetPath': '', // se source è 'asset'
          'url': '', // se source è 'url'
          'fit': 'contain', // contain, cover, fill, fitWidth, fitHeight
        };
      case ReportElementType.line:
        return {
          'strokeWidth': 1.0,
          'color': '#000000',
          'dashPattern': null, // es: [5, 3] per linea tratteggiata
        };
      case ReportElementType.rectangle:
        return {
          'strokeWidth': 1.0,
          'strokeColor': '#000000',
          'fillColor': null,
          'borderRadius': 0.0,
        };
      case ReportElementType.circle:
        return {
          'strokeWidth': 1.0,
          'strokeColor': '#000000',
          'fillColor': null,
        };
      case ReportElementType.table:
        return {
          'columns': [], // lista di definizioni colonne
          'dataSource': '', // nome della lista dati
          'headerStyle': {
            'fontSize': 10.0,
            'fontWeight': 'bold',
            'backgroundColor': '#EEEEEE',
          },
          'cellStyle': {
            'fontSize': 9.0,
            'padding': 2.0,
          },
          'borderWidth': 0.5,
          'borderColor': '#000000',
        };
      case ReportElementType.pageNumber:
        return {
          'format': 'Pagina {current} di {total}',
          'fontSize': 8.0,
          'alignment': 'center',
          'color': '#666666',
        };
      case ReportElementType.date:
        return {
          'format': 'dd/MM/yyyy',
          'fontSize': 8.0,
          'color': '#000000',
        };
      case ReportElementType.logo:
        return {
          'assetPath': '',
          'fit': 'contain',
        };
      case ReportElementType.checkbox:
        return {
          'fieldName': '', // campo booleano da cui prendere il valore
          'label': '',
          'checkedByDefault': false,
          'size': 12.0,
          'color': '#000000',
        };
      case ReportElementType.textbox:
        return {
          'fieldName': '', // campo da cui prendere il valore
          'placeholder': '',
          'fontSize': 10.0,
          'fontWeight': 'normal',
          'alignment': 'left',
          'color': '#000000',
          'backgroundColor': '#FFFFFF',
          'borderColor': '#000000',
          'borderWidth': 1.0,
          'maxLines': 1,
        };
    }
  }

  /// Nome visualizzato per il tipo di elemento
  String get displayName {
    switch (type) {
      case ReportElementType.text:
        return 'Testo';
      case ReportElementType.dynamicField:
        return 'Campo Dinamico';
      case ReportElementType.barcode:
        return 'Barcode';
      case ReportElementType.qrCode:
        return 'QR Code';
      case ReportElementType.image:
        return 'Immagine';
      case ReportElementType.line:
        return 'Linea';
      case ReportElementType.rectangle:
        return 'Rettangolo';
      case ReportElementType.circle:
        return 'Cerchio';
      case ReportElementType.table:
        return 'Tabella';
      case ReportElementType.pageNumber:
        return 'Numero Pagina';
      case ReportElementType.date:
        return 'Data';
      case ReportElementType.logo:
        return 'Logo';
      case ReportElementType.checkbox:
        return 'Checkbox';
      case ReportElementType.textbox:
        return 'Casella Testo';
    }
  }

  /// Icona per il tipo di elemento
  IconData get icon {
    switch (type) {
      case ReportElementType.text:
        return Icons.text_fields;
      case ReportElementType.dynamicField:
        return Icons.data_object;
      case ReportElementType.barcode:
        return Icons.qr_code_2;
      case ReportElementType.qrCode:
        return Icons.qr_code;
      case ReportElementType.image:
        return Icons.image;
      case ReportElementType.line:
        return Icons.horizontal_rule;
      case ReportElementType.rectangle:
        return Icons.rectangle_outlined;
      case ReportElementType.circle:
        return Icons.circle_outlined;
      case ReportElementType.table:
        return Icons.table_chart;
      case ReportElementType.pageNumber:
        return Icons.numbers;
      case ReportElementType.date:
        return Icons.calendar_today;
      case ReportElementType.logo:
        return Icons.business;
      case ReportElementType.checkbox:
        return Icons.check_box;
      case ReportElementType.textbox:
        return Icons.text_snippet;
    }
  }

  ReportElement copyWith({
    String? id,
    ReportElementType? type,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? zIndex,
    Map<String, dynamic>? properties,
  }) {
    return ReportElement(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      properties: properties ?? Map.from(this.properties),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'zIndex': zIndex,
      'properties': properties,
    };
  }

  factory ReportElement.fromJson(Map<String, dynamic> json) {
    return ReportElement(
      id: json['id'],
      type: ReportElementType.values.firstWhere((e) => e.name == json['type']),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      zIndex: json['zIndex'] ?? 0,
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
    );
  }
}
