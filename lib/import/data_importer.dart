import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import '../schema/data_schema.dart';
import '../schema/field_definition.dart';

/// Result of a data import
class ImportResult {
  final DataSchema schema;
  final List<Map<String, dynamic>> data;
  final int rowCount;
  final String? error;

  ImportResult({
    required this.schema,
    required this.data,
    required this.rowCount,
    this.error,
  });

  bool get isSuccess => error == null;
}

/// Imports data from several sources (CSV, JSON)
class DataImporter {
  /// Imports from a CSV file
  static Future<ImportResult> fromCsv(
    String filePath, {
    String? schemaName,
    String delimiter = ',',
    bool hasHeader = true,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(
          schema: _createEmptySchema(schemaName ?? 'ImportedData'),
          data: [],
          rowCount: 0,
          error: 'File not found: $filePath',
        );
      }

      final content = await file.readAsString();
      return fromCsvString(
        content,
        schemaName: schemaName ?? _extractFileName(filePath),
        delimiter: delimiter,
        hasHeader: hasHeader,
      );
    } catch (e) {
      return ImportResult(
        schema: _createEmptySchema(schemaName ?? 'ImportedData'),
        data: [],
        rowCount: 0,
        error: 'Error reading the file: $e',
      );
    }
  }

  /// Imports from a CSV string
  static ImportResult fromCsvString(
    String csvContent, {
    String schemaName = 'ImportedData',
    String delimiter = ',',
    bool hasHeader = true,
  }) {
    try {
      final converter = CsvDecoder(
        fieldDelimiter: delimiter,
        dynamicTyping: true,
      );

      final rows = converter.convert(csvContent);
      if (rows.isEmpty) {
        return ImportResult(
          schema: _createEmptySchema(schemaName),
          data: [],
          rowCount: 0,
          error: 'Empty CSV',
        );
      }

      // Extract the header
      List<String> headers;
      int dataStartIndex;

      if (hasHeader) {
        headers = rows.first.map((e) => e.toString()).toList();
        dataStartIndex = 1;
      } else {
        headers = List.generate(rows.first.length, (i) => 'campo_$i');
        dataStartIndex = 0;
      }

      // Infer the types from the data
      final fieldTypes = _inferFieldTypes(rows, headers, dataStartIndex);

      final fields = <FieldDefinition>[];
      for (int i = 0; i < headers.length; i++) {
        fields.add(
          FieldDefinition(
            name: _sanitizeFieldName(headers[i]),
            displayName: headers[i],
            type: fieldTypes[i],
            isRequired: false,
          ),
        );
      }

      final data = <Map<String, dynamic>>[];
      for (int i = dataStartIndex; i < rows.length; i++) {
        final row = rows[i];
        final rowMap = <String, dynamic>{};

        for (int j = 0; j < headers.length && j < row.length; j++) {
          final fieldName = _sanitizeFieldName(headers[j]);
          rowMap[fieldName] = row[j];
        }

        data.add(rowMap);
      }

      // Create a dynamic schema
      final schema = _ImportedDataSchema(
        name: schemaName,
        displayName: schemaName,
        description: 'Schema imported from CSV',
        fields: fields,
        sampleData: data.isNotEmpty ? data.first : {},
      );

      return ImportResult(schema: schema, data: data, rowCount: data.length);
    } catch (e) {
      return ImportResult(
        schema: _createEmptySchema(schemaName),
        data: [],
        rowCount: 0,
        error: 'Error parsing the CSV: $e',
      );
    }
  }

  /// Imports from a JSON file
  static Future<ImportResult> fromJson(
    String filePath, {
    String? schemaName,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(
          schema: _createEmptySchema(schemaName ?? 'ImportedData'),
          data: [],
          rowCount: 0,
          error: 'File not found: $filePath',
        );
      }

      final content = await file.readAsString();
      return fromJsonString(
        content,
        schemaName: schemaName ?? _extractFileName(filePath),
      );
    } catch (e) {
      return ImportResult(
        schema: _createEmptySchema(schemaName ?? 'ImportedData'),
        data: [],
        rowCount: 0,
        error: 'Error reading the file: $e',
      );
    }
  }

  /// Imports from a JSON string
  static ImportResult fromJsonString(
    String jsonContent, {
    String schemaName = 'ImportedData',
  }) {
    try {
      final decoded = jsonDecode(jsonContent);

      List<Map<String, dynamic>> dataList;
      if (decoded is List) {
        dataList = decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (decoded is Map) {
        dataList = [Map<String, dynamic>.from(decoded)];
      } else {
        return ImportResult(
          schema: _createEmptySchema(schemaName),
          data: [],
          rowCount: 0,
          error: 'Invalid JSON format',
        );
      }

      if (dataList.isEmpty) {
        return ImportResult(
          schema: _createEmptySchema(schemaName),
          data: [],
          rowCount: 0,
          error: 'Empty JSON',
        );
      }

      // Extract the fields from the first object
      final firstItem = dataList.first;
      final fields = <FieldDefinition>[];

      firstItem.forEach((key, value) {
        fields.add(
          FieldDefinition(
            name: key,
            displayName: _formatDisplayName(key),
            type: _inferType(value),
            isRequired: false,
          ),
        );
      });

      final schema = _ImportedDataSchema(
        name: schemaName,
        displayName: schemaName,
        description: 'Schema imported from JSON',
        fields: fields,
        sampleData: firstItem,
      );

      return ImportResult(
        schema: schema,
        data: dataList,
        rowCount: dataList.length,
      );
    } catch (e) {
      return ImportResult(
        schema: _createEmptySchema(schemaName),
        data: [],
        rowCount: 0,
        error: 'Error parsing the JSON: $e',
      );
    }
  }

  // Helper methods

  static String _extractFileName(String path) {
    final name = path.split('/').last.split('\\').last;
    final dotIndex = name.lastIndexOf('.');
    return dotIndex > 0 ? name.substring(0, dotIndex) : name;
  }

  static String _sanitizeFieldName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  static String _formatDisplayName(String name) {
    return name
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '',
        )
        .join(' ')
        .trim();
  }

  static List<Type> _inferFieldTypes(
    List<List<dynamic>> rows,
    List<String> headers,
    int dataStartIndex,
  ) {
    final types = List<Type>.filled(headers.length, String);
    final maxRows = (rows.length < dataStartIndex + 100)
        ? rows.length
        : dataStartIndex + 100;

    for (int col = 0; col < headers.length; col++) {
      bool allInt = true;
      bool allDouble = true;
      bool allBool = true;

      for (int row = dataStartIndex; row < maxRows; row++) {
        if (col >= rows[row].length) continue;

        final value = rows[row][col];
        if (value == null || value.toString().isEmpty) continue;

        if (value is! int) allInt = false;
        if (value is! double && value is! int) allDouble = false;
        if (value is! bool &&
            value.toString().toLowerCase() != 'true' &&
            value.toString().toLowerCase() != 'false') {
          allBool = false;
        }
      }

      if (allBool) {
        types[col] = bool;
      } else if (allInt) {
        types[col] = int;
      } else if (allDouble) {
        types[col] = double;
      } else {
        types[col] = String;
      }
    }

    return types;
  }

  static Type _inferType(dynamic value) {
    if (value == null) return String;
    if (value is int) return int;
    if (value is double) return double;
    if (value is bool) return bool;
    if (value is List) return List;
    if (value is Map) return Map;
    return String;
  }

  static DataSchema _createEmptySchema(String name) {
    return _ImportedDataSchema(
      name: name,
      displayName: name,
      description: 'Empty schema',
      fields: [],
      sampleData: {},
    );
  }
}

/// Dynamic schema created by the import
class _ImportedDataSchema extends DataSchema {
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

  _ImportedDataSchema({
    required this.name,
    required this.displayName,
    required this.description,
    required this.fields,
    required this.sampleData,
  });

  @override
  Map<String, dynamic> get metadata => {
    'source': 'import',
    'importedAt': DateTime.now().toIso8601String(),
  };
}
