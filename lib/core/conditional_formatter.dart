import 'package:flutter/material.dart';
import '../models/report_element.dart';

/// Servizio per applicare formattazione condizionale agli elementi
class ConditionalFormatter {
  /// Applica le regole di formattazione condizionale a un valore
  static Map<String, dynamic> applyRules(dynamic value, List<Map<String, dynamic>> rules) {
    for (final rule in rules) {
      if (_evaluateCondition(value, rule)) {
        return {
          'color': rule['foregroundColor'],
          'backgroundColor': rule['backgroundColor'],
          'fontWeight': rule['fontWeight'],
          'fontSize': rule['fontSize'],
          'fontStyle': rule['fontStyle'],
          'decoration': rule['decoration'],
        };
      }
    }
    return {}; // Nessuna regola applicata
  }

  /// Valuta una condizione di formattazione
  static bool _evaluateCondition(dynamic value, Map<String, dynamic> rule) {
    final type = rule['type'] as String?;
    
    switch (type) {
      case 'threshold':
        return _evaluateThreshold(value, rule);
      case 'contains':
        return _evaluateContains(value, rule);
      case 'range':
        return _evaluateRange(value, rule);
      case 'expression':
        return _evaluateExpression(value, rule);
      default:
        return false;
    }
  }

  /// Valuta condizioni basate su soglie numeriche
  static bool _evaluateThreshold(dynamic value, Map<String, dynamic> rule) {
    final condition = rule['condition'] as String?;
    final threshold = rule['value'] as num?;
    
    if (threshold == null) return false;
    
    final numValue = num.tryParse(value.toString());
    if (numValue == null) return false;
    
    switch (condition) {
      case 'greater':
        return numValue > threshold;
      case 'less':
        return numValue < threshold;
      case 'equal':
        return numValue == threshold;
      case 'greater_equal':
        return numValue >= threshold;
      case 'less_equal':
        return numValue <= threshold;
      default:
        return false;
    }
  }

  /// Valuta condizioni basate su contenuto testuale
  static bool _evaluateContains(dynamic value, Map<String, dynamic> rule) {
    final text = rule['text'] as String?;
    if (text == null) return false;
    
    final valueStr = value.toString().toLowerCase();
    final searchStr = text.toLowerCase();
    
    return valueStr.contains(searchStr);
  }

  /// Valuta condizioni basate su range di valori
  static bool _evaluateRange(dynamic value, Map<String, dynamic> rule) {
    final min = rule['min'] as num?;
    final max = rule['max'] as num?;
    
    if (min == null || max == null) return false;
    
    final numValue = num.tryParse(value.toString());
    if (numValue == null) return false;
    
    return numValue >= min && numValue <= max;
  }

