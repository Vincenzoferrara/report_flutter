import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/data_extractor.dart';
import '../models/report_element.dart';
import '../models/report_template.dart';
import 'paper_format.dart';
import 'print_template.dart';

/// Fonts embedded in every generated PDF.
///
/// The standard PDF fonts have no euro sign, so the library ships Latin
/// subsets of Noto Sans and Noto Serif under `assets/fonts/`.
class PrintFonts {
  final pw.Font sans;
  final pw.Font sansBold;
  final pw.Font serif;
  final pw.Font serifBold;

  const PrintFonts({
    required this.sans,
    required this.sansBold,
    required this.serif,
    required this.serifBold,
  });

  static PrintFonts? _cached;

  static Future<PrintFonts> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    // Inside an app the fonts are package assets; when the library runs on
    // its own (the demo) they are plain assets.
    Future<pw.Font> font(String file) async {
      try {
        return pw.Font.ttf(
          await rootBundle.load('packages/report_flutter/assets/fonts/$file'),
        );
      } catch (_) {
        return pw.Font.ttf(await rootBundle.load('assets/fonts/$file'));
      }
    }

    final loaded = PrintFonts(
      sans: await font('NotoSans-Regular.ttf'),
      sansBold: await font('NotoSans-Bold.ttf'),
      serif: await font('NotoSerif-Regular.ttf'),
      serifBold: await font('NotoSerif-Bold.ttf'),
    );
    _cached = loaded;
    return loaded;
  }
}

/// What to print and how many times.
class PrintRequest {
  final PrintTemplate template;
  final PaperFormat paper;

  /// Locale used to format numbers and dates printed by the template.
  final String localeName;

  /// Fields shown when [cellData] is null: example values the app gives so
  /// templates can be previewed without real data.
  final Map<String, dynamic> sampleData;

  /// Small text printed at the bottom right of every page, e.g. a notice
  /// that the figures are examples. Null prints nothing.
  final String? pageNotice;

  /// Number of labels or signs to print. Ignored by reports and when
  /// [cellData] is given.
  final int copies;

  /// Data of each label, in print order (one entry per label). When null,
  /// every cell shows the example data of the template.
  final List<Map<String, dynamic>>? cellData;

  /// Positions already used at the start of each sheet (sheet 1 first):
  /// printing starts after them, so partly used adhesive sheets are not
  /// wasted. Missing entries count as 0; ignored by rolls.
  final List<int> skippedPerSheet;

  /// Draws the outline of every cell. Used only by the on-screen preview,
  /// never on the printed page.
  final bool showCutGuides;

  /// Renders one label or sign on a page of its own size, used for
  /// thumbnails and the close-up preview of sheet formats.
  final bool singleCellPage;

  const PrintRequest({
    required this.template,
    required this.paper,
    required this.localeName,
    this.sampleData = const {},
    this.pageNotice,
    this.copies = 1,
    this.cellData,
    this.skippedPerSheet = const [],
    this.showCutGuides = false,
    this.singleCellPage = false,
  });
}

/// Turns a [PrintTemplate] into a PDF document.
///
/// The template design is drawn element by element with the units of the
/// designer: positions, sizes, font sizes and stroke widths are millimetres.
/// When the paper cell differs from the design size, the design is stretched
/// to fill the cell and fonts follow the smaller of the two ratios.
///
/// Preview and print use the same bytes, so what the user sees on screen is
/// exactly what reaches the printer.
class PrintPdfRenderer {
  PrintPdfRenderer._();

  static Future<Uint8List> render(PrintRequest request) async {
    final fonts = await PrintFonts.load();
    final document = pw.Document(
      title: request.template.name,
      theme: pw.ThemeData.withFont(
        base: fonts.sans,
        bold: fonts.sansBold,
        italic: fonts.sans,
        boldItalic: fonts.sansBold,
      ),
    );
    final context = _RenderContext(request, fonts);
    if (request.singleCellPage) {
      _addSingleCell(document, context);
    } else {
      _addCells(document, context);
    }
    return document.save();
  }

