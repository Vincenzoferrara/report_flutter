import 'package:flutter/material.dart';
import '../models/report_element.dart';
import '../models/report_template.dart';
import '../schema/data_schema.dart';
import '../schema/field_definition.dart';
import '../core/data_extractor.dart';

/// Motore principale per il rendering e processing dei report
class ReportEngine {
  /// Renderizza un singolo elemento con dati
  static Widget renderElement(
    ReportElement element,
    dynamic data, {
    DataSchema? schema,
    double scale = 1.0,
  }) {
    switch (element.type) {
      case ReportElementType.text:
        return _renderTextElement(element, scale);
      case ReportElementType.dynamicField:
        return _renderDynamicFieldElement(element, data, scale);
      case ReportElementType.barcode:
        return _renderBarcodeElement(element, data, scale);
      case ReportElementType.qrCode:
        return _renderQRCodeElement(element, data, scale);
      case ReportElementType.image:
        return _renderImageElement(element, data, scale);
      case ReportElementType.line:
        return _renderLineElement(element, scale);
      case ReportElementType.rectangle:
        return _renderRectangleElement(element, scale);
      case ReportElementType.circle:
        return _renderCircleElement(element, scale);
      case ReportElementType.checkbox:
        return _renderCheckboxElement(element, data, scale);
      case ReportElementType.textbox:
        return _renderTextboxElement(element, data, scale);
      case ReportElementType.date:
        return _renderDateElement(element, scale);
      case ReportElementType.pageNumber:
        return _renderPageNumberElement(element, scale);
      case ReportElementType.logo:
        return _renderLogoElement(element, scale);
      case ReportElementType.table:
        return _renderTableElement(element, data, scale);
    }
  }

  /// Processa un template con dati e restituisce una lista di widget
  static List<Widget> processTemplate(
    ReportTemplate template,
    List<dynamic> data, {
    DataSchema? schema,
    double scale = 1.0,
    Function(int)? onPageChanged,
  }) {
    final pages = <Widget>[];
    
    for (int i = 0; i < data.length; i++) {
      final pageWidgets = <Widget>[];
      
      for (final element in template.sortedElements) {
        final positionedWidget = Positioned(
          left: element.x * scale,
          top: element.y * scale,
          child: SizedBox(
            width: element.width * scale,
            height: element.height * scale,
            child: renderElement(element, data[i], schema: schema, scale: scale),
          ),
        );
        pageWidgets.add(positionedWidget);
      }
      
      final page = Stack(
        key: ValueKey('page_$i'),
        children: pageWidgets,
      );
      
      pages.add(page);
    }
    
    return pages;
  }

  /// Valida dati contro schema
  static ValidationResult validateData(
    List<dynamic> data,
    DataSchema schema,
  ) {
    return schema.validateList(data);
  }

  /// Estrai valore da dati con fallback
  static dynamic extractValue(dynamic data, String fieldPath, {dynamic defaultValue}) {
    final value = DataExtractor.getValue(data, fieldPath);
    return value ?? defaultValue;
  }

  /// Formatta valore secondo regole
  static String formatValue(dynamic value, {String? format, String? prefix = '', String? suffix = ''}) {
    final formattedValue = DataExtractor.formatValue(value, format: format);
    return '$prefix$formattedValue$suffix';
  }

