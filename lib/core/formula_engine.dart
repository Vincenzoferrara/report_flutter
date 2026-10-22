/// Engine that evaluates Excel-like formulas
class FormulaEngine {
  /// Evaluates a formula with the given data
  static dynamic evaluate(
    String formula,
    Map<String, dynamic> data,
    Map<String, String> variables,
  ) {
    try {
      // 1. Replace the {field} variables with the real values
      final resolvedFormula = _resolveVariables(formula, data, variables);

      // 2. Evaluate the arithmetic expression without external dependencies.
      return _FormulaExpressionParser(resolvedFormula).parse();
    } catch (e) {
      throw Exception('Formula evaluation error: $e');
    }
  }

  /// Replaces the {field} variables with the real values from the data
  static String _resolveVariables(
    String formula,
    Map<String, dynamic> data,
    Map<String, String> variables,
  ) {
    String resolved = formula;

    variables.forEach((varName, dataPath) {
      final value = _getNestedValue(data, dataPath);
      final varPattern = '{$varName}';
      resolved = resolved.replaceAll(varPattern, value.toString());
    });

    return resolved;
  }

  /// Reads a nested value from a map using dot notation (e.g. 'user.profile.name')
  static dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;

    final parts = path.split('.');
    dynamic current = data;

    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null; // Field not found
      }
    }

    return current;
  }

  /// Formats the result with the given format
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

  /// Formats as currency (€)
  static String _formatCurrency(dynamic value) {
    final numValue = num.tryParse(value.toString()) ?? 0;
    return '€${numValue.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Formats as percentage
  static String _formatPercentage(dynamic value) {
    final numValue = num.tryParse(value.toString()) ?? 0;
    return '${(numValue * 100).toStringAsFixed(1)}%';
  }

  /// Formats as number
  static String _formatNumber(dynamic value) {
    final numValue = num.tryParse(value.toString()) ?? 0;
    if (numValue is int) {
      return numValue.toString();
    } else {
      return numValue.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  /// Formats as date
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

  /// Extracts the variables of a formula
  static List<String> extractVariables(String formula) {
    final regex = RegExp(r'\{([^}]+)\}');
    final matches = regex.allMatches(formula);
    return matches.map((match) => match.group(1)!).toList();
  }

  /// Validates the syntax of a formula
  static bool validateSyntax(String formula) {
    try {
      // Temporarily remove the variables for the validation
      String testFormula = formula;
      final variables = extractVariables(formula);

      for (final variable in variables) {
        testFormula = testFormula.replaceAll('{$variable}', '1');
      }

      _FormulaExpressionParser(testFormula).parse();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Returns the data fields a formula needs
  static List<String> getRequiredFields(
    String formula,
    Map<String, String> variables,
  ) {
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

class _FormulaExpressionParser {
  _FormulaExpressionParser(this._source);

  final String _source;
  int _index = 0;

  num parse() {
    final value = _parseExpression();
    _skipWhitespace();
    if (!_isAtEnd) {
      throw FormatException('Invalid character: ${_source[_index]}');
    }
    return value;
  }

  num _parseExpression() {
    var value = _parseTerm();
    while (true) {
      _skipWhitespace();
      if (_match('+')) {
        value += _parseTerm();
      } else if (_match('-')) {
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  num _parseTerm() {
    var value = _parseFactor();
    while (true) {
      _skipWhitespace();
      if (_match('*')) {
        value *= _parseFactor();
      } else if (_match('/')) {
        final divisor = _parseFactor();
        if (divisor == 0) {
          throw const FormatException('Division by zero');
        }
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  num _parseFactor() {
    _skipWhitespace();
    if (_match('+')) return _parseFactor();
    if (_match('-')) return -_parseFactor();

    if (_match('(')) {
      final value = _parseExpression();
      _skipWhitespace();
      if (!_match(')')) {
        throw const FormatException('Missing closing parenthesis');
      }
      return value;
    }

    return _parseNumber();
  }

  num _parseNumber() {
    _skipWhitespace();
    final start = _index;

    while (!_isAtEnd && _isDigit(_source[_index])) {
      _index++;
    }

    if (!_isAtEnd && (_source[_index] == '.' || _source[_index] == ',')) {
      _index++;
      while (!_isAtEnd && _isDigit(_source[_index])) {
        _index++;
      }
    }

    if (start == _index) {
      throw const FormatException('Number expected');
    }

    final token = _source.substring(start, _index).replaceAll(',', '.');
    final value = num.tryParse(token);
    if (value == null) {
      throw FormatException('Invalid number: $token');
    }
    return value;
  }

  bool _match(String expected) {
    if (_isAtEnd || _source[_index] != expected) return false;
    _index++;
    return true;
  }

  void _skipWhitespace() {
    while (!_isAtEnd && _source[_index].trim().isEmpty) {
      _index++;
    }
  }

  bool _isDigit(String char) =>
      char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;

  bool get _isAtEnd => _index >= _source.length;
}
