import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/report_element.dart';
import '../../models/report_template.dart';
import '../../schema/data_schema.dart';
import '../../core/data_extractor.dart';
import '../widgets/interactive_table.dart';
import '../widgets/interactive_chart.dart';
import '../../core/formula_engine.dart';
import '../../core/conditional_formatter.dart';
import '../../core/markdown_renderer.dart';
import '../../core/conditional_image_loader.dart';

/// Report display mode
enum ReportViewMode { singlePage, continuous, twoPage, dashboard }

/// Filter options for the report data
class ReportFilter {
  final String field;
  final dynamic value;
  final String operator; // 'equals', 'contains', 'greater', 'less', 'between'
  final bool enabled;

  const ReportFilter({
    required this.field,
    required this.value,
    this.operator = 'equals',
    this.enabled = true,
  });

  ReportFilter copyWith({
    String? field,
    dynamic value,
    String? operator,
    bool? enabled,
  }) {
    return ReportFilter(
      field: field ?? this.field,
      value: value ?? this.value,
      operator: operator ?? this.operator,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Sort options for the report tables
class ReportSort {
  final String field;
  final bool ascending;

  const ReportSort({required this.field, this.ascending = true});
}

/// Options of the report viewer
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

  final ReportViewMode viewMode;
  final bool showSidebar;
  final bool enableFilters;
  final bool enableParameters;
  final bool enableDataInteraction;
  final bool enableTableSorting;
  final bool enableRowSelection;
  final bool enableDrillDown;
  final bool enableExport;
  final bool enableAnnotations;
  final bool enableDataRefresh;
  final List<ReportFilter> filters;
  final List<ReportSort> sorts;
  final Map<String, dynamic> parameters;

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

    this.viewMode = ReportViewMode.singlePage,
    this.showSidebar = true,
    this.enableFilters = true,
    this.enableParameters = true,
    this.enableDataInteraction = true,
    this.enableTableSorting = true,
    this.enableRowSelection = true,
    this.enableDrillDown = true,
    this.enableExport = true,
    this.enableAnnotations = false,
    this.enableDataRefresh = true,
    this.filters = const [],
    this.sorts = const [],
    this.parameters = const {},
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

    ReportViewMode? viewMode,
    bool? showSidebar,
    bool? enableFilters,
    bool? enableParameters,
    bool? enableDataInteraction,
    bool? enableTableSorting,
    bool? enableRowSelection,
    bool? enableDrillDown,
    bool? enableExport,
    bool? enableAnnotations,
    bool? enableDataRefresh,
    List<ReportFilter>? filters,
    List<ReportSort>? sorts,
    Map<String, dynamic>? parameters,
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

      viewMode: viewMode ?? this.viewMode,
      showSidebar: showSidebar ?? this.showSidebar,
      enableFilters: enableFilters ?? this.enableFilters,
      enableParameters: enableParameters ?? this.enableParameters,
      enableDataInteraction:
          enableDataInteraction ?? this.enableDataInteraction,
      enableTableSorting: enableTableSorting ?? this.enableTableSorting,
      enableRowSelection: enableRowSelection ?? this.enableRowSelection,
      enableDrillDown: enableDrillDown ?? this.enableDrillDown,
      enableExport: enableExport ?? this.enableExport,
      enableAnnotations: enableAnnotations ?? this.enableAnnotations,
      enableDataRefresh: enableDataRefresh ?? this.enableDataRefresh,
      filters: filters ?? this.filters,
      sorts: sorts ?? this.sorts,
      parameters: parameters ?? this.parameters,
    );
  }
}

