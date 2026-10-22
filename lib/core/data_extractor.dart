/// Information about a field extracted from a class
class FieldInfo {
  final String name;
  final String displayName;
  final Type type;
  final dynamic value;
  final bool isNested; // true for an object with sub-fields

  FieldInfo({
    required this.name,
    required this.displayName,
    required this.type,
    this.value,
    this.isNested = false,
  });

  @override
  String toString() => '$displayName ($type)';
}

/// Extracts fields from any object for the report designer
class DataExtractor {
  /// Extracts all available fields from an object
  /// Supports: Map, objects with toJson(), plain objects
  static List<FieldInfo> extractFields(dynamic object, {String prefix = ''}) {
    if (object == null) return [];

    final fields = <FieldInfo>[];
    Map<String, dynamic>? data;

    // Converti in Map
    if (object is Map<String, dynamic>) {
      data = object;
    } else if (object is Map) {
      data = Map<String, dynamic>.from(object);
    } else {
      // Try toJson()
      try {
        data = (object as dynamic).toJson() as Map<String, dynamic>;
      } catch (_) {
        return [];
      }
    }

    data.forEach((key, value) {
      final fieldName = prefix.isEmpty ? key : '$prefix.$key';
      final displayName = _formatDisplayName(key);

      if (value is Map) {
        // Nested field - extract recursively
        fields.add(
          FieldInfo(
            name: fieldName,
            displayName: displayName,
            type: Map,
            value: value,
            isNested: true,
          ),
        );
        fields.addAll(extractFields(value, prefix: fieldName));
      } else if (value is List) {
        fields.add(
          FieldInfo(
            name: fieldName,
            displayName: displayName,
            type: List,
            value: value,
            isNested: true,
          ),
        );
        // When the list has items, extract the fields of the first one
        if (value.isNotEmpty && value.first is Map) {
          fields.addAll(extractFields(value.first, prefix: '$fieldName[]'));
        }
      } else {
        fields.add(
          FieldInfo(
            name: fieldName,
            displayName: displayName,
            type: value.runtimeType,
            value: value,
          ),
        );
      }
    });

    return fields;
  }

  /// Reads a field value from an object by path (e.g. "product.name")
  static dynamic getValue(dynamic object, String fieldPath) {
    if (object == null || fieldPath.isEmpty) return null;

    Map<String, dynamic>? data;

    // Converti in Map
    if (object is Map<String, dynamic>) {
      data = object;
    } else if (object is Map) {
      data = Map<String, dynamic>.from(object);
    } else {
      try {
        data = (object as dynamic).toJson() as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }

    final parts = fieldPath.split('.');
    dynamic current = data;

    for (final part in parts) {
      if (current == null) return null;

      // Handle array access (e.g. "items[0]")
      final arrayMatch = RegExp(r'^(.+)\[(\d+)\]$').firstMatch(part);
      if (arrayMatch != null) {
        final key = arrayMatch.group(1)!;
        final index = int.parse(arrayMatch.group(2)!);
        if (current is Map) {
          current = current[key];
        }
        if (current is List && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current;
  }

  /// Formats the value for display
  static String formatValue(dynamic value, {String? format}) {
    if (value == null) return '';

    switch (format) {
      case 'currency':
        if (value is num) {
          return value.toStringAsFixed(2);
        }
        break;
      case 'date':
        if (value is DateTime) {
          return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
        } else if (value is String) {
          try {
            final dt = DateTime.parse(value);
            return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
          } catch (_) {}
        }
        break;
      case 'datetime':
        if (value is DateTime) {
          return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
        }
        break;
      case 'number':
        if (value is num) {
          return value.toString();
        }
        break;
      case 'integer':
        if (value is num) {
          return value.toInt().toString();
        }
        break;
      case 'percentage':
        if (value is num) {
          return '${(value * 100).toStringAsFixed(1)}%';
        }
        break;
    }

    return value.toString();
  }

  /// Converts a field name to a readable label
  static String _formatDisplayName(String name) {
    // camelCase or snake_case -> "Readable Name"
    return name
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  /// Lists the fields as plain strings (for dropdowns)
  static List<String> getFieldNames(dynamic object) {
    return extractFields(
      object,
    ).where((f) => !f.isNested).map((f) => f.name).toList();
  }

  /// Maps field name -> type (for validation)
  static Map<String, Type> getFieldTypes(dynamic object) {
    return Map.fromEntries(
      extractFields(
        object,
      ).where((f) => !f.isNested).map((f) => MapEntry(f.name, f.type)),
    );
  }
}
