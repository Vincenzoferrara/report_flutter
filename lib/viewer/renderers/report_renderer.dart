import 'package:flutter/material.dart';
import '../../models/report_element.dart';
import '../../models/report_template.dart';
import '../../schema/data_schema.dart';
import '../../core/data_extractor.dart';

/// Opzioni per il visualizzatore report
class ReportViewerOptions {
  final double scale;
  final bool showGrid;
  final bool showBorders;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final bool enableZoom;
  final bool enablePan;
  final EdgeInsets padding;

  const ReportViewerOptions({
    this.scale = 1.0,
    this.showGrid = false,
    this.showBorders = true,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.grey,
    this.borderWidth = 1.0,
    this.enableZoom = true,
    this.enablePan = true,
    this.padding = const EdgeInsets.all(8.0),
  });

  ReportViewerOptions copyWith({
    double? scale,
    bool? showGrid,
    bool? showBorders,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    bool? enableZoom,
    bool? enablePan,
    EdgeInsets? padding,
  }) {
    return ReportViewerOptions(
      scale: scale ?? this.scale,
      showGrid: showGrid ?? this.showGrid,
      showBorders: showBorders ?? this.showBorders,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      enableZoom: enableZoom ?? this.enableZoom,
      enablePan: enablePan ?? this.enablePan,
      padding: padding ?? this.padding,
    );
  }
}

/// Renderer per report singolo
class ReportRenderer extends StatelessWidget {
  final ReportTemplate template;
  final dynamic data;
  final DataSchema? schema;
  final ReportViewerOptions options;

