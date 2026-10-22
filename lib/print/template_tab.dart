import 'package:flutter/material.dart';

import '../l10n/report_l10n.dart';
import 'print_theme.dart';
import 'paper_format.dart';
import 'paper_formats_page.dart';
import 'print_designer.dart';
import 'print_design_builder.dart';
import 'print_library.dart';
import 'print_template.dart';
import 'print_widgets.dart';

/// Template tab: every template of the shop grouped by category, with the
/// tools to create, edit, move and delete templates and categories and to
/// manage the paper formats. Only shop managers can change anything.
class TemplateTab extends StatelessWidget {
  const TemplateTab({super.key, required this.library});

  final PrintLibrary library;

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    final canManage = library.canManage;
    return ListView(
      padding: context.printSpacing.iL,
      children: [
        if (!canManage) ...[
          InfoBox(icon: Icons.lock_outline, text: l10n.printManagersOnly),
          SizedBox(height: context.printSpacing.s),
        ] else
          Wrap(
            spacing: context.printSpacing.s,
            runSpacing: context.printSpacing.s,
            children: [
              FilledButton.icon(
                onPressed: () => _createTemplate(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.printNewTemplate),
              ),
              OutlinedButton.icon(
                onPressed: () => _createCategory(context),
                icon: const Icon(Icons.create_new_folder_outlined),
                label: Text(l10n.printNewCategory),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PaperFormatsPage(library: library),
                  ),
                ),
                icon: const Icon(Icons.straighten),
                label: Text(l10n.printPaperFormats),
              ),
              OutlinedButton.icon(
                onPressed: () => editPaperFormat(context, library, null),
                icon: const Icon(Icons.add),
                label: Text(l10n.printNewPaperFormat),
              ),
            ],
          ),
        PrintTemplateGroups(
          library: library,
          showEmptyCategories: canManage,
          onTap: (template) => canManage ? _edit(context, template) : null,
          cardMenu: canManage
              ? (template) => _templateMenu(context, template)
              : null,
          categoryActions: canManage
              ? (category) => _categoryMenu(context, category)
              : null,
        ),
      ],
    );
  }

  // --- Templates --------------------------------------------------------------

  Widget _templateMenu(BuildContext context, PrintTemplate template) {
    final l10n = context.reportL10n;
    return PopupMenuButton<String>(
      tooltip: l10n.printTemplateActions,
      onSelected: (action) {
        switch (action) {
          case 'edit':
            _edit(context, template);
          case 'rename':
            _rename(context, template);
          case 'duplicate':
            _duplicate(context, template);
          case 'move':
            _move(context, template);
          case 'delete':
            _delete(context, template);
        }
      },
      itemBuilder: (_) => [
        _menuItem('edit', Icons.edit_outlined, l10n.printEditDesign),
        _menuItem('rename', Icons.drive_file_rename_outline, l10n.printRename),
        _menuItem('duplicate', Icons.copy_outlined, l10n.printDuplicate),
        _menuItem(
          'move',
          Icons.drive_file_move_outline,
          l10n.printMoveToCategory,
        ),
        _menuItem(
          'delete',
          Icons.delete_outline,
          l10n.printDelete,
          color: context.printColors.errorColorStatus,
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem(
      value: value,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _edit(BuildContext context, PrintTemplate template) async {
    final edited = await openPrintTemplateDesigner(context, template);
    if (edited == null || !context.mounted) return;
    await _save(
      context,
      () => library.saveTemplate(edited),
      context.reportL10n.printTemplateSaved(edited.name),
    );
  }

  Future<void> _rename(BuildContext context, PrintTemplate template) async {
    final l10n = context.reportL10n;
    final name = await askPrintName(
      context,
      title: l10n.printRename,
      label: l10n.printTemplateNameLabel,
      initial: template.name,
    );
    if (name == null || !context.mounted) return;
    await _save(
      context,
      () => library.saveTemplate(template.copyWith(name: name)),
      l10n.printTemplateSaved(name),
    );
  }

  Future<void> _duplicate(BuildContext context, PrintTemplate template) async {
    final l10n = context.reportL10n;
    final copy = template.copyWith(
      id: PrintTemplate.newId(),
      name: l10n.printCopyOf(template.name),
    );
    await _save(
      context,
      () => library.saveTemplate(copy),
      l10n.printTemplateSaved(copy.name),
    );
  }

  Future<void> _move(BuildContext context, PrintTemplate template) async {
    final l10n = context.reportL10n;
    const none = '';
    final chosen = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.printMoveToCategory),
        children: [
          for (final category in library.categories)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, category.id),
              child: Text(category.name),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, none),
            child: Text(l10n.printNoCategory),
          ),
        ],
      ),
    );
    if (chosen == null || !context.mounted) return;
    final moved = chosen == none
        ? template.copyWith(clearCategory: true)
        : template.copyWith(categoryId: chosen);
    await _save(
      context,
      () => library.saveTemplate(moved),
      l10n.printTemplateSaved(template.name),
    );
  }

  Future<void> _delete(BuildContext context, PrintTemplate template) async {
    final l10n = context.reportL10n;
    final confirmed = await confirmPrintDelete(
      context,
      title: l10n.printDeleteTemplateTitle,
      message: l10n.printDeleteTemplateMessage(template.name),
    );
    if (!confirmed || !context.mounted) return;
    await _save(
      context,
      () => library.deleteTemplate(template.id),
      l10n.printTemplateDeleted(template.name),
    );
  }

  Future<void> _createTemplate(BuildContext context) async {
    final setup = await showDialog<_NewTemplateSetup>(
      context: context,
      builder: (_) => _NewTemplateDialog(library: library),
    );
    if (setup == null || !context.mounted) return;
    final paper = setup.paper;
    final blank = PrintDesign(paper.cellWidthMm, paper.cellHeightMm);
    final id = PrintTemplate.newId();
    final template = PrintTemplate(
      id: id,
      name: setup.name,
      categoryId: setup.categoryId,
      paperFormatId: paper.id,
      design: blank.build(id: id, name: setup.name),
    );
    final edited = await openPrintTemplateDesigner(context, template);
    if (edited == null || !context.mounted) return;
    await _save(
      context,
      () => library.saveTemplate(edited),
      context.reportL10n.printTemplateSaved(edited.name),
    );
  }

  // --- Categories -------------------------------------------------------------

  Widget _categoryMenu(BuildContext context, PrintCategory category) {
    final l10n = context.reportL10n;
    return PopupMenuButton<String>(
      tooltip: l10n.printCategoryActions,
      onSelected: (action) {
        switch (action) {
          case 'rename':
            _renameCategory(context, category);
          case 'up':
            _save(context, () => library.moveCategory(category, -1), null);
          case 'down':
            _save(context, () => library.moveCategory(category, 1), null);
          case 'delete':
            _deleteCategory(context, category);
        }
      },
      itemBuilder: (_) => [
        _menuItem('rename', Icons.drive_file_rename_outline, l10n.printRename),
        _menuItem('up', Icons.arrow_upward, l10n.printMoveUp),
        _menuItem('down', Icons.arrow_downward, l10n.printMoveDown),
        _menuItem(
          'delete',
          Icons.delete_outline,
          l10n.printDelete,
          color: context.printColors.errorColorStatus,
        ),
      ],
    );
  }

  Future<void> _createCategory(BuildContext context) async {
    final l10n = context.reportL10n;
    final name = await askPrintName(
      context,
      title: l10n.printNewCategory,
      label: l10n.printCategoryNameLabel,
    );
    if (name == null || !context.mounted) return;
    final category = PrintCategory(
      id: PrintCategory.newId(),
      name: name,
      position: library.nextCategoryPosition,
    );
    await _save(
      context,
      () => library.saveCategory(category),
      l10n.printCategorySaved(name),
    );
  }

  Future<void> _renameCategory(
    BuildContext context,
    PrintCategory category,
  ) async {
    final l10n = context.reportL10n;
    final name = await askPrintName(
      context,
      title: l10n.printRename,
      label: l10n.printCategoryNameLabel,
      initial: category.name,
    );
    if (name == null || !context.mounted) return;
    await _save(
      context,
      () => library.saveCategory(category.copyWith(name: name)),
      l10n.printCategorySaved(name),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    PrintCategory category,
  ) async {
    final l10n = context.reportL10n;
    final confirmed = await confirmPrintDelete(
      context,
      title: l10n.printDeleteCategoryTitle,
      message: l10n.printDeleteCategoryMessage(category.name),
    );
    if (!confirmed || !context.mounted) return;
    await _save(
      context,
      () => library.deleteCategory(category.id),
      l10n.printCategoryDeleted(category.name),
    );
  }

  /// Runs a change on the server and reports the outcome.
  Future<void> _save(
    BuildContext context,
    Future<void> Function() action,
    String? success,
  ) async {
    final l10n = context.reportL10n;
    try {
      await action();
      if (success != null && context.mounted) {
        context.showPrintMessage(success, kind: PrintMessageKind.success);
      }
    } catch (error) {
      if (!context.mounted) return;
      context.showPrintMessage(
        l10n.printSaveError(error.toString()),
        kind: PrintMessageKind.error,
      );
    }
  }
}

