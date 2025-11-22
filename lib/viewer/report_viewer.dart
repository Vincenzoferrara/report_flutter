import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/report_template.dart';
import '../schema/data_schema.dart';
import '../formats/template_loader.dart';
import 'renderers/report_renderer.dart';
import 'widgets/report_sidebar.dart';
import '../export/report_export_service.dart';
import '../core/data_cache_service.dart';
import '../core/annotation_service.dart';

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
  final DataRefreshCallback? onRefreshData;

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
    this.onRefreshData,
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
  bool _isRefreshing = false; // Traccia se è in corso un refresh
  DataSource _dataSource = DataSource.remote; // Sorgente dati corrente
  List<SessionAnnotation> _annotations = []; // Annotazioni temporanee del report
  bool _showAnnotations = false; // Mostra/nascondi annotazioni

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
      _loadAnnotations();
      
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

  void _loadAnnotations() {
    if (_template == null || !_currentOptions.enableAnnotations) return;
    
    // Carica annotazioni temporanee dalla sessione
    final annotations = SessionAnnotationService.getAnnotations(_template!.name);
    setState(() {
      _annotations = annotations;
    });
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
        // Toolbar potenziata con funzionalità report
        _buildEnhancedToolbar(),

        // Area principale con sidebar e contenuto
        Expanded(
          child: Row(
            children: [
              // Sidebar (se abilitata)
              if (_currentOptions.showSidebar)
                ReportSidebar(
                  template: _template!,
                  data: widget.data,
                  schema: _schema,
                  options: _currentOptions,
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onPageSelected: _goToPage,
                  onFiltersChanged: _onFiltersChanged,
                  onParametersChanged: _onParametersChanged,
                ),

              // Area visualizzazione
              Expanded(
                child: _buildContentArea(),
              ),
            ],
          ),
        ),

        // Barra di stato con informazioni report
        _buildStatusBar(),

        // Paginazione (se abilitata e non in modalità continua)
        if (widget.enablePagination && _totalPages > 1 && _currentOptions.viewMode != ReportViewMode.continuous)
          _buildPaginationControls(),
      ],
    );
  }

  Widget _buildEnhancedToolbar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu File e Azioni
          _buildMenuSection(),

          const VerticalDivider(width: 16, indent: 8, endIndent: 8),

          // Paginazione (sinistra)
          if (widget.enablePagination && _totalPages > 1) ...[
            IconButton(
              onPressed: _currentPage > 0 ? _previousPage : null,
              icon: const Icon(Icons.chevron_left, size: 20),
              tooltip: 'Pagina precedente',
              visualDensity: VisualDensity.compact,
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 60),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${_currentPage + 1} / $_totalPages',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
              icon: const Icon(Icons.chevron_right, size: 20),
              tooltip: 'Pagina successiva',
              visualDensity: VisualDensity.compact,
            ),
            const VerticalDivider(width: 16, indent: 8, endIndent: 8),
          ],

          // Modalità visualizzazione
          _buildViewModeSection(),

          const VerticalDivider(width: 16, indent: 8, endIndent: 8),

          // Controlli zoom (centro)
          if (_currentOptions.enableZoom) ...[
            IconButton(
              onPressed: () => _updateZoom(_currentOptions.scale - 0.25),
              icon: const Icon(Icons.remove, size: 18),
              tooltip: 'Zoom indietro',
              visualDensity: VisualDensity.compact,
            ),
            GestureDetector(
              onTap: _showZoomMenu,
              child: Container(
                constraints: const BoxConstraints(minWidth: 55),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(_currentOptions.scale * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => _updateZoom(_currentOptions.scale + 0.25),
              icon: const Icon(Icons.add, size: 18),
              tooltip: 'Zoom avanti',
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: _fitToScreen,
              icon: const Icon(Icons.fit_screen, size: 18),
              tooltip: 'Adatta allo schermo',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: _actualSize,
              icon: const Icon(Icons.crop_free, size: 18),
              tooltip: 'Dimensione reale',
              visualDensity: VisualDensity.compact,
            ),
          ],

          const Spacer(),

          // Azioni report
          _buildActionSection(),

          const SizedBox(width: 8),

          // Info template (destra)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _template!.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_template!.itemWidth.toInt()}x${_template!.itemHeight.toInt()} mm',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Row(
      children: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu, size: 20),
          tooltip: 'Menu',
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'refresh', child: Text('Aggiorna dati')),
            const PopupMenuItem(value: 'export', child: Text('Esporta report')),
            const PopupMenuItem(value: 'print', child: Text('Stampa')),
            const PopupMenuItem(value: 'settings', child: Text('Impostazioni')),
          ],
          onSelected: _handleMenuAction,
        ),
      ],
    );
  }

  Widget _buildViewModeSection() {
    return Row(
      children: [
        IconButton(
          onPressed: () => _changeViewMode(ReportViewMode.singlePage),
          icon: const Icon(Icons.description, size: 18),
          tooltip: 'Pagina singola',
          color: _currentOptions.viewMode == ReportViewMode.singlePage 
              ? Theme.of(context).colorScheme.primary 
              : null,
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          onPressed: () => _changeViewMode(ReportViewMode.continuous),
          icon: const Icon(Icons.view_stream, size: 18),
          tooltip: 'Scorrimento continuo',
          color: _currentOptions.viewMode == ReportViewMode.continuous 
              ? Theme.of(context).colorScheme.primary 
              : null,
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          onPressed: () => _changeViewMode(ReportViewMode.twoPage),
          icon: const Icon(Icons.view_column, size: 18),
          tooltip: 'Vista a due pagine',
          color: _currentOptions.viewMode == ReportViewMode.twoPage 
              ? Theme.of(context).colorScheme.primary 
              : null,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return Row(
      children: [
          if (_currentOptions.enableDataRefresh)
            IconButton(
              onPressed: _isRefreshing ? null : _refreshData,
              icon: _isRefreshing 
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : const Icon(Icons.refresh, size: 18),
              tooltip: _isRefreshing ? 'Aggiornamento in corso...' : 'Aggiorna dati',
              visualDensity: VisualDensity.compact,
            ),
        if (_currentOptions.enableExport)
          IconButton(
            onPressed: _exportReport,
            icon: const Icon(Icons.download, size: 18),
            tooltip: 'Esporta',
            visualDensity: VisualDensity.compact,
          ),
        if (_currentOptions.enableAnnotations)
          Stack(
            children: [
              IconButton(
                onPressed: _toggleAnnotations,
                icon: const Icon(Icons.comment, size: 18),
                tooltip: 'Annotazioni',
                visualDensity: VisualDensity.compact,
              ),
              if (_annotations.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        IconButton(
          onPressed: _toggleSidebar,
          icon: Icon(
            _currentOptions.showSidebar ? Icons.menu_open : Icons.menu,
            size: 18,
          ),
          tooltip: 'Barra laterale',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Informazioni dati
          Text(
            '${widget.data.length} record',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          
          // Filtri attivi
          if (_currentOptions.filters.isNotEmpty) ...[
            const SizedBox(width: 16),
            Icon(
              Icons.filter_alt,
              size: 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '${_currentOptions.filters.where((f) => f.enabled).length} filtri attivi',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          
          const Spacer(),
          
          // Zoom corrente
          Text(
            '${(_currentOptions.scale * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Modalità visualizzazione
          Text(
            _getViewModeLabel(_currentOptions.viewMode),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Sorgente dati
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _dataSource == DataSource.cache 
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _dataSource == DataSource.cache 
                    ? Colors.orange.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
              ),
            ),
            child: Text(
              _getSourceLabel(_dataSource),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _dataSource == DataSource.cache 
                    ? Colors.orange.shade700
                    : Colors.green.shade700,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showZoomMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);

    showMenu<double>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + 100,
        offset.dy + 48,
        offset.dx + 200,
        offset.dy + 200,
      ),
      items: [
        const PopupMenuItem(value: 0.25, child: Text('25%')),
        const PopupMenuItem(value: 0.5, child: Text('50%')),
        const PopupMenuItem(value: 0.75, child: Text('75%')),
        const PopupMenuItem(value: 1.0, child: Text('100%')),
        const PopupMenuItem(value: 1.5, child: Text('150%')),
        const PopupMenuItem(value: 2.0, child: Text('200%')),
        const PopupMenuItem(value: 3.0, child: Text('300%')),
      ],
    ).then((value) {
      if (value != null) {
        _updateZoom(value);
      }
    });
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
               child: Stack(
                 children: [
                   // Report renderer
                   ReportRenderer(
                     template: _template!,
                     data: currentData,
                     schema: _schema,
                     options: _currentOptions,
                   ),
                   
                    // Overlay annotazioni
                    if (_showAnnotations && _currentOptions.enableAnnotations)
                      SessionAnnotationOverlay(
                       reportId: _template!.name,
                       pageIndex: _currentPage,
                       annotations: _annotations.where((a) => a.pageIndex == _currentPage).toList(),
                       enabled: true,
                       onAnnotationAdded: (annotation) {
                         setState(() {
                           _annotations.add(annotation);
                         });
                       },
                       onAnnotationUpdated: (annotation) {
                         setState(() {
                           final index = _annotations.indexWhere((a) => a.id == annotation.id);
                           if (index >= 0) {
                             _annotations[index] = annotation;
                           }
                         });
                       },
                       onAnnotationDeleted: (annotationId) {
                         setState(() {
                           _annotations.removeWhere((a) => a.id == annotationId);
                         });
                       },
                     ),
                 ],
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
    if (_template == null || !mounted) return;
    
    // Calcola la scala per adattare il template allo schermo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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

  // Nuovi metodi per funzionalità report

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _refreshData();
        break;
      case 'export':
        _exportReport();
        break;
      case 'print':
        _printReport();
        break;
      case 'settings':
        _showSettings();
        break;
    }
  }

  void _changeViewMode(ReportViewMode mode) {
    setState(() {
      _currentOptions = _currentOptions.copyWith(viewMode: mode);
    });
  }

  void _toggleSidebar() {
    setState(() {
      _currentOptions = _currentOptions.copyWith(
        showSidebar: !_currentOptions.showSidebar,
      );
    });
  }

  void _refreshData() async {
    if (_isRefreshing || widget.onRefreshData == null || _template == null) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final result = await DataRefreshService.refreshData(
        _template!,
        parameters: _currentOptions.parameters,
        filters: _currentOptions.filters,
        refreshCallback: widget.onRefreshData,
      );
      
      setState(() {
        _dataSource = result.source;
      });
      
      // Notifica il parent con i nuovi dati
      // TODO: Implementare callback per aggiornare dati nel parent
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dati aggiornati da ${_getSourceLabel(result.source)}',
          ),
          backgroundColor: result.source == DataSource.cache 
              ? Colors.orange 
              : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore aggiornamento dati: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  String _getSourceLabel(DataSource source) {
    switch (source) {
      case DataSource.cache:
        return 'Cache';
      case DataSource.remote:
        return 'Server';
    }
  }

  void _exportReport() {
    // TODO: Implementare esportazione report
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Esporta Report',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              subtitle: const Text('Esporta come documento PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportToPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel'),
              subtitle: const Text('Esporta come foglio di calcolo'),
              onTap: () {
                Navigator.pop(context);
                _exportToExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('CSV'),
              subtitle: const Text('Esporta come file CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportToCSV();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportToPDF() async {
    try {
      // TODO: Implementare esportazione PDF completa
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esportazione PDF in sviluppo...'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _showExportError('PDF', e);
    }
  }

  void _exportToExcel() async {
    try {
      final filePath = await ReportExportService.exportToExcel(
        widget.data,
        _template!,
        includeSummary: true,
      );
      
      _showExportSuccess('Excel', filePath);
    } catch (e) {
      _showExportError('Excel', e);
    }
  }

  void _exportToCSV() async {
    try {
      final filePath = await ReportExportService.exportToCSV(
        widget.data,
        _template!,
      );
      
      _showExportSuccess('CSV', filePath);
    } catch (e) {
      _showExportError('CSV', e);
    }
  }

  void _showExportSuccess(String format, String filePath) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Esportazione $format completata!'),
        action: SnackBarAction(
          label: 'Apri',
          onPressed: () {
            // TODO: Implementare apertura file
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showExportError(String format, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Errore esportazione $format: $error'),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _printReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stampa in sviluppo...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Impostazioni Visualizzatore'),
        content: const Text('Impostazioni in sviluppo...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  void _toggleAnnotations() {
    setState(() {
      _showAnnotations = !_showAnnotations;
    });
    
    if (_showAnnotations) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Annotazioni attive (${_annotations.length})'),
          action: SnackBarAction(
            label: 'Gestisci',
            onPressed: _showAnnotationsManager,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showAnnotationsManager() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annotazioni Report'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: _annotations.isEmpty
              ? const Center(
                  child: Text('Nessuna annotazione presente'),
                )
              : ListView.builder(
                  itemCount: _annotations.length,
                  itemBuilder: (context, index) {
                    final annotation = _annotations[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          _getAnnotationIcon(annotation.type),
                          color: _getAnnotationColor(annotation.type),
                        ),
                        title: Text(
                          annotation.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${annotation.author} • ${_formatDate(annotation.createdAt)}',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          onPressed: () => _deleteAnnotation(annotation.id),
                          icon: const Icon(Icons.delete_outline),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAnnotation(String annotationId) async {
    try {
      SessionAnnotationService.deleteAnnotation(_template!.name, annotationId);
      setState(() {
        _annotations.removeWhere((a) => a.id == annotationId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annotazione eliminata')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore eliminazione: $e')),
      );
    }
  }

  IconData _getAnnotationIcon(AnnotationType type) {
    switch (type) {
      case AnnotationType.note:
        return Icons.note;
      case AnnotationType.highlight:
        return Icons.highlight;
      case AnnotationType.comment:
        return Icons.comment;
      case AnnotationType.question:
        return Icons.help;
      case AnnotationType.issue:
        return Icons.error;
    }
  }

  Color _getAnnotationColor(AnnotationType type) {
    switch (type) {
      case AnnotationType.note:
        return Colors.blue;
      case AnnotationType.highlight:
        return Colors.yellow;
      case AnnotationType.comment:
        return Colors.green;
      case AnnotationType.question:
        return Colors.orange;
      case AnnotationType.issue:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _onFiltersChanged(List<ReportFilter> filters) {
    setState(() {
      _currentOptions = _currentOptions.copyWith(filters: filters);
    });
    // TODO: Applicare filtri ai dati
  }

  void _onParametersChanged(Map<String, dynamic> parameters) {
    setState(() {
      _currentOptions = _currentOptions.copyWith(parameters: parameters);
    });
    // TODO: Applicare parametri al report
  }

  void _handleDrillDown(dynamic rowData, String dataSource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Drill-Down'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dettagli record:'),
            const SizedBox(height: 8),
            ...rowData.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      '${entry.key}:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(child: Text(entry.value.toString())),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigare a report dettaglio
            },
            child: const Text('Vai al dettaglio'),
          ),
        ],
      ),
    );
  }

  String _getViewModeLabel(ReportViewMode mode) {
    switch (mode) {
      case ReportViewMode.singlePage:
        return 'Pagina singola';
      case ReportViewMode.continuous:
        return 'Scorrimento continuo';
      case ReportViewMode.twoPage:
        return 'Vista a due pagine';
      case ReportViewMode.dashboard:
        return 'Dashboard';
    }
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