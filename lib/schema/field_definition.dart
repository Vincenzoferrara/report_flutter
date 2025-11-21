/// Risultato della validazione
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final String? errorMessage;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.errorMessage,
  });

  factory ValidationResult.success() {
    return const ValidationResult(isValid: true);
  }

  factory ValidationResult.failure(List<String> errors, {List<String> warnings = const []}) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
      errorMessage: errors.isNotEmpty ? errors.first : null,
    );
  }

  factory ValidationResult.warning(List<String> warnings) {
    return ValidationResult(
      isValid: true,
      warnings: warnings,
    );
  }

  factory ValidationResult.error(String message) {
    return ValidationResult(
      isValid: false,
      errors: [message],
      errorMessage: message,
    );
  }
}

/// Definizione di un campo dati per lo schema
class FieldDefinition {
  final String name;
  final String displayName;
  final Type type;
  final bool isRequired;
  final dynamic defaultValue;
  final List<String> validationRules;
  final String? description;
  final Map<String, dynamic>? metadata;

  FieldDefinition({
    required this.name,
    required this.displayName,
    required this.type,
    this.isRequired = false,
    this.defaultValue,
    this.validationRules = const [],
    this.description,
    this.metadata,
  });

  /// Crea FieldDefinition da JSON
  factory FieldDefinition.fromJson(Map<String, dynamic> json) {
    Type fieldType;
    final typeString = json['type'] as String;
    
    switch (typeString.toLowerCase()) {
      case 'string':
        fieldType = String;
        break;
      case 'int':
      case 'integer':
        fieldType = int;
        break;
      case 'double':
      case 'num':
      case 'number':
        fieldType = double;
        break;
      case 'bool':
      case 'boolean':
        fieldType = bool;
        break;
      case 'datetime':
        fieldType = DateTime;
        break;
      default:
        fieldType = String; // fallback
    }

    return FieldDefinition(
      name: json['name'],
      displayName: json['displayName'] ?? json['name'],
      type: fieldType,
      isRequired: json['isRequired'] ?? false,
      defaultValue: json['defaultValue'],
      validationRules: List<String>.from(json['validationRules'] ?? []),
      description: json['description'],
      metadata: json['metadata'],
    );
  }

  /// Converte in JSON
  Map<String, dynamic> toJson() {
    String typeString;
    if (type == String) {
      typeString = 'String';
    } else if (type == int) {
      typeString = 'int';
    } else if (type == double) {
      typeString = 'double';
    } else if (type == bool) {
      typeString = 'bool';
    } else if (type == DateTime) {
      typeString = 'DateTime';
    } else {
      typeString = type.toString();
    }

    return {
      'name': name,
      'displayName': displayName,
      'type': typeString,
      'isRequired': isRequired,
      'defaultValue': defaultValue,
      'validationRules': validationRules,
      'description': description,
      'metadata': metadata,
    };
  }

  /// Valida un valore contro questa definizione
  ValidationResult validate(dynamic value) {
    // Check required
    if (isRequired && (value == null || value.toString().trim().isEmpty)) {
      return ValidationResult.error('Il campo "$displayName" è obbligatorio');
    }

    // Skip validation if value is null and not required
    if (value == null) {
      return ValidationResult.success();
    }

    // Type validation
    if (!_isValidType(value)) {
      return ValidationResult.error('Il campo "$displayName" deve essere di tipo ${_getTypeName()}');
    }

    // Custom validation rules
    for (final rule in validationRules) {
      final result = _validateRule(rule, value);
      if (!result.isValid) {
        return result;
      }
    }

    return ValidationResult.success();
  }

  bool _isValidType(dynamic value) {
    if (type == String) return value is String;
    if (type == int) return value is int || (value is String && int.tryParse(value) != null);
    if (type == double) return value is double || (value is String && double.tryParse(value) != null);
    if (type == bool) return value is bool || (value is String && (value.toLowerCase() == 'true' || value.toLowerCase() == 'false'));
    if (type == DateTime) return value is DateTime || (value is String && DateTime.tryParse(value) != null);
    return true;
  }

  String _getTypeName() {
    if (type == String) return 'testo';
    if (type == int) return 'numero intero';
    if (type == double) return 'numero decimale';
    if (type == bool) return 'booleano';
    if (type == DateTime) return 'data';
    return type.toString();
  }

  ValidationResult _validateRule(String rule, dynamic value) {
    final parts = rule.split(':');
    final ruleName = parts[0];
    final ruleParam = parts.length > 1 ? parts[1] : null;

    switch (ruleName) {
      case 'minLength':
        final minLength = int.tryParse(ruleParam ?? '0') ?? 0;
        if (value.toString().length < minLength) {
          return ValidationResult.error('Il campo "$displayName" deve avere almeno $minLength caratteri');
        }
        break;
      case 'maxLength':
        final maxLength = int.tryParse(ruleParam ?? '999') ?? 999;
        if (value.toString().length > maxLength) {
          return ValidationResult.error('Il campo "$displayName" non può superare $maxLength caratteri');
        }
        break;
      case 'min':
        final min = double.tryParse(ruleParam ?? '0') ?? 0;
        final numValue = double.tryParse(value.toString()) ?? 0;
        if (numValue < min) {
          return ValidationResult.error('Il campo "$displayName" deve essere almeno $min');
        }
        break;
      case 'max':
        final max = double.tryParse(ruleParam ?? '999999') ?? 999999;
        final numValue = double.tryParse(value.toString()) ?? 0;
        if (numValue > max) {
          return ValidationResult.error('Il campo "$displayName" non può superare $max');
        }
        break;
      case 'pattern':
        final pattern = ruleParam ?? '';
        final regex = RegExp(pattern);
        if (!regex.hasMatch(value.toString())) {
          return ValidationResult.error('Il campo "$displayName" non ha un formato valido');
        }
        break;
    }

    return ValidationResult.success();
  }

  /// Copia con modifiche
  FieldDefinition copyWith({
    String? name,
    String? displayName,
    Type? type,
    bool? isRequired,
    dynamic defaultValue,
    List<String>? validationRules,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return FieldDefinition(
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      defaultValue: defaultValue ?? this.defaultValue,
      validationRules: validationRules ?? this.validationRules,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldDefinition &&
        other.name == name &&
        other.displayName == displayName &&
        other.type == type &&
        other.isRequired == isRequired &&
        other.defaultValue == defaultValue &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(name, displayName, type, isRequired, defaultValue, description);
  }

  @override
  String toString() {
    return 'FieldDefinition(name: $name, displayName: $displayName, type: $type, required: $isRequired)';
  }
}