class _NewTemplateSetup {
  final String name;
  final String? categoryId;
  final PaperFormat paper;

  const _NewTemplateSetup({
    required this.name,
    required this.categoryId,
    required this.paper,
  });
}

/// Name, category and paper format of a new template. The layout is
/// then drawn in the designer.
class _NewTemplateDialog extends StatefulWidget {
  const _NewTemplateDialog({required this.library});

  final PrintLibrary library;

  @override
  State<_NewTemplateDialog> createState() => _NewTemplateDialogState();
}

class _NewTemplateDialogState extends State<_NewTemplateDialog> {
  final TextEditingController _nameController = TextEditingController();
  String? _categoryId;
  String? _paperId;

  @override
  void initState() {
    super.initState();
    final categories = widget.library.categories;
    _categoryId = categories.isEmpty ? null : categories.first.id;
    _paperId = widget.library.paperFormats.firstOrNull?.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final paper = widget.library.paperFormats
        .where((format) => format.id == _paperId)
        .firstOrNull;
    if (name.isEmpty || paper == null) return;
    Navigator.pop(
      context,
      _NewTemplateSetup(name: name, categoryId: _categoryId, paper: paper),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    final formats = widget.library.paperFormats;
    return AlertDialog(
      title: Text(l10n.printNewTemplate),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: printInputDecoration(l10n.printTemplateNameLabel),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: context.printSpacing.l),
            DropdownButtonFormField<String?>(
              initialValue: _categoryId,
              decoration: printInputDecoration(l10n.printCategoryLabel),
              items: [
                for (final category in widget.library.categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.printNoCategory),
                ),
              ],
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            SizedBox(height: context.printSpacing.l),
            if (formats.isEmpty)
              Text(
                l10n.printPaperMissing,
                style: TextStyle(color: context.printColors.errorColorStatus),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _paperId,
                decoration: printInputDecoration(l10n.printSectionPaper),
                items: [
                  for (final format in formats)
                    DropdownMenuItem(
                      value: format.id,
                      child: Text(format.displayName(l10n)),
                    ),
                ],
                onChanged: (value) => setState(() => _paperId = value),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.printCancel),
        ),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty || formats.isEmpty
              ? null
              : _submit,
          child: Text(l10n.printOpenDesigner),
        ),
      ],
    );
  }
}