  // Metodi privati di rendering
  static Widget _renderTextElement(ReportElement element, double scale) {
    final text = element.properties['text'] ?? '';
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 10;
    final fontWeight = _getFontWeight(element.properties['fontWeight']);
    final alignment = _getAlignment(element.properties['alignment']);
    final color = _parseColor(element.properties['color'] ?? '#000000');

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize * scale,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: alignment,
      overflow: TextOverflow.ellipsis,
      maxLines: (element.properties['maxLines'] as num?)?.toInt() ?? 1,
    );
  }

  static Widget _renderDynamicFieldElement(ReportElement element, dynamic data, double scale) {
    final fieldName = element.properties['fieldName'] ?? '';
    final prefix = element.properties['prefix'] ?? '';
    final suffix = element.properties['suffix'] ?? '';
    final format = element.properties['format'];
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 10;
    final fontWeight = _getFontWeight(element.properties['fontWeight']);
    final alignment = _getAlignment(element.properties['alignment']);
    final color = _parseColor(element.properties['color'] ?? '#000000');

    final value = extractValue(data, fieldName);
    final formattedValue = formatValue(value, format: format, prefix: prefix, suffix: suffix);

    return Text(
      formattedValue,
      style: TextStyle(
        fontSize: fontSize * scale,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: alignment,
      overflow: TextOverflow.ellipsis,
      maxLines: (element.properties['maxLines'] as num?)?.toInt() ?? 1,
    );
  }

  static Widget _renderBarcodeElement(ReportElement element, dynamic data, double scale) {
    final fieldName = element.properties['fieldName'] ?? '';
    final showText = element.properties['showText'] ?? true;
    final textSize = (element.properties['textSize'] as num?)?.toDouble() ?? 8;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.qr_code_2,
          size: 20 * scale,
          color: Colors.black,
        ),
        if (showText)
          Text(
            extractValue(data, fieldName)?.toString() ?? '123456789',
            style: TextStyle(
              fontSize: textSize * scale,
            ),
          ),
      ],
    );
  }

  static Widget _renderQRCodeElement(ReportElement element, dynamic data, double scale) {
    return Icon(
      Icons.qr_code,
      size: 20 * scale,
      color: Colors.black,
    );
  }

  static Widget _renderImageElement(ReportElement element, dynamic data, double scale) {
    return Icon(
      Icons.image,
      size: 20 * scale,
      color: Colors.grey,
    );
  }

  static Widget _renderLineElement(ReportElement element, double scale) {
    final strokeWidth = (element.properties['strokeWidth'] as num?)?.toDouble() ?? 1;
    final color = _parseColor(element.properties['color'] ?? '#000000');

    return Container(
      height: strokeWidth * scale,
      color: color,
    );
  }

  static Widget _renderRectangleElement(ReportElement element, double scale) {
    final strokeWidth = (element.properties['strokeWidth'] as num?)?.toDouble() ?? 1;
    final strokeColor = _parseColor(element.properties['strokeColor'] ?? '#000000');
    final fillColor = element.properties['fillColor'];
    final borderRadius = (element.properties['borderRadius'] as num?)?.toDouble() ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: fillColor != null ? _parseColor(fillColor) : null,
        border: Border.all(
          color: strokeColor,
          width: strokeWidth * scale,
        ),
        borderRadius: BorderRadius.circular(borderRadius * scale),
      ),
    );
  }

  static Widget _renderCircleElement(ReportElement element, double scale) {
    final strokeWidth = (element.properties['strokeWidth'] as num?)?.toDouble() ?? 1;
    final strokeColor = _parseColor(element.properties['strokeColor'] ?? '#000000');
    final fillColor = element.properties['fillColor'];

    return Container(
      decoration: BoxDecoration(
        color: fillColor != null ? _parseColor(fillColor) : null,
        border: Border.all(
          color: strokeColor,
          width: strokeWidth * scale,
        ),
        shape: BoxShape.circle,
      ),
    );
  }

  static Widget _renderCheckboxElement(ReportElement element, dynamic data, double scale) {
    final fieldName = element.properties['fieldName'] ?? '';
    final label = element.properties['label'] ?? '';
    final size = (element.properties['size'] as num?)?.toDouble() ?? 12;
    final isChecked = extractValue(data, fieldName) ?? false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isChecked ? Icons.check_box : Icons.check_box_outline_blank,
          size: size * scale,
          color: Colors.black,
        ),
        if (label.isNotEmpty) ...[
          SizedBox(width: 4 * scale),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: size * scale * 0.8,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  static Widget _renderTextboxElement(ReportElement element, dynamic data, double scale) {
    final fieldName = element.properties['fieldName'] ?? '';
    final placeholder = element.properties['placeholder'] ?? '';
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 10;

    final value = extractValue(data, fieldName) ?? placeholder;

    return Container(
      padding: EdgeInsets.all(2 * scale),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(2 * scale),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
          fontSize: fontSize * scale,
          color: Colors.black87,
        ),
      ),
    );
  }

  static Widget _renderDateElement(ReportElement element, double scale) {
    final format = element.properties['format'] ?? 'dd/MM/yyyy';
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 10;
    final color = _parseColor(element.properties['color'] ?? '#000000');

    final now = DateTime.now();
    final formattedDate = formatValue(now, format: format);

    return Text(
      formattedDate,
      style: TextStyle(
        fontSize: fontSize * scale,
        color: color,
      ),
    );
  }

  static Widget _renderPageNumberElement(ReportElement element, double scale) {
    final format = element.properties['format'] ?? 'Pagina {current}';
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 8;
    final color = _parseColor(element.properties['color'] ?? '#666666');

    final text = format.replaceAll('{current}', '1').replaceAll('{total}', '1');

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize * scale,
        color: color,
      ),
    );
  }

  static Widget _renderLogoElement(ReportElement element, double scale) {
    return Icon(
      Icons.business,
      size: 20 * scale,
      color: Colors.grey,
    );
  }

  static Widget _renderTableElement(ReportElement element, dynamic data, double scale) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
      ),
      child: Center(
        child: Text(
          'Tabella',
          style: TextStyle(
            fontSize: 10 * scale,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  static Widget _renderFallbackElement(ReportElement element, double scale) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red),
      ),
      child: Center(
        child: Text(
          'Unknown: ${element.type.name}',
          style: TextStyle(
            fontSize: 8 * scale,
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Helper methods
  static FontWeight? _getFontWeight(String? weight) {
    switch (weight) {
      case 'bold':
        return FontWeight.bold;
      case 'normal':
      default:
        return FontWeight.normal;
    }
  }

  static TextAlign _getAlignment(String? alignment) {
    switch (alignment) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'left':
      default:
        return TextAlign.left;
    }
  }

  static Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}