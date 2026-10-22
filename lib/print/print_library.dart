import 'package:flutter/widgets.dart';

import '../l10n/report_l10n.dart';
import 'paper_format.dart';
import 'print_store.dart';
import 'print_template.dart';

/// Defaults stored the first time a print library is set up.
class PrintLibraryOptions {
  const PrintLibraryOptions({
    this.loadDefaultPaperFormats = true,
    this.defaultTemplates,
    this.defaultCategories,
  });

  /// Stores the ready-made paper formats of the library
  /// ([PaperFormatDefaults]) together with the other defaults. When false the
  /// library starts without paper formats and they are created by hand.
  final bool loadDefaultPaperFormats;

  /// Ready-made templates of the app, built in the current language.
  final List<PrintTemplate> Function(BuildContext context)? defaultTemplates;

  /// Ready-made categories of the app, built in the current language.
  final List<PrintCategory> Function(BuildContext context)? defaultCategories;
}

/// Manages a print library: templates, their categories and the paper
/// formats, kept by a [PrintStore].
///
/// Nothing is changed locally first: every change goes to the store and the
/// lists change only when the store accepted it.
class PrintLibrary extends ChangeNotifier {
  PrintLibrary({
    required this.store,
    this.options = const PrintLibraryOptions(),
  });

  /// Where the library is read from and written to.
  final PrintStore store;
  final PrintLibraryOptions options;

  List<PrintTemplate> _templates = const [];
  List<PrintCategory> _categories = const [];
  List<PaperFormat> _paperFormats = const [];
  bool _canManage = false;
  bool _defaultsLoaded = false;
  bool _loading = false;
  bool _loaded = false;
  Object? _error;

  List<PrintTemplate> get templates => List.unmodifiable(_templates);
  List<PaperFormat> get paperFormats => List.unmodifiable(_paperFormats);
  bool get canManage => _canManage;
  bool get defaultsLoaded => _defaultsLoaded;
  bool get loading => _loading;
  bool get loaded => _loaded;
  Object? get error => _error;

  /// Categories sorted by position, then by name.
  List<PrintCategory> get categories {
    final sorted = List<PrintCategory>.of(_categories);
    sorted.sort((a, b) {
      final byPosition = a.position.compareTo(b.position);
      return byPosition != 0
          ? byPosition
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  /// Templates grouped by category, in category order. Templates whose
  /// category does not exist any more are listed under a null key at the end.
  List<({PrintCategory? category, List<PrintTemplate> templates})> grouped({
    bool Function(PrintTemplate template)? where,
  }) {
    final visible = _templates.where(where ?? (_) => true).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final knownIds = _categories.map((category) => category.id).toSet();
    return [
      for (final category in categories)
        (
          category: category,
          templates: visible
              .where((template) => template.categoryId == category.id)
              .toList(),
        ),
      (
        category: null,
        templates: visible
            .where((template) => !knownIds.contains(template.categoryId))
            .toList(),
      ),
    ];
  }

  /// The paper format of [template]. When it was deleted, a single page as
  /// big as the design is used, so the template still prints.
  PaperFormat paperFormatOf(PrintTemplate template, {String? overrideId}) {
    final wanted = overrideId ?? template.paperFormatId;
    for (final format in _paperFormats) {
      if (format.id == wanted) return format;
    }
    return PaperFormat.single(
      widthMm: template.design.itemWidth,
      heightMm: template.design.itemHeight,
    );
  }

  /// Reads the library from the store. The first time a user allowed to
  /// manage it opens it, the defaults of [options] are stored once.
  Future<void> load(BuildContext context, {bool force = false}) async {
    if (_loading || (_loaded && !force)) return;
    _loading = true;
    _error = null;
    notifyListeners();
    // Built before the first await, while the context is surely valid.
    final templates =
        options.defaultTemplates?.call(context) ?? const <PrintTemplate>[];
    final categories =
        options.defaultCategories?.call(context) ?? const <PrintCategory>[];
    final paperFormats = options.loadDefaultPaperFormats
        ? PaperFormatDefaults.all(context.reportL10n)
        : const <PaperFormat>[];
    try {
      var library = await store.load();
      if (!library.defaultsLoaded && library.canManage) {
        library = await store.loadDefaults(
          templates: templates.map((item) => item.toItem()).toList(),
          paperFormats: paperFormats.map((item) => item.toItem()).toList(),
          categories: categories.map((item) => item.toItem()).toList(),
        );
      }
      _apply(library);
      _loaded = true;
    } catch (error, stack) {
      debugPrint('Print library not loaded: $error\n$stack');
      _error = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _apply(PrintStoreSnapshot library) {
    _canManage = library.canManage;
    _defaultsLoaded = library.defaultsLoaded;
    _templates = library.templates
        .map(PrintTemplate.tryFromItem)
        .whereType<PrintTemplate>()
        .toList();
    _paperFormats = library.paperFormats
        .map(PaperFormat.tryFromItem)
        .whereType<PaperFormat>()
        .toList();
    _categories = library.categories.map(PrintCategory.fromItem).toList();
  }

  Future<void> saveTemplate(PrintTemplate template) async {
    await store.save(PrintCollection.templates, template.toItem());
    _templates = [
      for (final entry in _templates)
        if (entry.id != template.id) entry,
      template,
    ];
    notifyListeners();
  }

  Future<void> deleteTemplate(String templateId) async {
    await store.delete(PrintCollection.templates, templateId);
    _templates = _templates.where((entry) => entry.id != templateId).toList();
    notifyListeners();
  }

  Future<void> saveCategory(PrintCategory category) async {
    await store.save(PrintCollection.categories, category.toItem());
    _categories = [
      for (final entry in _categories)
        if (entry.id != category.id) entry,
      category,
    ];
    notifyListeners();
  }

  /// Deletes the category. Its templates stay and are listed without a
  /// category until they are moved.
  Future<void> deleteCategory(String categoryId) async {
    await store.delete(PrintCollection.categories, categoryId);
    _categories = _categories.where((entry) => entry.id != categoryId).toList();
    notifyListeners();
  }

  /// Moves [category] one place up (-1) or down (+1) and stores the new
  /// positions of every category.
  Future<void> moveCategory(PrintCategory category, int direction) async {
    final ordered = categories;
    final index = ordered.indexWhere((entry) => entry.id == category.id);
    final target = index + direction;
    if (index < 0 || target < 0 || target >= ordered.length) return;
    final moved = ordered.removeAt(index);
    ordered.insert(target, moved);
    for (var position = 0; position < ordered.length; position++) {
      if (ordered[position].position != position) {
        await saveCategory(ordered[position].copyWith(position: position));
      }
    }
  }

  int get nextCategoryPosition => _categories.isEmpty
      ? 0
      : _categories
                .map((entry) => entry.position)
                .reduce((a, b) => a > b ? a : b) +
            1;

  Future<void> savePaperFormat(PaperFormat format) async {
    await store.save(PrintCollection.paperFormats, format.toItem());
    _paperFormats = [
      for (final entry in _paperFormats)
        if (entry.id != format.id) entry,
      format,
    ];
    notifyListeners();
  }

  Future<void> deletePaperFormat(String formatId) async {
    await store.delete(PrintCollection.paperFormats, formatId);
    _paperFormats = _paperFormats
        .where((entry) => entry.id != formatId)
        .toList();
    notifyListeners();
  }

  /// Templates that print on [formatId], shown before deleting a format.
  int templatesUsing(String formatId) =>
      _templates.where((template) => template.paperFormatId == formatId).length;

  static String newPaperFormatId() =>
      'paper_${DateTime.now().microsecondsSinceEpoch}';
}
