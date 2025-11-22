import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../models/report_element.dart';

/// Servizio per il rendering di contenuto Markdown
class MarkdownRenderer {
  /// Renderizza il contenuto Markdown in un Widget
  static Widget render(String data, Map<String, dynamic> config, {TextStyle? baseStyle}) {
    final enableToc = config['enableToc'] ?? false;
    final theme = config['theme'] ?? 'light';
    final isDark = theme == 'dark';
    
    // Usa la configurazione predefinita basata sul tema
    final markdownConfig = isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig;
    
    return MarkdownWidget(
      data: data,
      config: markdownConfig,
      tocController: enableToc ? TocController() : null,
    );
  }

  /// Verifica se un elemento ha il Markdown abilitato
  static bool isMarkdownEnabled(ReportElement element) {
    return element.properties['useMarkdown'] == true;
  }

  /// Ottiene i dati Markdown da un elemento
  static String getMarkdownData(ReportElement element) {
    return element.properties['markdownData'] ?? '';
  }

  /// Ottiene la configurazione Markdown da un elemento
  static Map<String, dynamic> getMarkdownConfig(ReportElement element) {
    return Map<String, dynamic>.from(element.properties['markdownConfig'] ?? {});
  }

  /// Abilita il Markdown per un elemento
  static void enableMarkdown(ReportElement element, bool enabled) {
    element.properties['useMarkdown'] = enabled;
  }

  /// Imposta i dati Markdown per un elemento
  static void setMarkdownData(ReportElement element, String data) {
    element.properties['markdownData'] = data;
  }

  /// Imposta la configurazione Markdown per un elemento
  static void setMarkdownConfig(ReportElement element, Map<String, dynamic> config) {
    element.properties['markdownConfig'] = config;
  }

  /// Renderizza un'anteprima del contenuto Markdown
  static Widget renderPreview(String data, {double maxHeight = 200}) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: MarkdownWidget(
            data: data,
            config: MarkdownConfig.defaultConfig,
          ),
        ),
      ),
    );
  }

  /// Estrae il testo puro dal contenuto Markdown
  static String extractPlainText(String markdown) {
    // Rimuovi la sintassi Markdown di base
    String plain = markdown;
    
    // Rimuovi headers
    plain = plain.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');
    
    // Rimuovi grassetto e corsivo
    plain = plain.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'\1');
    plain = plain.replaceAll(RegExp(r'\*(.*?)\*'), r'\1');
    plain = plain.replaceAll(RegExp(r'__(.*?)__'), r'\1');
    plain = plain.replaceAll(RegExp(r'_(.*?)_'), r'\1');
    
    // Rimuovi codice inline
    plain = plain.replaceAll(RegExp(r'`(.*?)`'), r'\1');
    
    // Rimuovi link
    plain = plain.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'\1');
    
    // Rimuovi immagini
    plain = plain.replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]+\)'), r'\1');
    
    // Rimuovi blocchi di codice
    plain = plain.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    
    // Rimuovi blockquote
    plain = plain.replaceAll(RegExp(r'^>\s*', multiLine: true), '');
    
    // Rimuovi linee orizzontali
    plain = plain.replaceAll(RegExp(r'^---+$', multiLine: true), '');
    
    // Rimuovi liste
    plain = plain.replaceAll(RegExp(r'^[\s]*[-*+]\s*', multiLine: true), '');
    plain = plain.replaceAll(RegExp(r'^[\s]*\d+\.\s*', multiLine: true), '');
    
    // Pulisci spazi multipli
    plain = plain.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
    plain = plain.trim();
    
    return plain;
  }

  /// Conta i caratteri nel testo puro del Markdown
  static int countPlainTextCharacters(String markdown) {
    return extractPlainText(markdown).length;
  }

  /// Verifica se il contenuto contiene sintassi Markdown valida
  static bool containsMarkdownSyntax(String text) {
    final markdownPatterns = [
      RegExp(r'^#+\s*', multiLine: true), // Headers
      RegExp(r'\*\*.*?\*\*'), // Grassetto
      RegExp(r'\*.*?\*'), // Corsivo
      RegExp(r'`.*?`'), // Codice inline
      RegExp(r'```[\s\S]*?```'), // Blocchi di codice
      RegExp(r'\[.*?\]\(.*?\)'), // Link
      RegExp(r'!\[.*?\]\(.*?\)'), // Immagini
      RegExp(r'^>\s*', multiLine: true), // Blockquote
      RegExp(r'^---+$', multiLine: true), // Linee orizzontali
      RegExp(r'^[\s]*[-*+]\s*', multiLine: true), // Liste non ordinate
      RegExp(r'^[\s]*\d+\.\s*', multiLine: true), // Liste ordinate
    ];
    
    return markdownPatterns.any((pattern) => pattern.hasMatch(text));
  }
}