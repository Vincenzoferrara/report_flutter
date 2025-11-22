import 'field_definition.dart';
import 'dart:convert';

/// Schema astratto per definire la struttura dei dati
abstract class DataSchema {
  String get name;
  String get displayName;
  String get description;
  List<FieldDefinition> get fields;
  Map<String, dynamic> get sampleData;
  Map<String, dynamic> get metadata;

  const DataSchema();

  /// Trova una field definition per nome
  FieldDefinition? getField(String name) {
    try {
      return fields.firstWhere((field) => field.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Valida un oggetto dati contro questo schema
  ValidationResult validate(dynamic data) {
    if (data == null) {
      return ValidationResult.error('I dati sono null');
    }

    // Converti in Map se necessario
    Map<String, dynamic> dataMap;
    if (data is Map<String, dynamic>) {
      dataMap = data;
    } else if (data is Map) {
      dataMap = Map<String, dynamic>.from(data);
    } else {
      try {
        dataMap = (data as dynamic).toJson() as Map<String, dynamic>;
      } catch (_) {
        return ValidationResult.error('Impossibile convertire i dati in formato valido');
      }
    }

    // Valida tutti i campi definiti nello schema
    for (final field in fields) {
      final value = dataMap[field.name];
      final result = field.validate(value);
      
      if (!result.isValid) {
        return result;
      }
    }

    return ValidationResult.success();
  }

  /// Valida una lista di oggetti dati
  ValidationResult validateList(List<dynamic> dataList) {
    if (dataList.isEmpty) {
      return ValidationResult.error('La lista di dati è vuota');
    }

    for (int i = 0; i < dataList.length; i++) {
      final result = validate(dataList[i]);
      if (!result.isValid) {
        return ValidationResult.error('Errore alla riga ${i + 1}: ${result.errorMessage}');
      }
    }

    return ValidationResult.success();
  }

  /// Estrai tutti i nomi dei campi disponibili
  List<String> getFieldNames() {
    return fields.map((field) => field.name).toList();
  }

  /// Estrai i campi di un certo tipo
  List<FieldDefinition> getFieldsByType(Type type) {
    return fields.where((field) => field.type == type).toList();
  }

  /// Estrai solo i campi richiesti
  List<FieldDefinition> getRequiredFields() {
    return fields.where((field) => field.isRequired).toList();
  }

  /// Converte lo schema in JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'description': description,
      'fields': fields.map((field) => field.toJson()).toList(),
      'sampleData': sampleData,
      'metadata': metadata,
    };
  }

  /// Crea schema da JSON
  factory DataSchema.fromJson(Map<String, dynamic> json) {
    return _JsonDataSchema.fromJson(json);
  }

  /// Crea schema da classe generica (reflection-based)
  factory DataSchema.fromClass(Type type) {
    return _ReflectionDataSchema(type);
  }
}

/// Implementazione concreta per schema da JSON
class _JsonDataSchema extends DataSchema {
  @override
  final String name;
  @override
  final String displayName;
  @override
  final String description;
  @override
  final List<FieldDefinition> fields;
  @override
  final Map<String, dynamic> sampleData;
  @override
  final Map<String, dynamic> metadata;

  const _JsonDataSchema({
    required this.name,
    required this.displayName,
    required this.description,
    required this.fields,
    required this.sampleData,
    required this.metadata,
  });

  factory _JsonDataSchema.fromJson(Map<String, dynamic> json) {
    return _JsonDataSchema(
      name: json['name'],
      displayName: json['displayName'] ?? json['name'],
      description: json['description'] ?? '',
      fields: (json['fields'] as List?)
          ?.map((field) => FieldDefinition.fromJson(field))
          .toList() ?? [],
      sampleData: Map<String, dynamic>.from(json['sampleData'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Implementazione per schema basata su reflection (future implementation)
class _ReflectionDataSchema extends DataSchema {
  final Type _type;
  
  _ReflectionDataSchema(this._type);

  @override
  String get name => _type.toString();
  
  @override
  String get displayName => _formatDisplayName(_type.toString());
  
  @override
  String get description => 'Schema generato da classe $name';
  
  @override
  List<FieldDefinition> get fields => _extractFieldsFromClass();
  
  @override
  Map<String, dynamic> get sampleData => _generateSampleData();
  
  @override
  Map<String, dynamic> get metadata => {
    'generated': true,
    'source': 'reflection',
    'className': name,
  };

  List<FieldDefinition> _extractFieldsFromClass() {
    // TODO: Implementare reflection quando disponibile in Dart
    // Per ora ritorna lista vuota
    return [];
  }

  Map<String, dynamic> _generateSampleData() {
    // TODO: Generare dati sample basati sui campi
    return {};
  }

  String _formatDisplayName(String className) {
    return className
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }
}

/// Registry per schemi disponibili
class SchemaRegistry {
  static final Map<String, DataSchema Function()> _schemas = {
    // Gli schemi vengono registrati dall'app che usa il pacchetto
    // Esempio: SchemaRegistry.register('Product', () => MyProductSchema());
  };

  /// Registra un nuovo schema
  static void register(String name, DataSchema Function() factory) {
    _schemas[name] = factory;
  }

  /// Ottieni schema per nome
  static DataSchema? getSchema(String name) {
    final factory = _schemas[name];
    return factory?.call();
  }

  /// Lista tutti i nomi degli schemi disponibili
  static List<String> getAvailableSchemas() {
    return _schemas.keys.toList();
  }

  /// Controlla se uno schema esiste
  static bool hasSchema(String name) {
    return _schemas.containsKey(name);
  }
}