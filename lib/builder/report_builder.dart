// The extensions below are part of _ReportBuilderState and call its setState.
// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import '../models/report_element.dart';
import '../models/report_template.dart';
import '../core/data_extractor.dart';
import '../theme/theme.dart';
import '../export/pdf_exporter.dart';
import '../formats/template_loader.dart';
import '../viewer/report_viewer.dart';
import '../viewer/renderers/report_renderer.dart';
import '../l10n/report_l10n.dart';

/// Main widget of the drag-and-drop report/label designer
class ReportBuilder extends StatefulWidget {
  final ReportTemplate template;
  final dynamic
  sampleData; // Sample data (no longer used to extract the fields)
  final List<dynamic>?
  additionalDataSources; // Extra classes for more data sources
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

class _ReportBuilderState extends State<ReportBuilder>
    with SingleTickerProviderStateMixin {
  late ReportTemplate _template;
  String? _selectedElementId;
  List<FieldInfo> _availableFields = [];
  Map<String, List<FieldInfo>> _fieldsBySource = {}; // Fields grouped by source

  // Display scale (mm -> pixel)
  double _scale = 1.0;

  // Whether the zoom was changed by hand
  bool _isManualZoom = false;

  final FocusNode _dialogFocusNode = FocusNode();

  // Debouncer that prevents repeated calls
  Timer? _changeTimer;

  // Canvas key, used to compute positions
  final GlobalKey _canvasKey = GlobalKey();

  // Alignment guide lines
  List<double> _snapLinesX = [];
  List<double> _snapLinesY = [];
  bool _showSnapLines = false;

  // Active guide lines (near the element)
  List<double> _activeSnapLinesX = [];
  List<double> _activeSnapLinesY = [];

  static const double _snapThreshold =
      2.0; // Snap threshold in mm (visual only, not a constraint)

  // Whether an element is being dragged (locks the InteractiveViewer)
  bool _isDraggingElement = false;
  String? _draggingElementId;
  Offset? _lastPointerPosition;

  // Resize handling
  bool _isResizingElement = false;
  String?
  _resizeHandle; // 'topLeft', 'topRight', 'bottomLeft', 'bottomRight', 'left', 'right', 'top', 'bottom'
  static const double _handleSize = 8.0; // Size in pixels
  static const double _minElementSize = 5.0; // Minimum size in mm

  // Undo/redo history
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  static const int _maxHistorySize = 50;

  final FocusNode _focusNode = FocusNode();

  late TabController _tabController;

  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _template = widget.template.copyWith();
    // A line is as tall as its thickness: fixes lines saved
    // with the height of a generic box.
    for (final element in _template.elements) {
      if (element.type == ReportElementType.line) {
        element.height = _lineThickness(element);
      }
    }
    _extractAllFields();
    // Save the initial state
    _saveToHistory();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _focusNode.dispose();
    _changeTimer?.cancel();
    super.dispose();
  }

