import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/report_template.dart';
import '../schema/data_schema.dart';
import '../formats/template_loader.dart';
import 'renderers/report_renderer.dart';

/// Widget principale per visualizzare report indipendentemente
class ReportViewer extends StatefulWidget {
  final String? templateFile;      // Path al file template .rpt
  final String? templateAsset;     // Path all'asset template
  final ReportTemplate? template;   // Template diretto
  final List<dynamic> data;         // Dati da visualizzare
  final ReportViewerOptions options;
  final bool enablePagination;
  final VoidCallback? onPageChanged;
  final Function(int)? onCurrentPageChanged;

  const ReportViewer({
    super.key,
    this.templateFile,
    this.templateAsset,
    this.template,
    required this.data,
    this.options = const ReportViewerOptions(),
    this.enablePagination = true,
    this.onPageChanged,
    this.onCurrentPageChanged,
  }) : assert(
         templateFile != null || templateAsset != null || template != null,
         'Devi fornire templateFile, templateAsset o template',
       );

  @override
  State<ReportViewer> createState() => _ReportViewerState();
}

class _ReportViewerState extends State<ReportViewer> {
  ReportTemplate? _template;
  DataSchema? _schema;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;
  late ReportViewerOptions _currentOptions;
  bool _isManualZoom = false; // Traccia se lo zoom è stato modificato manualmente

  @override
  void initState() {
    super.initState();
    _currentOptions = widget.options;
    _loadTemplate();
  }

  @override
  void didUpdateWidget(ReportViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Ricarica se cambia il template
    if (oldWidget.templateFile != widget.templateFile ||
        oldWidget.templateAsset != widget.templateAsset ||
        oldWidget.template != widget.template) {
      _loadTemplate();
    } else if (oldWidget.data.length != widget.data.length) {
      // Aggiorna paginazione se cambiano i dati
      _updatePagination();
    }
  }

  Future<void> _loadTemplate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      ReportTemplate? template;
      DataSchema? schema;

      if (widget.template != null) {
        template = widget.template!;
        schema = template.dataSchema;
      } else if (widget.templateFile != null) {
        final templateWithSchema = await TemplateLoader.fromFile(widget.templateFile!);
        template = templateWithSchema.template;
        schema = templateWithSchema.schema;
      } else if (widget.templateAsset != null) {
        final templateWithSchema = await TemplateLoader.fromAsset(widget.templateAsset!);
        template = templateWithSchema.template;
        schema = templateWithSchema.schema;
      }

      if (template == null) {
        throw Exception('Impossibile caricare il template');
      }

      setState(() {
        _template = template;
        _schema = schema;
        _isLoading = false;
      });

      _updatePagination();
      _validateData();
      
