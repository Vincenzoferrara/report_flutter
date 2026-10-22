import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../models/report_element.dart';

/// Service that renders Markdown content
class MarkdownRenderer {
  /// Renders Markdown content as a Widget
  static Widget render(
    String data,
    Map<String, dynamic> config, {
    TextStyle? baseStyle,
  }) {
    final enableToc = config['enableToc'] ?? false;
    final theme = config['theme'] ?? 'light';
    final isDark = theme == 'dark';

    // Default configuration based on the theme
    final markdownConfig = isDark
        ? MarkdownConfig.darkConfig
        : MarkdownConfig.defaultConfig;

    return MarkdownWidget(
      data: data,
      config: markdownConfig,
      tocController: enableToc ? TocController() : null,
    );
  }

  /// Whether an element has Markdown enabled
  static bool isMarkdownEnabled(ReportElement element) {
    return element.properties['useMarkdown'] == true;
  }

  /// Returns the Markdown data of an element
  static String getMarkdownData(ReportElement element) {
    return element.properties['markdownData'] ?? '';
  }

  /// Returns the Markdown configuration of an element
  static Map<String, dynamic> getMarkdownConfig(ReportElement element) {
    return Map<String, dynamic>.from(
      element.properties['markdownConfig'] ?? {},
    );
  }

  /// Enables Markdown for an element
  static void enableMarkdown(ReportElement element, bool enabled) {
    element.properties['useMarkdown'] = enabled;
  }

  /// Sets the Markdown data of an element
  static void setMarkdownData(ReportElement element, String data) {
    element.properties['markdownData'] = data;
  }

  /// Sets the Markdown configuration of an element
  static void setMarkdownConfig(
    ReportElement element,
    Map<String, dynamic> config,
  ) {
    element.properties['markdownConfig'] = config;
  }

  /// Renders a preview of the Markdown content
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

  /// Extracts the plain text from the Markdown content
  static String extractPlainText(String markdown) {
    String plain = markdown;

    // Remove headers
    plain = plain.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');

    plain = plain.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'\1');
    plain = plain.replaceAll(RegExp(r'\*(.*?)\*'), r'\1');
    plain = plain.replaceAll(RegExp(r'__(.*?)__'), r'\1');
    plain = plain.replaceAll(RegExp(r'_(.*?)_'), r'\1');

    // Remove inline code
    plain = plain.replaceAll(RegExp(r'`(.*?)`'), r'\1');

    // Remove links
    plain = plain.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'\1');

    // Remove images
    plain = plain.replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]+\)'), r'\1');

    plain = plain.replaceAll(RegExp(r'```[\s\S]*?```'), '');

    // Remove blockquotes
    plain = plain.replaceAll(RegExp(r'^>\s*', multiLine: true), '');

    // Remove horizontal rules
    plain = plain.replaceAll(RegExp(r'^---+$', multiLine: true), '');

    // Remove lists
    plain = plain.replaceAll(RegExp(r'^[\s]*[-*+]\s*', multiLine: true), '');
    plain = plain.replaceAll(RegExp(r'^[\s]*\d+\.\s*', multiLine: true), '');

    // Collapse multiple spaces
    plain = plain.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
    plain = plain.trim();

    return plain;
  }

  /// Counts the characters of the plain Markdown text
  static int countPlainTextCharacters(String markdown) {
    return extractPlainText(markdown).length;
  }

  /// Whether the content contains valid Markdown syntax
  static bool containsMarkdownSyntax(String text) {
    final markdownPatterns = [
      RegExp(r'^#+\s*', multiLine: true), // Headers
      RegExp(r'\*\*.*?\*\*'), // Grassetto
      RegExp(r'\*.*?\*'), // Corsivo
      RegExp(r'`.*?`'), // Inline code
      RegExp(r'```[\s\S]*?```'), // Code blocks
      RegExp(r'\[.*?\]\(.*?\)'), // Link
      RegExp(r'!\[.*?\]\(.*?\)'), // Immagini
      RegExp(r'^>\s*', multiLine: true), // Blockquote
      RegExp(r'^---+$', multiLine: true), // Horizontal rules
      RegExp(r'^[\s]*[-*+]\s*', multiLine: true), // Unordered lists
      RegExp(r'^[\s]*\d+\.\s*', multiLine: true), // Ordered lists
    ];

    return markdownPatterns.any((pattern) => pattern.hasMatch(text));
  }
}