  static void _addSingleCell(pw.Document document, _RenderContext context) {
    final paper = context.paper;
    final width = paper.cellWidthMm * PdfPageFormat.mm;
    final height = paper.cellHeightMm * PdfPageFormat.mm;
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(width, height),
        margin: pw.EdgeInsets.zero,
        build: (_) =>
            _DesignPainter(context, context.dataFor(0), width, height).build(),
      ),
    );
  }

  static void _addCells(pw.Document document, _RenderContext context) {
    final request = context.request;
    final paper = context.paper;
    final copies = math.max(1, request.cellData?.length ?? request.copies);
    final sheetSkips = paper.sheetSkips(copies, request.skippedPerSheet);
    final pageCount = sheetSkips.length;
    final pageFormat = PdfPageFormat(
      paper.pageWidthMm * PdfPageFormat.mm,
      paper.pageHeightMm * PdfPageFormat.mm,
    );
    final cellWidth = paper.cellWidthMm * PdfPageFormat.mm;
    final cellHeight = paper.cellHeightMm * PdfPageFormat.mm;

    // Labels placed on the sheets before the current one.
    var labelsBefore = 0;
    for (var page = 0; page < pageCount; page++) {
      final skipped = sheetSkips[page];
      final firstLabel = labelsBefore;
      labelsBefore += paper.cellsPerPage - skipped;
      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (_) {
            final children = <pw.Widget>[];
            for (var slot = 0; slot < paper.cellsPerPage; slot++) {
              final origin = paper.cellOrigin(slot);
              final labelIndex = firstLabel + slot - skipped;
              final isUsed = slot < skipped;
              final isFilled = !isUsed && labelIndex < copies;
              if (!isFilled && !request.showCutGuides) continue;
              children.add(
                pw.Positioned(
                  left: origin.leftMm * PdfPageFormat.mm,
                  top: origin.topMm * PdfPageFormat.mm,
                  child: pw.Container(
                    width: cellWidth,
                    height: cellHeight,
                    foregroundDecoration:
                        request.showCutGuides && paper.isMultiCellSheet
                        ? pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.grey400,
                              width: 0.4,
                              style: pw.BorderStyle.dashed,
                            ),
                          )
                        : null,
                    color: isUsed ? PdfColors.grey200 : null,
                    child: isFilled
                        ? _DesignPainter(
                            context,
                            context.dataFor(labelIndex),
                            cellWidth,
                            cellHeight,
                          ).build()
                        : null,
                  ),
                ),
              );
            }
            final notice = request.pageNotice;
            if (notice != null && notice.isNotEmpty) {
              children.add(_pageNotice(context, notice));
            }
            return pw.SizedBox(
              width: pageFormat.width,
              height: pageFormat.height,
              child: pw.Stack(children: children),
            );
          },
        ),
      );
    }
  }

  /// Notice at the bottom right of every page, e.g. "Example data".
  static pw.Widget _pageNotice(_RenderContext context, String notice) {
    return pw.Positioned(
      right: 14 * PdfPageFormat.mm,
      bottom: 8 * PdfPageFormat.mm,
      child: pw.Text(
        notice,
        style: pw.TextStyle(
          font: context.fonts.sansBold,
          fontSize: 7,
          color: PdfColors.grey600,
        ),
      ),
    );
  }
}

/// Shared values for one render.
class _RenderContext {
  final PrintRequest request;
  final PrintFonts fonts;

  _RenderContext(this.request, this.fonts);

  PaperFormat get paper => request.paper;

  ReportTemplate get design => request.template.design;

  /// Data of the label at [labelIndex] (0-based, skipped cells excluded).
  Map<String, dynamic> dataFor(int labelIndex) {
    final cells = request.cellData;
    if (cells == null || cells.isEmpty) return request.sampleData;
    return cells[labelIndex.clamp(0, cells.length - 1)];
  }
}

/// Draws the design elements inside one cell of [width] x [height] points.
class _DesignPainter {
  _DesignPainter(this.context, this.data, this.width, this.height)
    : scaleX = width / (_designWidth(context) * PdfPageFormat.mm),
      scaleY = height / (_designHeight(context) * PdfPageFormat.mm);

  final _RenderContext context;
  final Map<String, dynamic> data;
  final double width;
  final double height;
  final double scaleX;
  final double scaleY;

