import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/report_template.dart';
import '../core/data_extractor.dart';
import '../viewer/renderers/report_renderer.dart';

/// Service for advanced report export
class ReportExportService {
  /// Exports the data as CSV into the app documents folder.
  ///
  /// To let the user choose where to save, use [csvBytes] with a save dialog.
  static Future<String> exportToCSV(
    List<dynamic> data,
    ReportTemplate template, {
    List<String>? selectedFields,
    Map<String, String>? fieldHeaders,
  }) async {
    try {
      final csvData = csvText(
        data,
        selectedFields: selectedFields,
        fieldHeaders: fieldHeaders,
      );

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${template.name}_$timestamp.csv';
      final filePath = path.join(directory.path, fileName);

      final file = File(filePath);
      await file.writeAsString(csvData);

      return filePath;
    } catch (e) {
      throw Exception('Error during the CSV export: $e');
    }
  }

  /// The data as CSV bytes (UTF-8), ready for a save dialog.
  static Uint8List csvBytes(
    List<dynamic> data, {
    List<String>? selectedFields,
    Map<String, String>? fieldHeaders,
  }) {
    return Uint8List.fromList(
      utf8.encode(
        csvText(
          data,
          selectedFields: selectedFields,
          fieldHeaders: fieldHeaders,
        ),
      ),
    );
  }

  /// The data as CSV text.
  static String csvText(
    List<dynamic> data, {
    List<String>? selectedFields,
    Map<String, String>? fieldHeaders,
  }) {
    if (data.isEmpty) {
      throw Exception('No data to export');
    }

    final fields = selectedFields ?? _extractFieldsFromData(data);

    // Create the headers
    final headers = fields
        .map((field) => fieldHeaders?[field] ?? field)
        .toList();

    final rows = <List<String>>[];
    rows.add(headers);

    for (final item in data) {
      final row = fields.map((field) {
        final value = DataExtractor.getValue(item, field);
        return value?.toString() ?? '';
      }).toList();
      rows.add(row);
    }

    // Converti in CSV
    return CsvEncoder().convert(rows);
  }

  /// Exports the data as Excel into the app documents folder.
  ///
  /// To let the user choose where to save, use [excelBytes] with a save
  /// dialog.
  static Future<String> exportToExcel(
    List<dynamic> data,
    ReportTemplate template, {
    List<String>? selectedFields,
    Map<String, String>? fieldHeaders,
    bool includeCharts = false,
    bool includeSummary = true,
  }) async {
    try {
      final bytes = excelBytes(
        data,
        template,
        selectedFields: selectedFields,
        fieldHeaders: fieldHeaders,
        includeSummary: includeSummary,
      );

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${template.name}_$timestamp.xlsx';
      final filePath = path.join(directory.path, fileName);

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      throw Exception('Error during the Excel export: $e');
    }
  }

  /// The data as an Excel workbook, ready for a save dialog.
  static Uint8List excelBytes(
    List<dynamic> data,
    ReportTemplate template, {
    List<String>? selectedFields,
    Map<String, String>? fieldHeaders,
    bool includeSummary = true,
  }) {
    if (data.isEmpty) {
      throw Exception('No data to export');
    }

    final excel = Excel.createExcel();
    final sheet = excel['Data'];

    final fields = selectedFields ?? _extractFieldsFromData(data);

    // Add the headers
    for (int i = 0; i < fields.length; i++) {
      final field = fields[i];
      final header = fieldHeaders?[field] ?? field;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        header,
      );

      // Formatta intestazioni in grassetto
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.cellStyle = CellStyle(bold: true);
    }