  void _saveToHistory() {
    final state = jsonEncode(_template.toJson());

    // Skip saving when equal to the last state
    if (_undoStack.isNotEmpty && _undoStack.last == state) return;

    _undoStack.add(state);
    _redoStack.clear();

    // Limit the history size
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (_undoStack.length <= 1) return;

    _redoStack.add(_undoStack.removeLast());

    // Restore the previous state
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
      // Ignore parsing errors
    }
  }

  void _extractAllFields() {
    _availableFields = [];
    _fieldsBySource = {};

    // Extract the fields from the template dataSchema (if any)
    if (_template.dataSchema != null) {
      final fields = _template.dataSchema!.fields
          .map(
            (field) => FieldInfo(
              name: field.name,
              displayName: field.displayName,
              type: field.type,
              isNested: false,
            ),
          )
          .toList();

      final sourceName = _template.dataSchema!.displayName;
      _fieldsBySource[sourceName] = fields;
      _availableFields.addAll(fields);
    }
    // Without a schema, extract the fields from sampleData
    else if (widget.sampleData != null) {
      Map<String, dynamic>? map;

      if (widget.sampleData is Map<String, dynamic>) {
        map = widget.sampleData as Map<String, dynamic>;
      } else {
        try {
          final dynamic obj = widget.sampleData;
          if (obj.toMap != null) {
            map = obj.toMap() as Map<String, dynamic>;
          }
        } catch (_) {
          // Skip objects without toMap()
        }
      }

      if (map != null) {
        final fields = map.entries
            .map(
              (entry) => FieldInfo(
                name: entry.key,
                displayName: _formatDisplayName(entry.key),
                type: _inferType(entry.value),
                isNested: entry.value is Map || entry.value is List,
              ),
            )
            .toList();

        const sourceName = 'Data';
        _fieldsBySource[sourceName] = fields;
        _availableFields.addAll(fields);
      }
    }

    // Extract the fields of the extra sources (if any)
    if (widget.additionalDataSources != null &&
        widget.additionalDataSources!.isNotEmpty) {
      for (final source in widget.additionalDataSources!) {
        if (source != null) {
          final fields = DataExtractor.extractFields(source);
          final sourceName = source.runtimeType.toString();
          // Prefix to tell the fields apart
          final prefixedFields = fields
              .map(
                (f) => FieldInfo(
                  name: '${sourceName.toLowerCase()}.${f.name}',
                  displayName: '[$sourceName] ${f.displayName}',
                  type: f.type,
                  isNested: f.isNested,
                ),
              )
              .toList();
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
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '',
        )
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
    // Follows the app theme automatically
    final brightness = Theme.of(context).brightness;
    final primaryColor = Theme.of(context).colorScheme.primary;
    AppTheme.setDarkMode(brightness == Brightness.dark);
    AppTheme.setPrimaryColor(primaryColor);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Material(
        child: Column(
          children: [
            // Tab bar
            Container(
              color: AppTheme.panelBackground,
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: Icon(Icons.edit),
                    text: context.reportL10n.builderTabDesigner,
                  ),
                  Tab(
                    icon: Icon(Icons.preview),
                    text: context.reportL10n.printPreviewTitle,
                  ),
                ],
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Designer tab
                  Row(
                    children: [
                      _buildElementsPanel(),
                      Expanded(child: _buildDesignerCanvas()),
                      _buildPropertiesPanel(),
                    ],
                  ),
                  // Preview tab
                  _buildPreviewTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Preview tab with ReportViewer
  Widget _buildPreviewTab() {
    Map<String, dynamic>? sampleData;
    if (widget.sampleData != null) {
      if (widget.sampleData is Map<String, dynamic>) {
        sampleData = widget.sampleData as Map<String, dynamic>;
      } else {
        try {
          final dynamic obj = widget.sampleData;
          if (obj.toMap != null) {
            sampleData = obj.toMap() as Map<String, dynamic>;
          }
        } catch (_) {}
      }
    }

    if (_template.elements.isEmpty) {
      return Container(
        color: AppTheme.canvasBackground,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.preview, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                context.reportL10n.builderNoElements,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                context.reportL10n.builderNoElementsHelp,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final dataList = sampleData != null ? [sampleData] : [<String, dynamic>{}];

    // SizedBox.expand gives explicit constraints to the inner Column of ReportViewer
    return SizedBox.expand(
      child: ReportViewer(
        template: _template,
        data: dataList,
        options: const ReportViewerOptions(enableZoom: true, enablePan: true),
        enablePagination: false,
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    // Delete removes the selected element, unless a text field is being edited
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      final currentFocus = FocusManager.instance.primaryFocus;

      // EditableText is the inner widget of TextField and TextFormField
      bool isTextFocused = false;
      if (currentFocus != null) {
        final context = currentFocus.context;
        if (context != null) {
          final editableText = context
              .findAncestorWidgetOfExactType<EditableText>();
          isTextFocused = editableText != null || _dialogFocusNode.hasFocus;
        }
      }

      if (_selectedElementId != null && !isTextFocused) {
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

    // Ctrl+Shift+Z - alternative Redo
    if (isCtrl &&
        HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.keyZ) {
      _redo();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Panel with the draggable elements
  Widget _buildElementsPanel() {
    return Container(
      width: AppTheme.panelWidth,
      decoration: AppTheme.panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingLarge),
            decoration: AppTheme.panelHeaderDecoration,
            child: Row(
              children: [
                Icon(
                  Icons.widgets,
                  size: AppTheme.iconSize,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: AppTheme.paddingMedium),
                Text(
                  context.reportL10n.builderElements,
                  style: AppTheme.titleStyle,
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              children: [
                _buildSectionHeader(context.reportL10n.builderText),
                _buildDraggableElement(
                  ReportElementType.text,
                  context.reportL10n.builderStaticText,
                ),
                _buildDraggableElement(ReportElementType.formula, 'Formula'),
                _buildDraggableElement(ReportElementType.markdown, 'Markdown'),

                _buildSectionHeader(context.reportL10n.builderGroupCodes),
                _buildDraggableElement(ReportElementType.barcode, 'Barcode'),
                _buildDraggableElement(ReportElementType.qrCode, 'QR Code'),

                _buildSectionHeader(context.reportL10n.builderGroupShapes),
                _buildDraggableElement(
                  ReportElementType.line,
                  context.reportL10n.builderLine,
                ),
                _buildDraggableElement(
                  ReportElementType.rectangle,
                  context.reportL10n.builderRectangle,
                ),
                _buildDraggableElement(
                  ReportElementType.circle,
                  context.reportL10n.builderCircle,
                ),

                _buildSectionHeader(context.reportL10n.builderGroupControls),
                _buildDraggableElement(ReportElementType.checkbox, 'Checkbox'),
                _buildDraggableElement(
                  ReportElementType.textbox,
                  context.reportL10n.builderTextbox,
                ),

                _buildSectionHeader(context.reportL10n.builderGroupOther),
                _buildDraggableElement(
                  ReportElementType.image,
                  context.reportL10n.builderImage,
                ),
                _buildDraggableElement(
                  ReportElementType.date,
                  context.reportL10n.builderDate,
                ),

                // Fields from the data schema (only with an associated schema)
                if (_availableFields.isNotEmpty) ...[
                  _buildSectionHeader(
                    context.reportL10n.builderGroupDataFields,
                  ),
                  _buildDraggableElement(
                    ReportElementType.dynamicField,
                    context.reportL10n.builderGenericField,
                  ),
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
      padding: const EdgeInsets.only(
        top: AppTheme.paddingLarge,
        bottom: AppTheme.paddingSmall,
      ),
      child: Text(title, style: AppTheme.sectionHeaderStyle),
    );
  }

  Widget _buildDraggableElement(ReportElementType type, String label) {
    return Draggable<ReportElementType>(
      data: type,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingLarge,
            vertical: AppTheme.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          child: Text(label, style: AppTheme.bodyStyle),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: AppTheme.draggableElementDecoration(),
        child: ListTile(
          dense: true,
          leading: Icon(
            _getIconForType(type),
            size: AppTheme.smallIconSize,
            color: AppTheme.primary,
          ),
          title: Text(label, style: AppTheme.labelStyle),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildFieldDraggable(FieldInfo field) {
    return Draggable<FieldInfo>(
      data: field,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingLarge,
            vertical: AppTheme.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          child: Text(field.displayName, style: AppTheme.bodyStyle),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
        ),
        child: ListTile(
          dense: true,
          leading: const Icon(
            Icons.data_object,
            size: AppTheme.smallIconSize,
            color: AppTheme.success,
          ),
          title: Text(field.displayName, style: AppTheme.labelStyle),
          subtitle: Text(
            field.name,
            style: TextStyle(fontSize: 9, color: AppTheme.textHint),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingMedium,
          ),
        ),
      ),
    );
  }

  /// Main canvas of the designer - fills all the available space
  Widget _buildDesignerCanvas() {
    return GestureDetector(
      onTap: () {
        // Removes the focus from any text field
        _dialogFocusNode.unfocus();
      },
      child: Container(
        color: AppTheme.canvasBackground,
        child: Column(
          children: [
            // Toolbar
            _buildToolbar(),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _calculateFillScale(constraints);
                  });

                  return InteractiveViewer(
                    constrained:
                        false, // Allows zooming beyond the container bounds
                    boundaryMargin: EdgeInsets.all(constraints.maxWidth * 0.5),
                    minScale: 0.05,
                    maxScale: 6.0,
                    panEnabled: !_isDraggingElement,
                    child: Center(child: _buildCanvasWithRulers(constraints)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Computes the scale that fills the screen
  void _calculateFillScale(BoxConstraints constraints) {
    if (_isManualZoom) return;

    final availableWidth =
        constraints.maxWidth - 100; // Margin for rulers and padding
    final availableHeight = constraints.maxHeight - 100;

    final horizontalScale = availableWidth / _template.itemWidth;
    final verticalScale = availableHeight / _template.itemHeight;
    final fillScale =
        (horizontalScale < verticalScale ? horizontalScale : verticalScale) *
        0.85; // 85% leaves a margin

    final newScale = fillScale.clamp(0.5, 6.0);
    if ((newScale - _scale).abs() > 0.1) {
      // Update only when the difference is significant
      setState(() {
        _scale = newScale;
      });
    }
  }

  /// Canvas with millimetre rulers
  Widget _buildCanvasWithRulers(BoxConstraints constraints) {
    // Canvas size
    final canvasWidth = _template.itemWidth * _scale;
    final canvasHeight = _template.itemHeight * _scale;
    const rulerSize = AppTheme.rulerSize;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top horizontal ruler
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Empty corner
            Container(
              width: rulerSize,
              height: rulerSize,
              color: AppTheme.rulerBackground,
            ),
            // Horizontal ruler
            CustomPaint(
              size: Size(canvasWidth, rulerSize),
              painter: _HorizontalRulerPainter(
                scale: _scale,
                maxValue: _template.itemWidth,
              ),
            ),
          ],
        ),
        // Vertical ruler + canvas
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vertical ruler
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
        horizontal: AppTheme.paddingLarge,
        vertical: AppTheme.paddingMedium,
      ),
      decoration: AppTheme.panelHeaderDecoration,
      child: Row(
        children: [
          // Zoom
          IconButton(
            icon: const Icon(Icons.zoom_out, size: AppTheme.iconSize),
            onPressed: () => setState(() {
              _scale = (_scale - 0.25).clamp(0.25, 6.0);
              _isManualZoom = true;
            }),
            tooltip: 'Zoom -',
            color: AppTheme.textSecondary,
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingMedium,
            ),
            child: Text(
              '${(_scale * 100).toInt()}%',
              style: AppTheme.bodyStyle,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, size: AppTheme.iconSize),
            onPressed: () => setState(() {
              _scale = (_scale + 0.25).clamp(0.25, 6.0);
              _isManualZoom = true;
            }),
            tooltip: 'Zoom +',
            color: AppTheme.textSecondary,
          ),

          const SizedBox(width: AppTheme.paddingSmall),

          // Fit to Screen
          IconButton(
            icon: const Icon(Icons.fit_screen, size: AppTheme.iconSize),
            onPressed: () {
              setState(() {
                _isManualZoom = false; // Back to auto-fit
              });
              // Force an immediate recompute
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    _calculateFillScale(renderBox.constraints);
                  }
                }
              });
            },
            tooltip: context.reportL10n.reportFitToScreen,
            color: AppTheme.textSecondary,
          ),

          // Actual Size
          IconButton(
            icon: const Icon(Icons.fullscreen, size: AppTheme.iconSize),
            onPressed: () => setState(() {
              _scale = 1.0;
              _isManualZoom = true;
            }),
            tooltip: context.reportL10n.reportActualSize,
            color: AppTheme.textSecondary,
          ),

          const SizedBox(width: AppTheme.paddingXLarge),

          InkWell(
            onTap: _showSizeDialog,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingMedium,
                vertical: AppTheme.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                border: Border.all(color: AppTheme.panelBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.aspect_ratio,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_template.itemWidth.toInt()}x${_template.itemHeight.toInt()} mm',
                    style: AppTheme.labelStyle,
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 12, color: AppTheme.textHint),
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
                icon: const Icon(Icons.undo, size: AppTheme.iconSize),
                onPressed: _canUndo ? _undo : null,
                tooltip: context.reportL10n.builderUndo,
                color: _canUndo ? AppTheme.textSecondary : AppTheme.textHint,
              ),
              IconButton(
                icon: const Icon(Icons.redo, size: AppTheme.iconSize),
                onPressed: _canRedo ? _redo : null,
                tooltip: context.reportL10n.builderRedo,
                color: _canRedo ? AppTheme.textSecondary : AppTheme.textHint,
              ),
            ],
          ),

          const SizedBox(width: AppTheme.paddingMedium),

          // Template Management
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.folder_open, size: AppTheme.iconSize),
                onPressed: _loadTemplate,
                tooltip: context.reportL10n.builderLoadTemplate,
                color: AppTheme.textSecondary,
              ),
              IconButton(
                icon: const Icon(Icons.save, size: AppTheme.iconSize),
                onPressed: () => widget.onSave?.call(_template),
                tooltip: context.reportL10n.builderSaveTemplate,
                color: AppTheme.primary,
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, size: AppTheme.iconSize),
                onPressed: _exportToPdf,
                tooltip: context.reportL10n.builderExportPdf,
                color: AppTheme.error,
              ),
            ],
          ),

          const SizedBox(width: AppTheme.paddingMedium),

          if (_selectedElementId != null)
            IconButton(
              icon: const Icon(Icons.delete, size: AppTheme.iconSize),
              onPressed: _deleteSelectedElement,
              tooltip: context.reportL10n.printDelete,
              color: AppTheme.error,
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

        // The GlobalKey gives the correct canvas position
        final RenderBox? canvasBox =
            _canvasKey.currentContext?.findRenderObject() as RenderBox?;
        if (canvasBox == null) return;

        final localPosition = canvasBox.globalToLocal(details.offset);

        // Calcola posizione in mm dove l'utente ha rilasciato
        final x = (localPosition.dx / _scale).clamp(
          0.0,
          _template.itemWidth - 20,
        );
        final y = (localPosition.dy / _scale).clamp(
          0.0,
          _template.itemHeight - 10,
        );

        if (data is ReportElementType) {
          _addElement(data, x, y);
        } else if (data is FieldInfo) {
          _addFieldElement(data, x, y);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Listener(
          onPointerDown: (event) {
            final localPos = event.localPosition;
            final xMm = localPos.dx / _scale;
            final yMm = localPos.dy / _scale;

            // First check the resize handles of the selected element
            if (_selectedElementId != null) {
              final selectedElement = _template.getElementById(
                _selectedElementId!,
              );
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

            // Look for the element under the pointer (reverse order for z-index)
            ReportElement? hitElement;
            for (final element in _template.sortedElements.reversed) {
              // A thin line is selected also by clicking just above or below it.
              final pickMargin = element.type == ReportElementType.line
                  ? 4 / _scale
                  : 0.0;
              if (xMm >= element.x &&
                  xMm <= element.x + element.width &&
                  yMm >= element.y - pickMargin &&
                  yMm <= element.y + element.height + pickMargin) {
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

            // Resize handling
            if (_isResizingElement && _selectedElementId != null) {
              final element = _template.getElementById(_selectedElementId!);
              if (element != null) {
                setState(() {
                  _applyResize(element, deltaX, deltaY);
                });
              }
              return;
            }

            // Drag handling
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
              final snapped = _applySnapOnRelease(
                element.x,
                element.y,
                element.width,
                element.height,
              );
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
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.panelBorder),
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(canvasWidth, canvasHeight),
                  painter: _GridPainter(scale: _scale),
                ),

                // Alignment guide lines (only the active ones)
                if (_showSnapLines) ...[
                  // Active vertical lines
                  ..._activeSnapLinesX.map(
                    (x) => Positioned(
                      left: x * _scale,
                      top: 0,
                      child: Container(
                        width: 1,
                        height: canvasHeight,
                        color: AppTheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  // Active horizontal lines
                  ..._activeSnapLinesY.map(
                    (y) => Positioned(
                      left: 0,
                      top: y * _scale,
                      child: Container(
                        width: canvasWidth,
                        height: 1,
                        color: AppTheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],

                ..._template.sortedElements.map(
                  (element) => _buildElementWidget(element),
                ),
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
            MouseRegion(
              cursor: SystemMouseCursors.move,
              child: Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.elementSelected
                        : AppTheme.panelBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? AppTheme.elementSelected.withValues(alpha: 0.1)
                      : null,
                ),
                child: _buildElementPreview(element),
              ),
            ),
            // Resize handles (only when selected)
            if (isSelected)
              ..._buildResizeHandles(
                w,
                h,
                horizontalOnly: element.type == ReportElementType.line,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResizeHandles(
    double w,
    double h, {
    bool horizontalOnly = false,
  }) {
    final handleColor = AppTheme.elementSelected;
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

    // A line only has handles at its ends.
    if (horizontalOnly) {
      return [
        buildHandle(0, h / 2, SystemMouseCursors.resizeLeftRight),
        buildHandle(w, h / 2, SystemMouseCursors.resizeLeftRight),
      ];
    }

    return [
      // Angoli
      buildHandle(0, 0, SystemMouseCursors.resizeUpLeftDownRight),
      buildHandle(w, 0, SystemMouseCursors.resizeUpRightDownLeft),
      buildHandle(0, h, SystemMouseCursors.resizeUpRightDownLeft),
      buildHandle(w, h, SystemMouseCursors.resizeUpLeftDownRight),
      // Edge handles (only when large enough)
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
    final fontSize = (element.properties['fontSize'] as num?)?.toDouble() ?? 5;
    final scaledFontSize = fontSize * _scale;

    Alignment getAlignment(String? hAlign, String? vAlign) {
      double x = 0.0; // center
      double y = 0.0; // center

      switch (hAlign) {
        case 'left':
          x = -1.0;
          break;
        case 'right':
          x = 1.0;
          break;
        default:
          x = 0.0;
      }

      switch (vAlign) {
        case 'top':
          y = -1.0;
          break;
        case 'bottom':
          y = 1.0;
          break;
        default:
          y = 0.0;
      }

      return Alignment(x, y);
    }

    TextAlign getTextAlign(String? align) {
      switch (align) {
        case 'left':
          return TextAlign.left;
        case 'right':
          return TextAlign.right;
        default:
          return TextAlign.center;
      }
    }

    switch (element.type) {
      case ReportElementType.text:
        return Align(
          alignment: getAlignment(
            element.properties['alignment'],
            element.properties['verticalAlignment'],
          ),
          child: Text(
            element.properties['text'] ?? context.reportL10n.builderText,
            style: TextStyle(
              fontSize: scaledFontSize,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: getTextAlign(element.properties['alignment']),
          ),
        );
      case ReportElementType.dynamicField:
        final fieldName = element.properties['fieldName'] ?? '';
        final prefix = element.properties['prefix'] ?? '';
        final suffix = element.properties['suffix'] ?? '';
        return Align(
          alignment: getAlignment(
            element.properties['alignment'],
            element.properties['verticalAlignment'],
          ),
          child: Text(
            '$prefix{$fieldName}$suffix',
            style: TextStyle(fontSize: scaledFontSize, color: AppTheme.primary),
            overflow: TextOverflow.ellipsis,
            textAlign: getTextAlign(element.properties['alignment']),
          ),
        );
      case ReportElementType.barcode:
        return Center(
          child: Icon(Icons.barcode_reader, color: AppTheme.textSecondary),
        );
      case ReportElementType.qrCode:
        return Center(
          child: Icon(Icons.qr_code, color: AppTheme.textSecondary),
        );
      case ReportElementType.image:
        return Center(child: Icon(Icons.image, color: AppTheme.textSecondary));
      case ReportElementType.line:
        final lineColor = element.properties['color'] as String?;
        return Container(
          color: lineColor != null && lineColor.isNotEmpty
              ? _parseColor(lineColor)
              : AppTheme.textPrimary,
        );
      case ReportElementType.rectangle:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.textPrimary),
          ),
        );
      case ReportElementType.circle:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.textPrimary),
          ),
        );
      case ReportElementType.checkbox:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_box_outline_blank,
              size: scaledFontSize,
              color: AppTheme.textPrimary,
            ),
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
            border: Border.all(color: AppTheme.textSecondary),
            borderRadius: BorderRadius.circular(2),
          ),
          padding: const EdgeInsets.all(2),
          child: Text(
            element.properties['placeholder'] ??
                context.reportL10n.builderTextbox,
            style: TextStyle(
              fontSize: scaledFontSize * 0.8,
              color: AppTheme.textHint,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      case ReportElementType.formula:
        final formula = element.properties['formula'] ?? '';
        return Center(
          child: Text(
            formula.isEmpty ? 'Formula' : '=$formula',
            style: TextStyle(
              fontSize: scaledFontSize,
              color: AppTheme.primary,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      case ReportElementType.markdown:
        final useMarkdown = element.properties['useMarkdown'] ?? false;
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                useMarkdown ? Icons.code : Icons.text_fields,
                size: scaledFontSize,
                color: useMarkdown ? AppTheme.primary : AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                useMarkdown ? 'Markdown' : context.reportL10n.builderText,
                style: TextStyle(fontSize: scaledFontSize * 0.8),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      default:
        return Center(
          child: Text(
            element.displayName,
            style: TextStyle(fontSize: scaledFontSize),
          ),
        );
    }
  }

  /// Properties panel of the selected element
  Widget _buildPropertiesPanel() {
    final selectedElement = _selectedElementId != null
        ? _template.getElementById(_selectedElementId!)
        : null;

    return Container(
      width: AppTheme.propertiesPanelWidth,
      decoration: AppTheme.rightPanelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingLarge),
            decoration: AppTheme.panelHeaderDecoration,
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  size: AppTheme.iconSize,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: AppTheme.paddingMedium),
                Text(
                  context.reportL10n.builderProperties,
                  style: AppTheme.titleStyle,
                ),
              ],
            ),
          ),

          // Contenuto
          Expanded(
            child: selectedElement == null
                ? Center(
                    child: Text(
                      context.reportL10n.builderSelectElement,
                      style: TextStyle(color: AppTheme.textHint),
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
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      children: [
        Text(element.displayName, style: AppTheme.titleStyle),
        const SizedBox(height: AppTheme.paddingLarge),

        // Editable ID
        _buildPropertySection(context.reportL10n.builderSectionId, [
          TextFormField(
            initialValue: element.id,
            decoration: const InputDecoration(labelText: 'ID'),
            onChanged: (newId) {
              if (newId.isNotEmpty && newId != element.id) {
                // The ID must not be in use already
                final exists = _template.elements.any(
                  (e) => e.id == newId && e.id != element.id,
                );
                if (!exists) {
                  final index = _template.elements.indexWhere(
                    (e) => e.id == element.id,
                  );
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
        _buildPropertySection(context.reportL10n.builderSectionPosition, [
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
        _buildPropertySection(context.reportL10n.builderSectionSize, [
          _buildNumberField(context.reportL10n.builderWidthMm, element.width, (
            v,
          ) {
            element.width = v;
            _notifyChange();
          }),
          _buildNumberField(
            context.reportL10n.builderHeightMm,
            element.height,
            (v) {
              element.height = v;
              _notifyChange();
            },
          ),
        ]),

        ..._buildTypeSpecificProperties(element),
      ],
    );
  }

  Widget _buildPropertySection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.sectionHeaderStyle),
        const SizedBox(height: AppTheme.paddingMedium),
        ...children,
        const SizedBox(height: AppTheme.paddingXLarge),
      ],
    );
  }

  Widget _buildNumberField(
    String label,
    double value,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: AppTheme.labelStyle)),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: value.toStringAsFixed(1),
              keyboardType: TextInputType.number,
              style: AppTheme.bodyStyle,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingMedium,
                  vertical: AppTheme.paddingMedium,
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

    if (element.type == ReportElementType.text ||
        element.type == ReportElementType.dynamicField ||
        element.type == ReportElementType.date ||
        element.type == ReportElementType.pageNumber) {
      widgets.add(
        _buildPropertySection(context.reportL10n.builderSectionFormatting, [
          // Font Size
          _buildNumberField(
            context.reportL10n.builderFontSizeMm,
            (element.properties['fontSize'] as num?)?.toDouble() ?? 5.0,
            (v) {
              element.properties['fontSize'] = v;
              _notifyChange();
            },
          ),
          // Font Weight
          _buildDropdownField(
            context.reportL10n.builderFontWeight,
            element.properties['fontWeight'] ?? 'normal',
            ['normal', 'bold'],
            (v) {
              element.properties['fontWeight'] = v;
              _notifyChange();
            },
          ),
          // Horizontal alignment
          _buildDropdownField(
            context.reportL10n.builderHorizontalAlignment,
            element.properties['alignment'] ?? 'center',
            ['left', 'center', 'right'],
            (v) {
              element.properties['alignment'] = v;
              _notifyChange();
            },
          ),
          // Vertical alignment
          _buildDropdownField(
            context.reportL10n.builderVerticalAlignment,
            element.properties['verticalAlignment'] ?? 'center',
            ['top', 'center', 'bottom'],
            (v) {
              element.properties['verticalAlignment'] = v;
              _notifyChange();
            },
          ),
          _buildColorField(
            context.reportL10n.builderTextColor,
            element.properties['color'] ?? '#000000',
            (v) {
              element.properties['color'] = v;
              _notifyChange();
            },
          ),
          _buildColorField(
            context.reportL10n.builderBackgroundColor,
            element.properties['backgroundColor'],
            (v) {
              element.properties['backgroundColor'] = v;
              _notifyChange();
            },
            allowNull: true,
          ),
          // Markdown
          CheckboxListTile(
            title: Text(
              context.reportL10n.builderUseMarkdown,
              style: AppTheme.labelStyle,
            ),
            value: element.properties['useMarkdown'] ?? false,
            onChanged: (v) {
              element.properties['useMarkdown'] = v ?? false;
              _notifyChange();
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ]),
      );
    }

    widgets.add(
      _buildPropertySection(context.reportL10n.builderSectionBorder, [
        _buildNumberField(
          context.reportL10n.builderBorderWidthMm,
          (element.properties['borderWidth'] as num?)?.toDouble() ?? 0,
          (v) {
            element.properties['borderWidth'] = v;
            _notifyChange();
          },
        ),
        _buildColorField(
          context.reportL10n.builderBorderColor,
          element.properties['borderColor'] ?? '#000000',
          (v) {
            element.properties['borderColor'] = v;
            _notifyChange();
          },
        ),
      ]),
    );

    // Conditional formatting section
    if (element.type == ReportElementType.text ||
        element.type == ReportElementType.dynamicField ||
        element.type == ReportElementType.formula) {
      widgets.add(_buildConditionalFormattingSection(element));
    }

    switch (element.type) {
      case ReportElementType.text:
        widgets.insert(
          0,
          _buildPropertySection(context.reportL10n.builderSectionContent, [
            TextFormField(
              initialValue: element.properties['text'] ?? '',
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.reportL10n.builderText,
              ),
              onChanged: (v) {
                element.properties['text'] = v;
                _notifyChange();
              },
            ),
          ]),
        );
        break;

      case ReportElementType.dynamicField:
        widgets.insert(
          0,
          _buildPropertySection(context.reportL10n.builderDataField, [
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
                        context.reportL10n.builderNoDataFieldsSchema,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue:
                    element.properties['fieldName']?.toString().isEmpty ?? true
                    ? null
                    : element.properties['fieldName'],
                decoration: InputDecoration(
                  labelText: context.reportL10n.builderField,
                ),
                items: _availableFields
                    .where((f) => !f.isNested)
                    .map(
                      (f) => DropdownMenuItem(
                        value: f.name,
                        child: Text(f.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  element.properties['fieldName'] = v;
                  _notifyChange();
                },
              ),
            const SizedBox(height: AppTheme.paddingMedium),
            TextFormField(
              initialValue: element.properties['prefix'] ?? '',
              decoration: InputDecoration(
                labelText: context.reportL10n.builderPrefix,
              ),
              onChanged: (v) {
                element.properties['prefix'] = v;
                _notifyChange();
              },
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            TextFormField(
              initialValue: element.properties['suffix'] ?? '',
              decoration: InputDecoration(
                labelText: context.reportL10n.builderSuffix,
              ),
              onChanged: (v) {
                element.properties['suffix'] = v;
                _notifyChange();
              },
            ),
          ]),
        );

        if (element.type == ReportElementType.dynamicField) {
          widgets.add(_buildMarkdownSection(element));
        }

        break;

      case ReportElementType.barcode:
        widgets.insert(
          0,
          _buildPropertySection('Barcode', [
            _buildDropdownField(
              context.reportL10n.builderType,
              element.properties['barcodeType'] ?? 'code128',
              ['code128', 'ean13', 'ean8', 'upc', 'code39'],
              (v) {
                element.properties['barcodeType'] = v;
                _notifyChange();
              },
            ),
            SwitchListTile(
              title: Text(context.reportL10n.builderShowText),
              value: element.properties['showText'] ?? true,
              onChanged: (v) {
                setState(() {
                  element.properties['showText'] = v;
                  _notifyChange();
                });
              },
            ),
          ]),
        );
        break;

      case ReportElementType.rectangle:
        widgets.insert(
          0,
          _buildPropertySection(context.reportL10n.builderRectangle, [
            _buildNumberField(
              context.reportL10n.builderBorderRadiusMm,
              (element.properties['borderRadius'] as num?)?.toDouble() ?? 0,
              (v) {
                element.properties['borderRadius'] = v;
                _notifyChange();
              },
            ),
            _buildColorField(
              context.reportL10n.builderFillColor,
              element.properties['fillColor'],
              (v) {
                element.properties['fillColor'] = v;
                _notifyChange();
              },
              allowNull: true,
            ),
          ]),
        );
        break;

      case ReportElementType.line:
        widgets.insert(
          0,
          _buildPropertySection(context.reportL10n.builderLine, [
            _buildNumberField(
              context.reportL10n.builderThicknessMm,
              (element.properties['strokeWidth'] as num?)?.toDouble() ?? 1,
              (v) {
                element.properties['strokeWidth'] = v;
                setState(() => element.height = _lineThickness(element));
                _notifyChange();
              },
            ),
            _buildColorField(
              context.reportL10n.builderColor,
              element.properties['color'] ?? '#000000',
              (v) {
                element.properties['color'] = v;
                _notifyChange();
              },
            ),
          ]),
        );
        break;

      case ReportElementType.image:
        widgets.insert(
          0,
          _buildPropertySection(context.reportL10n.builderImage, [
            _buildDropdownField(
              context.reportL10n.builderSource,
              element.properties['source'] ?? 'field',
              ['field', 'asset', 'url', 'conditional'],
              (v) {
                element.properties['source'] = v;
                _notifyChange();
              },
            ),
            if (element.properties['source'] == 'field') ...[
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
                          context.reportL10n.builderNoDataFields,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue:
                      element.properties['fieldName']?.toString().isEmpty ??
                          true
                      ? null
                      : element.properties['fieldName'],
                  decoration: InputDecoration(
                    labelText: context.reportL10n.builderImageField,
                  ),
                  items: _availableFields
                      .where((f) => !f.isNested)
                      .map(
                        (f) => DropdownMenuItem(
                          value: f.name,
                          child: Text(f.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    element.properties['fieldName'] = v;
                    _notifyChange();
                  },
                ),
            ],
            if (element.properties['source'] == 'asset')
              TextFormField(
                initialValue: element.properties['assetPath'] ?? '',
                decoration: InputDecoration(
                  labelText: context.reportL10n.builderAssetPath,
                ),
                onChanged: (v) {
                  element.properties['assetPath'] = v;
                  _notifyChange();
                },
              ),
            if (element.properties['source'] == 'url')
              TextFormField(
                initialValue: element.properties['url'] ?? '',
                decoration: InputDecoration(
                  labelText: context.reportL10n.builderImageUrl,
                ),
                onChanged: (v) {
                  element.properties['url'] = v;
                  _notifyChange();
                },
              ),
            if (element.properties['source'] == 'conditional')
              _buildConditionalImageSection(element),
            _buildDropdownField(
              context.reportL10n.builderFit,
              element.properties['fit'] ?? 'contain',
              ['contain', 'cover', 'fill', 'fitWidth', 'fitHeight'],
              (v) {
                element.properties['fit'] = v;
                _notifyChange();
              },
            ),
          ]),
        );
        break;

      case ReportElementType.checkbox:
        widgets.insert(
          0,
          _buildPropertySection('Checkbox', [
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
                        context.reportL10n.builderNoDataFieldsSchema,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue:
                    element.properties['fieldName']?.toString().isEmpty ?? true
                    ? null
                    : element.properties['fieldName'],
                decoration: InputDecoration(
                  labelText: context.reportL10n.builderBooleanField,
                ),
                items: _availableFields
                    .where((f) => !f.isNested)
                    .map(
                      (f) => DropdownMenuItem(
                        value: f.name,
                        child: Text(f.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  element.properties['fieldName'] = v;
                  _notifyChange();
                },
              ),
            const SizedBox(height: AppTheme.paddingMedium),
            TextFormField(
              initialValue: element.properties['label'] ?? '',
              decoration: InputDecoration(
                labelText: context.reportL10n.builderLabel,
              ),
              onChanged: (v) {
                element.properties['label'] = v;
                _notifyChange();
              },
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            _buildNumberField(
              context.reportL10n.builderSizeMm,
              (element.properties['size'] as num?)?.toDouble() ?? 12,
              (v) {
                element.properties['size'] = v;
                _notifyChange();
              },
            ),
          ]),
        );
        break;

      case ReportElementType.textbox:
        widgets.insert(
          0,
          _buildPropertySection(context.reportL10n.builderTextbox, [
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
                        context.reportL10n.builderNoDataFieldsSchema,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue:
                    element.properties['fieldName']?.toString().isEmpty ?? true
                    ? null
                    : element.properties['fieldName'],
                decoration: InputDecoration(
                  labelText: context.reportL10n.builderField,
                ),
                items: _availableFields
                    .where((f) => !f.isNested)
                    .map(
                      (f) => DropdownMenuItem(
                        value: f.name,
                        child: Text(f.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  element.properties['fieldName'] = v;
                  _notifyChange();
                },
              ),
            const SizedBox(height: AppTheme.paddingMedium),
            TextFormField(
              initialValue: element.properties['placeholder'] ?? '',
              decoration: const InputDecoration(labelText: 'Placeholder'),
              onChanged: (v) {
                element.properties['placeholder'] = v;
                _notifyChange();
              },
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            _buildNumberField(
              context.reportL10n.builderMaxLines,
              (element.properties['maxLines'] as num?)?.toDouble() ?? 1,
              (v) {
                element.properties['maxLines'] = v.toInt();
                _notifyChange();
              },
            ),
          ]),
        );
        break;

      case ReportElementType.formula:
        widgets.insert(0, _buildFormulaSection(element));
        break;

      case ReportElementType.markdown:
        widgets.insert(0, _buildMarkdownSection(element));
        break;

      default:
        break;
    }

    return widgets;
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      child: DropdownButtonFormField<String>(
        initialValue: options.contains(value) ? value : options.first,
        decoration: InputDecoration(labelText: label),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildColorField(
    String label,
    String? value,
    Function(String?) onChanged, {
    bool allowNull = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: AppTheme.labelStyle)),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showColorPicker(value, onChanged, allowNull),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: value != null
                          ? _parseColor(value)
                          : Colors.transparent,
                      border: Border.all(color: AppTheme.panelBorder),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: value == null
                        ? const Icon(Icons.block, size: 16, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value ?? context.reportL10n.builderNone,
                    style: AppTheme.labelStyle,
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

  void _showColorPicker(
    String? currentValue,
    Function(String?) onChanged,
    bool allowNull,
  ) {
    final colors = [
      if (allowNull) null,
      '#000000',
      '#FFFFFF',
      '#FF0000',
      '#00FF00',
      '#0000FF',
      '#FFFF00',
      '#FF00FF',
      '#00FFFF',
      '#808080',
      '#C0C0C0',
      '#800000',
      '#008000',
      '#000080',
      '#808000',
      '#800080',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.reportL10n.builderSelectColor),
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
                  color: color != null
                      ? _parseColor(color)
                      : Colors.transparent,
                  border: Border.all(
                    color: currentValue == color
                        ? AppTheme.primary
                        : AppTheme.panelBorder,
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
      case ReportElementType.formula:
        return Icons.functions;
      case ReportElementType.markdown:
        return Icons.code;
      default:
        return Icons.widgets;
    }
  }

  void _addElement(ReportElementType type, double x, double y) {
    final id = '${type.name}_${DateTime.now().millisecondsSinceEpoch}';

    // Clamp the start position inside the bounds
    final defaultWidth = 30.0;
    final defaultHeight = 10.0;
    x = x.clamp(0, _template.itemWidth - defaultWidth);
    y = y.clamp(0, _template.itemHeight - defaultHeight);

    final element = ReportElement(id: id, type: type, x: x, y: y);
    if (type == ReportElementType.line) {
      element.properties['strokeWidth'] = 0.3;
      element.width = defaultWidth;
      element.height = _lineThickness(element);
    }

    // Find a free position when it overlaps
    final adjustedElement = _findFreePosition(element);

    setState(() {
      _template.addElement(adjustedElement);
      _selectedElementId = id;
    });
    _notifyChange();
  }

  void _addFieldElement(FieldInfo field, double x, double y) {
    final id = 'field_${DateTime.now().millisecondsSinceEpoch}';

    // Clamp the start position inside the bounds
    final defaultWidth = 30.0;
    final defaultHeight = 10.0;
    x = x.clamp(0, _template.itemWidth - defaultWidth);
    y = y.clamp(0, _template.itemHeight - defaultHeight);

    final element = ReportElement(
      id: id,
      type: ReportElementType.dynamicField,
      x: x,
      y: y,
      properties: {
        'fieldName': field.name,
        'fontSize': 5.0,
        'alignment': 'center',
        'verticalAlignment': 'center',
        'prefix': '',
        'suffix': '',
      },
    );

    // Find a free position when it overlaps
    final adjustedElement = _findFreePosition(element);

    setState(() {
      _template.addElement(adjustedElement);
      _selectedElementId = id;
    });
    _notifyChange();
  }

  /// Finds a free position for the element, avoiding overlaps
  ReportElement _findFreePosition(ReportElement element) {
    var x = element.x;
    var y = element.y;
    var attempts = 0;
    const maxAttempts = 50;

    while (_hasOverlap(element.id, x, y, element.width, element.height) &&
        attempts < maxAttempts) {
      // Sposta a destra o in basso
      x += 5;
      if (x + element.width > _template.itemWidth) {
        x = 0;
        y += 5;
      }
      if (y + element.height > _template.itemHeight) {
        // No space left: leave it where it was
        break;
      }
      attempts++;
    }

    return element.copyWith(x: x, y: y);
  }

  /// Whether it overlaps other elements
  bool _hasOverlap(
    String elementId,
    double x,
    double y,
    double width,
    double height,
  ) {
    for (final other in _template.elements) {
      if (other.id == elementId) continue;

      // Rectangle intersection check
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

  /// Finds the resize handle under the cursor
  String? _getResizeHandle(ReportElement element, double xMm, double yMm) {
    if (element.id != _selectedElementId) return null;

    final handleSizeMm = _handleSize / _scale;
    final x = element.x;
    final y = element.y;
    final w = element.width;
    final h = element.height;

    // A line only stretches horizontally: its height is the thickness.
    if (element.type == ReportElementType.line) {
      if (_isInHandle(xMm, yMm, x, y + h / 2, handleSizeMm)) return 'left';
      if (_isInHandle(xMm, yMm, x + w, y + h / 2, handleSizeMm)) return 'right';
      return null;
    }

    // Angoli
    if (_isInHandle(xMm, yMm, x, y, handleSizeMm)) return 'topLeft';
    if (_isInHandle(xMm, yMm, x + w, y, handleSizeMm)) return 'topRight';
    if (_isInHandle(xMm, yMm, x, y + h, handleSizeMm)) return 'bottomLeft';
    if (_isInHandle(xMm, yMm, x + w, y + h, handleSizeMm)) return 'bottomRight';

    // Edge handles (only when the element is large enough)
    if (w > handleSizeMm * 3) {
      if (_isInHandle(xMm, yMm, x + w / 2, y, handleSizeMm)) return 'top';
      if (_isInHandle(xMm, yMm, x + w / 2, y + h, handleSizeMm)) {
        return 'bottom';
      }
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

  /// Applies the resize from the delta and the active handle
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

    // Apply the minimum size
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

    // Keep it inside the canvas
    if (newX < 0) {
      newW += newX;
      newX = 0;
    }
    if (newY < 0) {
      newH += newY;
      newY = 0;
    }
    if (newX + newW > _template.itemWidth) {
      newW = _template.itemWidth - newX;
    }
    if (newY + newH > _template.itemHeight) {
      newH = _template.itemHeight - newY;
    }

    // Re-apply the minimum size after the clamp
    newW = newW.clamp(_minElementSize, _template.itemWidth);
    newH = newH.clamp(_minElementSize, _template.itemHeight);

    if (element.type == ReportElementType.line) {
      newY = element.y;
      newH = _lineThickness(element);
    }

    element.x = newX;
    element.y = newY;
    element.width = newW;
    element.height = newH;
  }

  /// Line thickness in mm, which is also its height.
  double _lineThickness(ReportElement element) {
    final thickness =
        (element.properties['strokeWidth'] as num?)?.toDouble() ?? 0.3;
    return thickness.clamp(0.1, _template.itemHeight).toDouble();
  }

  /// Computes the guide lines from the other elements
  void _updateSnapLines(String? excludeId) {
    _snapLinesX = [];
    _snapLinesY = [];

    for (final element in _template.elements) {
      if (element.id == excludeId) continue;

      // Vertical edges (X)
      _snapLinesX.add(element.x); // sinistro
      _snapLinesX.add(element.x + element.width / 2); // centro
      _snapLinesX.add(element.x + element.width); // destro

      // Horizontal edges (Y)
      _snapLinesY.add(element.y); // superiore
      _snapLinesY.add(element.y + element.height / 2); // centro
      _snapLinesY.add(element.y + element.height); // inferiore
    }
  }

  /// Updates the active guide lines (near the element while dragging)
  void _updateActiveSnapLines(double x, double y, double width, double height) {
    _activeSnapLinesX = [];
    _activeSnapLinesY = [];

    for (final guide in _snapLinesX) {
      final distLeft = (x - guide).abs();
      final distCenter = (x + width / 2 - guide).abs();
      final distRight = (x + width - guide).abs();

      if (distLeft <= _snapThreshold ||
          distCenter <= _snapThreshold ||
          distRight <= _snapThreshold) {
        if (!_activeSnapLinesX.contains(guide)) {
          _activeSnapLinesX.add(guide);
        }
      }
    }

    for (final guide in _snapLinesY) {
      final distTop = (y - guide).abs();
      final distCenter = (y + height / 2 - guide).abs();
      final distBottom = (y + height - guide).abs();

      if (distTop <= _snapThreshold ||
          distCenter <= _snapThreshold ||
          distBottom <= _snapThreshold) {
        if (!_activeSnapLinesY.contains(guide)) {
          _activeSnapLinesY.add(guide);
        }
      }
    }
  }

  /// Snaps on release only when active guide lines are visible
  Offset _applySnapOnRelease(double x, double y, double width, double height) {
    double snappedX = x;
    double snappedY = y;
    double minDistX = double.infinity;
    double minDistY = double.infinity;

    // Snap only to the active (visible) lines
    for (final guide in _activeSnapLinesX) {
      // Left edge
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
      // Right edge
      final distRight = (x + width - guide).abs();
      if (distRight < minDistX && distRight <= _snapThreshold) {
        minDistX = distRight;
        snappedX = guide - width;
      }
    }

    for (final guide in _activeSnapLinesY) {
      // Top edge
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
      // Bottom edge
      final distBottom = (y + height - guide).abs();
      if (distBottom < minDistY && distBottom <= _snapThreshold) {
        minDistY = distBottom;
        snappedY = guide - height;
      }
    }

    return Offset(snappedX, snappedY);
  }

  /// Moves overlapping elements to avoid overlaps
  void _pushOverlappingElements(ReportElement movedElement) {
    const minGap = 1.0; // minimum gap in mm
    bool changed = true;
    int iterations = 0;
    const maxIterations = 20;

    while (changed && iterations < maxIterations) {
      changed = false;
      iterations++;

      for (final other in _template.elements) {
        if (other.id == movedElement.id) continue;

        // Overlap check
        final overlapsX =
            movedElement.x < other.x + other.width &&
            movedElement.x + movedElement.width > other.x;
        final overlapsY =
            movedElement.y < other.y + other.height &&
            movedElement.y + movedElement.height > other.y;

        if (overlapsX && overlapsY) {
          // Pick the best push direction (smallest move)
          final pushRight = (movedElement.x + movedElement.width) - other.x;
          final pushLeft = (other.x + other.width) - movedElement.x;
          final pushDown = (movedElement.y + movedElement.height) - other.y;
          final pushUp = (other.y + other.height) - movedElement.y;

          final minPush = [
            pushRight,
            pushLeft,
            pushDown,
            pushUp,
          ].reduce((a, b) => a < b ? a : b);

          if (minPush == pushRight) {
            other.x = movedElement.x + movedElement.width + minGap;
          } else if (minPush == pushLeft) {
            other.x = movedElement.x - other.width - minGap;
          } else if (minPush == pushDown) {
            other.y = movedElement.y + movedElement.height + minGap;
          } else {
            other.y = movedElement.y - other.height - minGap;
          }

          // Keep it inside the canvas
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

    _changeTimer?.cancel();
    _changeTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        widget.onTemplateChanged?.call(_template);
      }
    });
  }

  void _showSizeDialog() {
    final widthController = TextEditingController(
      text: _template.itemWidth.toStringAsFixed(0),
    );
    final heightController = TextEditingController(
      text: _template.itemHeight.toStringAsFixed(0),
    );
    bool isLandscape = _template.itemWidth > _template.itemHeight;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.reportL10n.builderPageSize),
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
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stay_current_portrait, size: 16),
                            SizedBox(width: 4),
                            Text(context.reportL10n.builderPortrait),
                          ],
                        ),
                        selected: !isLandscape,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              isLandscape = false;
                              final w =
                                  double.tryParse(widthController.text) ?? 210;
                              final h =
                                  double.tryParse(heightController.text) ?? 297;
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
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stay_current_landscape, size: 16),
                            SizedBox(width: 4),
                            Text(context.reportL10n.builderLandscape),
                          ],
                        ),
                        selected: isLandscape,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              isLandscape = true;
                              final w =
                                  double.tryParse(widthController.text) ?? 210;
                              final h =
                                  double.tryParse(heightController.text) ?? 297;
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
                // Common presets
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSizePreset(
                      'A4',
                      isLandscape ? 297 : 210,
                      isLandscape ? 210 : 297,
                      widthController,
                      heightController,
                    ),
                    _buildSizePreset(
                      'A5',
                      isLandscape ? 210 : 148,
                      isLandscape ? 148 : 210,
                      widthController,
                      heightController,
                    ),
                    _buildSizePreset(
                      'A6',
                      isLandscape ? 148 : 105,
                      isLandscape ? 105 : 148,
                      widthController,
                      heightController,
                    ),
                    _buildSizePreset(
                      context.reportL10n.builderLabel,
                      50,
                      30,
                      widthController,
                      heightController,
                    ),
                    _buildSizePreset(
                      context.reportL10n.builderCard,
                      85,
                      55,
                      widthController,
                      heightController,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                // Manual inputs
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widthController,
                        keyboardType: TextInputType.number,
                        focusNode: _dialogFocusNode,
                        decoration: InputDecoration(
                          labelText: context.reportL10n.builderWidthMm,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: heightController,
                        keyboardType: TextInputType.number,
                        focusNode: _dialogFocusNode,
                        decoration: InputDecoration(
                          labelText: context.reportL10n.builderHeightMm,
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
            child: Text(context.reportL10n.printCancel),
          ),
          ElevatedButton(
            onPressed: () {
              final width = double.tryParse(widthController.text);
              final height = double.tryParse(heightController.text);
              if (width != null && height != null && width > 0 && height > 0) {
                setState(() {
                  _template.itemWidth = width;
                  _template.itemHeight = height;
                });
                _notifyChange();
                Navigator.pop(context);
              }
            },
            child: Text(context.reportL10n.builderApply),
          ),
        ],
      ),
    );
  }

  Widget _buildSizePreset(
    String name,
    double width,
    double height,
    TextEditingController widthCtrl,
    TextEditingController heightCtrl,
  ) {
    return ActionChip(
      label: Text(
        '$name\n${width.toInt()}x${height.toInt()}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10),
      ),
      onPressed: () {
        widthCtrl.text = width.toString();
        heightCtrl.text = height.toString();
      },
    );
  }
}

extension ReportBuilderMethods on _ReportBuilderState {
  /// Loads a template from a file
  Future<void> _loadTemplate() async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['rpt'],
      );

      if (result != null && result.path != null) {
        final templateWithSchema = await TemplateLoader.fromFile(result.path!);

        if (mounted) {
          setState(() {
            _template = templateWithSchema.template;
            _selectedElementId = null;
            _extractAllFields();
            _saveToHistory();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.reportL10n.builderTemplateLoaded),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.reportL10n.builderTemplateLoadError('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Exports the template to PDF
  Future<void> _exportToPdf() async {
    final l10n = context.reportL10n;
    try {
      // Generates the PDF and saves it through the native file picker dialog.
      final sampleData = _template.getSampleData();
      final dataList = sampleData.isNotEmpty ? [sampleData] : [{}];
      final bytes = await PdfExporter.exportToPdfBytes(
        template: _template,
        data: dataList,
      );

      final result = await FilePicker.saveFile(
        dialogTitle: l10n.builderExportPdf,
        fileName:
            '${_template.name}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes: bytes,
        mimeType: 'application/pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.builderPdfExported),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.builderPdfExportError('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Painter for the background grid
class _GridPainter extends CustomPainter {
  final double scale;

  _GridPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.panelBorder
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

/// Painter for the horizontal ruler
class _HorizontalRulerPainter extends CustomPainter {
  final double scale;
  final double maxValue;

  _HorizontalRulerPainter({required this.scale, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.rulerLine
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Ruler background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.rulerBackground,
    );

    for (int mm = 0; mm <= maxValue.toInt(); mm++) {
      final x = mm * scale;

      if (mm % 10 == 0) {
        // Major tick every 10 mm (1 cm)
        canvas.drawLine(
          Offset(x, size.height - 12),
          Offset(x, size.height),
          paint,
        );
        // Numero
        textPainter.text = TextSpan(
          text: '${mm ~/ 10}',
          style: TextStyle(color: AppTheme.rulerText, fontSize: 8),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, 2));
      } else if (mm % 5 == 0) {
        // Medium tick every 5 mm
        canvas.drawLine(
          Offset(x, size.height - 8),
          Offset(x, size.height),
          paint,
        );
      } else {
        // Minor tick every mm
        canvas.drawLine(
          Offset(x, size.height - 4),
          Offset(x, size.height),
          paint,
        );
      }
    }

    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for the vertical ruler
class _VerticalRulerPainter extends CustomPainter {
  final double scale;
  final double maxValue;

  _VerticalRulerPainter({required this.scale, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.rulerLine
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Ruler background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.rulerBackground,
    );

    for (int mm = 0; mm <= maxValue.toInt(); mm++) {
      final y = mm * scale;

      if (mm % 10 == 0) {
        // Major tick every 10 mm (1 cm)
        canvas.drawLine(
          Offset(size.width - 12, y),
          Offset(size.width, y),
          paint,
        );
        // Numero
        textPainter.text = TextSpan(
          text: '${mm ~/ 10}',
          style: TextStyle(color: AppTheme.rulerText, fontSize: 8),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(2, y - textPainter.height / 2));
      } else if (mm % 5 == 0) {
        // Medium tick every 5 mm
        canvas.drawLine(
          Offset(size.width - 8, y),
          Offset(size.width, y),
          paint,
        );
      } else {
        // Minor tick every mm
        canvas.drawLine(
          Offset(size.width - 4, y),
          Offset(size.width, y),
          paint,
        );
      }
    }

    canvas.drawLine(
      Offset(size.width - 1, 0),
      Offset(size.width - 1, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension ReportBuilderExtensions on _ReportBuilderState {
  /// Builds the formulas section
  Widget _buildFormulaSection(ReportElement element) {
    return _buildPropertySection('Formula', [
      TextFormField(
        initialValue: element.properties['formula'] ?? '',
        decoration: InputDecoration(
          labelText: 'Formula',
          hintText: 'SUM({price}, {tax}) * 0.22',
          helperText: context.reportL10n.builderFormulaHelp('{field}'),
        ),
        maxLines: 3,
        onChanged: (v) {
          element.properties['formula'] = v;
          _notifyChange();
        },
      ),
      const SizedBox(height: AppTheme.paddingMedium),
      Text(context.reportL10n.builderVariables, style: AppTheme.labelStyle),
      const SizedBox(height: AppTheme.paddingSmall),
      _buildVariablesMapper(element),
      const SizedBox(height: AppTheme.paddingMedium),
      _buildDropdownField(
        context.reportL10n.builderOutputFormat,
        element.properties['format'] ?? 'number',
        ['number', 'currency', 'percentage', 'date'],
        (v) {
          element.properties['format'] = v;
          _notifyChange();
        },
      ),
      const SizedBox(height: AppTheme.paddingMedium),
      TextFormField(
        initialValue: element.properties['errorValue'] ?? '0',
        decoration: InputDecoration(
          labelText: context.reportL10n.builderErrorValue,
          hintText: context.reportL10n.builderErrorValueHint,
        ),
        onChanged: (v) {
          element.properties['errorValue'] = v;
          _notifyChange();
        },
      ),
    ]);
  }

  /// Builds the variable mapper for formulas
  Widget _buildVariablesMapper(ReportElement element) {
    final variables = Map<String, String>.from(
      element.properties['variables'] ?? {},
    );
    final variableNames = variables.keys.toList();

    return Column(
      children: [
        ...variableNames.map(
          (varName) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    '{$varName}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.paddingSmall),
                Expanded(
                  flex: 2,
                  child: _availableFields.isEmpty
                      ? Text(
                          context.reportL10n.builderNoFields,
                          style: TextStyle(color: Colors.orange),
                        )
                      : DropdownButtonFormField<String>(
                          initialValue: variables[varName]?.isEmpty ?? true
                              ? null
                              : variables[varName],
                          decoration: InputDecoration(
                            labelText: context.reportL10n.builderDataField,
                          ),
                          items: _availableFields
                              .where((f) => !f.isNested)
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f.name,
                                  child: Text(f.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            variables[varName] = v ?? '';
                            element.properties['variables'] = variables;
                            _notifyChange();
                          },
                        ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    variables.remove(varName);
                    element.properties['variables'] = variables;
                    _notifyChange();
                  },
                ),
              ],
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () {
            final newVar = 'var${variables.length + 1}';
            variables[newVar] = '';
            element.properties['variables'] = variables;
            _notifyChange();
          },
          icon: const Icon(Icons.add),
          label: Text(context.reportL10n.builderAddVariable),
        ),
      ],
    );
  }

  /// Builds the Markdown section
  Widget _buildMarkdownSection(ReportElement element) {
    return _buildPropertySection('Markdown', [
      SwitchListTile(
        title: Text(context.reportL10n.builderUseMarkdown),
        subtitle: Text(context.reportL10n.builderEnableMarkdown),
        value: element.properties['useMarkdown'] ?? false,
        onChanged: (v) {
          setState(() {
            element.properties['useMarkdown'] = v;
            _notifyChange();
          });
        },
      ),
      if (element.properties['useMarkdown'] ?? false) ...[
        TextFormField(
          initialValue: element.properties['markdownData'] ?? '',
          decoration: InputDecoration(
            labelText: context.reportL10n.builderMarkdownContent,
            hintText: context.reportL10n.builderMarkdownHint,
          ),
          maxLines: 8,
          onChanged: (v) {
            element.properties['markdownData'] = v;
            _notifyChange();
          },
        ),
        const SizedBox(height: AppTheme.paddingMedium),
        SwitchListTile(
          title: Text(context.reportL10n.builderAutoToc),
          subtitle: Text(context.reportL10n.builderAutoTocHelp),
          value: element.properties['markdownConfig']?['enableToc'] ?? false,
          onChanged: (v) {
            final config = Map<String, dynamic>.from(
              element.properties['markdownConfig'] ?? {},
            );
            config['enableToc'] = v;
            element.properties['markdownConfig'] = config;
            _notifyChange();
          },
        ),
        SwitchListTile(
          title: Text(context.reportL10n.builderSyntaxHighlighting),
          subtitle: Text(context.reportL10n.builderSyntaxHighlightingHelp),
          value:
              element.properties['markdownConfig']?['enableCodeHighlighting'] ??
              true,
          onChanged: (v) {
            final config = Map<String, dynamic>.from(
              element.properties['markdownConfig'] ?? {},
            );
            config['enableCodeHighlighting'] = v;
            element.properties['markdownConfig'] = config;
            _notifyChange();
          },
        ),
        _buildDropdownField(
          context.reportL10n.builderTheme,
          element.properties['markdownConfig']?['theme'] ?? 'light',
          ['light', 'dark'],
          (v) {
            final config = Map<String, dynamic>.from(
              element.properties['markdownConfig'] ?? {},
            );
            config['theme'] = v;
            element.properties['markdownConfig'] = config;
            _notifyChange();
          },
        ),
      ],
    ]);
  }

  /// Builds the conditional formatting section
  Widget _buildConditionalFormattingSection(ReportElement element) {
    final conditionalFormatting = Map<String, dynamic>.from(
      element.properties['conditionalFormatting'] ??
          {'enabled': false, 'rules': []},
    );
    final rules = List<Map<String, dynamic>>.from(
      conditionalFormatting['rules'] ?? [],
    );

    return _buildPropertySection(
      context.reportL10n.builderConditionalFormatting,
      [
        SwitchListTile(
          title: Text(context.reportL10n.builderEnableConditionalFormatting),
          subtitle: Text(context.reportL10n.builderConditionalFormattingHelp),
          value: conditionalFormatting['enabled'] ?? false,
          onChanged: (v) {
            setState(() {
              conditionalFormatting['enabled'] = v;
              element.properties['conditionalFormatting'] =
                  conditionalFormatting;
              _notifyChange();
            });
          },
        ),
        if (conditionalFormatting['enabled'] ?? false) ...[
          ...rules.asMap().entries.map((entry) {
            final index = entry.key;
            final rule = entry.value;
            return _buildConditionalRule(element, rule, index);
          }),
          TextButton.icon(
            onPressed: () {
              rules.add({
                'type': 'threshold',
                'condition': 'greater',
                'value': 100,
                'foregroundColor': '#FF0000',
                'backgroundColor': '#FFFF00',
                'fontWeight': 'bold',
                'fontSize': 12.0,
              });
              conditionalFormatting['rules'] = rules;
              element.properties['conditionalFormatting'] =
                  conditionalFormatting;
              _notifyChange();
            },
            icon: const Icon(Icons.add),
            label: Text(context.reportL10n.builderAddRule),
          ),
        ],
      ],
    );
  }

  /// Builds a single conditional formatting rule
  Widget _buildConditionalRule(
    ReportElement element,
    Map<String, dynamic> rule,
    int index,
  ) {
    final conditionalFormatting = Map<String, dynamic>.from(
      element.properties['conditionalFormatting'] ??
          {'enabled': false, 'rules': []},
    );
    final rules = List<Map<String, dynamic>>.from(
      conditionalFormatting['rules'] ?? [],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.reportL10n.builderRuleNumber(index + 1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    rules.removeAt(index);
                    conditionalFormatting['rules'] = rules;
                    element.properties['conditionalFormatting'] =
                        conditionalFormatting;
                    _notifyChange();
                  },
                ),
              ],
            ),
            _buildDropdownField(
              context.reportL10n.builderType,
              rule['type'] ?? 'threshold',
              ['threshold', 'contains', 'range', 'expression'],
              (v) {
                rule['type'] = v;
                conditionalFormatting['rules'] = rules;
                element.properties['conditionalFormatting'] =
                    conditionalFormatting;
                _notifyChange();
              },
            ),
            if (rule['type'] == 'threshold') ...[
              _buildDropdownField(
                context.reportL10n.builderCondition,
                rule['condition'] ?? 'greater',
                ['greater', 'less', 'equal', 'greater_equal', 'less_equal'],
                (v) {
                  rule['condition'] = v;
                  conditionalFormatting['rules'] = rules;
                  element.properties['conditionalFormatting'] =
                      conditionalFormatting;
                  _notifyChange();
                },
              ),
              TextFormField(
                initialValue: rule['value']?.toString() ?? '100',
                decoration: InputDecoration(
                  labelText: context.reportL10n.builderValue,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  rule['value'] = num.tryParse(v) ?? 100;
                  conditionalFormatting['rules'] = rules;
                  element.properties['conditionalFormatting'] =
                      conditionalFormatting;
                  _notifyChange();
                },
              ),
            ],
            if (rule['type'] == 'contains') ...[
              TextFormField(
                initialValue: rule['text'] ?? '',
                decoration: InputDecoration(
                  labelText: context.reportL10n.builderSearchText,
                ),
                onChanged: (v) {
                  rule['text'] = v;
                  conditionalFormatting['rules'] = rules;
                  element.properties['conditionalFormatting'] =
                      conditionalFormatting;
                  _notifyChange();
                },
              ),
            ],
            _buildColorField(
              context.reportL10n.builderTextColor,
              rule['foregroundColor'] ?? '#000000',
              (v) {
                rule['foregroundColor'] = v;
                conditionalFormatting['rules'] = rules;
                element.properties['conditionalFormatting'] =
                    conditionalFormatting;
                _notifyChange();
              },
            ),
            _buildColorField(
              context.reportL10n.builderBackgroundColor,
              rule['backgroundColor'],
              (v) {
                rule['backgroundColor'] = v;
                conditionalFormatting['rules'] = rules;
                element.properties['conditionalFormatting'] =
                    conditionalFormatting;
                _notifyChange();
              },
              allowNull: true,
            ),
            _buildDropdownField(
              'Peso Font',
              rule['fontWeight'] ?? 'normal',
              ['normal', 'bold'],
              (v) {
                rule['fontWeight'] = v;
                conditionalFormatting['rules'] = rules;
                element.properties['conditionalFormatting'] =
                    conditionalFormatting;
                _notifyChange();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the conditional images section
  Widget _buildConditionalImageSection(ReportElement element) {
    final conditionalImages = List<Map<String, dynamic>>.from(
      element.properties['conditionalImages'] ?? [],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.reportL10n.builderConditionalImages,
          style: AppTheme.labelStyle,
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        ...conditionalImages.asMap().entries.map((entry) {
          final index = entry.key;
          final imageRule = entry.value;
          return _buildConditionalImageRule(element, imageRule, index);
        }),
        TextButton.icon(
          onPressed: () {
            conditionalImages.add({
              'condition': 'status == "active"',
              'imageField': 'activeImage',
              'fallbackAsset': 'assets/inactive.png',
            });
            element.properties['conditionalImages'] = conditionalImages;
            _notifyChange();
          },
          icon: const Icon(Icons.add),
          label: Text(context.reportL10n.builderAddImageRule),
        ),
      ],
    );
  }

  /// Builds a single conditional image rule
  Widget _buildConditionalImageRule(
    ReportElement element,
    Map<String, dynamic> rule,
    int index,
  ) {
    final conditionalImages = List<Map<String, dynamic>>.from(
      element.properties['conditionalImages'] ?? [],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.reportL10n.builderImageRuleNumber(index + 1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    conditionalImages.removeAt(index);
                    element.properties['conditionalImages'] = conditionalImages;
                    _notifyChange();
                  },
                ),
              ],
            ),
            TextFormField(
              initialValue: rule['condition'] ?? '',
              decoration: InputDecoration(
                labelText: context.reportL10n.builderCondition,
                hintText: 'status == "active"',
              ),
              onChanged: (v) {
                rule['condition'] = v;
                element.properties['conditionalImages'] = conditionalImages;
                _notifyChange();
              },
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            TextFormField(
              initialValue: rule['imageField'] ?? '',
              decoration: InputDecoration(
                labelText: context.reportL10n.builderImageFieldIfTrue,
                hintText: context.reportL10n.builderImageFieldIfTrueHint,
              ),
              onChanged: (v) {
                rule['imageField'] = v;
                element.properties['conditionalImages'] = conditionalImages;
                _notifyChange();
              },
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            TextFormField(
              initialValue: rule['fallbackAsset'] ?? '',
              decoration: InputDecoration(
                labelText: context.reportL10n.builderFallbackImage,
                hintText: context.reportL10n.builderFallbackImageHint,
              ),
              onChanged: (v) {
                rule['fallbackAsset'] = v;
                element.properties['conditionalImages'] = conditionalImages;
                _notifyChange();
              },
            ),
          ],
        ),
      ),
    );
  }
}
