import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/report_element.dart';
import '../models/report_template.dart';
import '../schema/data_schema.dart';
import '../core/data_extractor.dart';
import '../core/report_theme.dart';
import '../export/pdf_exporter.dart';
import '../formats/template_loader.dart';


/// Widget principale per il designer drag-and-drop di report/etichette
class ReportBuilder extends StatefulWidget {
  final ReportTemplate template;
  final dynamic sampleData; // Dati di esempio (non più utilizzato per l'estrazione campi)
  final List<dynamic>? additionalDataSources; // Classi aggiuntive per più dati
  final Function(ReportTemplate)? onTemplateChanged;
  final Function(ReportTemplate)? onSave;

  const ReportBuilder({
    super.key,
    required this.template,
    this.sampleData,
    this.additionalDataSources,
    this.onTemplateChanged,
    this.onSave,
  });

  @override
  State<ReportBuilder> createState() => _ReportBuilderState();
}

class _ReportBuilderState extends State<ReportBuilder> {
  late ReportTemplate _template;
  String? _selectedElementId;
  List<FieldInfo> _availableFields = [];
  Map<String, List<FieldInfo>> _fieldsBySource = {}; // Campi organizzati per sorgente

  // Per il drag
  Offset? _dragOffset;

  // Scala visualizzazione (mm -> pixel)
  double _scale = 3.0;
  
  // Traccia se lo zoom è stato modificato manualmente
  bool _isManualZoom = false;

  // GlobalKey per il canvas per calcolare posizioni
  final GlobalKey _canvasKey = GlobalKey();

  // Linee guida per allineamento
  List<double> _snapLinesX = [];
  List<double> _snapLinesY = [];
  bool _showSnapLines = false;

  // Linee guida attive (vicine all'elemento)
  List<double> _activeSnapLinesX = [];
  List<double> _activeSnapLinesY = [];

  // Soglia di snap in mm (solo visivo, non vincoli)
  static const double _snapThreshold = 2.0; // Soglia per mostrare/attivare snap

  // Traccia se stiamo trascinando un elemento (per bloccare InteractiveViewer)
  bool _isDraggingElement = false;
  String? _draggingElementId;
  Offset? _lastPointerPosition;

  // Resize handling
  bool _isResizingElement = false;
  String? _resizeHandle; // 'topLeft', 'topRight', 'bottomLeft', 'bottomRight', 'left', 'right', 'top', 'bottom'
  static const double _handleSize = 8.0; // Size in pixels
  static const double _minElementSize = 5.0; // Minimum size in mm

  // History per undo/redo
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  static const int _maxHistorySize = 50;

  // Focus node per shortcut tastiera
  final FocusNode _focusNode = FocusNode();

  // Getter per stato undo/redo
  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _template = widget.template.copyWith();
    _extractAllFields();
    // Salva stato iniziale
    _saveToHistory();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _saveToHistory() {
    final state = jsonEncode(_template.toJson());

    // Non salvare se uguale all'ultimo stato
    if (_undoStack.isNotEmpty && _undoStack.last == state) return;

    _undoStack.add(state);
    _redoStack.clear();

    // Limita dimensione history
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (_undoStack.length <= 1) return;

    // Salva stato corrente nel redo
    _redoStack.add(_undoStack.removeLast());

    // Ripristina stato precedente
    if (_undoStack.isNotEmpty) {
      _restoreFromHistory(_undoStack.last);
    }
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    final state = _redoStack.removeLast();
    _undoStack.add(state);
    _restoreFromHistory(state);
  }

  void _restoreFromHistory(String state) {
    try {
      final map = jsonDecode(state) as Map<String, dynamic>;
      setState(() {
        _template = ReportTemplate.fromJson(map);
        _selectedElementId = null;
      });
      widget.onTemplateChanged?.call(_template);
    } catch (e) {
      // Ignora errori di parsing
    }
  }

  void _extractAllFields() {
    _availableFields = [];
    _fieldsBySource = {};

    // Estrai campi dal dataSchema del template (solo se presente)
    if (_template.dataSchema != null) {
      final fields = _template.dataSchema!.fields.map((field) => FieldInfo(
        name: field.name,
        displayName: field.displayName,
        type: field.type is Type ? field.type : String,
        isNested: false,
      )).toList();

      final sourceName = _template.dataSchema!.displayName;
      _fieldsBySource[sourceName] = fields;
      _availableFields.addAll(fields);
    }
    // Se non c'è schema, estrai campi da sampleData
    else if (widget.sampleData != null) {
      Map<String, dynamic>? map;

      // Se è già una Map
      if (widget.sampleData is Map<String, dynamic>) {
        map = widget.sampleData as Map<String, dynamic>;
      }
      // Se ha metodo toMap()
      else {
        try {
          final dynamic obj = widget.sampleData;
          if (obj.toMap != null) {
            map = obj.toMap() as Map<String, dynamic>;
          }
        } catch (_) {
          // Ignora se non ha toMap()
        }
      }

      if (map != null) {
        final fields = map.entries.map((entry) => FieldInfo(
          name: entry.key,
          displayName: _formatDisplayName(entry.key),
          type: _inferType(entry.value),
          isNested: entry.value is Map || entry.value is List,
        )).toList();

        const sourceName = 'Dati';
        _fieldsBySource[sourceName] = fields;
        _availableFields.addAll(fields);
      }
    }

    // Estrai campi dalle sorgenti aggiuntive (solo se presenti)
    if (widget.additionalDataSources != null && widget.additionalDataSources!.isNotEmpty) {
      for (final source in widget.additionalDataSources!) {
        if (source != null) {
          final fields = DataExtractor.extractFields(source);
          final sourceName = source.runtimeType.toString();
          // Aggiungi prefisso per distinguere i campi
          final prefixedFields = fields.map((f) => FieldInfo(
            name: '${sourceName.toLowerCase()}.${f.name}',
            displayName: '[$sourceName] ${f.displayName}',
            type: f.type,
            isNested: f.isNested,
          )).toList();
          _fieldsBySource[sourceName] = prefixedFields;
          _availableFields.addAll(prefixedFields);
        }
      }
    }
  }

  String _formatDisplayName(String name) {
    return name
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ')
        .trim();
  }

  Type _inferType(dynamic value) {
    if (value == null) return String;
    if (value is int) return int;
    if (value is double) return double;
    if (value is bool) return bool;
    if (value is List) return List;
    if (value is Map) return Map;
    return String;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Adatta automaticamente al tema dell'app
    final brightness = Theme.of(context).brightness;
    final primaryColor = Theme.of(context).primaryColor;
    ReportTheme.setDarkMode(brightness == Brightness.dark);
    ReportTheme.setPrimaryColor(primaryColor);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Row(
        children: [
          // Pannello sinistro - Elementi disponibili (larghezza fissa)
          _buildElementsPanel(),

          // Area centrale - Canvas del designer (occupa tutto lo spazio rimanente)
          Expanded(
            child: _buildDesignerCanvas(),
          ),

          // Pannello destro - Proprietà elemento selezionato (larghezza fissa)
          _buildPropertiesPanel(),
        ],
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    // Delete - elimina elemento selezionato
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_selectedElementId != null) {
        _deleteSelectedElement();
        return KeyEventResult.handled;
      }
    }