      // Auto-adatta lo zoom allo schermo dopo il caricamento
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Piccolo ritardo per assicurarsi che il layout sia completo
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _fitToScreen();
          }
        });
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _updatePagination() {
    if (_template == null || widget.data.isEmpty) {
      setState(() {
        _totalPages = 0;
        _currentPage = 0;
      });
      return;
    }

    final totalPages = widget.data.length;
    setState(() {
      _totalPages = totalPages;
      _currentPage = (_currentPage < totalPages) ? _currentPage : 0;
    });
  }

  void _validateData() {
    if (_template == null || _schema == null) return;

    final validation = _template!.validateData(widget.data);
    if (!validation.isValid) {
      setState(() {
        _error = 'Validazione dati fallita: ${validation.errorMessage}';
      });
    }
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      setState(() {
        _currentPage = page;
      });
      widget.onPageChanged?.call();
      widget.onCurrentPageChanged?.call(page);
    }
  }

  void _nextPage() {
    _goToPage(_currentPage + 1);
  }

  void _previousPage() {
    _goToPage(_currentPage - 1);
  }

  void _firstPage() {
    _goToPage(0);
  }

  void _lastPage() {
    _goToPage(_totalPages - 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Caricamento template...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Errore',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTemplate,
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }

    if (_template == null) {
      return const Center(
        child: Text('Nessun template caricato'),
      );
    }

    if (widget.data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.data_array,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Nessun dato da visualizzare',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Toolbar con controlli zoom e paginazione
        _buildToolbar(),

        // Area visualizzazione
        Expanded(
          child: _buildContentArea(),
        ),

        // Paginazione (se abilitata)
        if (widget.enablePagination && _totalPages > 1)
          _buildPaginationControls(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Info template
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _template!.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (_template!.description != null)
                  Text(
                    _template!.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          // Controlli zoom
          if (widget.options.enableZoom) ...[
            // Fit to Screen
            IconButton(
              onPressed: _fitToScreen,
              icon: const Icon(Icons.fit_screen),
              tooltip: 'Adatta allo schermo',
            ),
            // Actual Size
            IconButton(
              onPressed: _actualSize,
              icon: const Icon(Icons.fullscreen),
              tooltip: 'Dimensione reale (100%)',
            ),
            const SizedBox(width: 4),
            // Zoom Out
            IconButton(
              onPressed: () => _updateZoom(_currentOptions.scale - 0.25),
              icon: const Icon(Icons.zoom_out),
              tooltip: 'Zoom indietro',
            ),
            // Zoom percentage
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(_currentOptions.scale * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Zoom In
            IconButton(
              onPressed: () => _updateZoom(_currentOptions.scale + 0.25),
              icon: const Icon(Icons.zoom_in),
              tooltip: 'Zoom avanti',
            ),
            const SizedBox(width: 8),
          ],

          // Info paginazione
          if (widget.enablePagination)
            Text(
              'Pagina ${_currentPage + 1} di $_totalPages',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    final currentData = widget.data[_currentPage];
    
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      padding: _currentOptions.padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Auto-adatta quando le dimensioni cambiano (solo se non è zoom manuale)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_template != null && !_isManualZoom) {
              _fitToScreen();
            }
          });
          
          return Center(
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent && _currentOptions.enableZoom) {
                  // Gestisce zoom con mouse wheel
                  final delta = pointerSignal.scrollDelta.dy;
                  final zoomFactor = delta > 0 ? 0.9 : 1.1; // Zoom out/in
                  final newScale = _currentOptions.scale * zoomFactor;
                  _updateZoom(newScale);
                }
              },
              child: InteractiveViewer(
                minScale: 0.1,
                maxScale: 5.0,
                panEnabled: _currentOptions.enablePan,
                boundaryMargin: EdgeInsets.all(
                  constraints.maxWidth * 0.1, // Margine dinamico basato sulla larghezza
                ),
                constrained: false, // Permette zoom oltre i limiti del contenitore
                alignment: Alignment.center, // Centra il contenuto durante lo zoom
                transformationController: null, // Usa il controller di default
                child: ReportRenderer(
                  template: _template!,
                  data: currentData,
                  schema: _schema,
                  options: _currentOptions,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Prima pagina
          IconButton(
            onPressed: _currentPage > 0 ? _firstPage : null,
            icon: const Icon(Icons.first_page),
            tooltip: 'Prima pagina',
          ),
          
          // Pagina precedente
          IconButton(
            onPressed: _currentPage > 0 ? _previousPage : null,
            icon: const Icon(Icons.keyboard_arrow_left),
            tooltip: 'Pagina precedente',
          ),
          
          // Info pagina corrente
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentPage + 1} / $_totalPages',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Pagina successiva
          IconButton(
            onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
            icon: const Icon(Icons.keyboard_arrow_right),
            tooltip: 'Pagina successiva',
          ),
          
          // Ultima pagina
          IconButton(
            onPressed: _currentPage < _totalPages - 1 ? _lastPage : null,
            icon: const Icon(Icons.last_page),
            tooltip: 'Ultima pagina',
          ),
        ],
      ),
    );
  }

  void _updateZoom(double newScale) {
    setState(() {
      _currentOptions = _currentOptions.copyWith(scale: newScale.clamp(0.1, 5.0));
      _isManualZoom = true; // Marca come zoom manuale
    });
  }

  void _fitToScreen() {
    if (_template == null) return;
    
    // Calcola la scala per adattare il template allo schermo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;
      
      final screenSize = renderBox.size;
      final templateWidth = _template!.itemWidth;
      final templateHeight = _template!.itemHeight;
      
      // Calcola lo spazio disponibile (escludendo padding e margini)
      final availableWidth = screenSize.width - (_currentOptions.padding.horizontal + 40); // 40px margine extra
      final availableHeight = screenSize.height - (_currentOptions.padding.vertical + 120); // 120px per UI elements
      
      // Calcola la scala orizzontale e verticale
      final horizontalScale = availableWidth / templateWidth;
      final verticalScale = availableHeight / templateHeight;
      
      // Usa la scala più piccola per garantire che il template sia completamente visibile
      final optimalScale = horizontalScale < verticalScale ? horizontalScale : verticalScale;
      
      // Applica un fattore di sicurezza (95%) per garantire un piccolo margine
      final finalScale = (optimalScale * 0.95).clamp(0.1, 5.0);
      
      setState(() {
        _currentOptions = _currentOptions.copyWith(scale: finalScale);
        _isManualZoom = false; // Resetta il flag dopo fit-to-screen
      });
    });
  }

  void _actualSize() {
    setState(() {
      _currentOptions = _currentOptions.copyWith(scale: 1.0);
      _isManualZoom = true; // Marca come zoom manuale
    });
  }
}

