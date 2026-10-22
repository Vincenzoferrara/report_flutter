import 'package:flutter/material.dart';

import '../l10n/report_l10n.dart';
import 'print_theme.dart';
import 'paper_format.dart';
import 'print_library.dart';
import 'print_widgets.dart';

/// Paper formats of the shop, grouped by template type. Shop managers can
/// add, change and delete them, defaults included.
class PaperFormatsPage extends StatelessWidget {
  const PaperFormatsPage({super.key, required this.library});

  final PrintLibrary library;

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    return ListenableBuilder(
      listenable: library,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.printPaperFormats)),
        floatingActionButton: library.canManage
            ? FloatingActionButton.extended(
                onPressed: () => _edit(context, null),
                icon: const Icon(Icons.add),
                label: Text(l10n.printNewPaperFormat),
              )
            : null,
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            context.printSpacing.l,
            context.printSpacing.l,
            context.printSpacing.l,
            96,
          ),
          children: [
            Text(
              l10n.printPaperFormatsHelp,
              style: context.printText.bodyLarge?.copyWith(
                color: context.printColors.subtitleColor,
              ),
            ),
            if (library.paperFormats.isEmpty) ...[
              SizedBox(height: context.printSpacing.l),
              Text(
                l10n.printPaperMissing,
                style: context.printText.bodyMedium?.copyWith(
                  color: context.printColors.subtitleColor,
                ),
              ),
            ],
            for (final feed in PaperFeed.values)
              if (library.paperFormats.any(
                (format) => format.feed == feed,
              )) ...[
                SizedBox(height: context.printSpacing.l),
                Text(
                  feed == PaperFeed.roll
                      ? l10n.printPaperGroupRolls
                      : l10n.printPaperGroupSheets,
                  style: context.printText.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 16),
                for (final format in library.paperFormats.where(
                  (format) => format.feed == feed,
                ))
                  Card(
                    child: ListTile(
                      leading: Icon(
                        format.feed == PaperFeed.roll
                            ? Icons.receipt_long_outlined
                            : Icons.description_outlined,
                      ),
                      title: Text(format.displayName(l10n)),
                      subtitle: Text(format.describe(l10n)),
                      onTap: library.canManage
                          ? () => _edit(context, format)
                          : null,
                      trailing: library.canManage
                          ? IconButton(
                              tooltip: l10n.printDelete,
                              icon: Icon(
                                Icons.delete_outline,
                                color: context.printColors.errorColorStatus,
                              ),
                              onPressed: () => _delete(context, format),
                            )
                          : null,
                    ),
                  ),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, PaperFormat? format) =>
      editPaperFormat(context, library, format);

  Future<void> _delete(BuildContext context, PaperFormat format) async {
    final l10n = context.reportL10n;
    final used = library.templatesUsing(format.id);
    final confirmed = await confirmPrintDelete(
      context,
      title: l10n.printDeletePaperFormatTitle,
      message: used == 0
          ? l10n.printDeletePaperFormatMessage(format.displayName(l10n))
          : l10n.printDeletePaperFormatUsedMessage(
              format.displayName(l10n),
              used,
            ),
    );
    if (!confirmed || !context.mounted) return;
    try {
      await library.deletePaperFormat(format.id);
    } catch (error) {
      if (!context.mounted) return;
      context.showPrintMessage(
        l10n.printSaveError(error.toString()),
        kind: PrintMessageKind.error,
      );
    }
  }
}

/// Opens the paper format form: a new format when [format] is null, the
/// given one otherwise. The format is saved in [library] when confirmed.
Future<void> editPaperFormat(
  BuildContext context,
  PrintLibrary library,
  PaperFormat? format,
) async {
  final l10n = context.reportL10n;
  final edited = await showDialog<PaperFormat>(
    context: context,
    builder: (_) => _PaperFormatDialog(initial: format),
  );
  if (edited == null || !context.mounted) return;
  try {
    await library.savePaperFormat(edited);
    if (!context.mounted) return;
    context.showPrintMessage(
      l10n.printPaperFormatSaved(edited.displayName(l10n)),
      kind: PrintMessageKind.success,
    );
  } catch (error) {
    if (!context.mounted) return;
    context.showPrintMessage(
      l10n.printSaveError(error.toString()),
      kind: PrintMessageKind.error,
    );
  }
}

/// Every measure of a paper format, in millimetres.
class _PaperFormatDialog extends StatefulWidget {
  const _PaperFormatDialog({this.initial});

  final PaperFormat? initial;

  @override
  State<_PaperFormatDialog> createState() => _PaperFormatDialogState();
}

