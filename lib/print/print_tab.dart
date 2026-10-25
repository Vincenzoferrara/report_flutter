import 'package:flutter/material.dart';

import '../l10n/report_l10n.dart';
import 'print_theme.dart';
import 'paper_format.dart';
import 'print_controller.dart';
import 'print_job.dart';
import 'print_pdf_renderer.dart';
import 'print_preview.dart';
import 'print_scope.dart';
import 'print_widgets.dart';

/// Print tab: every template grouped by category; tapping one shows the
/// preview and the print settings. When labels were requested from the
/// products list, only product labels are listed and they print the real
/// products.
class PrintTab extends StatelessWidget {
  const PrintTab({super.key, required this.controller});

  final PrintController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: controller.isPrinting
          ? _PrintSettingsView(
              key: const ValueKey('settings'),
              controller: controller,
            )
          : _ChooseTemplateView(
              key: const ValueKey('choose'),
              controller: controller,
            ),
    );
  }
}

class _ChooseTemplateView extends StatelessWidget {
  const _ChooseTemplateView({super.key, required this.controller});

  final PrintController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    final job = controller.job;
    return ListView(
      padding: context.printSpacing.iL,
      children: [
        if (job != null) ...[
          _JobBanner(controller: controller, job: job),
          SizedBox(height: context.printSpacing.m),
        ],
        Text(
          job == null
              ? l10n.printTemplateQuestion
              : l10n.printJobTemplateQuestion,
          style: context.printText.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.printSpacing.xs),
        Text(
          l10n.printPrintHelp,
          style: context.printText.bodyLarge?.copyWith(
            color: context.printColors.subtitleColor,
          ),
        ),
        PrintTemplateGroups(
          library: controller.library,
          where: controller.accepts,
          onTap: controller.chooseTemplate,
        ),
      ],
    );
  }
}

class _JobBanner extends StatelessWidget {
  const _JobBanner({required this.controller, required this.job});

