import 'package:flutter/material.dart';
import 'builder/builder.dart';
import 'models/report_template.dart';
import 'theme/theme.dart';

void main() {
  runApp(const ReportFlutterApp());
}

class ReportFlutterApp extends StatelessWidget {
  const ReportFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Crea un template di default per il builder
    final defaultTemplate = ReportTemplate(
      id: 'default',
      name: 'Nuovo Report',
      description: 'Report di esempio',
      itemWidth: 210.0, // A4
      itemHeight: 297.0, // A4
      elements: [],
    );

    return MaterialApp(
      title: 'Report Designer',
      theme: AppTheme.themeData,
      home: ReportBuilder(
        template: defaultTemplate,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}