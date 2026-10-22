import 'package:flutter/material.dart';

import '../l10n/report_l10n.dart';
import 'print_theme.dart';
import 'paper_format.dart';
import 'print_library.dart';
import 'print_preview.dart';
import 'print_template.dart';

/// Every template on one screen, grouped by category: each group has its
/// title and a dividing line. Templates without a category close the list.
class PrintTemplateGroups extends StatelessWidget {
  const PrintTemplateGroups({
    super.key,
    required this.library,
    required this.onTap,
    this.where,
    this.showEmptyCategories = false,
    this.cardMenu,
    this.categoryActions,
    this.emptyText,
  });

  final PrintLibrary library;
  final ValueChanged<PrintTemplate> onTap;
  final bool Function(PrintTemplate template)? where;
  final bool showEmptyCategories;
  final Widget Function(PrintTemplate template)? cardMenu;
  final Widget Function(PrintCategory category)? categoryActions;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    final groups = library
        .grouped(where: where)
        .where(
          (group) =>
              group.templates.isNotEmpty ||
              (showEmptyCategories && group.category != null),
        );
    if (groups.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.printSpacing.xxl),
        child: Center(
          child: Text(
            emptyText ?? l10n.printNoTemplates,
            textAlign: TextAlign.center,
            style: context.printText.bodyLarge?.copyWith(
              color: context.printColors.subtitleColor,
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups) ...[
          SizedBox(height: context.printSpacing.l),
          Row(
            children: [
              Expanded(
                child: Text(
                  group.category?.name ?? l10n.printNoCategory,
                  style: context.printText.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (group.category != null && categoryActions != null)
                categoryActions!(group.category!),
            ],
          ),
          const Divider(height: 16),
          if (group.templates.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: context.printSpacing.s),
              child: Text(
                l10n.printEmptyCategory,
                style: context.printText.bodyMedium?.copyWith(
                  color: context.printColors.subtitleColor,
                ),
              ),
            )
          else
            _TemplateGrid(
              templates: group.templates,
              library: library,
              onTap: onTap,
              cardMenu: cardMenu,
            ),
        ],
      ],
    );
  }
}

class _TemplateGrid extends StatelessWidget {
  const _TemplateGrid({
    required this.templates,
    required this.library,
    required this.onTap,
    this.cardMenu,
  });

  final List<PrintTemplate> templates;
  final PrintLibrary library;
  final ValueChanged<PrintTemplate> onTap;
  final Widget Function(PrintTemplate template)? cardMenu;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = context.printSpacing.m;
        final columns = (constraints.maxWidth / 230).floor().clamp(2, 6);
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final template in templates)
              SizedBox(
                width: width,
                child: PrintTemplateCard(
                  template: template,
                  paper: library.paperFormatOf(template),
                  onTap: () => onTap(template),
                  menu: cardMenu?.call(template),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Preview, name and paper format of a template.
class PrintTemplateCard extends StatelessWidget {
  const PrintTemplateCard({
    super.key,
    required this.template,
    required this.paper,
    required this.onTap,
    this.menu,
  });

  final PrintTemplate template;
  final PaperFormat paper;
  final VoidCallback onTap;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 150,
              color: context.printTheme.colorScheme.surfaceContainerHighest,
              padding: context.printSpacing.iM,
              child: PrintTemplateThumbnail(template: template),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.printSpacing.m,
                context.printSpacing.s,
                context.printSpacing.xs,
                context.printSpacing.m,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.printText.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: context.printSpacing.xs),
                        Text(
                          paper.displayName(l10n),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.printText.bodySmall?.copyWith(
                            color: context.printColors.subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ?menu,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditorSection extends StatelessWidget {
  const EditorSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(top: context.printSpacing.m),
      child: Padding(
        padding: context.printSpacing.iL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: context.printTheme.colorScheme.primary,
                ),
                SizedBox(width: context.printSpacing.s),
                Expanded(
                  child: Text(
                    title,
                    style: context.printText.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.printSpacing.m),
            child,
          ],
        ),
      ),
    );
  }
}

class InfoBox extends StatelessWidget {
  const InfoBox({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.printTheme.colorScheme;
    return Container(
      padding: context.printSpacing.iM,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: context.printShapes.m,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.onPrimaryContainer),
          SizedBox(width: context.printSpacing.s),
          Expanded(
            child: Text(
              text,
              style: context.printText.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.printTheme.dividerColor),
        borderRadius: context.printShapes.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.printDecrease,
            icon: const Icon(Icons.remove),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: context.printText.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.printIncrease,
            icon: const Icon(Icons.add),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

/// Paper formats, sheets and rolls listed separately.
class PaperPicker extends StatelessWidget {
  const PaperPicker({
    super.key,
    required this.formats,
    required this.selectedId,
    required this.onSelected,
  });

  final List<PaperFormat> formats;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    if (formats.isEmpty) {
      return Text(l10n.printPaperMissing, style: context.printText.bodyMedium);
    }
    final sheets = formats
        .where((format) => format.feed == PaperFeed.sheet)
        .toList();
    final rolls = formats
        .where((format) => format.feed == PaperFeed.roll)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sheets.isNotEmpty) ...[
          _groupTitle(
            context,
            Icons.description_outlined,
            l10n.printPaperGroupSheets,
          ),
          for (final format in sheets) _tile(context, format),
        ],
        if (rolls.isNotEmpty) ...[
          SizedBox(height: context.printSpacing.s),
          _groupTitle(
            context,
            Icons.receipt_long_outlined,
            l10n.printPaperGroupRolls,
          ),
          for (final format in rolls) _tile(context, format),
        ],
      ],
    );
  }

  Widget _groupTitle(BuildContext context, IconData icon, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.printSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.printColors.subtitleColor),
          SizedBox(width: context.printSpacing.xs),
          Expanded(
            child: Text(
              title,
              style: context.printText.labelLarge?.copyWith(
                color: context.printColors.subtitleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, PaperFormat format) {
    final selected = format.id == selectedId;
    final scheme = context.printTheme.colorScheme;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: context.printShapes.s),
      selected: selected,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.4),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? scheme.primary : null,
      ),
      title: Text(format.displayName(context.reportL10n)),
      subtitle: format.name.trim().isEmpty
          ? null
          : Text(format.describe(context.reportL10n)),
      onTap: () => onSelected(format.id),
    );
  }
}

/// Asks for a short text such as a template or category name.
Future<String?> askPrintName(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(title: title, label: label, initial: initial),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.label,
    required this.initial,
  });

  final String title;
  final String label;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        decoration: printInputDecoration(widget.label),
        onSubmitted: (_) => _submit(),
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

/// Asks to confirm a deletion. Returns true when confirmed.
Future<bool> confirmPrintDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final l10n = context.reportL10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.printCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: context.printColors.errorColorStatus,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.printDelete),
        ),
      ],
    ),
  );
  return confirmed == true;
}
