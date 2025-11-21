import 'package:flutter/material.dart';
import 'report_flutter.dart';

void main() {
  runApp(const ReportFlutterDemoApp());
}

class ReportFlutterDemoApp extends StatelessWidget {
  const ReportFlutterDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Report Flutter Library Demo',
      theme: ThemeData.light(), // Tema standard temporaneo
      home: const DemoHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Dati di esempio
  final List<Map<String, dynamic>> _products = [
    {
      'id': 1,
      'name': 'iPhone 15 Pro',
      'description': 'Smartphone Apple con chip A17 Pro',
      'price': 1199.99,
      'category': 'Smartphone',
      'sku': 'IP15-PRO-128',
      'inStock': true,
      'createdAt': '2024-01-15T10:30:00Z',
    },
    {
      'id': 2,
      'name': 'Samsung Galaxy S24',
      'description': 'Smartphone Android con AI avanzata',
      'price': 999.99,
      'category': 'Smartphone',
      'sku': 'SAMSUNG-S24-256',
      'inStock': true,
      'createdAt': '2024-01-20T14:15:00Z',
    },
    {
      'id': 3,
      'name': 'iPad Pro 12.9"',
      'description': 'Tablet professionale con chip M2',
      'price': 1299.99,
      'category': 'Tablet',
      'sku': 'IPAD-PRO-129-256',
      'inStock': false,
      'createdAt': '2024-01-10T09:00:00Z',
    },
    {
      'id': 4,
      'name': 'MacBook Air M2',
      'description': 'Laptop ultraleggero con chip M2',
      'price': 1499.99,
      'category': 'Laptop',
      'sku': 'MACBOOK-AIR-M2-512',
      'inStock': true,
      'createdAt': '2024-01-05T16:45:00Z',
    },
    {
      'id': 5,
      'name': 'AirPods Pro 2',
      'description': 'Cuffie wireless con cancellazione rumore',
      'price': 249.99,
      'category': 'Audio',
      'sku': 'AIRPODS-PRO-2',
      'inStock': true,
      'createdAt': '2024-01-25T11:20:00Z',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Flutter Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.visibility),
              text: 'Viewer',
            ),
            Tab(
              icon: Icon(Icons.edit),
              text: 'Builder',
            ),
            Tab(
              icon: Icon(Icons.info),
              text: 'Info',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildViewerTab(),
          _buildBuilderTab(),
          _buildInfoTab(),
        ],
      ),
    );
  }

  Widget _buildViewerTab() {
    return Column(
      children: [
        // Header con controlli
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report Viewer Demo',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Visualizzazione template .rpt con dati reali',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showSingleReportViewer(),
                    icon: const Icon(Icons.description),
                    label: const Text('Singolo Report'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showPaginatedReportViewer(),
                    icon: const Icon(Icons.view_carousel),
                    label: const Text('Report Paginato'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showCustomTemplateViewer(),
                    icon: const Icon(Icons.code),
                    label: const Text('Template Custom'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Area viewer
        Expanded(
          child: _buildDefaultViewer(),
        ),
      ],
    );
  }

  Widget _buildDefaultViewer() {
    // Temporaneamente semplificato per debug
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.visibility, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Viewer in costruzione', style: TextStyle(fontSize: 18)),
          Text('Template: assets/templates/product_label.rpt'),
          Text('Dati: ${5} prodotti'),
        ],
      ),
    );
  }

  Widget _buildBuilderTab() {
    // Crea un template di esempio per il builder
    final sampleTemplate = ReportTemplate(
      id: 'demo_template',
      name: 'Template Demo',
      description: 'Template di esempio per il builder',
      itemWidth: 50,  // Verticale: larghezza minore
      itemHeight: 80, // Verticale: altezza maggiore
      dataSchema: ProductSchema(),
    );

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report Builder Demo',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Editor drag-and-drop per creare template personalizzati',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        
        // Builder
        Expanded(
          child: ReportBuilder(
            template: sampleTemplate,
            sampleData: _products.first,
            onTemplateChanged: (template) {
              // Callback quando il template cambia
              print('Template modificato: ${template.name}');
            },
            onSave: (template) {
              // Callback quando si salva
              _showSaveDialog(template);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Designer Library',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          
          _buildInfoCard(
            '🎯 Caratteristiche Principali',
            [
              '• ReportViewer: Visualizzatore indipendente di report',
              '• ReportBuilder: Editor drag-and-drop per template',
              '• Supporto schema dati con validazione',
              '• File .rpt per template riutilizzabili',
              '• Multiple fonti dati (embedded, classi, database)',
              '• Export in vari formati (PDF, immagini)',
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoCard(
            '📄 Formato File .rpt',
            [
              '• Formato JSON standardizzato',
              '• Contiene template, schema e metadati',
              '• Supporto versioning',
              '• Compatibilità cross-platform',
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoCard(
            '🔧 Utilizzo Viewer',
            [
              '```dart',
              'ReportViewer(',
              '  templateFile: "template.rpt",',
              '  data: productList,',
              '  options: ReportViewerOptions(',
              '    scale: 2.0,',
              '  ),',
              ')',
              '```',
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoCard(
            '🏗️ Utilizzo Builder',
            [
              '```dart',
              'ReportBuilder(',
              '  template: myTemplate,',
              '  sampleData: product,',
              '  onSave: (template) => saveTemplate(template),',
              ')',
              '```',
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoCard(
            '📊 Schema Dati',
            [
              '• Definizione struttura dati',
              '• Validazione automatica',
              '• Type safety a runtime',
              '• Supporto campi required/optional',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...content.map((text) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: text.startsWith('```') ? 'monospace' : null,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showSingleReportViewer() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              AppBar(
                title: const Text('Singolo Report'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: SingleReportViewer(
                  templateAsset: 'assets/templates/product_label.rpt',
                  data: _products.first,
                  options: const ReportViewerOptions(
                    scale: 3.0,
                    showGrid: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaginatedReportViewer() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              AppBar(
                title: const Text('Report Paginato'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: ReportViewer(
                  templateAsset: 'assets/templates/product_label.rpt',
                  data: _products,
                  options: const ReportViewerOptions(
                    scale: 2.5,
                    showGrid: false,
                  ),
                  enablePagination: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomTemplateViewer() {
    // Crea un template custom al volo (verticale)
    final customTemplate = ReportTemplate(
      id: 'custom_demo',
      name: 'Template Custom',
      description: 'Template creato dinamicamente',
      itemWidth: 50,  // Verticale
      itemHeight: 70, // Verticale
      dataSchema: ProductSchema(),
      elements: [
        ReportElement(
          id: 'title',
          type: ReportElementType.text,
          x: 5,
          y: 5,
          width: 40,
          height: 8,
          properties: {
            'text': 'Scheda Prodotto',
            'fontSize': 12,
            'fontWeight': 'bold',
            'alignment': 'center',
          },
        ),
        ReportElement(
          id: 'product_info',
          type: ReportElementType.dynamicField,
          x: 5,
          y: 15,
          width: 40,
          height: 10,
          properties: {
            'fieldName': 'name',
            'fontSize': 9,
            'alignment': 'center',
          },
        ),
        ReportElement(
          id: 'price_info',
          type: ReportElementType.dynamicField,
          x: 5,
          y: 28,
          width: 20,
          height: 6,
          properties: {
            'fieldName': 'price',
            'fontSize': 10,
            'fontWeight': 'bold',
            'format': 'currency',
          },
        ),
        ReportElement(
          id: 'category_info',
          type: ReportElementType.dynamicField,
          x: 25,
          y: 28,
          width: 20,
          height: 6,
          properties: {
            'fieldName': 'category',
            'fontSize': 7,
            'alignment': 'right',
          },
        ),
        ReportElement(
          id: 'sku_info',
          type: ReportElementType.dynamicField,
          x: 5,
          y: 36,
          width: 40,
          height: 5,
          properties: {
            'fieldName': 'sku',
            'fontSize': 7,
            'alignment': 'center',
          },
        ),
        ReportElement(
          id: 'barcode',
          type: ReportElementType.barcode,
          x: 10,
          y: 43,
          width: 30,
          height: 15,
          properties: {
            'fieldName': 'sku',
            'barcodeType': 'code128',
            'showText': true,
            'textSize': 6,
          },
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              AppBar(
                title: const Text('Template Custom'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: ReportViewer(
                  template: customTemplate,
                  data: _products,
                  options: const ReportViewerOptions(
                    scale: 2.0,
                    showGrid: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaveDialog(ReportTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salva Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: ${template.name}'),
            Text('Elementi: ${template.elements.length}'),
            const SizedBox(height: 8),
            const Text('Template salvato con successo!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}