class _PaperFormatDialogState extends State<_PaperFormatDialog> {
  late PaperFeed _feed = widget.initial?.feed ?? PaperFeed.sheet;
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  late final Map<String, TextEditingController> _numbers = {
    'pageWidth': _numberController(widget.initial?.pageWidthMm ?? 210),
    'pageHeight': _numberController(widget.initial?.pageHeightMm ?? 297),
    'columns': _numberController((widget.initial?.columns ?? 3).toDouble()),
    'rows': _numberController((widget.initial?.rows ?? 8).toDouble()),
    'cellWidth': _numberController(widget.initial?.cellWidthMm ?? 70),
    'cellHeight': _numberController(widget.initial?.cellHeightMm ?? 37),
    'marginTop': _numberController(widget.initial?.marginTopMm ?? 0),
    'marginLeft': _numberController(widget.initial?.marginLeftMm ?? 0),
    'gapX': _numberController(widget.initial?.gapXMm ?? 0),
    'gapY': _numberController(widget.initial?.gapYMm ?? 0),
  };
  PaperFormatError? _error;

  static TextEditingController _numberController(double value) =>
      TextEditingController(text: PaperFormat.formatMm(value));

  @override
  void dispose() {
    _name.dispose();
    for (final controller in _numbers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double _value(String key) =>
      double.tryParse(_numbers[key]!.text.trim().replaceAll(',', '.')) ?? 0;

  PaperFormat _build() {
    final isRoll = _feed == PaperFeed.roll;
    final cellWidth = _value('cellWidth');
    final cellHeight = _value('cellHeight');
    return PaperFormat(
      id: widget.initial?.id ?? PrintLibrary.newPaperFormatId(),
      name: _name.text.trim(),
      feed: _feed,
      // A roll prints one label per page: the page is the label.
      pageWidthMm: isRoll ? cellWidth : _value('pageWidth'),
      pageHeightMm: isRoll ? cellHeight : _value('pageHeight'),
      columns: isRoll ? 1 : _value('columns').round(),
      rows: isRoll ? 1 : _value('rows').round(),
      cellWidthMm: cellWidth,
      cellHeightMm: cellHeight,
      marginTopMm: isRoll ? 0 : _value('marginTop'),
      marginLeftMm: isRoll ? 0 : _value('marginLeft'),
      gapXMm: isRoll ? 0 : _value('gapX'),
      gapYMm: isRoll ? 0 : _value('gapY'),
    );
  }

  void _submit() {
    final format = _build();
    final error = format.validationError;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, format);
  }

  String _errorText(ReportLocalizations l10n, PaperFormatError error) =>
      switch (error) {
        PaperFormatError.sizeMissing => l10n.printPaperErrorSize,
        PaperFormatError.gridOutOfRange => l10n.printPaperErrorGrid,
        PaperFormatError.cellsOutsidePage => l10n.printPaperErrorOutside,
      };

  Widget _field(String key, String label) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: _numbers[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: printInputDecoration(label),
        onChanged: (_) => setState(() => _error = null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    final isRoll = _feed == PaperFeed.roll;
    final spacing = context.printSpacing.m;
    return AlertDialog(
      title: Text(
        widget.initial == null
            ? l10n.printNewPaperFormat
            : l10n.printEditPaperFormat,
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: printInputDecoration(
                  l10n.printPaperNameLabel,
                  helperText: l10n.printPaperNameHelp,
                ),
              ),
              SizedBox(height: spacing),
              SegmentedButton<PaperFeed>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: PaperFeed.sheet,
                    icon: const Icon(Icons.description_outlined),
                    label: Text(l10n.printPaperFeedSheet),
                  ),
                  ButtonSegment(
                    value: PaperFeed.roll,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(l10n.printPaperFeedRoll),
                  ),
                ],
                selected: {_feed},
                onSelectionChanged: (selection) =>
                    setState(() => _feed = selection.first),
              ),
              SizedBox(height: spacing),
              Text(
                isRoll
                    ? l10n.printPaperLabelSizeTitle
                    : l10n.printPaperCellSizeTitle,
                style: context.printText.labelLarge,
              ),
              SizedBox(height: context.printSpacing.s),
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _field('cellWidth', l10n.printPaperWidth),
                  _field('cellHeight', l10n.printPaperHeight),
                ],
              ),
              if (!isRoll) ...[
                SizedBox(height: spacing),
                Text(
                  l10n.printPaperPageTitle,
                  style: context.printText.labelLarge,
                ),
                SizedBox(height: context.printSpacing.s),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _field('pageWidth', l10n.printPaperWidth),
                    _field('pageHeight', l10n.printPaperHeight),
                  ],
                ),
                SizedBox(height: spacing),
                Text(
                  l10n.printPaperGridTitle,
                  style: context.printText.labelLarge,
                ),
                SizedBox(height: context.printSpacing.s),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _field('columns', l10n.printPaperColumns),
                    _field('rows', l10n.printPaperRows),
                    _field('marginTop', l10n.printPaperMarginTop),
                    _field('marginLeft', l10n.printPaperMarginLeft),
                    _field('gapX', l10n.printPaperGapX),
                    _field('gapY', l10n.printPaperGapY),
                  ],
                ),
              ],
              if (_error != null) ...[
                SizedBox(height: spacing),
                Text(
                  _errorText(l10n, _error!),
                  style: TextStyle(color: context.printColors.errorColorStatus),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.printCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.printSave)),
      ],
    );
  }
}
