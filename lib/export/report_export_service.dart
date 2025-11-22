import 'dart:io';
import 'dart:math' as math;
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/report_template.dart';
import '../core/data_extractor.dart';
import '../viewer/renderers/report_renderer.dart';

/// Servizio per esportazione avanzata di report
class ReportExportService {
  /// Esporta i dati in formato CSV
  static Future<String> exportToCSV(
    List<dynamic> data,
    ReportTemplate template, {
    List<String>? selectedFields,
    Map<String, String>? fieldHeaders,
  }) async {
    try {
      if (data.isEmpty) {
        throw Exception('Nessun dato da esportare');
      }

      // Determina i campi da esportare
      final fields = selectedFields ?? _extractFieldsFromData(data);
      
      // Crea le intestazioni
      final headers = fields.map((field) => 
        fieldHeaders?[field] ?? field
      ).toList();

      // Crea le righe
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
      final csvData = const ListToCsvConverter().convert(rows);
      
      // Salva su file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${template.name}_$timestamp.csv';
      final filePath = path.join(directory.path, fileName);
      
      final file = File(filePath);
      await file.writeAsString(csvData);

      return filePath;
    } catch (e) {
      throw Exception('Errore durante l\'esportazione CSV: $e');
    }
  }

  /// Esporta i dati in formato Excel
  static Future<String> exportToExcel(
    List<dynamic> data,
    ReportTemplate template, {
    List<String>? selectedFields,
    Map<String, String>? fieldHeaders,
    bool includeCharts = false,
    bool includeSummary = true,
  }) async {
    try {
      if (data.isEmpty) {
        throw Exception('Nessun dato da esportare');
      }

      // Crea il workbook Excel
      final excel = Excel.createExcel();
      final sheet = excel['Dati'];

      // Determina i campi da esportare
      final fields = selectedFields ?? _extractFieldsFromData(data);
      
      // Aggiungi intestazioni
      for (int i = 0; i < fields.length; i++) {
        final field = fields[i];
        final header = fieldHeaders?[field] ?? field;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(header);
        
        // Formatta intestazioni in grassetto
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.cellStyle = CellStyle(
          bold: true,
        );
      }

      // Aggiungi dati
      for (int rowIndex = 0; rowIndex < data.length; rowIndex++) {
        final item = data[rowIndex];
        
        for (int colIndex = 0; colIndex < fields.length; colIndex++) {
          final field = fields[colIndex];
          final value = DataExtractor.getValue(item, field);
          
          final cellValue = value?.toString() ?? '';
          sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: colIndex, 
            rowIndex: rowIndex + 1
          )).value = TextCellValue(cellValue);
        }
      }

      // Aggiungi foglio riassuntivo se richiesto
      if (includeSummary) {
        _addSummarySheet(excel, data, template, fields);
      }

      // Salva il file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${template.name}_$timestamp.xlsx';
      final filePath = path.join(directory.path, fileName);
      
      final file = File(filePath);
      final bytes = excel.save()!;
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      throw Exception('Errore durante l\'esportazione Excel: $e');
    }
  }

  /// Esporta i dati selezionati (dopo filtri)
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
        throw Exception('Formato non supportato: $format');
    }
  }

  /// Esporta report completo con metadati
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
          data, template, parameters, filters, includeMetadata
        );
      case 'excel':
        return await _exportFullReportExcel(
          data, template, parameters, filters, includeMetadata
        );
      default:
        throw Exception('Formato non supportato: $format');
    }
  }

  /// Estrae i campi disponibili dai dati
  static List<String> _extractFieldsFromData(List<dynamic> data) {
    if (data.isEmpty) return [];
    
    final firstItem = data.first;
    if (firstItem is Map) {
      return firstItem.keys.cast<String>().toList();
    }
    
    return [];
  }

  /// Aggiunge foglio riassuntivo in Excel
  static void _addSummarySheet(
    Excel excel,
    List<dynamic> data,
    ReportTemplate template,
    List<String> fields,
  ) {
    final summarySheet = excel['Riepilogo'];
    
    // Informazioni generali
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      .value = TextCellValue('Report: ${template.name}');
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
      .value = TextCellValue('Data esportazione: ${DateTime.now().toString().split('.')[0]}');
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
      .value = TextCellValue('Numero record: ${data.length}');
    
    // Statistiche numeriche
    int rowIndex = 4;
    for (final field in fields) {
      final numericValues = data
          .map((item) => DataExtractor.getValue(item, field))
          .where((value) => value != null && value is num)
          .cast<num>()
          .toList();
      
      if (numericValues.isNotEmpty) {
        summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(field);
        summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue('Media: ${numericValues.reduce((a, b) => a + b) / numericValues.length}');
        summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue('Min: ${numericValues.reduce(math.min)}');
        summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue('Max: ${numericValues.reduce(math.max)}');
        rowIndex++;
      }
    }
  }

  /// Esporta report completo in CSV con metadati
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
        sink.writeln('# Data esportazione: ${DateTime.now()}');
        sink.writeln('# Numero record: ${data.length}');
        
        if (parameters != null && parameters.isNotEmpty) {
          sink.writeln('# Parametri:');
          parameters.forEach((key, value) {
            sink.writeln('#   $key: $value');
          });
        }
        
        if (filters != null && filters.isNotEmpty) {
          sink.writeln('# Filtri:');
          for (final filter in filters) {
            if (filter.enabled) {
              sink.writeln('#   ${filter.field} ${filter.operator} ${filter.value}');
            }
          }
        }
        
        sink.writeln(''); // Linea vuota
      }
      
      // Dati
      final fields = _extractFieldsFromData(data);
      final headers = fields.join(',');
      sink.writeln(headers);
      
      for (final item in data) {
        final row = fields.map((field) {
          final value = DataExtractor.getValue(item, field);
          final stringValue = value?.toString() ?? '';
          // Escape per CSV
          if (stringValue.contains(',') || stringValue.contains('"') || stringValue.contains('\n')) {
            return '"${stringValue.replaceAll('"', '""')}"';
          }
          return stringValue;
        }).join(',');
        sink.writeln(row);
      }
      
      return filePath;
    } finally {
      await sink.close();
    }
  }

  /// Esporta report completo in Excel con metadati
  static Future<String> _exportFullReportExcel(
    List<dynamic> data,
    ReportTemplate template,
    Map<String, dynamic>? parameters,
    List<ReportFilter>? filters,
    bool includeMetadata,
  ) async {
    final excel = Excel.createExcel();
    
    // Foglio metadati
    if (includeMetadata) {
      final metadataSheet = excel['Metadati'];
      
      metadataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = TextCellValue('Report: ${template.name}');
      metadataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
        .value = TextCellValue('Data esportazione: ${DateTime.now()}');
      metadataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue('Numero record: ${data.length}');
      
      int rowIndex = 4;
      
      if (parameters != null && parameters.isNotEmpty) {
        metadataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue('Parametri:');
        rowIndex++;
        
        parameters.forEach((key, value) {
          metadataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = TextCellValue(key);
          metadataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(value.toString());
          rowIndex++;
        });
      }
      
      if (filters != null && filters.isNotEmpty) {
        rowIndex++;
        metadataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue('Filtri:');
        rowIndex++;
        
        for (final filter in filters) {
          if (filter.enabled) {
            metadataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
              .value = TextCellValue(filter.field);
            metadataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
              .value = TextCellValue('${filter.operator} ${filter.value}');
            rowIndex++;
          }
        }
      }
    }
    
    // Foglio dati
    await exportToExcel(data, template);
    
    // Salva il file
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