  /// Valuta espressioni complesse (futuro implementazione)
  static bool _evaluateExpression(dynamic value, Map<String, dynamic> rule) {
    final expression = rule['expression'] as String?;
    if (expression == null) return false;
    
    // Implementazione base - potrebbe essere estesa con un motore di espressioni
    try {
      // Sostituisci {value} con il valore reale
      final evalExpression = expression.replaceAll('{value}', value.toString());
      
      // Valutazione semplificata - in una implementazione completa
      // si userebbe un motore di espressioni più potente
      if (evalExpression.contains('>')) {
        final parts = evalExpression.split('>');
        if (parts.length == 2) {
          final left = num.tryParse(parts[0].trim());
          final right = num.tryParse(parts[1].trim());
          return left != null && right != null && left > right;
        }
      }
      
      if (evalExpression.contains('<')) {
        final parts = evalExpression.split('<');
        if (parts.length == 2) {
          final left = num.tryParse(parts[0].trim());
          final right = num.tryParse(parts[1].trim());
          return left != null && right != null && left < right;
        }
      }
      
      if (evalExpression.contains('==')) {
        final parts = evalExpression.split('==');
        if (parts.length == 2) {
          return parts[0].trim() == parts[1].trim();
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Crea uno stile TextStyle basato sulle regole applicate
  static TextStyle? applyTextStyle(dynamic value, List<Map<String, dynamic>> rules, TextStyle baseStyle) {
    final formatting = applyRules(value, rules);
    if (formatting.isEmpty) return null;
    
    return baseStyle.copyWith(
      color: formatting['color'] != null ? _parseColor(formatting['color']) : baseStyle.color,
      backgroundColor: formatting['backgroundColor'] != null ? _parseColor(formatting['backgroundColor']) : baseStyle.backgroundColor,
      fontWeight: _parseFontWeight(formatting['fontWeight']),
      fontSize: formatting['fontSize'] != null ? (formatting['fontSize'] as num).toDouble() : baseStyle.fontSize,
      fontStyle: _parseFontStyle(formatting['fontStyle']),
      decoration: _parseTextDecoration(formatting['decoration']),
    );
  }

  /// Converte un colore esadecimale in Color
  static Color? _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;
    
    try {
      final buffer = StringBuffer();
      if (hexColor.length == 6 || hexColor.length == 7) buffer.write('ff');
      buffer.write(hexColor.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return null;
    }
  }

  /// Converte una stringa di peso font in FontWeight
  static FontWeight? _parseFontWeight(String? weight) {
    switch (weight) {
      case 'bold':
        return FontWeight.bold;
      case 'normal':
      default:
        return FontWeight.normal;
    }
  }

  /// Converte una stringa di stile font in FontStyle
  static FontStyle? _parseFontStyle(String? style) {
    switch (style) {
      case 'italic':
        return FontStyle.italic;
      case 'normal':
      default:
        return FontStyle.normal;
    }
  }

  /// Converte una stringa di decorazione in TextDecoration
  static TextDecoration? _parseTextDecoration(String? decoration) {
    switch (decoration) {
      case 'underline':
        return TextDecoration.underline;
      case 'lineThrough':
        return TextDecoration.lineThrough;
      case 'overline':
        return TextDecoration.overline;
      case 'none':
      default:
        return TextDecoration.none;
    }
  }

  /// Verifica se un elemento ha formattazione condizionale abilitata
  static bool isConditionalFormattingEnabled(ReportElement element) {
    final conditionalFormatting = element.properties['conditionalFormatting'] as Map<String, dynamic>?;
    return conditionalFormatting?['enabled'] == true;
  }

  /// Ottiene le regole di formattazione condizionale da un elemento
  static List<Map<String, dynamic>> getConditionalRules(ReportElement element) {
    final conditionalFormatting = element.properties['conditionalFormatting'] as Map<String, dynamic>?;
    final rules = conditionalFormatting?['rules'] as List<dynamic>?;
    
    if (rules == null) return [];
    
    return rules.map((rule) => Map<String, dynamic>.from(rule)).toList();
  }

  /// Aggiunge una nuova regola di formattazione condizionale
  static void addConditionalRule(ReportElement element, Map<String, dynamic> rule) {
    final conditionalFormatting = Map<String, dynamic>.from(
      element.properties['conditionalFormatting'] ?? {'enabled': true, 'rules': []}
    );
    
    final rules = List<Map<String, dynamic>>.from(conditionalFormatting['rules'] ?? []);
    rules.add(rule);
    
    conditionalFormatting['rules'] = rules;
    conditionalFormatting['enabled'] = true;
    
    element.properties['conditionalFormatting'] = conditionalFormatting;
  }

  /// Rimuove una regola di formattazione condizionale
  static void removeConditionalRule(ReportElement element, int index) {
    final conditionalFormatting = Map<String, dynamic>.from(
      element.properties['conditionalFormatting'] ?? {'enabled': true, 'rules': []}
    );
    
    final rules = List<Map<String, dynamic>>.from(conditionalFormatting['rules'] ?? []);
    if (index >= 0 && index < rules.length) {
      rules.removeAt(index);
      conditionalFormatting['rules'] = rules;
      element.properties['conditionalFormatting'] = conditionalFormatting;
    }
  }

  /// Aggiorna una regola di formattazione condizionale
  static void updateConditionalRule(ReportElement element, int index, Map<String, dynamic> rule) {
    final conditionalFormatting = Map<String, dynamic>.from(
      element.properties['conditionalFormatting'] ?? {'enabled': true, 'rules': []}
    );
    
    final rules = List<Map<String, dynamic>>.from(conditionalFormatting['rules'] ?? []);
    if (index >= 0 && index < rules.length) {
      rules[index] = rule;
      conditionalFormatting['rules'] = rules;
      element.properties['conditionalFormatting'] = conditionalFormatting;
    }
  }
}