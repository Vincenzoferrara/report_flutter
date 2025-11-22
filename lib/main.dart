import 'package:flutter/material.dart';
import 'report_flutter.dart';
import 'theme/theme.dart';

void main() {
  runApp(const ReportFlutterApp());
}

class ReportFlutterApp extends StatelessWidget {
  const ReportFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Report Flutter Library',
      theme: AppTheme.themeData,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Flutter Library'),
        backgroundColor: AppTheme.primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text(
              'Report Flutter Library',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'A Flutter library for creating and viewing reports',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}