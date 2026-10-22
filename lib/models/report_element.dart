import 'package:flutter/material.dart';

/// Type of element that can be added to the report
enum ReportElementType {
  // Text
  text,
  dynamicField,

  // Codici
  barcode,
  qrCode,

  // Forme
  image,
  line,
  rectangle,
  circle,

  // Tabelle
  table,

  // Grafici
  pieChart,
  barChart,
  lineChart,

  // Form controls
  checkbox,
  textbox,

  // Speciali
  pageNumber,
  date,
  logo,

  formula, // Excel-like calculations
  markdown, // Markdown text
}

/// Single element of the report template
class ReportElement {
  final String id;
  final ReportElementType type;
  double x; // posizione X in mm
  double y; // posizione Y in mm
  double width; // larghezza in mm
  double height; // altezza in mm
  double rotation; // rotazione in gradi
  int zIndex; // stacking order
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
          'text': 'Text',
          'fontSize': 5.0,
          'fontWeight': 'normal',
          'fontStyle': 'normal',
          'alignment': 'center',
          'verticalAlignment': 'center',
          'color': '#000000',
          'backgroundColor': null,
          // Conditional formatting
          'conditionalFormatting': {'enabled': false, 'rules': []},
        };
      case ReportElementType.dynamicField:
        return {
          'fieldName':
              '', // data field name (e.g. 'product.name', 'price', 'sku')
          'fontSize': 5.0,
          'fontWeight': 'normal',
          'alignment': 'center',
          'verticalAlignment': 'center',
          'color': '#000000',
          'prefix': '',
          'suffix': '',
          'format': null, // optional format (e.g. 'currency', 'date', 'number')
          'maxLines': 1,
          // Conditional formatting
          'conditionalFormatting': {'enabled': false, 'rules': []},
          // Markdown support
          'useMarkdown': false,
          'markdownConfig': {
            'enableToc': false,
            'enableCodeHighlighting': true,
            'theme': 'light',
          },
        };
      case ReportElementType.barcode:
        return {
          'fieldName': 'sku', // field that holds the value
          'barcodeType': 'code128', // code128, ean13, ean8, upc, code39
          'showText': true,
          'textSize': 8.0,
        };
      case ReportElementType.qrCode:
        return {
          'fieldName': '', // field or template for the content
          'errorCorrection': 'M', // L, M, Q, H
        };
      case ReportElementType.image:
        return {
          'source': 'field', // 'field', 'asset', 'url', 'conditional'
          'fieldName': 'image', // when source is 'field'
          'assetPath': '', // when source is 'asset'
          'url': '', // when source is 'url'
          'fit': 'contain', // contain, cover, fill, fitWidth, fitHeight
          // Conditional images
          'conditionalImages': [],
          'classImageField': 'image', // class field that holds the image
          'classImageMethod': 'getImage()', // method that returns the image
        };
      case ReportElementType.line:
        return {
          'strokeWidth': 1.0,
          'color': '#000000',
          'dashPattern': null, // e.g. [5, 3] for a dashed line
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
          'columns': [], // list of column definitions
          'dataSource': '', // name of the data list
          'headerStyle': {
            'fontSize': 5.0,
            'fontWeight': 'bold',
            'backgroundColor': '#EEEEEE',
            'alignment': 'center',
            'verticalAlignment': 'center',
          },
          'cellStyle': {
            'fontSize': 5.0,
            'padding': 2.0,
            'alignment': 'center',
            'verticalAlignment': 'center',
          },
          'borderWidth': 0.5,
          'borderColor': '#000000',
        };
      case ReportElementType.pieChart:
        return {
          'dataSource': '', // name of the data list
          'valueField': '', // numeric field of the values
          'labelField': '', // field of the labels
          'showLabels': true,
          'showPercentage': true,
          'showLegend': true,
          'colors': [
            '#FF6384',
            '#36A2EB',
            '#FFCE56',
            '#4BC0C0',
            '#9966FF',
            '#FF9F40',
          ],
          'title': '',
        };
      case ReportElementType.barChart:
        return {
          'dataSource': '', // name of the data list
          'valueField': '', // numeric field of the values
          'labelField': '', // field of the bar labels
          'showValues': true,
          'showGrid': true,
          'horizontal': false, // true for horizontal bars
          'barColor': '#36A2EB',
          'title': '',
          'axisLabelX': '',
          'axisLabelY': '',
        };
      case ReportElementType.lineChart:
        return {
          'dataSource': '', // name of the data list
          'valueField': '', // numeric field of the Y values
          'labelField': '', // field of the X labels
          'showPoints': true,
          'showGrid': true,
          'showArea': false, // fill below the line
          'lineColor': '#FF6384',
          'lineWidth': 2.0,
          'title': '',
          'axisLabelX': '',
          'axisLabelY': '',
        };
      case ReportElementType.pageNumber:
        return {
          'format': 'Page {current} of {total}',
          'fontSize': 5.0,
          'alignment': 'center',
          'verticalAlignment': 'center',
          'color': '#666666',
        };
      case ReportElementType.date:
        return {
          'format': 'dd/MM/yyyy',
          'fontSize': 5.0,
          'alignment': 'center',
          'verticalAlignment': 'center',
          'color': '#000000',
        };
      case ReportElementType.logo:
        return {'assetPath': '', 'fit': 'contain'};
      case ReportElementType.checkbox:
        return {
          'fieldName': '', // boolean field that holds the value
          'label': '',
          'checkedByDefault': false,
          'size': 12.0,
          'color': '#000000',
        };
      case ReportElementType.textbox:
        return {
          'fieldName': '', // field that holds the value
          'placeholder': '',
          'fontSize': 5.0,
          'fontWeight': 'normal',
          'alignment': 'center',
          'verticalAlignment': 'center',
          'color': '#000000',
          'backgroundColor': '#FFFFFF',
          'borderColor': '#000000',
          'borderWidth': 1.0,
          'maxLines': 1,
        };
      case ReportElementType.formula:
        return {
          'formula': '', // Excel-like formula
          'variables': {}, // variable -> data field mapping
          'format': 'number', // 'number', 'currency', 'percentage', 'date'
          'errorValue': '0', // value on error
          'fontSize': 5.0,
          'fontWeight': 'normal',
          'alignment': 'center',
          'verticalAlignment': 'center',
          'color': '#000000',
          // Conditional formatting
          'conditionalFormatting': {'enabled': false, 'rules': []},
        };
      case ReportElementType.markdown:
        return {
          'markdownData': '# Title\n\n**Bold** text',
          'useMarkdown': true,
          'markdownConfig': {
            'enableToc': false,
            'enableCodeHighlighting': true,
            'theme': 'light',
          },
          'fontSize': 5.0,
          'alignment': 'center',
          'verticalAlignment': 'center',
          'color': '#000000',
        };
    }
  }

  /// Display name of the element type
  String get displayName {
    switch (type) {
      case ReportElementType.text:
        return 'Text';
      case ReportElementType.dynamicField:
        return 'Dynamic field';
      case ReportElementType.barcode:
        return 'Barcode';
      case ReportElementType.qrCode:
        return 'QR Code';
      case ReportElementType.image:
        return 'Image';
      case ReportElementType.line:
        return 'Line';
      case ReportElementType.rectangle:
        return 'Rectangle';
      case ReportElementType.circle:
        return 'Circle';
      case ReportElementType.table:
        return 'Table';
      case ReportElementType.pieChart:
        return 'Pie chart';
      case ReportElementType.barChart:
        return 'Bar chart';
      case ReportElementType.lineChart:
        return 'Line chart';
      case ReportElementType.pageNumber:
        return 'Page number';
      case ReportElementType.date:
        return 'Date';
      case ReportElementType.logo:
        return 'Logo';
      case ReportElementType.checkbox:
        return 'Checkbox';
      case ReportElementType.textbox:
        return 'Text box';
      case ReportElementType.formula:
        return 'Formula';
      case ReportElementType.markdown:
        return 'Markdown';
    }
  }

  /// Icon of the element type
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
      case ReportElementType.pieChart:
        return Icons.pie_chart;
      case ReportElementType.barChart:
        return Icons.bar_chart;
      case ReportElementType.lineChart:
        return Icons.show_chart;
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
      case ReportElementType.formula:
        return Icons.functions;
      case ReportElementType.markdown:
        return Icons.code;
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