    for (int rowIndex = 0; rowIndex < data.length; rowIndex++) {
      final item = data[rowIndex];

      for (int colIndex = 0; colIndex < fields.length; colIndex++) {
        final field = fields[colIndex];
        final value = DataExtractor.getValue(item, field);

        final cellValue = value?.toString() ?? '';
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex + 1,
              ),
            )
            .value = TextCellValue(
          cellValue,
        );
      }
    }

    // Add a summary sheet when requested
    if (includeSummary) {
      _addSummarySheet(excel, data, template, fields);
    }

    return Uint8List.fromList(excel.save()!);
  }

  /// Exports the selected data (after filters)
  static Future<String> exportSelectedData(
    List<dynamic> selectedData,
    ReportTemplate template,
    String format, {
    Map<String, dynamic>? filters,
  }) async {
    switch (format.toLowerCase()) {
      case 'csv':
        return await exportToCSV(selectedData, template);
      case 'excel':
        return await exportToExcel(selectedData, template);
      default:
        throw Exception('Unsupported format: $format');
    }
  }

  /// Exports the full report with metadata
  static Future<String> exportFullReport(
    List<dynamic> data,
    ReportTemplate template,
    String format, {
    Map<String, dynamic>? parameters,
    List<ReportFilter>? filters,
    bool includeMetadata = true,
  }) async {
    switch (format.toLowerCase()) {
      case 'csv':
        return await _exportFullReportCSV(
          data,
          template,
          parameters,
          filters,
          includeMetadata,
        );
      case 'excel':
        return await _exportFullReportExcel(
          data,
          template,
          parameters,
          filters,
          includeMetadata,
        );
      default:
        throw Exception('Unsupported format: $format');
    }
  }

  /// Extracts the available fields from the data
  static List<String> _extractFieldsFromData(List<dynamic> data) {
    if (data.isEmpty) return [];

    final firstItem = data.first;
    if (firstItem is Map) {
      return firstItem.keys.cast<String>().toList();
    }

    return [];
  }

  /// Adds a summary sheet to the Excel file
  static void _addSummarySheet(
    Excel excel,
    List<dynamic> data,
    ReportTemplate template,
    List<String> fields,
  ) {
    final summarySheet = excel['Riepilogo'];

    // General information
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = TextCellValue(
      'Report: ${template.name}',
    );
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
        .value = TextCellValue(
      'Export date: ${DateTime.now().toString().split('.')[0]}',
    );
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(
      'Records: ${data.length}',
    );

    // Numeric statistics
    int rowIndex = 4;
    for (final field in fields) {
      final numericValues = data
          .map((item) => DataExtractor.getValue(item, field))
          .where((value) => value != null && value is num)
          .cast<num>()
          .toList();

      if (numericValues.isNotEmpty) {
        summarySheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          field,
        );
        summarySheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          'Media: ${numericValues.reduce((a, b) => a + b) / numericValues.length}',
        );
        summarySheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          'Min: ${numericValues.reduce(math.min)}',
        );
        summarySheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          'Max: ${numericValues.reduce(math.max)}',
        );
        rowIndex++;
      }
    }
  }

  /// Exports the full report as CSV with metadata
  static Future<String> _exportFullReportCSV(
    List<dynamic> data,
    ReportTemplate template,
    Map<String, dynamic>? parameters,
    List<ReportFilter>? filters,
    bool includeMetadata,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${template.name}_full_$timestamp.csv';
    final filePath = path.join(directory.path, fileName);

    final file = File(filePath);
    final sink = file.openWrite();

    try {
      // Metadati
      if (includeMetadata) {
        sink.writeln('# Report: ${template.name}');
        sink.writeln('# Export date: ${DateTime.now()}');
        sink.writeln('# Records: ${data.length}');

        if (parameters != null && parameters.isNotEmpty) {
          sink.writeln('# Parameters:');
          parameters.forEach((key, value) {
            sink.writeln('#   $key: $value');
          });
        }

        if (filters != null && filters.isNotEmpty) {
          sink.writeln('# Filters:');
          for (final filter in filters) {
            if (filter.enabled) {
              sink.writeln(
                '#   ${filter.field} ${filter.operator} ${filter.value}',
              );
            }
          }
        }

        sink.writeln('');
      }

      final fields = _extractFieldsFromData(data);
      final headers = fields.join(',');
      sink.writeln(headers);

      for (final item in data) {
        final row = fields
            .map((field) {
              final value = DataExtractor.getValue(item, field);
              final stringValue = value?.toString() ?? '';
              // CSV escaping
              if (stringValue.contains(',') ||
                  stringValue.contains('"') ||
                  stringValue.contains('\n')) {
                return '"${stringValue.replaceAll('"', '""')}"';
              }
              return stringValue;
            })
            .join(',');
        sink.writeln(row);
      }

      return filePath;
    } finally {
      await sink.close();
    }
  }

  /// Exports the full report as Excel with metadata
  static Future<String> _exportFullReportExcel(
    List<dynamic> data,
    ReportTemplate template,
    Map<String, dynamic>? parameters,
    List<ReportFilter>? filters,
    bool includeMetadata,
  ) async {
    final excel = Excel.createExcel();

    // Metadata sheet
    if (includeMetadata) {
      final metadataSheet = excel['Metadati'];

      metadataSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = TextCellValue(
        'Report: ${template.name}',
      );
      metadataSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
          .value = TextCellValue(
        'Export date: ${DateTime.now()}',
      );
      metadataSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
          .value = TextCellValue(
        'Records: ${data.length}',
      );

      int rowIndex = 4;

      if (parameters != null && parameters.isNotEmpty) {
        metadataSheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          'Parameters:',
        );
        rowIndex++;

        parameters.forEach((key, value) {
          metadataSheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            key,
          );
          metadataSheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            value.toString(),
          );
          rowIndex++;
        });
      }

      if (filters != null && filters.isNotEmpty) {
        rowIndex++;
        metadataSheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          'Filters:',
        );
        rowIndex++;

        for (final filter in filters) {
          if (filter.enabled) {
            metadataSheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: 0,
                    rowIndex: rowIndex,
                  ),
                )
                .value = TextCellValue(
              filter.field,
            );
            metadataSheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: 1,
                    rowIndex: rowIndex,
                  ),
                )
                .value = TextCellValue(
              '${filter.operator} ${filter.value}',
            );
            rowIndex++;
          }
        }
      }
    }

    // Data sheet
    await exportToExcel(data, template);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${template.name}_full_$timestamp.xlsx';
    final filePath = path.join(directory.path, fileName);

    final file = File(filePath);
    final bytes = excel.save()!;
    await file.writeAsBytes(bytes);

    return filePath;
  }
}