    // Ctrl+Z - Undo
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
      _undo();
      return KeyEventResult.handled;
    }

    // Ctrl+Y - Redo
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyY) {
      _redo();
      return KeyEventResult.handled;
    }

    // Ctrl+Shift+Z - Redo alternativo
    if (isCtrl && HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.keyZ) {
      _redo();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Pannello con gli elementi trascinabili
  Widget _buildElementsPanel() {
    return Container(
      width: ReportTheme.panelWidth,
      decoration: ReportTheme.panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(ReportTheme.paddingLarge),
            decoration: ReportTheme.panelHeaderDecoration,
            child: Row(
              children: [
                Icon(Icons.widgets, size: ReportTheme.iconSize, color: ReportTheme.primary),
                const SizedBox(width: ReportTheme.paddingMedium),
                Text('Elementi', style: ReportTheme.titleStyle),
              ],
            ),
          ),

          // Lista elementi base
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(ReportTheme.paddingMedium),
              children: [
                _buildSectionHeader('Testo'),
                _buildDraggableElement(ReportElementType.text, 'Testo Statico'),

                _buildSectionHeader('Codici'),
                _buildDraggableElement(ReportElementType.barcode, 'Barcode'),
                _buildDraggableElement(ReportElementType.qrCode, 'QR Code'),

                _buildSectionHeader('Forme'),
                _buildDraggableElement(ReportElementType.line, 'Linea'),
                _buildDraggableElement(ReportElementType.rectangle, 'Rettangolo'),
                _buildDraggableElement(ReportElementType.circle, 'Cerchio'),

                _buildSectionHeader('Controlli'),
                _buildDraggableElement(ReportElementType.checkbox, 'Checkbox'),
                _buildDraggableElement(ReportElementType.textbox, 'Casella Testo'),

                _buildSectionHeader('Altri'),
                _buildDraggableElement(ReportElementType.image, 'Immagine'),
                _buildDraggableElement(ReportElementType.date, 'Data'),

                // Campi disponibili dallo schema dati (solo se schema associato)
                if (_availableFields.isNotEmpty) ...[
                  _buildSectionHeader('Campi Dati'),
                  _buildDraggableElement(ReportElementType.dynamicField, 'Campo Generico'),
                  ..._availableFields
                      .where((f) => !f.isNested)
                      .map((f) => _buildFieldDraggable(f)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: ReportTheme.paddingLarge, bottom: ReportTheme.paddingSmall),
      child: Text(title, style: ReportTheme.sectionHeaderStyle),
    );
  }

  Widget _buildDraggableElement(ReportElementType type, String label) {
    return Draggable<ReportElementType>(
      data: type,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(ReportTheme.borderRadiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ReportTheme.paddingLarge,
            vertical: ReportTheme.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: ReportTheme.primaryLight,
            borderRadius: BorderRadius.circular(ReportTheme.borderRadiusSmall),
          ),
          child: Text(label, style: ReportTheme.bodyStyle),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: ReportTheme.draggableElementDecoration(),
        child: ListTile(
          dense: true,
          leading: Icon(_getIconForType(type), size: ReportTheme.smallIconSize, color: ReportTheme.primary),
          title: Text(label, style: ReportTheme.labelStyle),
          contentPadding: const EdgeInsets.symmetric(horizontal: ReportTheme.paddingMedium),
        ),
      ),
    );
  }

  Widget _buildFieldDraggable(FieldInfo field) {
    return Draggable<FieldInfo>(
      data: field,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(ReportTheme.borderRadiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ReportTheme.paddingLarge,
            vertical: ReportTheme.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: ReportTheme.success.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(ReportTheme.borderRadiusSmall),
          ),
          child: Text(field.displayName, style: ReportTheme.bodyStyle),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: ReportTheme.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ReportTheme.borderRadiusSmall),
          border: Border.all(color: ReportTheme.success.withValues(alpha: 0.3)),
        ),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.data_object, size: ReportTheme.smallIconSize, color: ReportTheme.success),
          title: Text(field.displayName, style: ReportTheme.labelStyle),
          subtitle: Text(field.name, style: TextStyle(fontSize: 9, color: ReportTheme.textHint)),
          contentPadding: const EdgeInsets.symmetric(horizontal: ReportTheme.paddingMedium),
        ),
      ),
    );
  }

  /// Canvas principale del designer - occupa tutto lo spazio disponibile
  Widget _buildDesignerCanvas() {
    return Container(
      color: ReportTheme.canvasBackground,
      child: Column(
        children: [
          // Toolbar
          _buildToolbar(),

          // Canvas - occupa tutto lo spazio rimanente
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calcola scala di riempimento automatico
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _calculateFillScale(constraints);
                });

                return InteractiveViewer(
                  constrained: false, // Permette zoom oltre i limiti del contenitore
                  boundaryMargin: EdgeInsets.all(constraints.maxWidth * 0.5),
                  minScale: 0.05,
                  maxScale: 6.0,
                  panEnabled: !_isDraggingElement,
                  child: Center(
                    child: _buildCanvasWithRulers(constraints),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Calcola la scala per riempire lo schermo
  void _calculateFillScale(BoxConstraints constraints) {
    if (_isManualZoom) return;
    
    final availableWidth = constraints.maxWidth - 100; // Margin per righelli e padding
    final availableHeight = constraints.maxHeight - 100;
    
    final horizontalScale = availableWidth / _template.itemWidth;
    final verticalScale = availableHeight / _template.itemHeight;
    final fillScale = (horizontalScale < verticalScale ? horizontalScale : verticalScale) * 0.85; // 85% per margine
    
    final newScale = fillScale.clamp(0.5, 6.0);
    if ((newScale - _scale).abs() > 0.1) { // Aggiorna solo se la differenza è significativa
      setState(() {
        _scale = newScale;
      });
    }
  }

  /// Canvas con righelli millimetrati
  Widget _buildCanvasWithRulers(BoxConstraints constraints) {
    // Calcola dimensioni canvas
    final canvasWidth = _template.itemWidth * _scale;
    final canvasHeight = _template.itemHeight * _scale;
    const rulerSize = ReportTheme.rulerSize;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Righello orizzontale superiore
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Angolo vuoto
            Container(
              width: rulerSize,
              height: rulerSize,
              color: ReportTheme.rulerBackground,
            ),
            // Righello orizzontale
            CustomPaint(
              size: Size(canvasWidth, rulerSize),
              painter: _HorizontalRulerPainter(
                scale: _scale,
                maxValue: _template.itemWidth,
              ),
            ),
          ],
        ),
        // Righello verticale + Canvas
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Righello verticale
            CustomPaint(
              size: Size(rulerSize, canvasHeight),
              painter: _VerticalRulerPainter(
                scale: _scale,
                maxValue: _template.itemHeight,
              ),
            ),
            // Canvas
            _buildCanvas(),
          ],
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ReportTheme.paddingLarge,
        vertical: ReportTheme.paddingMedium,
      ),
      decoration: ReportTheme.panelHeaderDecoration,
      child: Row(
        children: [
          // Zoom
          IconButton(
            icon: const Icon(Icons.zoom_out, size: ReportTheme.iconSize),
            onPressed: () => setState(() {
              _scale = (_scale - 0.5).clamp(1.0, 6.0);
              _isManualZoom = true;
            }),
            tooltip: 'Zoom -',
            color: ReportTheme.textSecondary,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: ReportTheme.paddingMedium),
            child: Text(
              '${(_scale * 100 / 3).toInt()}%',
              style: ReportTheme.bodyStyle,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, size: ReportTheme.iconSize),
            onPressed: () => setState(() {
              _scale = (_scale + 0.5).clamp(1.0, 6.0);
              _isManualZoom = true;
            }),
            tooltip: 'Zoom +',
            color: ReportTheme.textSecondary,
          ),

          const SizedBox(width: ReportTheme.paddingSmall),

          // Fit to Screen
          IconButton(
            icon: const Icon(Icons.fit_screen, size: ReportTheme.iconSize),
            onPressed: () {
              setState(() {
                _isManualZoom = false; // Resetta per auto-fit
              });
              // Forza ricalcolo immediato
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    _calculateFillScale(renderBox.constraints! as BoxConstraints);
                  }
                }
              });
            },
            tooltip: 'Adatta allo schermo',
            color: ReportTheme.textSecondary,
          ),

          // Actual Size
          IconButton(
            icon: const Icon(Icons.fullscreen, size: ReportTheme.iconSize),
            onPressed: () => setState(() {
              _scale = 3.0; // Scala default
              _isManualZoom = true;
            }),
            tooltip: 'Dimensione reale',
            color: ReportTheme.textSecondary,
          ),

          const SizedBox(width: ReportTheme.paddingXLarge),

          // Dimensioni - cliccabile per modificare
          InkWell(
            onTap: _showSizeDialog,
            borderRadius: BorderRadius.circular(ReportTheme.borderRadiusSmall),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ReportTheme.paddingMedium,
                vertical: ReportTheme.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: ReportTheme.surface,
                borderRadius: BorderRadius.circular(ReportTheme.borderRadiusSmall),
                border: Border.all(color: ReportTheme.panelBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.aspect_ratio, size: 14, color: ReportTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${_template.itemWidth.toInt()}x${_template.itemHeight.toInt()} mm',
                    style: ReportTheme.labelStyle,
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 12, color: ReportTheme.textHint),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Undo/Redo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.undo, size: ReportTheme.iconSize),
                onPressed: _canUndo ? _undo : null,
                tooltip: 'Undo (Ctrl+Z)',
                color: _canUndo ? ReportTheme.textSecondary : ReportTheme.textHint,
              ),
              IconButton(
                icon: const Icon(Icons.redo, size: ReportTheme.iconSize),
                onPressed: _canRedo ? _redo : null,
                tooltip: 'Redo (Ctrl+Y)',
                color: _canRedo ? ReportTheme.textSecondary : ReportTheme.textHint,
              ),
            ],
          ),

          const SizedBox(width: ReportTheme.paddingMedium),

          // Template Management
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.folder_open, size: ReportTheme.iconSize),
                onPressed: _loadTemplate,
                tooltip: 'Carica Template',
                color: ReportTheme.textSecondary,
              ),
              IconButton(
                icon: const Icon(Icons.save, size: ReportTheme.iconSize),
                onPressed: () => widget.onSave?.call(_template),
                tooltip: 'Salva Template',
                color: ReportTheme.primary,
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, size: ReportTheme.iconSize),
                onPressed: _exportToPdf,
                tooltip: 'Esporta PDF',
                color: ReportTheme.error,
              ),
            ],
          ),

          const SizedBox(width: ReportTheme.paddingMedium),

          // Azioni elemento
          if (_selectedElementId != null)
            IconButton(
              icon: const Icon(Icons.delete, size: ReportTheme.iconSize),
              onPressed: _deleteSelectedElement,
              tooltip: 'Elimina',
              color: ReportTheme.error,
            ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    final canvasWidth = _template.itemWidth * _scale;
    final canvasHeight = _template.itemHeight * _scale;

    return DragTarget<Object>(
      key: _canvasKey,
      onAcceptWithDetails: (details) {
        final data = details.data;

        // Usa la GlobalKey per ottenere la posizione corretta del canvas
        final RenderBox? canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
        if (canvasBox == null) return;

        final localPosition = canvasBox.globalToLocal(details.offset);

        // Calcola posizione in mm dove l'utente ha rilasciato
        final x = (localPosition.dx / _scale).clamp(0.0, _template.itemWidth - 20);
        final y = (localPosition.dy / _scale).clamp(0.0, _template.itemHeight - 10);

        if (data is ReportElementType) {
          _addElement(data, x, y);
        } else if (data is FieldInfo) {
          _addFieldElement(data, x, y);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Listener(
          onPointerDown: (event) {
            // Trova quale elemento è sotto il pointer
            final localPos = event.localPosition;
            final xMm = localPos.dx / _scale;
            final yMm = localPos.dy / _scale;

            // Prima controlla se siamo su un handle di resize dell'elemento selezionato
            if (_selectedElementId != null) {
              final selectedElement = _template.getElementById(_selectedElementId!);
              if (selectedElement != null) {
                final handle = _getResizeHandle(selectedElement, xMm, yMm);
                if (handle != null) {
                  _resizeHandle = handle;
                  _lastPointerPosition = event.localPosition;
                  setState(() {
                    _isResizingElement = true;
                    _isDraggingElement = true;
                  });
                  return;
                }
              }
            }

            // Cerca elemento sotto il pointer (in ordine inverso per z-index)
            ReportElement? hitElement;
            for (final element in _template.sortedElements.reversed) {
              if (xMm >= element.x && xMm <= element.x + element.width &&
                  yMm >= element.y && yMm <= element.y + element.height) {
                hitElement = element;
                break;
              }
            }

            if (hitElement != null) {
              _draggingElementId = hitElement.id;
              _lastPointerPosition = event.localPosition;
              setState(() {
                _selectedElementId = hitElement!.id;
                _updateSnapLines(hitElement.id);
                _showSnapLines = true;
                _isDraggingElement = true;
              });
            }
          },
          onPointerMove: (event) {
            if (_lastPointerPosition == null) return;

            final delta = event.localPosition - _lastPointerPosition!;
            _lastPointerPosition = event.localPosition;

            final deltaX = delta.dx / _scale;
            final deltaY = delta.dy / _scale;

            // Gestione resize
            if (_isResizingElement && _selectedElementId != null) {
              final element = _template.getElementById(_selectedElementId!);
              if (element != null) {
                setState(() {
                  _applyResize(element, deltaX, deltaY);
                });
              }
              return;
            }

            // Gestione drag
            if (_draggingElementId == null) return;

            final element = _template.getElementById(_draggingElementId!);
            if (element == null) return;

            double newX = element.x + deltaX;
            double newY = element.y + deltaY;

            newX = newX.clamp(0, _template.itemWidth - element.width);
            newY = newY.clamp(0, _template.itemHeight - element.height);

            setState(() {
              element.x = newX;
              element.y = newY;
              _updateActiveSnapLines(newX, newY, element.width, element.height);
            });
          },
          onPointerUp: (event) {
            // Reset resize state
            if (_isResizingElement) {
              setState(() {
                _isResizingElement = false;
                _isDraggingElement = false;
              });
              _resizeHandle = null;
              _lastPointerPosition = null;
              _notifyChange();
              return;
            }

            if (_draggingElementId == null) return;

            final element = _template.getElementById(_draggingElementId!);
            if (element != null) {
              final snapped = _applySnapOnRelease(element.x, element.y, element.width, element.height);
              setState(() {
                element.x = snapped.dx;
                element.y = snapped.dy;
                _showSnapLines = false;
                _isDraggingElement = false;
                _activeSnapLinesX = [];
                _activeSnapLinesY = [];
              });
              _pushOverlappingElements(element);
              _notifyChange();
            }
            _draggingElementId = null;
            _lastPointerPosition = null;
          },
          child: Container(
              width: canvasWidth,
              height: canvasHeight,
              decoration: BoxDecoration(
                color: ReportTheme.surface,
                border: Border.all(color: ReportTheme.panelBorder),
                boxShadow: ReportTheme.elevatedShadow,
              ),
              child: Stack(
                children: [
                  // Griglia di sfondo
                  CustomPaint(
                    size: Size(canvasWidth, canvasHeight),
                    painter: _GridPainter(scale: _scale),
                  ),

                  // Linee guida di allineamento (solo quelle attive/vicine)
                  if (_showSnapLines) ...[
                    // Linee verticali attive
                    ..._activeSnapLinesX.map((x) => Positioned(
                      left: x * _scale,
                      top: 0,
                      child: Container(
                        width: 1,
                        height: canvasHeight,
                        color: ReportTheme.primary.withValues(alpha: 0.7),
                      ),
                    )),
                    // Linee orizzontali attive
                    ..._activeSnapLinesY.map((y) => Positioned(
                      left: 0,
                      top: y * _scale,
                      child: Container(
                        width: canvasWidth,
                        height: 1,
                        color: ReportTheme.primary.withValues(alpha: 0.7),
                      ),
                    )),
                  ],

                  // Elementi
                  ..._template.sortedElements.map((element) => _buildElementWidget(element)),
                ],
              ),
          ),
        );
      },
    );
  }

  Widget _buildElementWidget(ReportElement element) {
    final isSelected = element.id == _selectedElementId;
    final w = element.width * _scale;
    final h = element.height * _scale;

    return Positioned(
      left: element.x * _scale,
      top: element.y * _scale,
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Elemento principale
            MouseRegion(
              cursor: SystemMouseCursors.move,
              child: Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? ReportTheme.elementSelected : ReportTheme.panelBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected ? ReportTheme.elementSelected.withValues(alpha: 0.1) : null,
                ),
                child: _buildElementPreview(element),
              ),
            ),
            // Resize handles (solo se selezionato)
            if (isSelected) ..._buildResizeHandles(w, h),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResizeHandles(double w, double h) {
    final handleColor = ReportTheme.elementSelected;
    final half = _handleSize / 2;

    Widget buildHandle(double left, double top, MouseCursor cursor) {
      return Positioned(
        left: left - half,
        top: top - half,
        child: MouseRegion(
          cursor: cursor,
          child: Container(
            width: _handleSize,
            height: _handleSize,
            decoration: BoxDecoration(
              color: handleColor,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
        ),
      );
    }

    return [
      // Angoli
      buildHandle(0, 0, SystemMouseCursors.resizeUpLeftDownRight),
      buildHandle(w, 0, SystemMouseCursors.resizeUpRightDownLeft),
      buildHandle(0, h, SystemMouseCursors.resizeUpRightDownLeft),
      buildHandle(w, h, SystemMouseCursors.resizeUpLeftDownRight),
      // Bordi (solo se abbastanza grande)
      if (w > _handleSize * 4) ...[
        buildHandle(w / 2, 0, SystemMouseCursors.resizeUpDown),
        buildHandle(w / 2, h, SystemMouseCursors.resizeUpDown),
      ],
      if (h > _handleSize * 4) ...[
        buildHandle(0, h / 2, SystemMouseCursors.resizeLeftRight),
        buildHandle(w, h / 2, SystemMouseCursors.resizeLeftRight),
      ],
    ];
  }

  Widget _buildElementPreview(ReportElement element) {
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 10;
    final scaledFontSize = fontSize * _scale / 3;

    switch (element.type) {
      case ReportElementType.text:
        return Center(
          child: Text(
            element.properties['text'] ?? 'Testo',
            style: TextStyle(fontSize: scaledFontSize, color: ReportTheme.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        );
      case ReportElementType.dynamicField:
        final fieldName = element.properties['fieldName'] ?? '';
        final prefix = element.properties['prefix'] ?? '';
        final suffix = element.properties['suffix'] ?? '';
        return Center(
          child: Text(
            '$prefix{$fieldName}$suffix',
            style: TextStyle(fontSize: scaledFontSize, color: ReportTheme.primary),
            overflow: TextOverflow.ellipsis,
          ),
        );
      case ReportElementType.barcode:
        return Center(child: Icon(Icons.barcode_reader, color: ReportTheme.textSecondary));
      case ReportElementType.qrCode:
        return Center(child: Icon(Icons.qr_code, color: ReportTheme.textSecondary));
      case ReportElementType.image:
        return Center(child: Icon(Icons.image, color: ReportTheme.textSecondary));
      case ReportElementType.line:
        return Divider(thickness: 1, color: ReportTheme.textPrimary);
      case ReportElementType.rectangle:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: ReportTheme.textPrimary),
          ),
        );
      case ReportElementType.circle:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ReportTheme.textPrimary),
          ),
        );
      case ReportElementType.checkbox:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_box_outline_blank, size: scaledFontSize, color: ReportTheme.textPrimary),
            if ((element.properties['label'] ?? '').isNotEmpty)
              Expanded(
                child: Text(
                  element.properties['label'],
                  style: TextStyle(fontSize: scaledFontSize * 0.8),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
      case ReportElementType.textbox:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: ReportTheme.textSecondary),
            borderRadius: BorderRadius.circular(2),
          ),
          padding: const EdgeInsets.all(2),
          child: Text(
            element.properties['placeholder'] ?? 'Casella testo',
            style: TextStyle(fontSize: scaledFontSize * 0.8, color: ReportTheme.textHint),
            overflow: TextOverflow.ellipsis,
          ),
        );
      default:
        return Center(child: Text(element.displayName, style: TextStyle(fontSize: scaledFontSize)));
    }
  }

  /// Pannello proprietà elemento selezionato
  Widget _buildPropertiesPanel() {
    final selectedElement = _selectedElementId != null
        ? _template.getElementById(_selectedElementId!)
        : null;

    return Container(
      width: ReportTheme.propertiesPanelWidth,
      decoration: ReportTheme.rightPanelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(ReportTheme.paddingLarge),
            decoration: ReportTheme.panelHeaderDecoration,
            child: Row(
              children: [
                Icon(Icons.tune, size: ReportTheme.iconSize, color: ReportTheme.primary),
                const SizedBox(width: ReportTheme.paddingMedium),
                Text('Proprietà', style: ReportTheme.titleStyle),
              ],
            ),
          ),

          // Contenuto
          Expanded(
            child: selectedElement == null
                ? Center(
                    child: Text(
                      'Seleziona un elemento',
                      style: TextStyle(color: ReportTheme.textHint),
                    ),
                  )
                : _buildPropertiesEditor(selectedElement),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesEditor(ReportElement element) {
    return ListView(
      padding: const EdgeInsets.all(ReportTheme.paddingLarge),
      children: [
        // Info elemento
        Text(element.displayName, style: ReportTheme.titleStyle),
        const SizedBox(height: ReportTheme.paddingLarge),

        // ID modificabile
        _buildPropertySection('Identificativo', [
          TextFormField(
            initialValue: element.id,
            decoration: const InputDecoration(labelText: 'ID'),
            onChanged: (newId) {
              if (newId.isNotEmpty && newId != element.id) {
                // Verifica che l'ID non sia già in uso
                final exists = _template.elements.any((e) => e.id == newId && e.id != element.id);
                if (!exists) {
                  final index = _template.elements.indexWhere((e) => e.id == element.id);
                  if (index != -1) {
                    final newElement = element.copyWith(id: newId);
                    _template.elements[index] = newElement;
                    setState(() {
                      _selectedElementId = newId;
                    });
                    _notifyChange();
                  }
                }
              }
            },
          ),
        ]),

        // Posizione
        _buildPropertySection('Posizione', [
          _buildNumberField('X (mm)', element.x, (v) {
            element.x = v;
            _notifyChange();
          }),
          _buildNumberField('Y (mm)', element.y, (v) {
            element.y = v;
            _notifyChange();
          }),
        ]),

        // Dimensioni
        _buildPropertySection('Dimensioni', [
          _buildNumberField('Larghezza (mm)', element.width, (v) {
            element.width = v;
            _notifyChange();
          }),
          _buildNumberField('Altezza (mm)', element.height, (v) {
            element.height = v;
            _notifyChange();
          }),
        ]),

        // Proprietà specifiche per tipo
        ..._buildTypeSpecificProperties(element),
      ],
    );
  }

  Widget _buildPropertySection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ReportTheme.sectionHeaderStyle),
        const SizedBox(height: ReportTheme.paddingMedium),
        ...children,
        const SizedBox(height: ReportTheme.paddingXLarge),
      ],
    );
  }

  Widget _buildNumberField(String label, double value, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ReportTheme.paddingMedium),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: ReportTheme.labelStyle),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: value.toStringAsFixed(1),
              keyboardType: TextInputType.number,
              style: ReportTheme.bodyStyle,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ReportTheme.paddingMedium,
                  vertical: ReportTheme.paddingMedium,
                ),
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null) {
                  onChanged(parsed);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTypeSpecificProperties(ReportElement element) {
    final widgets = <Widget>[];

    // Proprietà comuni di formattazione testo
    if (element.type == ReportElementType.text ||
        element.type == ReportElementType.dynamicField ||
        element.type == ReportElementType.date ||
        element.type == ReportElementType.pageNumber) {
      widgets.add(_buildPropertySection('Formattazione', [
        // Font Size
        _buildNumberField(
          'Dimensione Font',
          (element.properties['fontSize'] as num?)?.toDouble() ?? 10,
          (v) {
            element.properties['fontSize'] = v;
            _notifyChange();
          },
        ),
        // Font Weight
        _buildDropdownField(
          'Peso Font',
          element.properties['fontWeight'] ?? 'normal',
          ['normal', 'bold'],
          (v) {
            element.properties['fontWeight'] = v;
            _notifyChange();
          },
        ),
        // Alignment
        _buildDropdownField(
          'Allineamento',
          element.properties['alignment'] ?? 'left',
          ['left', 'center', 'right'],
          (v) {
            element.properties['alignment'] = v;
            _notifyChange();
          },
        ),
        // Colore testo
        _buildColorField(
          'Colore Testo',
          element.properties['color'] ?? '#000000',
          (v) {
            element.properties['color'] = v;
            _notifyChange();
          },
        ),
        // Colore sfondo
        _buildColorField(
          'Colore Sfondo',
          element.properties['backgroundColor'],
          (v) {
            element.properties['backgroundColor'] = v;
            _notifyChange();
          },
          allowNull: true,
        ),
      ]));
    }

    // Proprietà bordo per tutti gli elementi
    widgets.add(_buildPropertySection('Bordo', [
      _buildNumberField(
        'Spessore Bordo',
        (element.properties['borderWidth'] as num?)?.toDouble() ?? 0,
        (v) {
          element.properties['borderWidth'] = v;
          _notifyChange();
        },
      ),
      _buildColorField(
        'Colore Bordo',
        element.properties['borderColor'] ?? '#000000',
        (v) {
          element.properties['borderColor'] = v;
          _notifyChange();
        },
      ),
    ]));

    // Proprietà specifiche per tipo
    switch (element.type) {
      case ReportElementType.text:
        widgets.insert(0, _buildPropertySection('Contenuto', [
          TextFormField(
            initialValue: element.properties['text'] ?? '',
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Testo'),
            onChanged: (v) {
              element.properties['text'] = v;
              _notifyChange();
            },
          ),
        ]));
        break;

      case ReportElementType.dynamicField:
        widgets.insert(0, _buildPropertySection('Campo Dati', [
          if (_availableFields.isEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nessun campo dati disponibile. Associare uno schema dati al template.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: element.properties['fieldName']?.toString().isEmpty ?? true
                  ? null
                  : element.properties['fieldName'],
              decoration: const InputDecoration(labelText: 'Campo'),
              items: _availableFields
                  .where((f) => !f.isNested)
                  .map((f) => DropdownMenuItem(value: f.name, child: Text(f.displayName)))
                  .toList(),
              onChanged: (v) {
                element.properties['fieldName'] = v;
                _notifyChange();
              },
            ),
          const SizedBox(height: ReportTheme.paddingMedium),
          TextFormField(
            initialValue: element.properties['prefix'] ?? '',
            decoration: const InputDecoration(labelText: 'Prefisso'),
            onChanged: (v) {
              element.properties['prefix'] = v;
              _notifyChange();
            },
          ),
          const SizedBox(height: ReportTheme.paddingMedium),
          TextFormField(
            initialValue: element.properties['suffix'] ?? '',
            decoration: const InputDecoration(labelText: 'Suffisso'),
            onChanged: (v) {
              element.properties['suffix'] = v;
              _notifyChange();
            },
          ),
        ]));
        break;

      case ReportElementType.barcode:
        widgets.insert(0, _buildPropertySection('Barcode', [
          _buildDropdownField(
            'Tipo',
            element.properties['barcodeType'] ?? 'code128',
            ['code128', 'ean13', 'ean8', 'upc', 'code39'],
            (v) {
              element.properties['barcodeType'] = v;
              _notifyChange();
            },
          ),
          SwitchListTile(
            title: const Text('Mostra Testo'),
            value: element.properties['showText'] ?? true,
            onChanged: (v) {
              setState(() {
                element.properties['showText'] = v;
                _notifyChange();
              });
            },
          ),
        ]));
        break;

      case ReportElementType.rectangle:
        widgets.insert(0, _buildPropertySection('Rettangolo', [
          _buildNumberField(
            'Raggio Bordo',
            (element.properties['borderRadius'] as num?)?.toDouble() ?? 0,
            (v) {
              element.properties['borderRadius'] = v;
              _notifyChange();
            },
          ),
          _buildColorField(
            'Colore Riempimento',
            element.properties['fillColor'],
            (v) {
              element.properties['fillColor'] = v;
              _notifyChange();
            },
            allowNull: true,
          ),
        ]));
        break;

      case ReportElementType.line:
        widgets.insert(0, _buildPropertySection('Linea', [
          _buildNumberField(
            'Spessore',
            (element.properties['strokeWidth'] as num?)?.toDouble() ?? 1,
            (v) {
              element.properties['strokeWidth'] = v;
              _notifyChange();
            },
          ),
          _buildColorField(
            'Colore',
            element.properties['color'] ?? '#000000',
            (v) {
              element.properties['color'] = v;
              _notifyChange();
            },
          ),
        ]));
        break;

      case ReportElementType.checkbox:
        widgets.insert(0, _buildPropertySection('Checkbox', [
          if (_availableFields.isEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nessun campo dati disponibile. Associare uno schema dati al template.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: element.properties['fieldName']?.toString().isEmpty ?? true
                  ? null
                  : element.properties['fieldName'],
              decoration: const InputDecoration(labelText: 'Campo Booleano'),
              items: _availableFields
                  .where((f) => !f.isNested)
                  .map((f) => DropdownMenuItem(value: f.name, child: Text(f.displayName)))
                  .toList(),
              onChanged: (v) {
                element.properties['fieldName'] = v;
                _notifyChange();
              },
            ),
          const SizedBox(height: ReportTheme.paddingMedium),
          TextFormField(
            initialValue: element.properties['label'] ?? '',
            decoration: const InputDecoration(labelText: 'Etichetta'),
            onChanged: (v) {
              element.properties['label'] = v;
              _notifyChange();
            },
          ),
          const SizedBox(height: ReportTheme.paddingMedium),
          _buildNumberField(
            'Dimensione',
            (element.properties['size'] as num?)?.toDouble() ?? 12,
            (v) {
              element.properties['size'] = v;
              _notifyChange();
            },
          ),
        ]));
        break;

      case ReportElementType.textbox:
        widgets.insert(0, _buildPropertySection('Casella Testo', [
          if (_availableFields.isEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nessun campo dati disponibile. Associare uno schema dati al template.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: element.properties['fieldName']?.toString().isEmpty ?? true
                  ? null
                  : element.properties['fieldName'],
              decoration: const InputDecoration(labelText: 'Campo'),
              items: _availableFields
                  .where((f) => !f.isNested)
                  .map((f) => DropdownMenuItem(value: f.name, child: Text(f.displayName)))
                  .toList(),
              onChanged: (v) {
                element.properties['fieldName'] = v;
                _notifyChange();
              },
            ),
          const SizedBox(height: ReportTheme.paddingMedium),
          TextFormField(
            initialValue: element.properties['placeholder'] ?? '',
            decoration: const InputDecoration(labelText: 'Placeholder'),
            onChanged: (v) {
              element.properties['placeholder'] = v;
              _notifyChange();
            },
          ),
          const SizedBox(height: ReportTheme.paddingMedium),
          _buildNumberField(
            'Righe Max',
            (element.properties['maxLines'] as num?)?.toDouble() ?? 1,
            (v) {
              element.properties['maxLines'] = v.toInt();
              _notifyChange();
            },
          ),
        ]));
        break;

      default:
        break;
    }

    return widgets;
  }

  Widget _buildDropdownField(String label, String value, List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ReportTheme.paddingMedium),
      child: DropdownButtonFormField<String>(
        value: options.contains(value) ? value : options.first,
        decoration: InputDecoration(labelText: label),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildColorField(String label, String? value, Function(String?) onChanged, {bool allowNull = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ReportTheme.paddingMedium),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: ReportTheme.labelStyle),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Anteprima colore
                GestureDetector(
                  onTap: () => _showColorPicker(value, onChanged, allowNull),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: value != null ? _parseColor(value) : Colors.transparent,
                      border: Border.all(color: ReportTheme.panelBorder),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: value == null ? const Icon(Icons.block, size: 16, color: Colors.grey) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value ?? 'Nessuno',
                    style: ReportTheme.labelStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(String? currentValue, Function(String?) onChanged, bool allowNull) {
    final colors = [
      if (allowNull) null,
      '#000000', '#FFFFFF', '#FF0000', '#00FF00', '#0000FF',
      '#FFFF00', '#FF00FF', '#00FFFF', '#808080', '#C0C0C0',
      '#800000', '#008000', '#000080', '#808000', '#800080',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleziona Colore'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                onChanged(color);
                Navigator.pop(context);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color != null ? _parseColor(color) : Colors.transparent,
                  border: Border.all(
                    color: currentValue == color ? ReportTheme.primary : ReportTheme.panelBorder,
                    width: currentValue == color ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: color == null ? const Icon(Icons.block, size: 20) : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // Helper methods

  IconData _getIconForType(ReportElementType type) {
    switch (type) {
      case ReportElementType.text:
        return Icons.text_fields;
      case ReportElementType.dynamicField:
        return Icons.data_object;
      case ReportElementType.barcode:
        return Icons.qr_code_2;
      case ReportElementType.qrCode:
        return Icons.qr_code;
      case ReportElementType.image:
        return Icons.image;
      case ReportElementType.line:
        return Icons.horizontal_rule;
      case ReportElementType.rectangle:
        return Icons.rectangle_outlined;
      case ReportElementType.circle:
        return Icons.circle_outlined;
      case ReportElementType.checkbox:
        return Icons.check_box;
      case ReportElementType.textbox:
        return Icons.text_snippet;
      default:
        return Icons.widgets;
    }
  }

  void _addElement(ReportElementType type, double x, double y) {
    final id = '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
    final element = ReportElement(
      id: id,
      type: type,
      x: x,
      y: y,
    );

    // Trova posizione libera se c'è sovrapposizione
    final adjustedElement = _findFreePosition(element);

    setState(() {
      _template.addElement(adjustedElement);
      _selectedElementId = id;
    });
    _notifyChange();
  }

  void _addFieldElement(FieldInfo field, double x, double y) {
    final id = 'field_${DateTime.now().millisecondsSinceEpoch}';
    final element = ReportElement(
      id: id,
      type: ReportElementType.dynamicField,
      x: x,
      y: y,
      properties: {
        'fieldName': field.name,
        'fontSize': 10.0,
        'prefix': '',
        'suffix': '',
      },
    );

    // Trova posizione libera se c'è sovrapposizione
    final adjustedElement = _findFreePosition(element);

    setState(() {
      _template.addElement(adjustedElement);
      _selectedElementId = id;
    });
    _notifyChange();
  }

  /// Trova una posizione libera per l'elemento evitando sovrapposizioni
  ReportElement _findFreePosition(ReportElement element) {
    var x = element.x;
    var y = element.y;
    var attempts = 0;
    const maxAttempts = 50;

    while (_hasOverlap(element.id, x, y, element.width, element.height) && attempts < maxAttempts) {
      // Sposta a destra o in basso
      x += 5;
      if (x + element.width > _template.itemWidth) {
        x = 0;
        y += 5;
      }
      if (y + element.height > _template.itemHeight) {
        // Non c'è più spazio, lascia dove era
        break;
      }
      attempts++;
    }

    return element.copyWith(x: x, y: y);
  }

  /// Verifica se c'è sovrapposizione con altri elementi
  bool _hasOverlap(String elementId, double x, double y, double width, double height) {
    for (final other in _template.elements) {
      if (other.id == elementId) continue;

      // Controlla intersezione rettangoli
      final overlapsX = x < other.x + other.width && x + width > other.x;
      final overlapsY = y < other.y + other.height && y + height > other.y;

      if (overlapsX && overlapsY) {
        return true;
      }
    }
    return false;
  }

  void _deleteSelectedElement() {
    if (_selectedElementId != null) {
      setState(() {
        _template.removeElement(_selectedElementId!);
        _selectedElementId = null;
      });
      _notifyChange();
    }
  }

  /// Determina quale handle di resize è sotto il cursore
  String? _getResizeHandle(ReportElement element, double xMm, double yMm) {
    if (element.id != _selectedElementId) return null;

    final handleSizeMm = _handleSize / _scale;
    final x = element.x;
    final y = element.y;
    final w = element.width;
    final h = element.height;

    // Angoli
    if (_isInHandle(xMm, yMm, x, y, handleSizeMm)) return 'topLeft';
    if (_isInHandle(xMm, yMm, x + w, y, handleSizeMm)) return 'topRight';
    if (_isInHandle(xMm, yMm, x, y + h, handleSizeMm)) return 'bottomLeft';
    if (_isInHandle(xMm, yMm, x + w, y + h, handleSizeMm)) return 'bottomRight';

    // Bordi (solo se l'elemento è abbastanza grande)
    if (w > handleSizeMm * 3) {
      if (_isInHandle(xMm, yMm, x + w / 2, y, handleSizeMm)) return 'top';
      if (_isInHandle(xMm, yMm, x + w / 2, y + h, handleSizeMm)) return 'bottom';
    }
    if (h > handleSizeMm * 3) {
      if (_isInHandle(xMm, yMm, x, y + h / 2, handleSizeMm)) return 'left';
      if (_isInHandle(xMm, yMm, x + w, y + h / 2, handleSizeMm)) return 'right';
    }

    return null;
  }

  bool _isInHandle(double xMm, double yMm, double hx, double hy, double size) {
    return (xMm - hx).abs() <= size && (yMm - hy).abs() <= size;
  }

  /// Applica il resize basato sul delta e sull'handle attivo
  void _applyResize(ReportElement element, double deltaX, double deltaY) {
    double newX = element.x;
    double newY = element.y;
    double newW = element.width;
    double newH = element.height;

    switch (_resizeHandle) {
      case 'topLeft':
        newX += deltaX;
        newY += deltaY;
        newW -= deltaX;
        newH -= deltaY;
        break;
      case 'topRight':
        newY += deltaY;
        newW += deltaX;
        newH -= deltaY;
        break;
      case 'bottomLeft':
        newX += deltaX;
        newW -= deltaX;
        newH += deltaY;
        break;
      case 'bottomRight':
        newW += deltaX;
        newH += deltaY;
        break;
      case 'top':
        newY += deltaY;
        newH -= deltaY;
        break;
      case 'bottom':
        newH += deltaY;
        break;
      case 'left':
        newX += deltaX;
        newW -= deltaX;
        break;
      case 'right':
        newW += deltaX;
        break;
    }

    // Applica dimensioni minime
    if (newW < _minElementSize) {
      if (_resizeHandle!.contains('Left')) {
        newX = element.x + element.width - _minElementSize;
      }
      newW = _minElementSize;
    }
    if (newH < _minElementSize) {
      if (_resizeHandle!.contains('top') || _resizeHandle == 'top') {
        newY = element.y + element.height - _minElementSize;
      }
      newH = _minElementSize;
    }

    // Mantieni dentro i limiti del canvas
    newX = newX.clamp(0.0, _template.itemWidth - newW);
    newY = newY.clamp(0.0, _template.itemHeight - newH);

    element.x = newX;
    element.y = newY;
    element.width = newW;
    element.height = newH;
  }

  /// Calcola le linee guida basate sugli altri elementi
  void _updateSnapLines(String? excludeId) {
    _snapLinesX = [];
    _snapLinesY = [];

    for (final element in _template.elements) {
      if (element.id == excludeId) continue;

      // Bordi verticali (X)
      _snapLinesX.add(element.x); // sinistro
      _snapLinesX.add(element.x + element.width / 2); // centro
      _snapLinesX.add(element.x + element.width); // destro

      // Bordi orizzontali (Y)
      _snapLinesY.add(element.y); // superiore
      _snapLinesY.add(element.y + element.height / 2); // centro
      _snapLinesY.add(element.y + element.height); // inferiore
    }
  }

  /// Aggiorna le linee guida attive (vicine all'elemento durante il drag)
  void _updateActiveSnapLines(double x, double y, double width, double height) {
    _activeSnapLinesX = [];
    _activeSnapLinesY = [];

    // Trova guide vicine per X
    for (final guide in _snapLinesX) {
      final distLeft = (x - guide).abs();
      final distCenter = (x + width / 2 - guide).abs();
      final distRight = (x + width - guide).abs();

      if (distLeft <= _snapThreshold || distCenter <= _snapThreshold || distRight <= _snapThreshold) {
        if (!_activeSnapLinesX.contains(guide)) {
          _activeSnapLinesX.add(guide);
        }
      }
    }

    // Trova guide vicine per Y
    for (final guide in _snapLinesY) {
      final distTop = (y - guide).abs();
      final distCenter = (y + height / 2 - guide).abs();
      final distBottom = (y + height - guide).abs();

      if (distTop <= _snapThreshold || distCenter <= _snapThreshold || distBottom <= _snapThreshold) {
        if (!_activeSnapLinesY.contains(guide)) {
          _activeSnapLinesY.add(guide);
        }
      }
    }
  }

  /// Applica lo snap al rilascio solo se ci sono linee attive visibili
  Offset _applySnapOnRelease(double x, double y, double width, double height) {
    double snappedX = x;
    double snappedY = y;
    double minDistX = double.infinity;
    double minDistY = double.infinity;

    // Snap solo alle linee attive (visibili)
    for (final guide in _activeSnapLinesX) {
      // Bordo sinistro
      final distLeft = (x - guide).abs();
      if (distLeft < minDistX && distLeft <= _snapThreshold) {
        minDistX = distLeft;
        snappedX = guide;
      }
      // Centro
      final distCenter = (x + width / 2 - guide).abs();
      if (distCenter < minDistX && distCenter <= _snapThreshold) {
        minDistX = distCenter;
        snappedX = guide - width / 2;
      }
      // Bordo destro
      final distRight = (x + width - guide).abs();
      if (distRight < minDistX && distRight <= _snapThreshold) {
        minDistX = distRight;
        snappedX = guide - width;
      }
    }

    for (final guide in _activeSnapLinesY) {
      // Bordo superiore
      final distTop = (y - guide).abs();
      if (distTop < minDistY && distTop <= _snapThreshold) {
        minDistY = distTop;
        snappedY = guide;
      }
      // Centro
      final distCenter = (y + height / 2 - guide).abs();
      if (distCenter < minDistY && distCenter <= _snapThreshold) {
        minDistY = distCenter;
        snappedY = guide - height / 2;
      }
      // Bordo inferiore
      final distBottom = (y + height - guide).abs();
      if (distBottom < minDistY && distBottom <= _snapThreshold) {
        minDistY = distBottom;
        snappedY = guide - height;
      }
    }

    return Offset(snappedX, snappedY);
  }

  /// Sposta gli elementi sovrapposti per evitare sovrapposizioni
  void _pushOverlappingElements(ReportElement movedElement) {
    const minGap = 1.0; // mm di distanza minima
    bool changed = true;
    int iterations = 0;
    const maxIterations = 20;

    while (changed && iterations < maxIterations) {
      changed = false;
      iterations++;

      for (final other in _template.elements) {
        if (other.id == movedElement.id) continue;

        // Controlla sovrapposizione
        final overlapsX = movedElement.x < other.x + other.width &&
                          movedElement.x + movedElement.width > other.x;
        final overlapsY = movedElement.y < other.y + other.height &&
                          movedElement.y + movedElement.height > other.y;

        if (overlapsX && overlapsY) {
          // Calcola la direzione di push migliore (minimo spostamento)
          final pushRight = (movedElement.x + movedElement.width) - other.x;
          final pushLeft = (other.x + other.width) - movedElement.x;
          final pushDown = (movedElement.y + movedElement.height) - other.y;
          final pushUp = (other.y + other.height) - movedElement.y;

          final minPush = [pushRight, pushLeft, pushDown, pushUp].reduce((a, b) => a < b ? a : b);

          if (minPush == pushRight) {
            other.x = movedElement.x + movedElement.width + minGap;
          } else if (minPush == pushLeft) {
            other.x = movedElement.x - other.width - minGap;
          } else if (minPush == pushDown) {
            other.y = movedElement.y + movedElement.height + minGap;
          } else {
            other.y = movedElement.y - other.height - minGap;
          }

          // Mantieni nei limiti del canvas
          other.x = other.x.clamp(0, _template.itemWidth - other.width);
          other.y = other.y.clamp(0, _template.itemHeight - other.height);
          changed = true;
        }
      }
    }
  }

  void _notifyChange({bool saveHistory = true}) {
    if (saveHistory) {
      _saveToHistory();
    }
    widget.onTemplateChanged?.call(_template);
  }

  void _showSizeDialog() {
    final widthController = TextEditingController(text: _template.itemWidth.toStringAsFixed(0));
    final heightController = TextEditingController(text: _template.itemHeight.toStringAsFixed(0));
    bool isLandscape = _template.itemWidth > _template.itemHeight;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dimensioni Pagina'),
        content: SizedBox(
          width: 400,
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Orientamento
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stay_current_portrait, size: 16),
                            SizedBox(width: 4),
                            Text('Verticale'),
                          ],
                        ),
                        selected: !isLandscape,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              isLandscape = false;
                              final w = double.tryParse(widthController.text) ?? 210;
                              final h = double.tryParse(heightController.text) ?? 297;
                              if (w < h) {
                                widthController.text = h.toString();
                                heightController.text = w.toString();
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stay_current_landscape, size: 16),
                            SizedBox(width: 4),
                            Text('Orizzontale'),
                          ],
                        ),
                        selected: isLandscape,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              isLandscape = true;
                              final w = double.tryParse(widthController.text) ?? 210;
                              final h = double.tryParse(heightController.text) ?? 297;
                              if (w > h) {
                                widthController.text = h.toString();
                                heightController.text = w.toString();
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Preset comuni
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSizePreset('A4', isLandscape ? 297 : 210, isLandscape ? 210 : 297, widthController, heightController),
                    _buildSizePreset('A5', isLandscape ? 210 : 148, isLandscape ? 148 : 210, widthController, heightController),
                    _buildSizePreset('A6', isLandscape ? 148 : 105, isLandscape ? 105 : 148, widthController, heightController),
                    _buildSizePreset('Etichetta', 50, 30, widthController, heightController),
                    _buildSizePreset('Biglietto', 85, 55, widthController, heightController),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                // Input manuali
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widthController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Larghezza (mm)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Altezza (mm)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final width = double.tryParse(widthController.text);
              final height = double.tryParse(heightController.text);
              if (width != null && height != null && width > 0 && height > 0) {
                this.setState(() {
                  _template.itemWidth = width;
                  _template.itemHeight = height;
                });
                _notifyChange();
                Navigator.pop(context);
              }
            },
            child: const Text('Applica'),
          ),
        ],
      ),
    );
  }

  Widget _buildSizePreset(String name, double width, double height,
      TextEditingController widthCtrl, TextEditingController heightCtrl) {
    return ActionChip(
      label: Text('$name\n${width.toInt()}x${height.toInt()}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10),
      ),
      onPressed: () {
        widthCtrl.text = width.toString();
        heightCtrl.text = height.toString();
      },
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Metodi aggiuntivi per _ReportBuilderState
extension ReportBuilderMethods on _ReportBuilderState {
  /// Carica un template da file
  Future<void> _loadTemplate() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['rpt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final templateWithSchema = await TemplateLoader.fromFile(result.files.single.path!);
        
        if (mounted) {
          setState(() {
            _template = templateWithSchema.template;
            _selectedElementId = null;
            _extractAllFields();
            _saveToHistory();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template caricato con successo'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel caricare il template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Esporta il template in PDF
  Future<void> _exportToPdf() async {
    try {
      // Mostra dialog per salvare
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Esporta PDF',
        fileName: '${_template.name}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        // Usa dati di esempio se disponibili
        final sampleData = _template.getSampleData();
        final dataList = sampleData.isNotEmpty ? [sampleData] : [{}];
        
        await PdfExporter.exportToPdf(
          template: _template,
          data: dataList,
          filePath: result,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF esportato con successo'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nell\'esportare PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Painter per la griglia di sfondo
class _GridPainter extends CustomPainter {
  final double scale;

  _GridPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ReportTheme.panelBorder
      ..strokeWidth = 0.5;

    // Griglia ogni 5mm
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

/// Painter per righello orizzontale
class _HorizontalRulerPainter extends CustomPainter {
  final double scale;
  final double maxValue;

  _HorizontalRulerPainter({required this.scale, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ReportTheme.rulerLine
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Sfondo righello
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = ReportTheme.rulerBackground,
    );

    // Tacche e numeri
    for (int mm = 0; mm <= maxValue.toInt(); mm++) {
      final x = mm * scale;

      if (mm % 10 == 0) {
        // Tacca grande ogni 10mm (1cm)
        canvas.drawLine(
          Offset(x, size.height - 12),
          Offset(x, size.height),
          paint,
        );
        // Numero
        textPainter.text = TextSpan(
          text: '${mm ~/ 10}',
          style: TextStyle(
            color: ReportTheme.rulerText,
            fontSize: 8,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, 2),
        );
      } else if (mm % 5 == 0) {
        // Tacca media ogni 5mm
        canvas.drawLine(
          Offset(x, size.height - 8),
          Offset(x, size.height),
          paint,
        );
      } else {
        // Tacca piccola ogni mm
        canvas.drawLine(
          Offset(x, size.height - 4),
          Offset(x, size.height),
          paint,
        );
      }
    }

    // Linea di base
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter per righello verticale
class _VerticalRulerPainter extends CustomPainter {
  final double scale;
  final double maxValue;

  _VerticalRulerPainter({required this.scale, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ReportTheme.rulerLine
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Sfondo righello
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = ReportTheme.rulerBackground,
    );

    // Tacche e numeri
    for (int mm = 0; mm <= maxValue.toInt(); mm++) {
      final y = mm * scale;

      if (mm % 10 == 0) {
        // Tacca grande ogni 10mm (1cm)
        canvas.drawLine(
          Offset(size.width - 12, y),
          Offset(size.width, y),
          paint,
        );
        // Numero
        textPainter.text = TextSpan(
          text: '${mm ~/ 10}',
          style: TextStyle(
            color: ReportTheme.rulerText,
            fontSize: 8,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(2, y - textPainter.height / 2),
        );
      } else if (mm % 5 == 0) {
        // Tacca media ogni 5mm
        canvas.drawLine(
          Offset(size.width - 8, y),
          Offset(size.width, y),
          paint,
        );
      } else {
        // Tacca piccola ogni mm
        canvas.drawLine(
          Offset(size.width - 4, y),
          Offset(size.width, y),
          paint,
        );
      }
    }

    // Linea di base
    canvas.drawLine(
      Offset(size.width - 1, 0),
      Offset(size.width - 1, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