  static double _designWidth(_RenderContext context) =>
      context.design.itemWidth > 0 ? context.design.itemWidth : 1;

  static double _designHeight(_RenderContext context) =>
      context.design.itemHeight > 0 ? context.design.itemHeight : 1;

  /// Millimetres of the design to points of the page, for sizes that must
  /// keep their proportions (fonts, strokes, radii).
  double _mm(num value) => value * PdfPageFormat.mm * math.min(scaleX, scaleY);

  pw.Widget build() {
    return pw.ClipRect(
      child: pw.SizedBox(
        width: width,
        height: height,
        child: pw.Stack(
          children: [
            for (final element in context.design.sortedElements)
              pw.Positioned(
                left: element.x * PdfPageFormat.mm * scaleX,
                top: element.y * PdfPageFormat.mm * scaleY,
                child: pw.SizedBox(
                  width: element.width * PdfPageFormat.mm * scaleX,
                  height: element.height * PdfPageFormat.mm * scaleY,
                  child: _element(element),
                ),
              ),
          ],
        ),
      ),
    );
  }

  pw.Widget _element(ReportElement element) {
    final properties = element.properties;
    final width = element.width * PdfPageFormat.mm * scaleX;
    switch (element.type) {
      case ReportElementType.text:
        return _text(properties['text']?.toString() ?? '', properties, width);
      case ReportElementType.dynamicField:
        final value = _format(
          _value(properties['fieldName']),
          properties['format'],
        );
        return _text(
          '${properties['prefix'] ?? ''}$value${properties['suffix'] ?? ''}',
          properties,
          width,
        );
      case ReportElementType.textbox:
        return _text(_value(properties['fieldName']), properties, width);
      case ReportElementType.date:
        return _text(
          _formatDate(properties['format']?.toString()),
          properties,
          width,
        );
      case ReportElementType.pageNumber:
        final format = properties['format']?.toString() ?? '{current}';
        return _text(
          format.replaceAll('{current}', '1').replaceAll('{total}', '1'),
          properties,
          width,
        );
      case ReportElementType.barcode:
        return _barcode(element);
      case ReportElementType.qrCode:
        return _qrCode(element);
      case ReportElementType.line:
        return _line(properties);
      case ReportElementType.rectangle:
        return _box(properties, circle: false);
      case ReportElementType.circle:
        return _box(properties, circle: true);
      case ReportElementType.table:
        return _table(element);
      case ReportElementType.image:
      case ReportElementType.logo:
      case ReportElementType.checkbox:
      case ReportElementType.pieChart:
      case ReportElementType.barChart:
      case ReportElementType.lineChart:
      case ReportElementType.formula:
      case ReportElementType.markdown:
        return pw.SizedBox();
    }
  }

  String _value(dynamic fieldName) {
    final name = fieldName?.toString() ?? '';
    if (name.isEmpty) return '';
    return DataExtractor.getValue(data, name)?.toString() ?? '';
  }

  String _format(String value, dynamic format) {
    if (format == null || value.isEmpty) return value;
    final number = double.tryParse(value);
    final locale = context.request.localeName;
    switch (format.toString()) {
      case 'currency':
        return number == null
            ? value
            : NumberFormat.currency(locale: locale, symbol: '€').format(number);
      case 'number':
        return number == null
            ? value
            : NumberFormat.decimalPattern(locale).format(number);
      case 'date':
        final date = DateTime.tryParse(value);
        return date == null ? value : DateFormat.yMd(locale).format(date);
      default:
        return value;
    }
  }

  String _formatDate(String? pattern) {
    try {
      return DateFormat(
        pattern ?? 'dd/MM/yyyy',
        context.request.localeName,
      ).format(DateTime.now());
    } catch (_) {
      return DateFormat.yMd(context.request.localeName).format(DateTime.now());
    }
  }

  PdfColor? _color(dynamic hex) {
    final text = hex?.toString();
    if (text == null || text.isEmpty) return null;
    try {
      return PdfColor.fromHex(text);
    } catch (_) {
      return null;
    }
  }

  pw.Font _font(Map<String, dynamic> properties) {
    final bold = properties['fontWeight'] == 'bold';
    final serif = properties['fontFamily'] == 'serif';
    if (serif) return bold ? context.fonts.serifBold : context.fonts.serif;
    return bold ? context.fonts.sansBold : context.fonts.sans;
  }

