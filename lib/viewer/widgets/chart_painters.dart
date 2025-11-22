import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Painter per grafico a torta
class PieChartPainter extends CustomPainter {
  final List<dynamic> data;
  final Map<String, dynamic> style;
  final double scale;
  final Offset panOffset;
  final double zoomLevel;
  final dynamic selectedItem;

  PieChartPainter({
    required this.data,
    required this.style,
    required this.scale,
    required this.panOffset,
    required this.zoomLevel,
    this.selectedItem,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.8;
    
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.brown,
      Colors.pink,
      Colors.grey,
    ];
    
    double total = 0;
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        total += (item['value'] as num?)?.toDouble() ?? 0.0;
      } else {
        total += (item as num?)?.toDouble() ?? 0.0;
      }
    }
    
    double currentAngle = 0;
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      double value = 0;
      if (item is Map<String, dynamic>) {
        value = (item['value'] as num?)?.toDouble() ?? 0.0;
      } else {
        value = (item as num?)?.toDouble() ?? 0.0;
      }
      
      final sweepAngle = (value / total) * 2 * math.pi;
      final color = colors[i % colors.length];
      final isHovered = selectedItem == item;
      
      // Disegna il settore
      final offset = isHovered ? 5 * scale : 0.0;
      final offsetAngle = currentAngle + sweepAngle / 2;
      final offsetCenter = Offset(
        center.dx + math.cos(offsetAngle) * offset,
        center.dy + math.sin(offsetAngle) * offset,
      );
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      // Disegna settore
      canvas.drawArc(
        Rect.fromCircle(center: offsetCenter, radius: radius),
        currentAngle,
        sweepAngle,
        true,
        paint,
      );
      
      // Disegna bordo
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 * scale;
      
      canvas.drawArc(
        Rect.fromCircle(center: offsetCenter, radius: radius),
        currentAngle,
        sweepAngle,
        true,
        borderPaint,
      );
      
      // Disegna etichetta se c'è spazio
      if (sweepAngle > 20 * math.pi / 180) {
        _drawPieLabel(canvas, offsetCenter, radius, currentAngle, sweepAngle, item);
      }
    }
  }

  void _drawPieLabel(Canvas canvas, Offset center, double radius, 
      double startAngle, double sweepAngle, Map<String, dynamic> sector) {
    final labelAngle = startAngle + sweepAngle / 2;
    final labelRadius = radius * 0.7;
    final labelX = center.dx + math.cos(labelAngle) * labelRadius;
    final labelY = center.dy + math.sin(labelAngle) * labelRadius;
    
    final label = sector['label'] as String;
    final percentage = (sector['percentage'] as double) * 100;
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$label\n${percentage.toStringAsFixed(1)}%',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        labelX - textPainter.width / 2,
        labelY - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// Painter per grafico a barre
class BarChartPainter extends CustomPainter {
  final List<dynamic> data;
  final Map<String, dynamic> style;
  final double scale;
  final Offset panOffset;
  final double zoomLevel;
  final dynamic selectedItem;

  BarChartPainter({
    required this.data,
    required this.style,
    required this.scale,
    required this.panOffset,
    required this.zoomLevel,
    this.selectedItem,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final padding = 20 * scale;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    final barWidth = chartWidth / data.length * 0.8;
    final barSpacing = chartWidth / data.length * 0.2;
    
    // Disegna assi
    _drawAxes(canvas, size, padding);
    
    // Disegna barre
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      double value = 0;
      if (item is Map<String, dynamic>) {
        value = (item['value'] as num?)?.toDouble() ?? 0.0;
      } else {
        value = (item as num?)?.toDouble() ?? 0.0;
      }
      final colors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.red,
        Colors.purple,
        Colors.brown,
        Colors.pink,
        Colors.grey,
      ];
      final color = colors[i % colors.length];
      final isHovered = selectedItem == item;
      
      final barHeight = (value / 100) * chartHeight; // Normalize to 0-100
      final barX = padding + i * (barWidth + barSpacing) + barSpacing / 2;
      final barY = size.height - padding - barHeight;
      
      final paint = Paint()
        ..color = isHovered ? color.withOpacity(0.8) : color
        ..style = PaintingStyle.fill;
      
      // Disegna barra
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        Radius.circular(2 * scale),
      );
      canvas.drawRRect(rect, paint);
      
      // Disegna valore sopra la barra
      _drawBarValue(canvas, barX, barY, barWidth, value);
    }
  }

  void _drawAxes(Canvas canvas, Size size, double padding) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1 * scale;
    
    // Asse X
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      paint,
    );
    
    // Asse Y
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      paint,
    );
  }

  void _drawBarValue(Canvas canvas, double barX, double barY, double barWidth, double value) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: value.toStringAsFixed(1),
        style: TextStyle(
          color: Colors.black87,
          fontSize: 8 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        barX + (barWidth - textPainter.width) / 2,
        barY - textPainter.height - 2 * scale,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// Painter per grafico a linee
class LineChartPainter extends CustomPainter {
  final List<dynamic> data;
  final Map<String, dynamic> style;
  final double scale;
  final Offset panOffset;
  final double zoomLevel;
  final dynamic selectedItem;

  LineChartPainter({
    required this.data,
    required this.style,
    required this.scale,
    required this.panOffset,
    required this.zoomLevel,
    this.selectedItem,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final padding = 20 * scale;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    final pointSpacing = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;
    final valueRange = 100.0; // Normalize to 0-100
    
    // Disegna assi
    _drawAxes(canvas, size, padding);
    
    // Disegna griglia
    _drawGrid(canvas, size, padding);
    
    // Disegna linea
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2 * scale
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      double y = 0;
      if (item is Map<String, dynamic>) {
        y = (item['y'] as num?)?.toDouble() ?? 0.0;
      } else {
        y = (item as num?)?.toDouble() ?? 0.0;
      }
      final x = padding + i * pointSpacing;
      final normalizedY = y / valueRange;
      final chartY = size.height - padding - (normalizedY * chartHeight);
      
      if (i == 0) {
        path.moveTo(x, chartY);
      } else {
        path.lineTo(x, chartY);
      }
    }
    
    canvas.drawPath(path, linePaint);
    
    // Disegna punti
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      double y = 0;
      if (item is Map<String, dynamic>) {
        y = (item['y'] as num?)?.toDouble() ?? 0.0;
      } else {
        y = (item as num?)?.toDouble() ?? 0.0;
      }
      final x = padding + i * pointSpacing;
      final normalizedY = y / valueRange;
      final chartY = size.height - padding - (normalizedY * chartHeight);
      final isHovered = selectedItem == item;
      
      final pointPaint = Paint()
        ..color = isHovered ? Colors.orange : Colors.blue
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x, chartY),
        isHovered ? 5 * scale : 3 * scale,
        pointPaint,
      );
      
      // Disegna valore se è hovered
      if (isHovered) {
        _drawPointValue(canvas, x, chartY, y);
      }
    }
  }

  void _drawAxes(Canvas canvas, Size size, double padding) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1 * scale;
    
    // Asse X
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      paint,
    );
    
    // Asse Y
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      paint,
    );
  }

  void _drawGrid(Canvas canvas, Size size, double padding) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.5 * scale;
    
    // Linee orizzontali
    for (int i = 0; i <= 5; i++) {
      final y = padding + (size.height - padding * 2) * i / 5;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }
  }

  void _drawPointValue(Canvas canvas, double x, double y, double value) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: value.toStringAsFixed(2),
        style: TextStyle(
          color: Colors.black87,
          fontSize: 8 * scale,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white.withOpacity(0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        x - textPainter.width / 2,
        y - textPainter.height - 5 * scale,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
/// Painter per grafico ad area
class AreaChartPainter extends CustomPainter {
  final List<dynamic> data;
  final Map<String, dynamic> style;
  final double scale;
  final Offset panOffset;
  final double zoomLevel;
  final dynamic selectedItem;

  AreaChartPainter({
    required this.data,
    required this.style,
    required this.scale,
    required this.panOffset,
    required this.zoomLevel,
    this.selectedItem,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    // Simple area chart implementation
    final width = size.width;
    final height = size.height;
    final stepX = width / (data.length - 1);
    
    path.moveTo(0, height);
    
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      double value = 0;
      if (item is Map<String, dynamic>) {
        value = (item['value'] as num?)?.toDouble() ?? 0.0;
      } else {
        value = (item as num?)?.toDouble() ?? 0.0;
      }
      
      final x = i * stepX;
      final y = height - (value / 100) * height; // Normalize to 0-100
      
      path.lineTo(x, y);
    }
    
    path.lineTo(width, height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// Painter per grafico a dispersione
class ScatterChartPainter extends CustomPainter {
  final List<dynamic> data;
  final Map<String, dynamic> style;
  final double scale;
  final Offset panOffset;
  final double zoomLevel;
  final dynamic selectedItem;

  ScatterChartPainter({
    required this.data,
    required this.style,
    required this.scale,
    required this.panOffset,
    required this.zoomLevel,
    this.selectedItem,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    final width = size.width;
    final height = size.height;
    
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      double x = 0, y = 0;
      if (item is Map<String, dynamic>) {
        x = (item['x'] as num?)?.toDouble() ?? 0.0;
        y = (item['y'] as num?)?.toDouble() ?? 0.0;
      } else {
        // Use index as x, value as y
        x = i.toDouble();
        y = (item as num?)?.toDouble() ?? 0.0;
      }
      
      // Normalize to canvas size
      final canvasX = (x / 100) * width;
      final canvasY = height - (y / 100) * height;
      
      canvas.drawCircle(
        Offset(canvasX, canvasY),
        4 * scale,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