  final PrintController controller;
  final PrintJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    return Card(
      color: context.printTheme.colorScheme.primaryContainer,
      child: Padding(
        padding: context.printSpacing.iL,
        child: Row(
          children: [
            Icon(
              Icons.sell_outlined,
              color: context.printTheme.colorScheme.onPrimaryContainer,
            ),
            SizedBox(width: context.printSpacing.m),
            Expanded(
              child: Text(
                l10n.printJobSummary(job.rows.length, job.totalCopies),
                style: context.printText.titleSmall?.copyWith(
                  color: context.printTheme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: controller.clearJob,
              icon: const Icon(Icons.close),
              label: Text(l10n.printJobCancel),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrintSettingsView extends StatefulWidget {
  const _PrintSettingsView({super.key, required this.controller});

  final PrintController controller;

  @override
  State<_PrintSettingsView> createState() => _PrintSettingsViewState();
}

class _PrintSettingsViewState extends State<_PrintSettingsView> {
  // Sheets open on the whole sheet: every label, real data and the skipped
  // positions are visible at once.
  bool _showWholeSheet = true;
  bool _busy = false;

  PrintController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final paper = _controller.paper!;
    final canZoom = paper.isMultiCellSheet;
    final preview = _PreviewPanel(
      request: _controller.request(
        context,
        preview: true,
        singleCell: canZoom && !_showWholeSheet,
      ),
      canSwitchView: canZoom,
      showWholeSheet: _showWholeSheet,
      hasRealData: _controller.job != null,
      onViewChanged: (value) => setState(() => _showWholeSheet = value),
    );
    final settings = _SettingsPanel(controller: _controller);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        return Column(
          children: [
            Expanded(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 400,
                          child: ListView(
                            padding: context.printSpacing.iL,
                            children: [settings],
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: preview),
                      ],
                    )
                  // On narrow screens the preview stays fixed on top and only
                  // the settings scroll, so every change is seen at once.
                  : Column(
                      children: [
                        SizedBox(
                          height: (constraints.maxHeight * 0.45).clamp(
                            220.0,
                            460.0,
                          ),
                          child: preview,
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView(
                            padding: context.printSpacing.iL,
                            children: [settings],
                          ),
                        ),
                      ],
                    ),
            ),
            _PrintActionBar(
              busy: _busy,
              canPrint: _controller.canPrint,
              onPrint: () => _run(_controller.printSelected),
              onSave: () => _run(_saveSelected),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSelected(BuildContext context) async {
    final saved = await _controller.saveSelected(context);
    // Cancelling the dialog is not an error: nothing to show.
    if (saved == null || !context.mounted) return;
    context.showPrintMessage(
      context.reportL10n.printPdfSaved(saved),
      kind: PrintMessageKind.success,
    );
  }

  Future<void> _run(Future<void> Function(BuildContext context) action) async {
    final l10n = context.reportL10n;
    setState(() => _busy = true);
    try {
      await action(context);
    } catch (error) {
      if (!mounted) return;
      context.showPrintMessage(
        l10n.printPrintError(error.toString()),
        kind: PrintMessageKind.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.controller});

  final PrintController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    final template = controller.template!;
    final paper = controller.paper!;
    final job = controller.job;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.printChangeTemplate,
              icon: const Icon(Icons.arrow_back),
              onPressed: controller.closeTemplate,
            ),
            Expanded(
              child: Text(
                template.name,
                style: context.printText.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (PrintScope.of(context).dataProvider.pageNotice(context, template)
            case final notice? when job == null) ...[
          SizedBox(height: context.printSpacing.m),
          InfoBox(text: notice),
        ],
        if (job != null)
          EditorSection(
            icon: Icons.sell_outlined,
            title: l10n.printJobLabelsTitle,
            child: _JobQuantities(
              controller: controller,
              job: job,
              paper: paper,
            ),
          )
        else
          EditorSection(
            icon: Icons.content_copy_outlined,
            title: l10n.printSectionQuantity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QuantityEditor(controller: controller, paper: paper),
                if (controller.dataProvider.canPickRows &&
                    controller.dataProvider.acceptsRows(template)) ...[
                  SizedBox(height: context.printSpacing.l),
                  Text(
                    l10n.printAddLabelsHelp,
                    style: context.printText.bodySmall?.copyWith(
                      color: context.printColors.subtitleColor,
                    ),
                  ),
                  SizedBox(height: context.printSpacing.s),
                  _AddLabelsButton(controller: controller),
                ],
              ],
            ),
          ),
        EditorSection(
          icon: Icons.straighten,
          title: l10n.printSectionPaper,
          child: PaperPicker(
            formats: controller.library.paperFormats,
            selectedId: paper.id,
            onSelected: controller.setPaper,
          ),
        ),
      ],
    );
  }
}

class _QuantityEditor extends StatelessWidget {
  const _QuantityEditor({required this.controller, required this.paper});

  final PrintController controller;
  final PaperFormat paper;

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    final isSheet = paper.isMultiCellSheet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.printCopiesQuestion, style: context.printText.bodyMedium),
        SizedBox(height: context.printSpacing.s),
        Wrap(
          spacing: context.printSpacing.s,
          runSpacing: context.printSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            NumberStepper(
              value: controller.copies,
              min: 1,
              max: 999,
              onChanged: controller.setCopies,
            ),
            if (isSheet && controller.copies != paper.cellsPerPage)
              ActionChip(
                avatar: const Icon(Icons.grid_on, size: 18),
                label: Text(l10n.printFullSheet(paper.cellsPerPage)),
                onPressed: () => controller.setCopies(paper.cellsPerPage),
              ),
          ],
        ),
        if (isSheet) _SkipEditor(controller: controller, paper: paper),
      ],
    );
  }
}

/// One line per product or variant, with its labels to print.
class _JobQuantities extends StatelessWidget {
  const _JobQuantities({
    required this.controller,
    required this.job,
    required this.paper,
  });

  final PrintController controller;
  final PrintJob job;
  final PaperFormat paper;

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.printJobQuantityHelp,
          style: context.printText.bodySmall?.copyWith(
            color: context.printColors.subtitleColor,
          ),
        ),
        SizedBox(height: context.printSpacing.s),
        _AddLabelsButton(controller: controller),
        SizedBox(height: context.printSpacing.s),
        if (job.rows.isEmpty)
          Text(l10n.printJobEmpty, style: context.printText.bodyMedium),
        for (final item in job.rows)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.printSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.printText.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.printText.bodySmall?.copyWith(
                          color: context.printColors.subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.printSpacing.s),
                Text(
                  l10n.printJobLabelCount(item.quantity),
                  style: context.printText.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  tooltip: l10n.printJobRemove,
                  icon: Icon(
                    Icons.delete_outline,
                    color: context.printColors.errorColorStatus,
                  ),
                  onPressed: () => controller.removeRow(item.key),
                ),
              ],
            ),
          ),
        if (paper.isMultiCellSheet)
          _SkipEditor(controller: controller, paper: paper),
      ],
    );
  }
}

