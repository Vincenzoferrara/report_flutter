import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'paper_format.dart';
import 'print_data_provider.dart';
import 'print_job.dart';
import 'print_library.dart';
import 'print_pdf_renderer.dart';
import 'print_template.dart';

/// State of the Print tab: the chosen template, the print settings and, when
/// rows with real data were given, the rows to print.
///
/// Print settings (copies, used positions, paper) belong to one print only:
/// they never change the stored template.
class PrintController extends ChangeNotifier {
  PrintController({required this.library, required this.dataProvider});

  final PrintLibrary library;
  final PrintDataProvider dataProvider;

  PrintTemplate? _template;
  String? _paperOverrideId;
  int _copies = 1;
  List<int> _skippedPerSheet = const [];
  PrintJob? _job;

  PrintTemplate? get template => _template;
  int get copies => _job?.totalCopies ?? _copies;
  PrintJob? get job => _job;

  /// True while the chosen template is shown with its print settings.
  bool get isPrinting => _template != null;

  /// Positions skipped on each sheet that will be printed (one entry per
  /// sheet). Rolls and single-page formats never skip positions.
  List<int> get sheetSkips {
    final format = paper;
    if (format == null) return const [];
    return format.sheetSkips(copies, _skippedPerSheet);
  }

  /// Templates the current job can use.
  bool accepts(PrintTemplate template) =>
      _job == null || dataProvider.acceptsRows(template);

  PaperFormat? get paper {
    final template = _template;
    if (template == null) return null;
    return library.paperFormatOf(template, overrideId: _paperOverrideId);
  }

  void chooseTemplate(PrintTemplate template) {
    _template = template;
    _paperOverrideId = null;
    _resetQuantities();
    notifyListeners();
  }

  /// Back to the template list.
  void closeTemplate() {
    _template = null;
    notifyListeners();
  }

  void setPaper(String formatId) {
    _paperOverrideId = formatId;
    _resetQuantities();
    notifyListeners();
  }

  void setCopies(int value) {
    _copies = value.clamp(1, 999);
    notifyListeners();
  }

  /// Sets how many positions are already used at the start of sheet
  /// [sheetIndex] (0-based).
  void setSkippedCells(int sheetIndex, int value) {
    final maxSkipped = (paper?.cellsPerPage ?? 1) - 1;
    final skips = List<int>.of(sheetSkips);
    while (skips.length <= sheetIndex) {
      skips.add(0);
    }
    skips[sheetIndex] = value.clamp(0, maxSkipped);
    _skippedPerSheet = skips;
    notifyListeners();
  }

  /// Starts printing [job]. A chosen template that cannot print its rows is
  /// dropped.
  void startJob(PrintJob job) {
    _job = job;
    if (_template != null && !accepts(_template!)) _template = null;
    _skippedPerSheet = const [];
    notifyListeners();
  }

  /// Adds the rows of [more] that are not in the job yet and returns how
  /// many were added. Without a job yet, it starts one.
  int addToJob(PrintJob more) {
    final current = _job;
    if (current == null) {
      startJob(more);
      return more.rows.length;
    }
    final merged = current.merge(more);
    _job = merged;
    notifyListeners();
    return merged.rows.length - current.rows.length;
  }

  /// Removes one row from the job.
  void removeRow(String key) {
    final job = _job;
    if (job == null) return;
    _job = job.without(key);
    notifyListeners();
  }

  void clearJob() {
    _job = null;
    _resetQuantities();
    notifyListeners();
  }

  /// The templates were reloaded or changed: keep showing the stored version
  /// of the chosen one, or go back to the list if it was deleted.
  void syncWithLibrary() {
    final template = _template;
    if (template == null) return;
    _template = library.templates
        .where((entry) => entry.id == template.id)
        .firstOrNull;
    notifyListeners();
  }

  /// What the renderer needs for the chosen template.
  PrintRequest request(
    BuildContext context, {
    bool preview = false,
    bool singleCell = false,
  }) {
    final template = _template!;
    final job = _job;
    List<Map<String, dynamic>>? cells;
    if (job != null && dataProvider.acceptsRows(template)) {
      final rows = job.expanded;
      final source = singleCell && rows.isNotEmpty ? [rows.first] : rows;
      cells = [for (final row in source) row.dataFor(template)];
    }
    return PrintRequest(
      template: template,
      paper: paper!,
      localeName: Localizations.localeOf(context).toString(),
      sampleData: dataProvider.sampleData(context, template),
      pageNotice: dataProvider.pageNotice(context, template),
      copies: singleCell ? 1 : _copies,
      cellData: cells,
      skippedPerSheet: singleCell ? const [] : _skippedPerSheet,
      showCutGuides: preview,
      singleCellPage: singleCell,
    );
  }

  /// True when there is something to print.
  bool get canPrint =>
      _template != null && (_job == null || _job!.totalCopies > 0);

  /// Sends the print to the system print dialog.
  Future<void> printSelected(BuildContext context) async {
    final printRequest = request(context);
    final bytes = await PrintPdfRenderer.render(printRequest);
    final format = printRequest.paper;
    await Printing.layoutPdf(
      name: _fileName,
      // Labels and signs carry their own page size: the document is not
      // re-laid out on the printer format, or labels drift off the sheet.
      format: PdfPageFormat(
        format.pageWidthMm * PdfPageFormat.mm,
        format.pageHeightMm * PdfPageFormat.mm,
      ),
      dynamicLayout: false,
      onLayout: (_) async => bytes,
    );
  }

  /// Saves or shares the PDF.
  Future<void> shareSelected(BuildContext context) async {
    final bytes = await PrintPdfRenderer.render(request(context));
    await Printing.sharePdf(bytes: bytes, filename: '$_fileName.pdf');
  }

  String get _fileName {
    final name = (_template?.name ?? 'print')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return name.isEmpty ? 'print' : name;
  }

  void _resetQuantities() {
    final format = paper;
    _skippedPerSheet = const [];
    // Sheets with several labels default to a full sheet, everything else
    // to one copy.
    _copies = format != null && format.isMultiCellSheet
        ? format.cellsPerPage
        : 1;
  }
}
