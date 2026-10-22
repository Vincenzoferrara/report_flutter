import '../models/report_template.dart';
import 'print_store.dart';

/// A label, sign or report template, kept by the [PrintStore].
///
/// [design] is the drag-and-drop layout edited in the designer: one label,
/// one sign or one report page, measured in millimetres. [paperFormatId] says
/// how many of them fit on the printed page. [settings] holds options the app
/// owns for this template (e.g. how it formats its data): the library stores
/// them with the template and never reads them.
class PrintTemplate {
  /// Keys of the stored data the library owns; every other key is a setting.
  static const Set<String> _ownKeys = {'category_id', 'paper_format', 'design'};

  final String id;
  final String name;
  final String? categoryId;
  final String paperFormatId;
  final ReportTemplate design;
  final Map<String, dynamic> settings;

  const PrintTemplate({
    required this.id,
    required this.name,
    this.categoryId,
    required this.paperFormatId,
    required this.design,
    this.settings = const {},
  });

  PrintTemplate copyWith({
    String? id,
    String? name,
    String? categoryId,
    bool clearCategory = false,
    String? paperFormatId,
    ReportTemplate? design,
    Map<String, dynamic>? settings,
  }) {
    return PrintTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      paperFormatId: paperFormatId ?? this.paperFormatId,
      design: design ?? this.design,
      settings: settings ?? this.settings,
    );
  }

  /// The template with [key] set to [value] in its [settings].
  PrintTemplate withSetting(String key, dynamic value) =>
      copyWith(settings: {...settings, key: value});

  PrintStoreItem toItem() => PrintStoreItem(
    id: id,
    name: name,
    data: {
      ...settings,
      'category_id': categoryId,
      'paper_format': paperFormatId,
      'design': design.toJson(),
    },
  );

  /// Returns null when the stored entry cannot be read, so a corrupted or
  /// future entry is skipped instead of breaking the template list.
  static PrintTemplate? tryFromItem(PrintStoreItem item) {
    final data = item.data;
    final design = data['design'];
    if (design is! Map) return null;
    try {
      return PrintTemplate(
        id: item.id,
        name: item.name,
        categoryId: data['category_id']?.toString(),
        paperFormatId: data['paper_format']?.toString() ?? '',
        design: ReportTemplate.fromJson(Map<String, dynamic>.from(design)),
        settings: {
          for (final entry in data.entries)
            if (!_ownKeys.contains(entry.key)) entry.key: entry.value,
        },
      );
    } catch (_) {
      return null;
    }
  }

  static String newId() => 'template_${DateTime.now().microsecondsSinceEpoch}';
}

/// A group of templates, e.g. "Labels" or "Sales". Categories only order the
/// list: the shop creates, renames, reorders and deletes them freely.
class PrintCategory {
  final String id;
  final String name;
  final int position;

  const PrintCategory({
    required this.id,
    required this.name,
    this.position = 0,
  });

  PrintCategory copyWith({String? name, int? position}) => PrintCategory(
    id: id,
    name: name ?? this.name,
    position: position ?? this.position,
  );

  PrintStoreItem toItem() =>
      PrintStoreItem(id: id, name: name, data: {'position': position});

  static PrintCategory fromItem(PrintStoreItem item) => PrintCategory(
    id: item.id,
    name: item.name,
    position: (item.data['position'] as num?)?.toInt() ?? 0,
  );

  static String newId() => 'category_${DateTime.now().microsecondsSinceEpoch}';
}
