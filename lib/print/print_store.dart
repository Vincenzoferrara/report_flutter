/// Collections of the print library.
enum PrintCollection { templates, paperFormats, categories }

/// One stored item. [data] is a JSON-compatible map owned by the library
/// model it comes from (template, paper format, category).
class PrintStoreItem {
  final String id;
  final String name;
  final Map<String, dynamic> data;

  const PrintStoreItem({
    required this.id,
    required this.name,
    required this.data,
  });
}

/// What a [PrintStore] holds at a given moment.
class PrintStoreSnapshot {
  /// The current user may create, change and delete items. Everybody can
  /// read and print.
  final bool canManage;

  /// The default library was already stored once: it must not be stored
  /// again, even when the user deleted every default item on purpose.
  final bool defaultsLoaded;

  final List<PrintStoreItem> templates;
  final List<PrintStoreItem> paperFormats;
  final List<PrintStoreItem> categories;

  const PrintStoreSnapshot({
    required this.canManage,
    required this.defaultsLoaded,
    this.templates = const [],
    this.paperFormats = const [],
    this.categories = const [],
  });
}

/// Where the print library lives: a server, a file, a database. The app
/// provides the implementation; the library only calls these methods and
/// changes its own lists after they succeed.
abstract class PrintStore {
  Future<PrintStoreSnapshot> load();

  /// Stores the default library once. Items that already exist are kept.
  Future<PrintStoreSnapshot> loadDefaults({
    required List<PrintStoreItem> templates,
    required List<PrintStoreItem> paperFormats,
    required List<PrintStoreItem> categories,
  });

  Future<void> save(PrintCollection collection, PrintStoreItem item);

  Future<void> delete(PrintCollection collection, String itemId);
}

/// Keeps the library in memory: useful for demos and for apps that do not
/// persist templates. Everything is lost when the app closes.
class InMemoryPrintStore implements PrintStore {
  InMemoryPrintStore({this.canManage = true});

  final bool canManage;
  bool _defaultsLoaded = false;
  final Map<PrintCollection, Map<String, PrintStoreItem>> _items = {
    for (final collection in PrintCollection.values) collection: {},
  };

  PrintStoreSnapshot _snapshot() => PrintStoreSnapshot(
    canManage: canManage,
    defaultsLoaded: _defaultsLoaded,
    templates: _items[PrintCollection.templates]!.values.toList(),
    paperFormats: _items[PrintCollection.paperFormats]!.values.toList(),
    categories: _items[PrintCollection.categories]!.values.toList(),
  );

  @override
  Future<PrintStoreSnapshot> load() async => _snapshot();

  @override
  Future<PrintStoreSnapshot> loadDefaults({
    required List<PrintStoreItem> templates,
    required List<PrintStoreItem> paperFormats,
    required List<PrintStoreItem> categories,
  }) async {
    if (!_defaultsLoaded) {
      void add(PrintCollection collection, List<PrintStoreItem> items) {
        for (final item in items) {
          _items[collection]!.putIfAbsent(item.id, () => item);
        }
      }

      add(PrintCollection.templates, templates);
      add(PrintCollection.paperFormats, paperFormats);
      add(PrintCollection.categories, categories);
      _defaultsLoaded = true;
    }
    return _snapshot();
  }

  @override
  Future<void> save(PrintCollection collection, PrintStoreItem item) async {
    _items[collection]![item.id] = item;
  }

  @override
  Future<void> delete(PrintCollection collection, String itemId) async {
    _items[collection]!.remove(itemId);
  }
}
