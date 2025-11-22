import 'package:formula_parser/formula_parser.dart';
import '../models/report_element.dart';
import '../schema/data_schema.dart';

/// Motore per la valutazione di formule Excel-like
class FormulaEngine {
  /// Valuta una formula con i dati forniti
  static dynamic evaluate(String formula, Map<String, dynamic> data, Map<String, String> variables) {
    try {
      // 1. Sostituisci le variabili {campo} con i valori reali
      final resolvedFormula = _resolveVariables(formula, data, variables);
      
      // 2. Usa formula_parser per valutare l'espressione
      final parser = FormulaParser(resolvedFormula);
      final result = parser.parse;
      
      if (result.isSuccess) {
        return result.value;
      } else {
        throw Exception('Errore sintassi formula: ${result.error}');
      }
    } catch (e) {
      throw Exception('Errore valutazione formula: $e');
    }
  }

  /// Risolve le variabili {campo} nei valori reali dai dati
  static String _resolveVariables(String formula, Map<String, dynamic> data, Map<String, String> variables) {
    String resolved = formula;
    
    // Sostituisci ogni variabile con il valore corrispondente dai dati
    variables.forEach((varName, dataPath) {
      final value = _getNestedValue(data, dataPath);
      final varPattern = '{$varName}';
      resolved = resolved.replaceAll(varPattern, value.toString());
    });
    
    return resolved;
  }

  /// Ottiene un valore annidato da una mappa usando notazione dot (es: 'user.profile.name')
  static dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;
    
    final parts = path.split('.');
    dynamic current = data;
    
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null; // Campo non trovato
      }
    }
    
    return current;
  }

  /// Formatta il risultato secondo il formato specificato
  static String formatResult(dynamic result, String? format) {
    if (result == null) return '0';
    
    switch (format) {
      case 'currency':
        return _formatCurrency(result);
      case 'percentage':
        return _formatPercentage(result);
      case 'date':
        return _formatDate(result);
      case 'number':
      default:
        return _formatNumber(result);
    }
  }

  /// Formatta come valuta (€)
  static String _formatCurrency(dynamic value) {
    final numValue = num.tryParse(value.toString()) ?? 0;
    return '€${numValue.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Formatta come percentuale
  static String _formatPercentage(dynamic value) {
    final numValue = num.tryParse(value.toString()) ?? 0;
    return '${(numValue * 100).toStringAsFixed(1)}%';
  }

  /// Formatta come numero
  static String _formatNumber(dynamic value) {
    final numValue = num.tryParse(value.toString()) ?? 0;
    if (numValue is int) {
      return numValue.toString();
    } else {
      return numValue.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  /// Formatta come data
  static String _formatDate(dynamic value) {
    try {
      DateTime date;
      if (value is DateTime) {
        date = value;
      } else if (value is String) {
        date = DateTime.parse(value);
      } else if (value is int) {
        date = DateTime.fromMillisecondsSinceEpoch(value);
      } else {
        return value.toString();
      }
      
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return value.toString();
    }
  }

  /// Estrae le variabili da una formula
  static List<String> extractVariables(String formula) {
    final regex = RegExp(r'\{([^}]+)\}');
    final matches = regex.allMatches(formula);
    return matches.map((match) => match.group(1)!).toList();
  }

  /// Valida la sintassi di una formula
  static bool validateSyntax(String formula) {
    try {
      // Rimuovi temporaneamente le variabili per la validazione
      String testFormula = formula;
      final variables = extractVariables(formula);
      
      for (final variable in variables) {
        testFormula = testFormula.replaceAll('{$variable}', '1');
      }
      
      final parser = FormulaParser(testFormula);
      final result = parser.parse;
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene i campi dati richiesti da una formula
  static List<String> getRequiredFields(String formula, Map<String, String> variables) {
    final fields = <String>[];
    final formulaVariables = extractVariables(formula);
    
    for (final formulaVar in formulaVariables) {
      final dataPath = variables[formulaVar];
      if (dataPath != null) {
        fields.add(dataPath);
      }
    }
    
    return fields;
  }
}