  pw.Alignment _alignment(Map<String, dynamic> properties) {
    final horizontal = switch (properties['alignment']) {
      'left' => -1.0,
      'right' => 1.0,
      _ => 0.0,
    };
    final vertical = switch (properties['verticalAlignment']) {
      'top' => -1.0,
      'bottom' => 1.0,
      _ => 0.0,
    };
    return pw.Alignment(horizontal, vertical);
  }

  pw.TextAlign _textAlign(dynamic alignment) => switch (alignment) {
    'left' => pw.TextAlign.left,
    'right' => pw.TextAlign.right,
    _ => pw.TextAlign.center,
  };

  /// Text that always fits its box: the font size set in the designer is the
  /// largest size, and the text shrinks when it would not fit. A one-line
  /// text shrinks to the box width; a text allowed more lines wraps at the
  /// box width and shrinks until every line fits the box height.
  pw.Widget _text(String value, Map<String, dynamic> properties, double width) {
    final background = _color(properties['backgroundColor']);
    if (value.isEmpty || width <= 0) return pw.Container(color: background);
    final color = _color(properties['color']) ?? PdfColors.black;
    final strike = properties['textDecoration'] == 'lineThrough';
    final singleLine = ((properties['maxLines'] as num?)?.toInt() ?? 1) <= 1;
    final alignment = _alignment(properties);
    final text = pw.Text(
      value,
      softWrap: !singleLine,
      textAlign: _textAlign(properties['alignment']),
      style: pw.TextStyle(
        font: _font(properties),
        fontSize: _mm((properties['fontSize'] as num?) ?? 5),
        color: color,
        lineSpacing: 0,
        decoration: strike ? pw.TextDecoration.lineThrough : null,
        decorationColor: color,
      ),
    );
    return pw.Container(
      color: background,
      alignment: alignment,
      child: pw.FittedBox(
        fit: pw.BoxFit.scaleDown,
        alignment: alignment,
        child: singleLine ? text : pw.SizedBox(width: width, child: text),
      ),
    );
  }

  pw.Widget _barcode(ReportElement element) {
    final properties = element.properties;
    final value = _value(properties['fieldName']);
    if (value.isEmpty) return pw.SizedBox();
    final elementHeight = element.height * PdfPageFormat.mm * scaleY;
    final barcode = switch (properties['barcodeType']
        ?.toString()
        .toLowerCase()) {
      'ean13' => pw.Barcode.ean13(),
      'ean8' => pw.Barcode.ean8(),
      'upc' => pw.Barcode.upcA(),
      'code39' => pw.Barcode.code39(),
      _ => pw.Barcode.code128(),
    };
    // An EAN barcode with a wrong check digit would break the whole
    // document: print the plain value instead.
    if (!barcode.isValid(value)) {
      return _text(value, {
        'fontSize': 2.2,
        'alignment': 'center',
      }, element.width * PdfPageFormat.mm * scaleX);
    }
    return pw.BarcodeWidget(
      barcode: barcode,
      data: value,
      drawText: properties['showText'] != false,
      textStyle: pw.TextStyle(
        font: context.fonts.sans,
        fontSize: math.min(elementHeight * 0.16, _mm(2.4)),
      ),
    );
  }