  const ReportRenderer({
    super.key,
    required this.template,
    this.data,
    this.schema,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final width = template.itemWidth * options.scale;
    final height = template.itemHeight * options.scale;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: options.backgroundColor,
        border: options.showBorders
            ? Border.all(
                color: options.borderColor,
                width: options.borderWidth,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Griglia di sfondo se richiesta
          if (options.showGrid)
            _buildGrid(width, height),

          // Elementi del report
          ...template.sortedElements.map((element) {
            return _buildElement(element);
          }),
        ],
      ),
    );
  }

  Widget _buildGrid(double width, double height) {
    return CustomPaint(
      size: Size(width, height),
      painter: _GridPainter(
        scale: options.scale,
        color: options.borderColor.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildElement(ReportElement element) {
    return Positioned(
      left: element.x * options.scale,
      top: element.y * options.scale,
      child: SizedBox(
        width: element.width * options.scale,
        height: element.height * options.scale,
        child: _renderElementContent(element),
      ),
    );
  }

  Widget _renderElementContent(ReportElement element) {
    switch (element.type) {
      case ReportElementType.text:
        return _renderText(element);
      case ReportElementType.dynamicField:
        return _renderDynamicField(element);
      case ReportElementType.barcode:
        return _renderBarcode(element);
      case ReportElementType.qrCode:
        return _renderQRCode(element);
      case ReportElementType.image:
        return _renderImage(element);
      case ReportElementType.line:
        return _renderLine(element);
      case ReportElementType.rectangle:
        return _renderRectangle(element);
      case ReportElementType.circle:
        return _renderCircle(element);
      case ReportElementType.checkbox:
        return _renderCheckbox(element);
      case ReportElementType.textbox:
        return _renderTextbox(element);
      case ReportElementType.date:
        return _renderDate(element);
      case ReportElementType.pageNumber:
        return _renderPageNumber(element);
      case ReportElementType.logo:
        return _renderLogo(element);
      case ReportElementType.table:
        return _renderTable(element);
    }
  }

  Widget _renderText(ReportElement element) {
    final text = element.properties['text'] ?? '';
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 10;
    final fontWeight = _getFontWeight(element.properties['fontWeight']);
    final alignment = _getAlignment(element.properties['alignment']);
    final color = _parseColor(element.properties['color'] ?? '#000000');
    final backgroundColor = element.properties['backgroundColor'];

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor != null ? _parseColor(backgroundColor) : null,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize * options.scale,
          fontWeight: fontWeight,
          color: color,
        ),
        textAlign: alignment,
        overflow: TextOverflow.ellipsis,
        maxLines: (element.properties['maxLines'] as num?)?.toInt() ?? 1,
      ),
    );
  }

  Widget _renderDynamicField(ReportElement element) {
    final fieldName = element.properties['fieldName'] ?? '';
    final prefix = element.properties['prefix'] ?? '';
    final suffix = element.properties['suffix'] ?? '';
    final format = element.properties['format'];
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 10;
    final fontWeight = _getFontWeight(element.properties['fontWeight']);
    final alignment = _getAlignment(element.properties['alignment']);
    final color = _parseColor(element.properties['color'] ?? '#000000');

    // Estrai valore dai dati
    final value = DataExtractor.getValue(data, fieldName);
    final formattedValue = DataExtractor.formatValue(value, format: format);
    final displayText = '$prefix$formattedValue$suffix';

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: fontSize * options.scale,
          fontWeight: fontWeight,
          color: color,
        ),
        textAlign: alignment,
        overflow: TextOverflow.ellipsis,
        maxLines: (element.properties['maxLines'] as num?)?.toInt() ?? 1,
      ),
    );
  }

  Widget _renderBarcode(ReportElement element) {
    final fieldName = element.properties['fieldName'] ?? '';
    final showText = element.properties['showText'] ?? true;
    final textSize = (element.properties['textSize'] as num?)?.toDouble() ?? 8;

    // Per ora renderizza come placeholder
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final iconSize = showText && fieldName.isNotEmpty 
              ? constraints.maxHeight * 0.7 
              : constraints.maxHeight * 0.9;
          final fontSize = constraints.maxHeight * 0.2;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Icon(
                  Icons.qr_code_2,
                  size: iconSize,
                  color: Colors.black,
                ),
              ),
              if (showText && fieldName.isNotEmpty)
                SizedBox(height: constraints.maxHeight * 0.02),
              if (showText && fieldName.isNotEmpty)
                Flexible(
                  child: Text(
                    DataExtractor.getValue(data, fieldName)?.toString() ?? '123456789',
                    style: TextStyle(
                      fontSize: fontSize.clamp(4.0, 10.0),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _renderQRCode(ReportElement element) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Icon(
        Icons.qr_code,
        size: element.height * options.scale * 0.8,
        color: Colors.black,
      ),
    );
  }

  Widget _renderImage(ReportElement element) {
    final source = element.properties['source'] ?? 'field';
    final fit = _getBoxFit(element.properties['fit']);

    if (source == 'field') {
      final fieldName = element.properties['fieldName'] ?? '';
      final imageData = DataExtractor.getValue(data, fieldName);
      
      // Per ora placeholder
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Icon(
          Icons.image,
          size: element.height * options.scale * 0.5,
          color: Colors.grey.shade600,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Icon(
        Icons.image,
        size: element.height * options.scale * 0.5,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _renderLine(ReportElement element) {
    final strokeWidth = (element.properties['strokeWidth'] as num?)?.toDouble() ?? 1;
    final color = _parseColor(element.properties['color'] ?? '#000000');

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: double.infinity,
          height: strokeWidth * options.scale,
          color: color,
        ),
      ),
    );
  }

  Widget _renderRectangle(ReportElement element) {
    final strokeWidth = (element.properties['strokeWidth'] as num?)?.toDouble() ?? 1;
    final strokeColor = _parseColor(element.properties['strokeColor'] ?? '#000000');
    final fillColor = element.properties['fillColor'];
    final borderRadius = (element.properties['borderRadius'] as num?)?.toDouble() ?? 0;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: fillColor != null ? _parseColor(fillColor) : null,
        border: Border.all(
          color: strokeColor,
          width: strokeWidth * options.scale,
        ),
        borderRadius: BorderRadius.circular(borderRadius * options.scale),
      ),
    );
  }

  Widget _renderCircle(ReportElement element) {
    final strokeWidth = (element.properties['strokeWidth'] as num?)?.toDouble() ?? 1;
    final strokeColor = _parseColor(element.properties['strokeColor'] ?? '#000000');
    final fillColor = element.properties['fillColor'];

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: fillColor != null ? _parseColor(fillColor) : null,
        border: Border.all(
          color: strokeColor,
          width: strokeWidth * options.scale,
        ),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _renderCheckbox(ReportElement element) {
    final fieldName = element.properties['fieldName'] ?? '';
    final label = element.properties['label'] ?? '';
    final size = (element.properties['size'] as num?)?.toDouble() ?? 12;
    final isChecked = DataExtractor.getValue(data, fieldName) ?? false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isChecked ? Icons.check_box : Icons.check_box_outline_blank,
          size: size * options.scale,
          color: Colors.black,
        ),
        if (label.isNotEmpty) ...[
          SizedBox(width: 4 * options.scale),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: size * options.scale * 0.8,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _renderTextbox(ReportElement element) {
    final fieldName = element.properties['fieldName'] ?? '';
    final placeholder = element.properties['placeholder'] ?? '';
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 10;
    final maxLines = (element.properties['maxLines'] as num?)?.toInt() ?? 1;

    final value = DataExtractor.getValue(data, fieldName) ?? placeholder;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(2 * options.scale),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(2 * options.scale),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
          fontSize: fontSize * options.scale,
          color: Colors.black87,
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _renderDate(ReportElement element) {
    final format = element.properties['format'] ?? 'dd/MM/yyyy';
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 10;
    final color = _parseColor(element.properties['color'] ?? '#000000');

    final now = DateTime.now();
    final formattedDate = DataExtractor.formatValue(now, format: format);

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Text(
        formattedDate,
        style: TextStyle(
          fontSize: fontSize * options.scale,
          color: color,
        ),
      ),
    );
  }

  Widget _renderPageNumber(ReportElement element) {
    final format = element.properties['format'] ?? 'Pagina {current}';
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 8;
    final color = _parseColor(element.properties['color'] ?? '#666666');

    // Per ora usa placeholder
    final text = format.replaceAll('{current}', '1').replaceAll('{total}', '1');

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize * options.scale,
          color: color,
        ),
      ),
    );
  }

  Widget _renderLogo(ReportElement element) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Icon(
        Icons.business,
        size: element.height * options.scale * 0.5,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _renderTable(ReportElement element) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
      ),
      child: Center(
        child: Text(
          'Tabella',
          style: TextStyle(
            fontSize: 10 * options.scale,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _renderFallback(ReportElement element) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red),
      ),
      child: Center(
        child: Text(
          'Unknown: ${element.type.name}',
          style: TextStyle(
            fontSize: 8 * options.scale,
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Helper methods
  FontWeight? _getFontWeight(String? weight) {
    switch (weight) {
      case 'bold':
        return FontWeight.bold;
      case 'normal':
      default:
        return FontWeight.normal;
    }
  }

  TextAlign _getAlignment(String? alignment) {
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

  BoxFit _getBoxFit(String? fit) {
    switch (fit) {
      case 'cover':
        return BoxFit.cover;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'contain':
      default:
        return BoxFit.contain;
    }
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

/// Painter per la griglia di sfondo
class _GridPainter extends CustomPainter {
  final double scale;
  final Color color;

  _GridPainter({required this.scale, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    // Griglia ogni 5mm
    final gridSpacing = 5 * scale;

    for (double x = 0; x <= size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}