/// Renderer for a single report
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
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        final templateWidth = template.itemWidth;
        final templateHeight = template.itemHeight;

        double finalScale;

        // With infinite constraints (e.g. inside an InteractiveViewer with constrained: false)
        // use a scale based on the template size for a sensible display
        if (!availableWidth.isFinite || !availableHeight.isFinite) {
          if (options.scale != 1.0) {
            finalScale = options.scale;
          } else {
            // Sensible scale based on the template size
            // Target: small label (50x30 mm) -> scale ~10, A4 (210x297 mm) -> scale ~3
            final minDimension = templateWidth < templateHeight
                ? templateWidth
                : templateHeight;
            finalScale = (300 / minDimension).clamp(2.0, 15.0);
          }
        } else {
          final horizontalScale = availableWidth / templateWidth;
          final verticalScale = availableHeight / templateHeight;

          // The smaller scale keeps the whole template visible
          final fillScale = horizontalScale < verticalScale
              ? horizontalScale
              : verticalScale;

          // Use the user scale when it is not 1.0, otherwise the fill scale
          finalScale = options.scale != 1.0 ? options.scale : fillScale;
        }

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
              if (options.showGrid) _buildGrid(width, height, finalScale),

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
        color: options.borderColor.withValues(alpha: 0.3),
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
        return _renderInteractiveChart(element, scale, ChartType.pie);
      case ReportElementType.barChart:
        return _renderInteractiveChart(element, scale, ChartType.bar);
      case ReportElementType.lineChart:
        return _renderInteractiveChart(element, scale, ChartType.line);
      case ReportElementType.formula:
        return _renderFormula(element, scale);
      case ReportElementType.markdown:
        return _renderMarkdown(element, scale);
    }
  }

  Widget _renderText(ReportElement element, double scale) {
    final text = element.properties['text'] ?? 'Text';
    final fontSize =
        (element.properties['fontSize'] as num?)?.toDouble() ?? 5.0;
    final fontWeight = _getFontWeight(element.properties['fontWeight']);
    final alignment = _getAlignment(element.properties['alignment']);
    final color = _parseColor(element.properties['color'] ?? '#000000');
    final backgroundColor = element.properties['backgroundColor'];

    // 1:1 scale - font size in points scaled directly
    final scaledFontSize = fontSize * scale;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor != null ? _parseColor(backgroundColor) : null,
      child: Text(
        text,
        style: TextStyle(
          fontSize: scaledFontSize,
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
    final fontSize =
        (element.properties['fontSize'] as num?)?.toDouble() ?? 5.0;
    final fontWeight = _getFontWeight(element.properties['fontWeight']);
    final alignment = _getAlignment(element.properties['alignment']);
    final color = _parseColor(element.properties['color'] ?? '#000000');

    final value = DataExtractor.getValue(data, fieldName);
    final formattedValue = DataExtractor.formatValue(value, format: format);
    final displayText = '$prefix$formattedValue$suffix';

    // With Markdown enabled, render as Markdown
    if (MarkdownRenderer.isMarkdownEnabled(element)) {
      return _renderMarkdown(element, scale);
    }

    // 1:1 scale - font size in points scaled directly
    final scaledFontSize = fontSize * scale;

    // Apply conditional formatting when enabled
    TextStyle textStyle = TextStyle(
      fontSize: scaledFontSize,
      fontWeight: fontWeight,
      color: color,
    );

    if (ConditionalFormatter.isConditionalFormattingEnabled(element)) {
      final rules = ConditionalFormatter.getConditionalRules(element);
      final conditionalStyle = ConditionalFormatter.applyTextStyle(
        value,
        rules,
        textStyle,
      );
      if (conditionalStyle != null) {
        textStyle = conditionalStyle;
      }
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Text(
        displayText,
        style: textStyle,
        textAlign: alignment,
        overflow: TextOverflow.ellipsis,
        maxLines: (element.properties['maxLines'] as num?)?.toInt() ?? 1,
      ),
    );
  }

  Widget _renderBarcode(ReportElement element, double scale) {
    final fieldName = element.properties['fieldName'] ?? '';
    final showText = element.properties['showText'] ?? true;

    // Rendered as a placeholder for now
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
                    DataExtractor.getValue(data, fieldName)?.toString() ??
                        '123456789',
                    style: TextStyle(fontSize: fontSize.clamp(4.0, 10.0)),
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

    // Placeholder when there is no data
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
    final fit = _getBoxFit(element.properties['fit']);

    // ConditionalImageLoader handles every source
    return ConditionalImageLoader.loadImage(
      data,
      element,
      width: double.infinity,
      height: double.infinity,
      fit: fit,
    );
  }

  Widget _renderLine(ReportElement element, double scale) {
    final strokeWidth =
        (element.properties['strokeWidth'] as num?)?.toDouble() ?? 1;
    final color = _parseColor(element.properties['color'] ?? '#000000');

    return SizedBox(
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
    final strokeWidth =
        (element.properties['strokeWidth'] as num?)?.toDouble() ?? 1;
    final strokeColor = _parseColor(
      element.properties['strokeColor'] ?? '#000000',
    );
    final fillColor = element.properties['fillColor'];
    final borderRadius =
        (element.properties['borderRadius'] as num?)?.toDouble() ?? 0;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: fillColor != null ? _parseColor(fillColor) : null,
        border: Border.all(color: strokeColor, width: strokeWidth * scale),
        borderRadius: BorderRadius.circular(borderRadius * scale),
      ),
    );
  }

  Widget _renderCircle(ReportElement element, double scale) {
    final strokeWidth =
        (element.properties['strokeWidth'] as num?)?.toDouble() ?? 1;
    final strokeColor = _parseColor(
      element.properties['strokeColor'] ?? '#000000',
    );
    final fillColor = element.properties['fillColor'];

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: fillColor != null ? _parseColor(fillColor) : null,
        border: Border.all(color: strokeColor, width: strokeWidth * scale),
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
    final fontSize =
        (element.properties['fontSize'] as num?)?.toDouble() ?? 5.0;
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
        style: TextStyle(fontSize: fontSize * scale / 3, color: Colors.black87),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _renderDate(ReportElement element, double scale) {
    final format = element.properties['format'] ?? 'dd/MM/yyyy';
    final fontSize =
        (element.properties['fontSize'] as num?)?.toDouble() ?? 5.0;
    final color = _parseColor(element.properties['color'] ?? '#000000');

    final now = DateTime.now();
    final formattedDate = DataExtractor.formatValue(now, format: format);

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Text(
        formattedDate,
        style: TextStyle(fontSize: fontSize * scale / 3, color: color),
      ),
    );
  }

  Widget _renderPageNumber(ReportElement element, double scale) {
    final format = element.properties['format'] ?? 'Page {current}';
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 8;
    final color = _parseColor(element.properties['color'] ?? '#666666');

    // Placeholder for now
    final text = format.replaceAll('{current}', '1').replaceAll('{total}', '1');

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Text(
        text,
        style: TextStyle(fontSize: fontSize * scale / 3, color: color),
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
    final borderWidth =
        (element.properties['borderWidth'] as num?)?.toDouble() ?? 0.5;
    final borderColor = _parseColor(
      element.properties['borderColor'] ?? '#000000',
    );
    final enableSorting = options.enableTableSorting;
    final enableSelection = options.enableRowSelection;
    final enableDrillDown = options.enableDrillDown;

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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.table_chart_outlined,
                size: 24 * scale,
                color: Colors.grey.shade600,
              ),
              SizedBox(height: 8 * scale),
              Text(
                'No table data',
                style: TextStyle(
                  fontSize: 8 * scale,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Build interactive table
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: InteractiveTable(
        columns: columns.cast<Map<String, dynamic>>(),
        tableData: tableData,
        headerStyle: headerStyle.cast<String, dynamic>(),
        cellStyle: cellStyle.cast<String, dynamic>(),
        borderWidth: borderWidth,
        borderColor: borderColor,
        scale: scale,
        enableSorting: enableSorting,
        enableSelection: enableSelection,
        enableDrillDown: enableDrillDown,
        onRowClick: enableDrillDown
            ? (rowData) => _handleDrillDown(rowData, dataSource)
            : null,
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
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
      default:
        return TextAlign.center;
    }
  }

  AlignmentGeometry _getAlignmentGeometry(TextAlign alignment) {
    switch (alignment) {
      case TextAlign.left:
        return Alignment.centerLeft;
      case TextAlign.right:
        return Alignment.centerRight;
      case TextAlign.center:
      default:
        return Alignment.center;
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

  Widget _buildLogoPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(Icons.business, size: 32.0, color: Colors.grey.shade500),
    );
  }

  Widget _renderInteractiveChart(
    ReportElement element,
    double scale,
    ChartType chartType,
  ) {
    final dataSource = element.properties['dataSource'] ?? '';
    final enableDrillDown = options.enableDrillDown;

    // Get chart data
    List<dynamic> chartData = [];
    if (dataSource.isNotEmpty) {
      chartData = DataExtractor.getValue(data, dataSource) as List? ?? [];
    }

    if (chartData.isEmpty) {
      return _buildChartPlaceholder(chartType, scale);
    }

    return InteractiveChart(
      type: chartType,
      data: chartData,
      style: element.properties,
      width: element.width,
      height: element.height,
      scale: scale,
      enableZoom: false,
      enablePan: false,
      enableSelection: enableDrillDown,
      onDataPointTap: enableDrillDown
          ? (itemData) => _handleChartDrillDown(itemData, chartType)
          : null,
    );
  }

  Widget _buildChartPlaceholder(ChartType chartType, double scale) {
    IconData icon;
    String label;

    switch (chartType) {
      case ChartType.pie:
        icon = Icons.pie_chart;
        label = 'Pie chart';
        break;
      case ChartType.bar:
        icon = Icons.bar_chart;
        label = 'Bar chart';
        break;
      case ChartType.line:
        icon = Icons.show_chart;
        label = 'Line chart';
        break;
      case ChartType.area:
        icon = Icons.area_chart;
        label = 'Area chart';
        break;
      case ChartType.scatter:
        icon = Icons.scatter_plot;
        label = 'Scatter chart';
        break;
    }

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

  /// Renders a Formula element
  Widget _renderFormula(ReportElement element, double scale) {
    final formula = element.properties['formula'] ?? '';
    final variables = Map<String, String>.from(
      element.properties['variables'] ?? {},
    );
    final format = element.properties['format'] ?? 'number';
    final errorValue = element.properties['errorValue'] ?? '0';
    final fontSize =
        (element.properties['fontSize'] as num?)?.toDouble() ?? 5.0;
    final fontWeight = _getFontWeight(element.properties['fontWeight']);
    final alignment = _getAlignment(element.properties['alignment']);
    final color = _parseColor(element.properties['color'] ?? '#000000');

    try {
      final result = FormulaEngine.evaluate(formula, data, variables);
      final formattedResult = FormulaEngine.formatResult(result, format);

      TextStyle textStyle = TextStyle(
        fontSize: fontSize * scale,
        fontWeight: fontWeight,
        color: color,
      );

      if (ConditionalFormatter.isConditionalFormattingEnabled(element)) {
        final rules = ConditionalFormatter.getConditionalRules(element);
        final conditionalStyle = ConditionalFormatter.applyTextStyle(
          result,
          rules,
          textStyle,
        );
        if (conditionalStyle != null) {
          textStyle = conditionalStyle;
        }
      }

      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Text(
          formattedResult,
          style: textStyle,
          textAlign: alignment,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    } catch (e) {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Text(
          errorValue,
          style: TextStyle(
            fontSize: fontSize * scale,
            fontWeight: fontWeight,
            color: Colors.red,
          ),
          textAlign: alignment,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }
  }

  /// Renders a Markdown element
  Widget _renderMarkdown(ReportElement element, double scale) {
    // Without Markdown, fall back to plain text
    if (!MarkdownRenderer.isMarkdownEnabled(element)) {
      return _renderText(element, scale);
    }

    final markdownData = MarkdownRenderer.getMarkdownData(element);
    final markdownConfig = MarkdownRenderer.getMarkdownConfig(element);
    final fontSize =
        (element.properties['fontSize'] as num?)?.toDouble() ?? 5.0;
    final alignment = _getAlignment(element.properties['alignment']);
    final color = _parseColor(element.properties['color'] ?? '#000000');

    final baseStyle = TextStyle(fontSize: fontSize * scale, color: color);

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Align(
        alignment: _getAlignmentGeometry(alignment),
        child: MarkdownRenderer.render(
          markdownData,
          markdownConfig,
          baseStyle: baseStyle,
        ),
      ),
    );
  }

  void _handleChartDrillDown(dynamic itemData, ChartType chartType) {
    // TODO: implement drill-down for charts
    // It will be handled by the main ReportViewer
  }

  void _handleDrillDown(dynamic rowData, String dataSource) {
    // TODO: implement drill-down for tables
    // It will be handled by the main ReportViewer
  }
}

/// Painter for the background grid
class _GridPainter extends CustomPainter {
  final double scale;
  final Color color;

  _GridPainter({required this.scale, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    // Grid every 5 mm
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
