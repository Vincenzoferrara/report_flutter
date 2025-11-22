import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/report_template.dart';
import '../models/report_element.dart';
import '../core/data_extractor.dart';

/// Servizio per esportare report in PDF
class PdfExporter {
  /// Esporta un template con dati in PDF
  static Future<void> exportToPdf({
    required ReportTemplate template,
    required List<dynamic> data,
    required String filePath,
    PdfExportOptions options = const PdfExportOptions(),
  }) async {
    final pdf = pw.Document();
    
    // Configura il template PDF
    final pageFormat = _getPageFormat(template);
    
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      
      if (template.reportType == ReportType.label) {
        // Etichette multiple per pagina
        await _addLabelsPage(pdf, template, item, pageFormat, options);
      } else {
        // Documento singolo
        await _addDocumentPage(pdf, template, item, pageFormat, options);
      }
    }
    
    // Salva il file
    final file = File(filePath);
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);
  }
  
  /// Mostra anteprima di stampa
  static Future<void> showPrintPreview({
    required ReportTemplate template,
    required List<dynamic> data,
    PdfExportOptions options = const PdfExportOptions(),
  }) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();
        final pageFormat = _getPageFormat(template);
        
        for (int i = 0; i < data.length; i++) {
          final item = data[i];
          
          if (template.reportType == ReportType.label) {
            await _addLabelsPage(pdf, template, item, pageFormat, options);
          } else {
            await _addDocumentPage(pdf, template, item, pageFormat, options);
          }
        }
        
        return await pdf.save();
      },
      name: '${template.name}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
  
  /// Genera PDF bytes
  static Future<Uint8List> _generatePdf(
    ReportTemplate template,
    List<dynamic> data,
    PdfExportOptions options,
  ) async {
    final pdf = pw.Document();
    final pageFormat = _getPageFormat(template);
    
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      
      if (template.reportType == ReportType.label) {
        await _addLabelsPage(pdf, template, item, pageFormat, options);
      } else {
        await _addDocumentPage(pdf, template, item, pageFormat, options);
      }
    }
    
    return await pdf.save();
  }
  
  /// Aggiunge pagina con etichette multiple
  static Future<void> _addLabelsPage(
    pw.Document pdf,
    ReportTemplate template,
    dynamic data,
    PdfPageFormat pageFormat,
    PdfExportOptions options,
  ) async {
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(
          template.marginLeft * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Wrap(
            spacing: template.horizontalGap * PdfPageFormat.mm,
            runSpacing: template.verticalGap * PdfPageFormat.mm,
            children: List.generate(
              template.itemsPerRow * template.itemsPerColumn,
              (index) => pw.Container(
                width: template.itemWidth * PdfPageFormat.mm,
                height: template.itemHeight * PdfPageFormat.mm,
                decoration: pw.BoxDecoration(
                  border: options.showBorders 
                    ? pw.Border.all(color: PdfColors.grey300, width: 0.5)
                    : null,
                ),
                child: pw.Stack(
                  children: template.sortedElements.map((element) {
                    return _buildPdfElement(element, data, options);
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// Aggiunge pagina documento singolo
  static Future<void> _addDocumentPage(
    pw.Document pdf,
    ReportTemplate template,
    dynamic data,
    PdfPageFormat pageFormat,
    PdfExportOptions options,
  ) async {
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(
          template.marginLeft * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Container(
            width: template.pageWidth * PdfPageFormat.mm,
            height: template.pageHeight * PdfPageFormat.mm,
            child: pw.Stack(
              children: template.sortedElements.map((element) {
                return _buildPdfElement(element, data, options);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
  
  /// Costruisce un elemento PDF
  static pw.Widget _buildPdfElement(
    ReportElement element,
    dynamic data,
    PdfExportOptions options,
  ) {
    final left = element.x * PdfPageFormat.mm;
    final top = element.y * PdfPageFormat.mm;
    final width = element.width * PdfPageFormat.mm;
    final height = element.height * PdfPageFormat.mm;
    
    return pw.Positioned(
      left: left,
      top: top,
      child: pw.Container(
        width: width,
        height: height,
        child: _buildPdfContent(element, data, options),
      ),
    );
  }
  
  /// Costruisce il contenuto PDF di un elemento
  static pw.Widget _buildPdfContent(
    ReportElement element,
    dynamic data,
    PdfExportOptions options,
  ) {
    switch (element.type) {
      case ReportElementType.text:
        return _buildPdfText(element);
      case ReportElementType.dynamicField:
        return _buildPdfDynamicField(element, data);
      case ReportElementType.barcode:
        return _buildPdfBarcode(element, data);
      case ReportElementType.qrCode:
        return _buildPdfQRCode(element, data);
      case ReportElementType.line:
        return _buildPdfLine(element);
      case ReportElementType.rectangle:
        return _buildPdfRectangle(element);
      case ReportElementType.circle:
        return _buildPdfCircle(element);
      case ReportElementType.image:
        return _buildPdfImage(element, data);
      case ReportElementType.table:
        return _buildPdfTable(element, data);
      case ReportElementType.checkbox:
        return _buildPdfCheckbox(element, data);
      case ReportElementType.textbox:
        return _buildPdfTextbox(element, data);
      case ReportElementType.pageNumber:
        return _buildPdfPageNumber(element);
      case ReportElementType.date:
        return _buildPdfDate(element);
      case ReportElementType.logo:
        return _buildPdfLogo(element);
      default:
        return pw.Container();
    }
  }
  
  /// Costruisce testo PDF
  static pw.Widget _buildPdfText(ReportElement element) {
    final text = element.properties['text'] ?? '';
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 10.0;
    final fontWeight = element.properties['fontWeight'] == 'bold' 
      ? pw.FontWeight.bold 
      : pw.FontWeight.normal;
    final alignment = _getPdfAlignment(element.properties['alignment']);
    final color = _parsePdfColor(element.properties['color'] ?? '#000000');
    
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
        textAlign: alignment,
      ),
    );
  }
  
  /// Costruisce campo dinamico PDF
  static pw.Widget _buildPdfDynamicField(ReportElement element, dynamic data) {
    final fieldName = element.properties['fieldName'] ?? '';
    final value = DataExtractor.getValue(data, fieldName)?.toString() ?? '';
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 10.0;
    final fontWeight = element.properties['fontWeight'] == 'bold' 
      ? pw.FontWeight.bold 
      : pw.FontWeight.normal;
    final alignment = _getPdfAlignment(element.properties['alignment']);
    final color = _parsePdfColor(element.properties['color'] ?? '#000000');
    final prefix = element.properties['prefix'] ?? '';
    final suffix = element.properties['suffix'] ?? '';
    final format = element.properties['format'];
    
    String formattedValue = value;
    if (format != null) {
      formattedValue = DataExtractor.formatValue(value, format: format);
    }
    
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      child: pw.Text(
        '$prefix$formattedValue$suffix',
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
        textAlign: alignment,
      ),
    );
  }
  
  /// Costruisce barcode PDF
  static pw.Widget _buildPdfBarcode(ReportElement element, dynamic data) {
    final fieldName = element.properties['fieldName'] ?? '';
    final value = DataExtractor.getValue(data, fieldName)?.toString() ?? '';
    final barcodeType = element.properties['barcodeType'] ?? 'code128';
    final showText = element.properties['showText'] ?? true;
    final textSize = (element.properties['textSize'] as num?)?.toDouble() ?? 8.0;
    
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.BarcodeWidget(
              data: value.isEmpty ? '123456789' : value,
              barcode: _getPdfBarcodeType(barcodeType),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          if (showText)
            pw.Text(
              value.isEmpty ? '123456789' : value,
              style: pw.TextStyle(fontSize: textSize),
            ),
        ],
      ),
    );
  }
  
  /// Costruisce QR Code PDF
  static pw.Widget _buildPdfQRCode(ReportElement element, dynamic data) {
    final fieldName = element.properties['fieldName'] ?? '';
    final value = DataExtractor.getValue(data, fieldName)?.toString() ?? '';
    final errorCorrection = element.properties['errorCorrection'] ?? 'M';
    
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      child: pw.BarcodeWidget(
        data: value.isEmpty ? 'QR Code' : value,
        barcode: pw.Barcode.qrCode(),
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
  
  /// Costruisce linea PDF
  static pw.Widget _buildPdfLine(ReportElement element) {
    final strokeWidth = (element.properties['strokeWidth'] as num?)?.toDouble() ?? 1.0;
    final color = _parsePdfColor(element.properties['color'] ?? '#000000');
    
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: color, width: strokeWidth),
          ),
        ),
      ),
    );
  }
  
  /// Costruisce rettangolo PDF
  static pw.Widget _buildPdfRectangle(ReportElement element) {
    final strokeWidth = (element.properties['strokeWidth'] as num?)?.toDouble() ?? 1.0;
    final strokeColor = _parsePdfColor(element.properties['strokeColor'] ?? '#000000');
    final fillColor = element.properties['fillColor'];
    final borderRadius = (element.properties['borderRadius'] as num?)?.toDouble() ?? 0.0;
    
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: strokeColor, width: strokeWidth),
        borderRadius: pw.BorderRadius.circular(borderRadius),
        color: fillColor != null ? _parsePdfColor(fillColor) : null,
      ),
    );
  }
  
  /// Costruisce cerchio PDF
  static pw.Widget _buildPdfCircle(ReportElement element) {
    final strokeWidth = (element.properties['strokeWidth'] as num?)?.toDouble() ?? 1.0;
    final strokeColor = _parsePdfColor(element.properties['strokeColor'] ?? '#000000');
    final fillColor = element.properties['fillColor'];
    
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: strokeColor, width: strokeWidth),
        color: fillColor != null ? _parsePdfColor(fillColor) : null,
      ),
    );
  }
  
  /// Costruisce immagine PDF (placeholder)
  static pw.Widget _buildPdfImage(ReportElement element, dynamic data) {
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Center(
        child: pw.Text(
          'Image',
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey600,
          ),
        ),
      ),
    );
  }
  
  /// Costruisce tabella PDF (placeholder)
  static pw.Widget _buildPdfTable(ReportElement element, dynamic data) {
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Center(
        child: pw.Text(
          'Table',
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey600,
          ),
        ),
      ),
    );
  }
  
  /// Costruisce checkbox PDF
  static pw.Widget _buildPdfCheckbox(ReportElement element, dynamic data) {
    final fieldName = element.properties['fieldName'] ?? '';
    final value = DataExtractor.getValue(data, fieldName) ?? false;
    final size = (element.properties['size'] as num?)?.toDouble() ?? 12.0;
    final color = _parsePdfColor(element.properties['color'] ?? '#000000');
    
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      child: pw.Row(
        children: [
          pw.Container(
            width: size,
            height: size,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: color, width: 1),
            ),
            child: value == true 
              ? pw.Text('✓', style: pw.TextStyle(fontSize: size * 0.8, color: color))
              : null,
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            element.properties['label'] ?? '',
            style: pw.TextStyle(fontSize: size * 0.8, color: color),
          ),
        ],
      ),
    );
  }
  
  /// Costruisce textbox PDF
  static pw.Widget _buildPdfTextbox(ReportElement element, dynamic data) {
    final fieldName = element.properties['fieldName'] ?? '';
    final value = DataExtractor.getValue(data, fieldName)?.toString() ?? '';
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 10.0;
    final color = _parsePdfColor(element.properties['color'] ?? '#000000');
    final backgroundColor = _parsePdfColor(element.properties['backgroundColor'] ?? '#FFFFFF');
    final borderColor = _parsePdfColor(element.properties['borderColor'] ?? '#000000');
    final borderWidth = (element.properties['borderWidth'] as num?)?.toDouble() ?? 1.0;
    
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      padding: pw.EdgeInsets.all(2),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        border: pw.Border.all(color: borderColor, width: borderWidth),
      ),
      child: pw.Text(
        value,
        style: pw.TextStyle(fontSize: fontSize, color: color),
      ),
    );
  }
  
  /// Costruisce numero pagina PDF
  static pw.Widget _buildPdfPageNumber(ReportElement element) {
    final format = element.properties['format'] ?? 'Pagina {current}';
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 8.0;
    final color = _parsePdfColor(element.properties['color'] ?? '#666666');
    
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      child: pw.Text(
        format.replaceAll('{current}', '1').replaceAll('{total}', '1'),
        style: pw.TextStyle(fontSize: fontSize, color: color),
      ),
    );
  }
  
  /// Costruisce data PDF
  static pw.Widget _buildPdfDate(ReportElement element) {
    final format = element.properties['format'] ?? 'dd/MM/yyyy';
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 8.0;
    final color = _parsePdfColor(element.properties['color'] ?? '#000000');
    
    final now = DateTime.now();
    final formattedDate = DataExtractor.formatValue(now, format: format);
    
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      child: pw.Text(
        formattedDate,
        style: pw.TextStyle(fontSize: fontSize, color: color),
      ),
    );
  }
  
  /// Costruisce logo PDF (placeholder)
  static pw.Widget _buildPdfLogo(ReportElement element) {
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Center(
        child: pw.Text(
          'Logo',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey500,
          ),
        ),
      ),
    );
  }
  
  /// Ottiene il formato pagina PDF
  static PdfPageFormat _getPageFormat(ReportTemplate template) {
    switch (template.pageFormat) {
      case PageFormat.a4Portrait:
        return PdfPageFormat.a4;
      case PageFormat.a4Landscape:
        return PdfPageFormat.a4.copyWith(
          width: PdfPageFormat.a4.height,
          height: PdfPageFormat.a4.width,
        );
      case PageFormat.letter:
        return PdfPageFormat.letter;
      case PageFormat.thermal58mm:
        return PdfPageFormat(58, 40);
      case PageFormat.thermal80mm:
        return PdfPageFormat(80, 40);
      case PageFormat.custom:
        return PdfPageFormat(
          template.pageWidth,
          template.pageHeight,
        );
      default:
        return PdfPageFormat.a4;
    }
  }
  
  /// Converte allineamento
  static pw.TextAlign _getPdfAlignment(String? alignment) {
    switch (alignment) {
      case 'center':
        return pw.TextAlign.center;
      case 'right':
        return pw.TextAlign.right;
      case 'left':
      default:
        return pw.TextAlign.left;
    }
  }
  
  /// Converte colore PDF
  static PdfColor _parsePdfColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    final color = int.parse(buffer.toString(), radix: 16);
    return PdfColor(
      ((color >> 16) & 0xFF) / 255.0,
      ((color >> 8) & 0xFF) / 255.0,
      (color & 0xFF) / 255.0,
      ((color >> 24) & 0xFF) / 255.0,
    );
  }
  
  /// Ottiene tipo barcode PDF
  static pw.Barcode _getPdfBarcodeType(String type) {
    switch (type.toLowerCase()) {
      case 'code128':
        return pw.Barcode.code128();
      case 'ean13':
        return pw.Barcode.ean13();
      case 'ean8':
        return pw.Barcode.ean8();
      case 'upc':
        return pw.Barcode.upcA();
      case 'code39':
        return pw.Barcode.code39();
      default:
        return pw.Barcode.code128();
    }
  }
}

/// Opzioni per export PDF
class PdfExportOptions {
  final bool showBorders;
  final bool includeBackground;
  final double quality;
  final bool compress;
  
  const PdfExportOptions({
    this.showBorders = true,
    this.includeBackground = true,
    this.quality = 1.0,
    this.compress = true,
  });
}