/// Lets the user choose more rows through the app ([PrintDataProvider.pickRows])
/// and adds the ones not listed yet.
class _AddLabelsButton extends StatelessWidget {
  const _AddLabelsButton({required this.controller});

  final PrintController controller;

  Future<void> _add(BuildContext context) async {
    final l10n = context.reportL10n;
    final more = await controller.dataProvider.pickRows(context);
    if (more == null || more.rows.isEmpty || !context.mounted) return;
    final added = controller.addToJob(more);
    if (added == 0) {
      context.showPrintMessage(
        l10n.printAddLabelsAlreadyListed,
        kind: PrintMessageKind.info,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.dataProvider.canPickRows) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: () => _add(context),
      icon: const Icon(Icons.add),
      label: Text(context.reportL10n.printAddLabels),
    );
  }
}

/// One "positions already used" counter per sheet to print. Only shown for
/// sheets with more than one label: rolls always start from the first label.
class _SkipEditor extends StatelessWidget {
  const _SkipEditor({required this.controller, required this.paper});

  final PrintController controller;
  final PaperFormat paper;

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    final skips = controller.sheetSkips;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.printSpacing.l),
        Text(l10n.printSkipQuestion, style: context.printText.bodyMedium),
        SizedBox(height: context.printSpacing.xs),
        Text(
          l10n.printSkipHelp,
          style: context.printText.bodySmall?.copyWith(
            color: context.printColors.subtitleColor,
          ),
        ),
        SizedBox(height: context.printSpacing.s),
        for (var sheet = 0; sheet < skips.length; sheet++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.printSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.printSheetNumber(sheet + 1),
                    style: context.printText.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                NumberStepper(
                  value: skips[sheet],
                  min: 0,
                  max: paper.cellsPerPage - 1,
                  onChanged: (value) =>
                      controller.setSkippedCells(sheet, value),
                ),
              ],
            ),
          ),
        SizedBox(height: context.printSpacing.m),
        Text(
          l10n.printSheetsNeeded(skips.length),
          style: context.printText.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.request,
    required this.canSwitchView,
    required this.showWholeSheet,
    required this.hasRealData,
    required this.onViewChanged,
  });

  final PrintRequest request;
  final bool canSwitchView;
  final bool showWholeSheet;
  final bool hasRealData;
  final ValueChanged<bool> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    final notice = canSwitchView && showWholeSheet
        ? l10n.printPreviewSheetNotice
        : hasRealData
        ? l10n.printPreviewRealNotice
        : l10n.printPreviewSampleNotice;
    return Container(
      color: context.printTheme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.5,
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.printSpacing.l,
              context.printSpacing.m,
              context.printSpacing.l,
              context.printSpacing.s,
            ),
            child: Wrap(
              spacing: context.printSpacing.m,
              runSpacing: context.printSpacing.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  l10n.printPreviewTitle,
                  style: context.printText.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (canSwitchView)
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: false,
                        icon: const Icon(Icons.zoom_in),
                        label: Text(l10n.printPreviewOneLabel),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: const Icon(Icons.grid_view),
                        label: Text(l10n.printPreviewWholeSheet),
                      ),
                    ],
                    selected: {showWholeSheet},
                    onSelectionChanged: (selection) =>
                        onViewChanged(selection.first),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.printSpacing.l),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: context.printColors.subtitleColor,
                ),
                SizedBox(width: context.printSpacing.xs),
                Expanded(
                  child: Text(
                    notice,
                    style: context.printText.bodySmall?.copyWith(
                      color: context.printColors.subtitleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: PdfPagesView(request: request)),
        ],
      ),
    );
  }
}

class _PrintActionBar extends StatelessWidget {
  const _PrintActionBar({
    required this.busy,
    required this.canPrint,
    required this.onPrint,
    required this.onSave,
  });

  final bool busy;
  final bool canPrint;
  final VoidCallback onPrint;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    final enabled = !busy && canPrint;
    return Material(
      elevation: 6,
      color: context.printTheme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.printSpacing.l,
            vertical: context.printSpacing.m,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: OutlinedButton.icon(
                  onPressed: enabled ? onSave : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l10n.printSavePdf),
                ),
              ),
              SizedBox(width: context.printSpacing.m),
              Flexible(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 18,
                    ),
                    textStyle: context.printText.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: enabled ? onPrint : null,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print),
                  label: Text(l10n.printPrint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
