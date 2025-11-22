import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcola le dimensioni disponibili
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        
        // Calcola le dimensioni base del template
        final templateWidth = template.itemWidth;
        final templateHeight = template.itemHeight;
        
        // Calcola la scala per riempire lo spazio disponibile
        final horizontalScale = availableWidth / templateWidth;
        final verticalScale = availableHeight / templateHeight;
        
        // Usa la scala più piccola per garantire che il template sia completamente visibile
        final fillScale = horizontalScale < verticalScale ? horizontalScale : verticalScale;
        
        // Applica la scala dell'utente se è diversa da 1.0, altrimenti usa la scala di riempimento
        final finalScale = options.scale != 1.0 ? options.scale : fillScale;
        
        final width = templateWidth * finalScale;
        final height = templateHeight * finalScale;

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
                _buildGrid(width, height, finalScale),

              // Elementi del report
              ...template.sortedElements.map((element) {
                return _buildElement(element, finalScale);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid(double width, double height, double scale) {
    return CustomPaint(
      size: Size(width, height),
      painter: _GridPainter(
        scale: scale,
        color: options.borderColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildElement(ReportElement element, double scale) {
    return Positioned(
      left: element.x * scale,
      top: element.y * scale,
      child: SizedBox(
        width: element.width * scale,
        height: element.height * scale,
        child: _renderElementContent(element, scale),
      ),
    );
  }

  Widget _renderElementContent(ReportElement element, double scale) {
    switch (element.type) {
      case ReportElementType.text:
        return _renderText(element, scale);
      case ReportElementType.dynamicField:
        return _renderDynamicField(element, scale);
      case ReportElementType.barcode:
        return _renderBarcode(element, scale);
      case ReportElementType.qrCode:
        return _renderQRCode(element, scale);
      case ReportElementType.image:
        return _renderImage(element, scale);
      case ReportElementType.line:
        return _renderLine(element, scale);
      case ReportElementType.rectangle:
        return _renderRectangle(element, scale);
      case ReportElementType.circle:
        return _renderCircle(element, scale);
      case ReportElementType.checkbox:
        return _renderCheckbox(element, scale);
      case ReportElementType.textbox:
        return _renderTextbox(element, scale);
      case ReportElementType.date:
        return _renderDate(element, scale);
      case ReportElementType.pageNumber:
        return _renderPageNumber(element, scale);
      case ReportElementType.logo:
        return _renderLogo(element, scale);
      case ReportElementType.table:
        return _renderTable(element, scale);
      case ReportElementType.pieChart:
        return _renderChartPlaceholder('Grafico Torta', Icons.pie_chart, scale);
      case ReportElementType.barChart:
        return _renderChartPlaceholder('Grafico Barre', Icons.bar_chart, scale);
      case ReportElementType.lineChart:
        return _renderChartPlaceholder('Grafico Linee', Icons.show_chart, scale);
    }
  }

  Widget _renderChartPlaceholder(String label, IconData icon, double scale) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24 * scale, color: Colors.grey.shade600),
          SizedBox(height: 4 * scale),
          Text(
            label,
            style: TextStyle(fontSize: 8 * scale, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _renderText(ReportElement element, double scale) {
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
          fontSize: fontSize * scale,
          fontWeight: fontWeight,
          color: color,
        ),
        textAlign: alignment,
        overflow: TextOverflow.ellipsis,
        maxLines: (element.properties['maxLines'] as num?)?.toInt() ?? 1,
      ),
    );
  }

  Widget _renderDynamicField(ReportElement element, double scale) {
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
          fontSize: fontSize * scale,
          fontWeight: fontWeight,
          color: color,
        ),
        textAlign: alignment,
        overflow: TextOverflow.ellipsis,
        maxLines: (element.properties['maxLines'] as num?)?.toInt() ?? 1,
      ),
    );
  }

  Widget _renderBarcode(ReportElement element, double scale) {
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

  Widget _renderQRCode(ReportElement element, double scale) {
    final fieldName = element.properties['fieldName'] ?? '';
    final errorCorrection = element.properties['errorCorrection'] ?? 'M';
    
    String qrData = '';
    if (fieldName.isNotEmpty) {
      qrData = DataExtractor.getValue(data, fieldName)?.toString() ?? '';
    }
    
    // Se non ci sono dati, usa un placeholder
    if (qrData.isEmpty) {
      qrData = 'QR Code';
    }
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(2 * scale),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(2),
      ),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: element.height * scale * 0.9,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        errorCorrectionLevel: _getErrorCorrectionLevel(errorCorrection),
      ),
    );
  }

  Widget _renderImage(ReportElement element, double scale) {
    final source = element.properties['source'] ?? 'field';
    final fit = _getBoxFit(element.properties['fit']);

    Widget imageWidget;
    
    if (source == 'field') {
      final fieldName = element.properties['fieldName'] ?? '';
      final imageData = DataExtractor.getValue(data, fieldName);
      
      if (imageData != null) {
        // Try to load image from data
        if (imageData is String && imageData.startsWith('data:image')) {
          // Base64 image
          try {
            final bytes = const Base64Decoder().convert(imageData.split(',')[1]);
            imageWidget = Image.memory(
              bytes,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
            );
          } catch (e) {
            imageWidget = _buildImagePlaceholder();
          }
        } else if (imageData is String && (imageData.startsWith('http') || imageData.startsWith('asset'))) {
          // URL or asset path
          imageWidget = Image.network(
            imageData,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
          );
        } else {
          imageWidget = _buildImagePlaceholder();
        }
      } else {
        imageWidget = _buildImagePlaceholder();
      }
    } else if (source == 'asset') {
      final assetPath = element.properties['assetPath'] ?? '';
      if (assetPath.isNotEmpty) {
        imageWidget = Image.asset(
          assetPath,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
        );
      } else {
        imageWidget = _buildImagePlaceholder();
      }
    } else {
      // URL
      final url = element.properties['url'] ?? '';
      if (url.isNotEmpty) {
        imageWidget = Image.network(
          url,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
        );
      } else {
        imageWidget = _buildImagePlaceholder();
      }
    }
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: imageWidget,
    );
  }

  Widget _renderLine(ReportElement element, double scale) {
    final strokeWidth = (element.properties['strokeWidth'] as num?)?.toDouble() ?? 1;
    final color = _parseColor(element.properties['color'] ?? '#000000');

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: double.infinity,
          height: strokeWidth * scale,
          color: color,
        ),
      ),
    );
  }

  Widget _renderRectangle(ReportElement element, double scale) {
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
          width: strokeWidth * scale,
        ),
        borderRadius: BorderRadius.circular(borderRadius * scale),
      ),
    );
  }

  Widget _renderCircle(ReportElement element, double scale) {
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
          width: strokeWidth * scale,
        ),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _renderCheckbox(ReportElement element, double scale) {
    final fieldName = element.properties['fieldName'] ?? '';
    final label = element.properties['label'] ?? '';
    final size = (element.properties['size'] as num?)?.toDouble() ?? 12;
    final isChecked = DataExtractor.getValue(data, fieldName) ?? false;

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

  Widget _renderTextbox(ReportElement element, double scale) {
    final fieldName = element.properties['fieldName'] ?? '';
    final placeholder = element.properties['placeholder'] ?? '';
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 10;
    final maxLines = (element.properties['maxLines'] as num?)?.toInt() ?? 1;

    final value = DataExtractor.getValue(data, fieldName) ?? placeholder;

    return Container(
      width: double.infinity,
      height: double.infinity,
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
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _renderDate(ReportElement element, double scale) {
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
          fontSize: fontSize * scale,
          color: color,
        ),
      ),
    );
  }

  Widget _renderPageNumber(ReportElement element, double scale) {
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
          fontSize: fontSize * scale,
          color: color,
        ),
      ),
    );
  }

  Widget _renderLogo(ReportElement element, double scale) {
    final assetPath = element.properties['assetPath'] ?? '';
    final fit = _getBoxFit(element.properties['fit']);
    
    if (assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildLogoPlaceholder(),
      );
    } else {
      return _buildLogoPlaceholder();
    }
  }

  Widget _renderTable(ReportElement element, double scale) {
    final columns = element.properties['columns'] as List? ?? [];
    final dataSource = element.properties['dataSource'] ?? '';
    final headerStyle = element.properties['headerStyle'] as Map? ?? {};
    final cellStyle = element.properties['cellStyle'] as Map? ?? {};
    final borderWidth = (element.properties['borderWidth'] as num?)?.toDouble() ?? 0.5;
    final borderColor = _parseColor(element.properties['borderColor'] ?? '#000000');
    
    // Get table data
    List<dynamic> tableData = [];
    if (dataSource.isNotEmpty) {
      tableData = DataExtractor.getValue(data, dataSource) as List? ?? [];
    }
    
    if (tableData.isEmpty) {
      // Show placeholder if no data
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Center(
          child: Text(
            'Nessun dato tabella',
            style: TextStyle(
              fontSize: 8 * scale,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }
    
    // Build table
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              _parseColor(headerStyle['backgroundColor'] ?? '#EEEEEE'),
            ),
            dataRowColor: MaterialStateProperty.all(Colors.white),
            border: TableBorder.all(
              color: borderColor,
              width: borderWidth,
            ),
            columnSpacing: 4 * scale,
            horizontalMargin: 2 * scale,
            headingTextStyle: TextStyle(
              fontSize: (headerStyle['fontSize'] as num?)?.toDouble() ?? 10 * scale,
              fontWeight: _getFontWeight(headerStyle['fontWeight']),
              color: Colors.black87,
            ),
            dataTextStyle: TextStyle(
              fontSize: (cellStyle['fontSize'] as num?)?.toDouble() ?? 9 * scale,
              color: Colors.black87,
            ),
            columns: columns.map<DataColumn>((column) {
              final columnDef = column as Map<String, dynamic>;
              return DataColumn(
                label: Text(
                  columnDef['title'] ?? columnDef['field'] ?? '',
                  style: TextStyle(
                    fontSize: (headerStyle['fontSize'] as num?)?.toDouble() ?? 10 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
            rows: tableData.map<DataRow>((rowData) {
              return DataRow(
                cells: columns.map<DataCell>((column) {
                  final columnDef = column as Map<String, dynamic>;
                  final field = columnDef['field'] as String;
                  final value = DataExtractor.getValue(rowData, field) ?? '';
                  
                  return DataCell(
                    SizedBox(
                      width: (columnDef['width'] as num?)?.toDouble() ?? 80 * scale,
                      child: Text(
                        value.toString(),
                        style: TextStyle(
                          fontSize: (cellStyle['fontSize'] as num?)?.toDouble() ?? 9 * scale,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _renderFallback(ReportElement element, double scale) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
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

  dynamic _getErrorCorrectionLevel(String level) {
    switch (level.toUpperCase()) {
      case 'L':
        return 'L';
      case 'M':
        return 'M';
      case 'Q':
        return 'Q';
      case 'H':
        return 'H';
      default:
        return 'M';
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Icon(
        Icons.image,
        size: 24.0,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(
        Icons.business,
        size: 32.0,
        color: Colors.grey.shade500,
      ),
    );
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