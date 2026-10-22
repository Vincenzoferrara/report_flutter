import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:report_flutter/report_flutter.dart';

/// Demo of the print system: the print center on an in-memory library, with
/// one example label template and example data.
void main() {
  runApp(const ReportFlutterApp());
}

final _demoLibrary = PrintLibrary(
  store: InMemoryPrintStore(),
  options: PrintLibraryOptions(
    loadDefaultPaperFormats: true,
    defaultCategories: (_) => const [
      PrintCategory(id: 'demo', name: 'Demo', position: 0),
    ],
    defaultTemplates: (_) {
      final design = PrintDesign(70, 37)
        ..field('name', 2.5, 2.5, 65, 5.5, size: 3.2, bold: true)
        ..field('detail', 2.5, 8.5, 65, 4.5, size: 2.4)
        ..field('price', 2.5, 24, 33, 10, size: 5.6, bold: true)
        ..barcode('code', 37, 21, 30.5, 13.5);
      return [
        PrintTemplate(
          id: 'demo_label',
          name: 'Demo label',
          categoryId: 'demo',
          paperFormatId: 'a4_3x8',
          design: design.build(id: 'demo_label', name: 'Demo label'),
        ),
      ];
    },
  ),
);

class _DemoDataProvider extends PrintDataProvider {
  const _DemoDataProvider();

  @override
  Map<String, dynamic> sampleData(
    BuildContext context,
    PrintTemplate template,
  ) => const {
    'name': 'Basic cotton T-shirt with a rather long name',
    'detail': 'Navy blue - M',
    'price': '€ 29.90',
    'code': '8001234567890',
  };
}

class ReportFlutterApp extends StatelessWidget {
  const ReportFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Report Flutter',
      theme: AppTheme.themeData,
      // The library also ships Italian: use Locale('it') to try it.
      locale: const Locale('en'),
      supportedLocales: ReportLocalizations.supportedLocales,
      localizationsDelegates: const [
        ReportLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: PrintCenter(
        library: _demoLibrary,
        dataProvider: const _DemoDataProvider(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
