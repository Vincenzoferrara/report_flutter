import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/report_template.dart';
import '../schema/data_schema.dart';

/// Result of loading a template with its schema
class TemplateWithSchema {
  final ReportTemplate template;
  final DataSchema? schema;
  final Map<String, dynamic> metadata;

  TemplateWithSchema({
    required this.template,
    this.schema,
    required this.metadata,
  });
}

/// Loader for .rpt template files
class TemplateLoader {
  /// Loads a template from the file system
  static Future<TemplateWithSchema> fromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Template file not found: $filePath');
      }

      final content = await file.readAsString(encoding: utf8);
      return _parseRptContent(content);
    } catch (e) {
      throw Exception('Error loading the template from file: $e');
    }
  }

  /// Loads a template from a Flutter asset
  static Future<TemplateWithSchema> fromAsset(String assetPath) async {
    try {
      final content = await rootBundle.loadString(assetPath);
      return _parseRptContent(content);
    } catch (e) {
      throw Exception('Error loading the template from asset: $e');
    }
  }

  /// Loads a template from a JSON string
  static TemplateWithSchema fromString(String jsonContent) {
    try {
      return _parseRptContent(jsonContent);
    } catch (e) {
      throw Exception('Error parsing the template string: $e');
    }
  }

  /// Saves a template to a file
  static Future<void> toFile(
    ReportTemplate template,
    String filePath, {
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      final file = File(filePath);

      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final rptContent = _createRptContent(template, additionalMetadata);
      await file.writeAsString(jsonEncode(rptContent), encoding: utf8);
    } catch (e) {
      throw Exception('Error saving the template to file: $e');
    }
  }

  /// Parses the .rpt content
  static TemplateWithSchema _parseRptContent(String content) {
    final json = jsonDecode(content) as Map<String, dynamic>;

    if (json['format'] != 'rpt') {
      throw Exception(
        'Formato file non supportato. Atteso "rpt", trovato "${json['format']}"',
      );
    }

    final version = json['version'] as String? ?? '1.0';
    if (!_isVersionSupported(version)) {
      throw Exception('Unsupported template version: $version');
    }

    // Extract the template
    final templateJson = json['template'] as Map<String, dynamic>;
    final template = ReportTemplate.fromJson(templateJson);

    DataSchema? schema;
    if (json.containsKey('dataSchema')) {
      schema = DataSchema.fromJson(json['dataSchema'] as Map<String, dynamic>);
    } else if (template.dataSchema != null) {
      schema = template.dataSchema;
    } else if (template.dataSchemaName != null) {
      // Try loading it from the registry
      schema = SchemaRegistry.getSchema(template.dataSchemaName!);
    }

    // Metadati
    final metadata = Map<String, dynamic>.from(json['metadata'] ?? {});
    metadata['loadedAt'] = DateTime.now().toIso8601String();
    metadata['filePath'] = json['filePath'];

    return TemplateWithSchema(
      template: template,
      schema: schema,
      metadata: metadata,
    );
  }

  /// Creates the complete .rpt content
  static Map<String, dynamic> _createRptContent(
    ReportTemplate template,
    Map<String, dynamic>? additionalMetadata,
  ) {
    final metadata = <String, dynamic>{
      'name': template.name,
      'description': template.description ?? '',
      'author': 'Report Designer',
      'version': '1.0',
      'createdAt': template.createdAt.toIso8601String(),
      'updatedAt': template.updatedAt.toIso8601String(),
      'exportedAt': DateTime.now().toIso8601String(),
    };

    // Add the extra metadata
    if (additionalMetadata != null) {
      metadata.addAll(additionalMetadata);
    }

    final content = {
      'format': 'rpt',
      'version': '1.0',
      'metadata': metadata,
      'template': template.toJson(),
    };

    if (template.dataSchema != null) {
      content['dataSchema'] = template.dataSchema!.toJson();
    }

    return content;
  }

  /// Whether the version is supported
  static bool _isVersionSupported(String version) {
    final supportedVersions = ['1.0'];
    return supportedVersions.contains(version);
  }

  /// Validates a .rpt file without fully loading it
  static Future<bool> validateFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final content = await file.readAsString(encoding: utf8);
      final json = jsonDecode(content) as Map<String, dynamic>;

      return json['format'] == 'rpt' &&
          _isVersionSupported(json['version'] as String? ?? '1.0');
    } catch (_) {
      return false;
    }
  }

  /// Extracts the metadata of a file without loading the whole template
  static Future<Map<String, dynamic>?> getMetadata(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final content = await file.readAsString(encoding: utf8);
      final json = jsonDecode(content) as Map<String, dynamic>;

      if (json['format'] != 'rpt') return null;

      return Map<String, dynamic>.from(json['metadata'] ?? {});
    } catch (_) {
      return null;
    }
  }

  /// Lists the templates available in a directory
  static Future<List<TemplateInfo>> listTemplates(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) return [];

      final templates = <TemplateInfo>[];

      await for (final entity in directory.list()) {
        if (entity is File && entity.path.endsWith('.rpt')) {
          final metadata = await getMetadata(entity.path);
          if (metadata != null) {
            templates.add(
              TemplateInfo(
                filePath: entity.path,
                name: metadata['name'] ?? entity.path.split('/').last,
                description: metadata['description'] ?? '',
                createdAt: metadata['createdAt'] != null
                    ? DateTime.parse(metadata['createdAt'])
                    : null,
                updatedAt: metadata['updatedAt'] != null
                    ? DateTime.parse(metadata['updatedAt'])
                    : null,
              ),
            );
          }
        }
      }

      return templates;
    } catch (e) {
      throw Exception('Error scanning the template directory: $e');
    }
  }
}

/// Basic information about a template
class TemplateInfo {
  final String filePath;
  final String name;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TemplateInfo({
    required this.filePath,
    required this.name,
    required this.description,
    this.createdAt,
    this.updatedAt,
  });
}
