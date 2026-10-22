import 'dart:convert';

import 'package:flutter/material.dart';

import '../builder/report_builder.dart';
import '../l10n/report_l10n.dart';
import '../models/report_template.dart';
import 'paper_format.dart';
import 'print_data_provider.dart';
import 'print_scope.dart';
import 'print_template.dart';
import 'print_theme.dart';

/// Opens the drag-and-drop designer on [template] and returns the template
/// with the edited layout, paper format and app settings, or null when the
/// user leaves without applying them.
///
/// Uses the library and data provider of the [PrintScope] above [context].
Future<PrintTemplate?> openPrintTemplateDesigner(
  BuildContext context,
  PrintTemplate template,
) {
  final scope = PrintScope.of(context);
  return Navigator.of(context).push<PrintTemplate>(
    MaterialPageRoute(
      fullscreenDialog: true,
      // The new route is not below the print center: it gets its own scope.
      builder: (_) => PrintScope(
        library: scope.library,
        dataProvider: scope.dataProvider,
        child: _TemplateDesignerPage(template: template),
      ),
    ),
  );
}

/// Drag-and-drop designer from the `report_flutter` package: rulers, canvas
/// in millimetres and the data fields on the left, ready to be dragged onto
/// the label, sign or report page. The bar above it chooses the paper format
/// (the canvas takes the size of one cell) and shows the settings the app
/// adds through [PrintDataProvider.designerSettings].
class _TemplateDesignerPage extends StatefulWidget {
  const _TemplateDesignerPage({required this.template});

  final PrintTemplate template;

  @override
  State<_TemplateDesignerPage> createState() => _TemplateDesignerPageState();
}

class _TemplateDesignerPageState extends State<_TemplateDesignerPage> {
  late ReportTemplate _design = ReportTemplate.fromJson(
    widget.template.design.toJson(),
  );
  late final String _initialJson = jsonEncode(widget.template.design.toJson());
  late Map<String, dynamic> _settings = widget.template.settings;
  late final String _initialSettings = jsonEncode(widget.template.settings);
  late String _paperFormatId = widget.template.paperFormatId;

  /// Changes when the canvas size changes, so the designer starts again on
  /// the resized layout.
  int _canvasGeneration = 0;

  bool get _changed =>
      jsonEncode(_design.toJson()) != _initialJson ||
      jsonEncode(_settings) != _initialSettings ||
      _paperFormatId != widget.template.paperFormatId;

  void _apply([ReportTemplate? design]) {
    Navigator.of(context).pop(
      widget.template.copyWith(
        design: design ?? _design,
        settings: _settings,
        paperFormatId: _paperFormatId,
      ),
    );
  }

  /// The canvas takes the size of one cell of the new paper format; the
  /// elements keep their position.
  void _changePaper(PaperFormat format) {
    final resized = ReportTemplate.fromJson(_design.toJson())
      ..itemWidth = format.cellWidthMm
      ..itemHeight = format.cellHeightMm
      ..pageWidth = format.cellWidthMm
      ..pageHeight = format.cellHeightMm;
    setState(() {
      _paperFormatId = format.id;
      _design = resized;
      _canvasGeneration++;
    });
  }

  Future<void> _close() async {
    if (!_changed) {
      Navigator.of(context).pop();
      return;
    }
    final l10n = context.reportL10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.printDiscardDesignTitle),
        content: Text(l10n.printDiscardDesignMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.printKeepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.printDiscardDesign),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    final scope = PrintScope.of(context);
    final template = widget.template.copyWith(settings: _settings);
    final sampleData = scope.dataProvider.sampleData(context, template);
    final appSettings = scope.dataProvider.designerSettings(
      context,
      template,
      (changed) => setState(() => _settings = changed.settings),
    );
    final formats = scope.library.paperFormats;
    final selectedFormat = formats
        .where((format) => format.id == _paperFormatId)
        .firstOrNull;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.printClose,
            onPressed: _close,
          ),
          title: Text(l10n.printDesignerTitle(widget.template.name)),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: context.printSpacing.m),
              child: FilledButton.icon(
                onPressed: _apply,
                icon: const Icon(Icons.check),
                label: Text(l10n.printApplyDesign),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Material(
              color: context.printTheme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.printSpacing.l,
                  vertical: context.printSpacing.s,
                ),
                child: Wrap(
                  spacing: context.printSpacing.xl,
                  runSpacing: context.printSpacing.s,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.straighten,
                          size: 20,
                          color: context.printTheme.colorScheme.primary,
                        ),
                        SizedBox(width: context.printSpacing.s),
                        Text(
                          l10n.printSectionPaper,
                          style: context.printText.bodyMedium,
                        ),
                        SizedBox(width: context.printSpacing.s),
                        DropdownButton<String>(
                          value: selectedFormat?.id,
                          hint: Text(l10n.printPaperMissing),
                          items: [
                            for (final format in formats)
                              DropdownMenuItem(
                                value: format.id,
                                child: Text(format.displayName(l10n)),
                              ),
                          ],
                          onChanged: (id) {
                            final format = formats
                                .where((entry) => entry.id == id)
                                .firstOrNull;
                            if (format != null) _changePaper(format);
                          },
                        ),
                      ],
                    ),
                    ?appSettings,
                  ],
                ),
              ),
            ),
            Expanded(
              child: ReportBuilder(
                key: ValueKey('canvas-$_canvasGeneration'),
                template: _design,
                sampleData: sampleData,
                onTemplateChanged: (design) => _design = design,
                onSave: _apply,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
