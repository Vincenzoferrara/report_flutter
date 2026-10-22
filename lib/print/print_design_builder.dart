import '../models/report_element.dart';
import '../models/report_template.dart';

/// A column of a table element.
class PrintColumn {
  final String field;
  final String title;
  final double widthMm;
  final bool alignRight;

  const PrintColumn(
    this.field,
    this.title,
    this.widthMm, {
    this.alignRight = false,
  });

  Map<String, dynamic> toJson() => {
    'field': field,
    'title': title,
    'width': widthMm,
    'align': alignRight ? 'right' : 'left',
  };
}

/// Small builder for designer layouts. Every measure is in millimetres.
class PrintDesign {
  PrintDesign(this.widthMm, this.heightMm);

  final double widthMm;
  final double heightMm;
  final List<ReportElement> _elements = [];

  void _add(
    ReportElementType type,
    double x,
    double y,
    double width,
    double height,
    Map<String, dynamic> properties,
  ) {
    final index = _elements.length;
    _elements.add(
      ReportElement(
        id: 'element_$index',
        type: type,
        x: x,
        y: y,
        width: width,
        height: height,
        zIndex: index,
        // Start from the designer defaults so every property panel finds the
        // keys it expects.
        properties: {
          ...ReportElement(id: 'defaults', type: type).properties,
          ...properties,
        },
      ),
    );
  }

  Map<String, dynamic> _textStyle({
    required double size,
    required bool bold,
    required String color,
    required String align,
    required String verticalAlign,
    required int maxLines,
    required bool strike,
    required bool serif,
  }) => {
    'fontSize': size,
    'fontWeight': bold ? 'bold' : 'normal',
    'color': color,
    'alignment': align,
    'verticalAlignment': verticalAlign,
    'maxLines': maxLines,
    if (strike) 'textDecoration': 'lineThrough',
    if (serif) 'fontFamily': 'serif',
  };

  void text(
    String value,
    double x,
    double y,
    double width,
    double height, {
    required double size,
    bool bold = false,
    String color = '#000000',
    String align = 'left',
    String verticalAlign = 'center',
    int maxLines = 1,
    bool strike = false,
    bool serif = false,
  }) {
    _add(ReportElementType.text, x, y, width, height, {
      'text': value,
      ..._textStyle(
        size: size,
        bold: bold,
        color: color,
        align: align,
        verticalAlign: verticalAlign,
        maxLines: maxLines,
        strike: strike,
        serif: serif,
      ),
    });
  }

  void field(
    String fieldName,
    double x,
    double y,
    double width,
    double height, {
    required double size,
    bool bold = false,
    String color = '#000000',
    String align = 'left',
    String verticalAlign = 'center',
    int maxLines = 1,
    bool strike = false,
    bool serif = false,
    String prefix = '',
    String suffix = '',
  }) {
    _add(ReportElementType.dynamicField, x, y, width, height, {
      'fieldName': fieldName,
      'prefix': prefix,
      'suffix': suffix,
      ..._textStyle(
        size: size,
        bold: bold,
        color: color,
        align: align,
        verticalAlign: verticalAlign,
        maxLines: maxLines,
        strike: strike,
        serif: serif,
      ),
    });
  }

  void barcode(
    String fieldName,
    double x,
    double y,
    double width,
    double height,
  ) {
    _add(ReportElementType.barcode, x, y, width, height, {
      'fieldName': fieldName,
      'barcodeType': 'code128',
      'showText': true,
    });
  }

  void qrCode(
    String fieldName,
    double x,
    double y,
    double width,
    double height,
  ) {
    _add(ReportElementType.qrCode, x, y, width, height, {
      'fieldName': fieldName,
    });
  }

  void rectangle(
    double x,
    double y,
    double width,
    double height, {
    String? fill,
    String stroke = '#000000',
    double strokeWidth = 0.3,
    double radius = 0,
  }) {
    _add(ReportElementType.rectangle, x, y, width, height, {
      'fillColor': fill,
      'strokeColor': stroke,
      'strokeWidth': strokeWidth,
      'borderRadius': radius,
    });
  }

  void line(
    double x,
    double y,
    double width, {
    String color = '#000000',
    double strokeWidth = 0.3,
  }) {
    // The height of a line is its thickness, as in the designer.
    _add(ReportElementType.line, x, y, width, strokeWidth, {
      'color': color,
      'strokeWidth': strokeWidth,
    });
  }

  void table(
    String dataSource,
    double x,
    double y,
    double width,
    double height, {
    required String accent,
    required List<PrintColumn> columns,
  }) {
    _add(ReportElementType.table, x, y, width, height, {
      'dataSource': dataSource,
      'columns': columns.map((column) => column.toJson()).toList(),
      'headerStyle': {
        'fontSize': 3.0,
        'fontWeight': 'bold',
        'backgroundColor': accent,
        'color': '#FFFFFF',
        'alignment': 'left',
        'verticalAlignment': 'center',
      },
      'cellStyle': {
        'fontSize': 3.0,
        'padding': 1.5,
        'alignment': 'left',
        'verticalAlignment': 'center',
        'stripeColor': '#F5F5F5',
      },
      'borderWidth': 0.0,
      'borderColor': '#E0E0E0',
    });
  }

  ReportTemplate build({
    required String id,
    required String name,
    ReportType reportType = ReportType.label,
  }) {
    return ReportTemplate(
      id: id,
      name: name,
      reportType: reportType,
      pageFormat: PageFormat.custom,
      pageWidth: widthMm,
      pageHeight: heightMm,
      marginTop: 0,
      marginBottom: 0,
      marginLeft: 0,
      marginRight: 0,
      itemsPerRow: 1,
      itemsPerColumn: 1,
      horizontalGap: 0,
      verticalGap: 0,
      itemWidth: widthMm,
      itemHeight: heightMm,
      elements: List.of(_elements),
    );
  }
}
