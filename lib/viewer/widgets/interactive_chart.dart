import 'package:flutter/material.dart';
import 'chart_painters.dart';

/// Tipi di grafici supportati
enum ChartType {
  bar,
  line,
  pie,
  area,
  scatter,
}

/// Widget interattivo per grafici con zoom, pan e drill-down
class InteractiveChart extends StatefulWidget {
  final ChartType type;
  final List<dynamic> data;
  final Map<String, dynamic> style;
  final double width;
  final double height;
  final double scale;
  final bool enableZoom;
  final bool enablePan;
  final bool enableSelection;
  final Function(dynamic)? onDataPointTap;

  const InteractiveChart({
    super.key,
    required this.type,
    required this.data,
    required this.style,
    required this.width,
    required this.height,
    required this.scale,
    required this.enableZoom,
    required this.enablePan,
    required this.enableSelection,
    this.onDataPointTap,
  });

  @override
  State<InteractiveChart> createState() => _InteractiveChartState();
}

class _InteractiveChartState extends State<InteractiveChart> {
  dynamic _selectedItem;
  Offset _panOffset = Offset.zero;
  double _zoomLevel = 1.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Header del grafico
          _buildChartHeader(),
          
          // Area del grafico
          Expanded(
            child: _buildChartArea(),
          ),
          
          // Legenda
          if (widget.data.isNotEmpty)
            _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildChartHeader() {
    final title = widget.style['title'] ?? _getChartTitle();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * widget.scale, vertical: 4 * widget.scale),
      child: Row(
        children: [
          Icon(
            _getChartIcon(),
            size: 16 * widget.scale,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 8 * widget.scale),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12 * widget.scale,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.enableSelection && _selectedItem != null)
            IconButton(
              onPressed: _clearSelection,
              icon: Icon(
                Icons.clear,
                size: 16 * widget.scale,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildChartArea() {
    if (widget.data.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16 * widget.scale),
        child: Center(
          child: Text(
            'Nessun dato disponibile',
            style: TextStyle(
              fontSize: 12 * widget.scale,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: widget.enableSelection ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.enableSelection ? _handleChartTap : null,
        onPanStart: widget.enablePan ? _handlePanStart : null,
        onPanUpdate: widget.enablePan ? _handlePanUpdate : null,
        onPanEnd: widget.enablePan ? _handlePanEnd : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CustomPaint(
            size: Size(widget.width, widget.height - 80),
            painter: _getChartPainter(),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * widget.scale, vertical: 4 * widget.scale),
      child: Wrap(
        spacing: 8 * widget.scale,
        runSpacing: 4 * widget.scale,
        children: _buildLegendItems(),
      ),
    );
  }

  List<Widget> _buildLegendItems() {
    final items = <Widget>[];
    final colors = _getChartColors();
    
    for (int i = 0; i < widget.data.length && i < colors.length; i++) {
      final item = widget.data[i];
      final label = _getDataLabel(item);
      final color = colors[i % colors.length];
      
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12 * widget.scale,
              height: 12 * widget.scale,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 4 * widget.scale),
            Text(
              label,
              style: TextStyle(
                fontSize: 10 * widget.scale,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }
    
    return items;
  }

  CustomPainter _getChartPainter() {
    switch (widget.type) {
      case ChartType.bar:
        return BarChartPainter(
          data: widget.data,
          style: widget.style,
          scale: widget.scale,
          panOffset: _panOffset,
          zoomLevel: _zoomLevel,
          selectedItem: _selectedItem,
        );
      case ChartType.line:
        return LineChartPainter(
          data: widget.data,
          style: widget.style,
          scale: widget.scale,
          panOffset: _panOffset,
          zoomLevel: _zoomLevel,
          selectedItem: _selectedItem,
        );
      case ChartType.pie:
        return PieChartPainter(
          data: widget.data,
          style: widget.style,
          scale: widget.scale,
          panOffset: _panOffset,
          zoomLevel: _zoomLevel,
          selectedItem: _selectedItem,
        );
      case ChartType.area:
        return AreaChartPainter(
          data: widget.data,
          style: widget.style,
          scale: widget.scale,
          panOffset: _panOffset,
          zoomLevel: _zoomLevel,
          selectedItem: _selectedItem,
        );
      case ChartType.scatter:
        return ScatterChartPainter(
          data: widget.data,
          style: widget.style,
          scale: widget.scale,
          panOffset: _panOffset,
          zoomLevel: _zoomLevel,
          selectedItem: _selectedItem,
        );
    }
  }

  String _getChartTitle() {
    switch (widget.type) {
      case ChartType.bar:
        return 'Grafico a Barre';
      case ChartType.line:
        return 'Grafico a Linee';
      case ChartType.pie:
        return 'Grafico a Torta';
      case ChartType.area:
        return 'Grafico ad Area';
      case ChartType.scatter:
        return 'Grafico a Dispersione';
    }
  }

  IconData _getChartIcon() {
    switch (widget.type) {
      case ChartType.bar:
        return Icons.bar_chart;
      case ChartType.line:
        return Icons.show_chart;
      case ChartType.pie:
        return Icons.pie_chart;
      case ChartType.area:
        return Icons.area_chart;
      case ChartType.scatter:
        return Icons.scatter_plot;
    }
  }

  List<Color> _getChartColors() {
    return [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.brown,
      Colors.pink,
      Colors.grey,
    ];
  }

  String _getDataLabel(dynamic item) {
    if (item is Map<String, dynamic>) {
      return item['label']?.toString() ?? item['name']?.toString() ?? 'Dato';
    }
    return item.toString();
  }

  void _handleChartTap() {
    // Implementazione del tap sul grafico
    if (widget.onDataPointTap != null && widget.data.isNotEmpty) {
      final selectedItem = widget.data.first;
      setState(() {
        _selectedItem = selectedItem;
      });
      widget.onDataPointTap!(selectedItem);
    }
  }

  void _handlePanStart(DragStartDetails details) {
    // Implementazione del pan start
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _panOffset += details.delta;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    // Implementazione del pan end
  }

  void _clearSelection() {
    setState(() {
      _selectedItem = null;
    });
  }
}