/// Widget semplificato per singolo report (senza paginazione)
class SingleReportViewer extends StatelessWidget {
  final String? templateFile;
  final String? templateAsset;
  final ReportTemplate? template;
  final dynamic data;
  final ReportViewerOptions options;

  const SingleReportViewer({
    super.key,
    this.templateFile,
    this.templateAsset,
    this.template,
    required this.data,
    this.options = const ReportViewerOptions(),
  }) : assert(
         templateFile != null || templateAsset != null || template != null,
         'Devi fornire templateFile, templateAsset o template',
       );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TemplateWithSchema>(
      future: _loadTemplate(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Errore: ${snapshot.error}'),
          );
        }

        final templateWithSchema = snapshot.data;
        if (templateWithSchema == null) {
          return const Center(child: Text('Template non trovato'));
        }

        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: options.padding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent && options.enableZoom) {
                      // Gestisce zoom con mouse wheel
                      final delta = pointerSignal.scrollDelta.dy;
                      final zoomFactor = delta > 0 ? 0.9 : 1.1; // Zoom out/in
                      // Nota: SingleReportViewer è StatelessWidget, quindi non può aggiornare lo stato
                      // Questo è solo per mostrare che il supporto mouse wheel è disponibile
                    }
                  },
                  child: InteractiveViewer(
                    minScale: 0.1,
                    maxScale: 5.0,
                    panEnabled: options.enablePan,
                    boundaryMargin: EdgeInsets.all(
                      constraints.maxWidth * 0.1,
                    ),
                    constrained: false,
                    alignment: Alignment.center,
                    child: ReportRenderer(
                      template: templateWithSchema.template,
                      data: data,
                      schema: templateWithSchema.schema,
                      options: options,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<TemplateWithSchema> _loadTemplate() async {
    if (template != null) {
      return TemplateWithSchema(
        template: template!,
        schema: template!.dataSchema,
        metadata: {},
      );
    } else if (templateFile != null) {
      return await TemplateLoader.fromFile(templateFile!);
    } else if (templateAsset != null) {
      return await TemplateLoader.fromAsset(templateAsset!);
    } else {
      throw Exception('Nessun template fornito');
    }
  }
}