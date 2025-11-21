import 'report_element.dart';
import '../schema/data_schema.dart';
import '../schema/field_definition.dart';

/// Formato pagina predefinito
enum PageFormat {
  a4Portrait,
  a4Landscape,
  letter,
  thermal58mm,
  thermal80mm,
  custom,
}

/// Tipo di report
enum ReportType {
  label,      // Etichette (multiple per pagina)
  document,   // Documento singolo
  list,       // Lista multi-pagina
}

/// Template per report - accetta qualsiasi classe dati
class ReportTemplate {
  final String id;
  String name;
  String? description;
  ReportType reportType;

  // Dimensioni pagina in mm
  double pageWidth;
  double pageHeight;
  PageFormat pageFormat;

  // Margini pagina in mm
  double marginTop;
  double marginBottom;
  double marginLeft;
  double marginRight;

  // Layout per etichette/items multipli
  int itemsPerRow;
  int itemsPerColumn;
  double horizontalGap;
  double verticalGap;
  double itemWidth;
  double itemHeight;

  // Elementi nel template
  List<ReportElement> elements;

  // Schema dati associato
  String? dataSchemaName;
  DataSchema? dataSchema;

  // Metadati
  DateTime createdAt;
  DateTime updatedAt;

  ReportTemplate({
    required this.id,
    required this.name,
    this.description,
    this.reportType = ReportType.label,
    this.pageWidth = 210,
    this.pageHeight = 297,
    this.pageFormat = PageFormat.a4Portrait,
    this.marginTop = 10,
    this.marginBottom = 10,
    this.marginLeft = 10,
    this.marginRight = 10,
    this.itemsPerRow = 4,
    this.itemsPerColumn = 6,
    this.horizontalGap = 2,
    this.verticalGap = 2,
    this.itemWidth = 40,  // Verticale: larghezza minore
    this.itemHeight = 45, // Verticale: altezza maggiore
    List<ReportElement>? elements,
    this.dataSchemaName,
    this.dataSchema,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : elements = elements ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  void setPageFormat(PageFormat format) {
    pageFormat = format;
    switch (format) {
      case PageFormat.a4Portrait:
        pageWidth = 210;
        pageHeight = 297;
        break;
      case PageFormat.a4Landscape:
        pageWidth = 297;
        pageHeight = 210;
        break;
      case PageFormat.letter:
        pageWidth = 216;
        pageHeight = 279;
        break;
      case PageFormat.thermal58mm:
        pageWidth = 58;
        pageHeight = 40;
        itemsPerRow = 1;
        itemsPerColumn = 1;
        break;
      case PageFormat.thermal80mm:
        pageWidth = 80;
        pageHeight = 40;
        itemsPerRow = 1;
        itemsPerColumn = 1;
        break;
      case PageFormat.custom:
        break;
    }
    updatedAt = DateTime.now();
  }

  void addElement(ReportElement element) {
    elements.add(element);
    updatedAt = DateTime.now();
  }

  void removeElement(String elementId) {
    elements.removeWhere((e) => e.id == elementId);
    updatedAt = DateTime.now();
  }

  void updateElement(ReportElement element) {
    final index = elements.indexWhere((e) => e.id == element.id);
    if (index != -1) {
      elements[index] = element;
      updatedAt = DateTime.now();
    }
  }

  ReportElement? getElementById(String elementId) {
    try {
      return elements.firstWhere((e) => e.id == elementId);
    } catch (_) {
      return null;
    }
  }

  List<ReportElement> get sortedElements {
    final sorted = List<ReportElement>.from(elements);
    sorted.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return sorted;
  }

  /// Valida una lista di dati contro lo schema del template
  ValidationResult validateData(List<dynamic> data) {
    if (dataSchema == null) {
      return ValidationResult.success(); // Nessuna validazione se non c'è schema
    }
    
    return dataSchema!.validateList(data);
  }

  /// Valida un singolo dato contro lo schema del template
  ValidationResult validateSingleData(dynamic data) {
    if (dataSchema == null) {
      return ValidationResult.success();
    }
    
    return dataSchema!.validate(data);
  }

  /// Imposta lo schema dati
  void setDataSchema(DataSchema schema) {
    dataSchema = schema;
    dataSchemaName = schema.name;
    updatedAt = DateTime.now();
  }

  /// Carica lo schema dal registry per nome
  bool loadSchemaByName(String schemaName) {
    final schema = SchemaRegistry.getSchema(schemaName);
    if (schema != null) {
      setDataSchema(schema);
      return true;
    }
    return false;
  }

  /// Verifica se un campo è valido nello schema
  bool isValidField(String fieldName) {
    if (dataSchema == null) return true; // Nessuna validazione se non c'è schema
    return dataSchema!.getField(fieldName) != null;
  }

  /// Ottieni la definizione di un campo
  FieldDefinition? getFieldDefinition(String fieldName) {
    return dataSchema?.getField(fieldName);
  }

  /// Lista tutti i campi disponibili dallo schema
  List<String> getAvailableFields() {
    if (dataSchema == null) return [];
    return dataSchema!.getFieldNames();
  }

  /// Ottieni dati sample dallo schema
  Map<String, dynamic> getSampleData() {
    return dataSchema?.sampleData ?? {};
  }

  ReportTemplate copyWith({
    String? id,
    String? name,
    String? description,
    ReportType? reportType,
    double? pageWidth,
    double? pageHeight,
    PageFormat? pageFormat,
    double? marginTop,
    double? marginBottom,
    double? marginLeft,
    double? marginRight,
    int? itemsPerRow,
    int? itemsPerColumn,
    double? horizontalGap,
    double? verticalGap,
    double? itemWidth,
    double? itemHeight,
    List<ReportElement>? elements,
    String? dataSchemaName,
    DataSchema? dataSchema,
  }) {
    return ReportTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      reportType: reportType ?? this.reportType,
      pageWidth: pageWidth ?? this.pageWidth,
      pageHeight: pageHeight ?? this.pageHeight,
      pageFormat: pageFormat ?? this.pageFormat,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
      itemsPerRow: itemsPerRow ?? this.itemsPerRow,
      itemsPerColumn: itemsPerColumn ?? this.itemsPerColumn,
      horizontalGap: horizontalGap ?? this.horizontalGap,
      verticalGap: verticalGap ?? this.verticalGap,
      itemWidth: itemWidth ?? this.itemWidth,
      itemHeight: itemHeight ?? this.itemHeight,
      elements: elements ?? this.elements.map((e) => e.copyWith()).toList(),
      dataSchemaName: dataSchemaName ?? this.dataSchemaName,
      dataSchema: dataSchema ?? this.dataSchema,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'reportType': reportType.name,
      'pageWidth': pageWidth,
      'pageHeight': pageHeight,
      'pageFormat': pageFormat.name,
      'marginTop': marginTop,
      'marginBottom': marginBottom,
      'marginLeft': marginLeft,
      'marginRight': marginRight,
      'itemsPerRow': itemsPerRow,
      'itemsPerColumn': itemsPerColumn,
      'horizontalGap': horizontalGap,
      'verticalGap': verticalGap,
      'itemWidth': itemWidth,
      'itemHeight': itemHeight,
      'elements': elements.map((e) => e.toJson()).toList(),
      'dataSchemaName': dataSchemaName,
      'dataSchema': dataSchema?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ReportTemplate.fromJson(Map<String, dynamic> json) {
    return ReportTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      reportType: ReportType.values.firstWhere(
        (e) => e.name == json['reportType'],
        orElse: () => ReportType.label,
      ),
      pageWidth: (json['pageWidth'] as num).toDouble(),
      pageHeight: (json['pageHeight'] as num).toDouble(),
      pageFormat: PageFormat.values.firstWhere(
        (e) => e.name == json['pageFormat'],
        orElse: () => PageFormat.a4Portrait,
      ),
      marginTop: (json['marginTop'] as num?)?.toDouble() ?? 10,
      marginBottom: (json['marginBottom'] as num?)?.toDouble() ?? 10,
      marginLeft: (json['marginLeft'] as num?)?.toDouble() ?? 10,
      marginRight: (json['marginRight'] as num?)?.toDouble() ?? 10,
      itemsPerRow: json['itemsPerRow'] ?? 3,
      itemsPerColumn: json['itemsPerColumn'] ?? 8,
      horizontalGap: (json['horizontalGap'] as num?)?.toDouble() ?? 2,
      verticalGap: (json['verticalGap'] as num?)?.toDouble() ?? 2,
      itemWidth: (json['itemWidth'] as num?)?.toDouble() ?? 50,
      itemHeight: (json['itemHeight'] as num?)?.toDouble() ?? 30,
      elements: (json['elements'] as List?)
              ?.map((e) => ReportElement.fromJson(e))
              .toList() ??
          [],
      dataSchemaName: json['dataSchemaName'],
      dataSchema: json['dataSchema'] != null 
          ? DataSchema.fromJson(json['dataSchema'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