  pw.Widget _qrCode(ReportElement element) {
    final value = _value(element.properties['fieldName']);
    if (value.isEmpty) return pw.SizedBox();
    final side = math.min(
      element.width * PdfPageFormat.mm * scaleX,
      element.height * PdfPageFormat.mm * scaleY,
    );
    return pw.Center(
      child: pw.SizedBox(
        width: side,
        height: side,
        child: pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: value),
      ),
    );
  }

  pw.Widget _line(Map<String, dynamic> properties) {
    final stroke = _mm((properties['strokeWidth'] as num?) ?? 0.3);
    return pw.Center(
      child: pw.Container(
        height: stroke,
        color: _color(properties['color']) ?? PdfColors.black,
      ),
    );
  }

  pw.Widget _box(Map<String, dynamic> properties, {required bool circle}) {
    final strokeWidth = ((properties['strokeWidth'] as num?) ?? 0).toDouble();
    final radius = _mm((properties['borderRadius'] as num?) ?? 0);
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _color(properties['fillColor']),
        shape: circle ? pw.BoxShape.circle : pw.BoxShape.rectangle,
        borderRadius: circle || radius <= 0
            ? null
            : pw.BorderRadius.circular(radius),
        border: strokeWidth > 0
            ? pw.Border.all(
                color: _color(properties['strokeColor']) ?? PdfColors.black,
                width: _mm(strokeWidth),
              )
            : null,
      ),
    );
  }

  pw.Widget _table(ReportElement element) {
    final properties = element.properties;
    final columns = ((properties['columns'] as List?) ?? const [])
        .whereType<Map>()
        .map((column) => Map<String, dynamic>.from(column))
        .toList();
    if (columns.isEmpty) return pw.SizedBox();
    final rawRows = DataExtractor.getValue(
      data,
      properties['dataSource']?.toString() ?? '',
    );
    final rows = rawRows is List ? rawRows : const [];
    final headerStyle = Map<String, dynamic>.from(
      (properties['headerStyle'] as Map?) ?? const {},
    );
    final cellStyle = Map<String, dynamic>.from(
      (properties['cellStyle'] as Map?) ?? const {},
    );
    final headerFontSize = _mm((headerStyle['fontSize'] as num?) ?? 3);
    final cellFontSize = _mm((cellStyle['fontSize'] as num?) ?? 3);
    final padding = _mm((cellStyle['padding'] as num?) ?? 1.5);
    final stripe = _color(cellStyle['stripeColor']);
    final borderWidth = ((properties['borderWidth'] as num?) ?? 0).toDouble();
    final borderColor = _color(properties['borderColor']) ?? PdfColors.grey300;

    final totalWidth = columns.fold<double>(
      0,
      (sum, column) => sum + (((column['width'] as num?) ?? 0).toDouble()),
    );
    final widths = {
      for (var index = 0; index < columns.length; index++)
        index: totalWidth > 0
            ? pw.FlexColumnWidth(
                ((columns[index]['width'] as num?) ?? 1).toDouble(),
              )
            : const pw.FlexColumnWidth(),
    };

    pw.Widget cell(
      String value,
      Map<String, dynamic> column, {
      required bool header,
    }) {
      final alignRight = column['align'] == 'right';
      if (value.isEmpty) {
        return pw.SizedBox(
          height: (header ? headerFontSize : cellFontSize) + padding * 1.6,
        );
      }
      // A value wider than its column shrinks instead of being cut.
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding * 0.8,
        ),
        child: pw.FittedBox(
          fit: pw.BoxFit.scaleDown,
          alignment: alignRight
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft,
          child: pw.Text(
            value,
            softWrap: false,
            textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
              font: header || cellStyle['fontWeight'] == 'bold'
                  ? context.fonts.sansBold
                  : context.fonts.sans,
              fontSize: header ? headerFontSize : cellFontSize,
              color: header
                  ? (_color(headerStyle['color']) ?? PdfColors.black)
                  : (_color(cellStyle['color']) ?? PdfColors.black),
            ),
          ),
        ),
      );
    }

    return pw.ClipRect(
      child: pw.Align(
        alignment: pw.Alignment.topLeft,
        child: pw.Table(
          columnWidths: widths,
          border: borderWidth > 0
              ? pw.TableBorder.all(color: borderColor, width: _mm(borderWidth))
              : null,
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: _color(headerStyle['backgroundColor']),
              ),
              children: [
                for (final column in columns)
                  cell(
                    column['title']?.toString() ??
                        column['field']?.toString() ??
                        '',
                    column,
                    header: true,
                  ),
              ],
            ),
            for (var index = 0; index < rows.length; index++)
              pw.TableRow(
                decoration: index.isOdd && stripe != null
                    ? pw.BoxDecoration(color: stripe)
                    : null,
                children: [
                  for (final column in columns)
                    cell(
                      DataExtractor.getValue(
                            rows[index],
                            column['field']?.toString() ?? '',
                          )?.toString() ??
                          '',
                      column,
                      header: false,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
