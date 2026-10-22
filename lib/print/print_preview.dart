import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../l10n/report_l10n.dart';
import 'print_pdf_renderer.dart';
import 'print_scope.dart';
import 'print_template.dart';

/// Rasterised PDF pages, cached by request so going back and forth between
/// steps does not render the same template twice.
class PdfImageCache {
  PdfImageCache._();

  static const int _maxEntries = 48;
  static final Map<String, Future<List<PdfRaster>>> _entries = {};

  static Future<List<PdfRaster>> pages(
    PrintRequest request, {
    required double widthPx,
  }) {
    final key = jsonEncode({
      'template': request.template.toItem().data,
      'template_name': request.template.name,
      'paper': request.paper.toItem().data,
      'sample': request.sampleData,
      'notice': request.pageNotice,
      'cells': request.cellData,
      'locale': request.localeName,
      'copies': request.copies,
      'skipped': request.skippedPerSheet,
      'guides': request.showCutGuides,
      'single': request.singleCellPage,
      'width': widthPx.round(),
    });
    final cached = _entries.remove(key);
    if (cached != null) {
      _entries[key] = cached;
      return cached;
    }
    final future = _render(request, widthPx);
    _entries[key] = future;
    if (_entries.length > _maxEntries) _entries.remove(_entries.keys.first);
    future.catchError((_) {
      _entries.remove(key);
      return <PdfRaster>[];
    });
    return future;
  }

  static Future<List<PdfRaster>> _render(
    PrintRequest request,
    double widthPx,
  ) async {
    final bytes = await PrintPdfRenderer.render(request);
    final paper = request.paper;
    final widthMm = request.singleCellPage
        ? paper.cellWidthMm
        : paper.pageWidthMm;
    final widthInches = widthMm / 25.4;
    final dpi = (widthPx / widthInches).clamp(36.0, 600.0);
    return Printing.raster(bytes, dpi: dpi).toList();
  }
}

class PrintTemplateThumbnail extends StatelessWidget {
  const PrintTemplateThumbnail({super.key, required this.template});

  final PrintTemplate template;

  @override
  Widget build(BuildContext context) {
    final scope = PrintScope.of(context);
    final request = PrintRequest(
      template: template,
      paper: scope.library.paperFormatOf(template),
      localeName: Localizations.localeOf(context).toString(),
      sampleData: scope.dataProvider.sampleData(context, template),
      pageNotice: scope.dataProvider.pageNotice(context, template),
      // One label or sign on its own page; a full page stays a full page.
      singleCellPage: true,
    );
    return FutureBuilder<List<PdfRaster>>(
      future: PdfImageCache.pages(request, widthPx: 360),
      builder: (context, snapshot) {
        final pages = snapshot.data;
        if (pages == null || pages.isEmpty) {
          return Center(
            child: snapshot.hasError
                ? Icon(
                    Icons.broken_image_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
          );
        }
        return Center(child: PdfPageImage(raster: pages.first));
      },
    );
  }
}

class PdfPageImage extends StatelessWidget {
  const PdfPageImage({super.key, required this.raster});

  final PdfRaster raster;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: raster.width / raster.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image(
          image: PdfRasterImage(raster),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// Shows every page of a request. While the user types, the previous pages
/// stay on screen and the new render starts after a short pause.
class PdfPagesView extends StatefulWidget {
  const PdfPagesView({super.key, required this.request});

  final PrintRequest request;

  @override
  State<PdfPagesView> createState() => _PdfPagesViewState();
}

class _PdfPagesViewState extends State<PdfPagesView> {
  static const _debounce = Duration(milliseconds: 350);

  List<PdfRaster> _pages = const [];
  Object? _error;
  bool _loading = true;
  Timer? _timer;
  int _renderToken = 0;
  double _widthPx = 0;

  @override
  void didUpdateWidget(covariant PdfPagesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _timer?.cancel();
    _timer = Timer(_debounce, _render);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _render() async {
    if (_widthPx <= 0) return;
    final token = ++_renderToken;
    setState(() => _loading = true);
    try {
      final pages = await PdfImageCache.pages(
        widget.request,
        widthPx: _widthPx,
      );
      if (!mounted || token != _renderToken) return;
      setState(() {
        _pages = pages;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || token != _renderToken) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pixelRatio = MediaQuery.devicePixelRatioOf(context);
        final displayWidth = (constraints.maxWidth - 48).clamp(120.0, 760.0);
        final widthPx = (displayWidth * pixelRatio).clamp(240.0, 1600.0);
        if ((widthPx - _widthPx).abs() > 64) {
          _widthPx = widthPx;
          _timer?.cancel();
          _timer = Timer(Duration.zero, _render);
        }
        if (_pages.isEmpty) {
          return Center(
            child: _error != null
                ? Text(context.reportL10n.printPreviewError(_error.toString()))
                : const CircularProgressIndicator(),
          );
        }
        return Stack(
          children: [
            ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _pages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 24),
              itemBuilder: (context, index) => Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: displayWidth,
                    maxHeight: constraints.maxHeight - 48 > 200
                        ? constraints.maxHeight - 48
                        : 200,
                  ),
                  child: PdfPageImage(raster: _pages[index]),
                ),
              ),
            ),
            if (_loading)
              const Positioned(
                top: 8,
                right: 16,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        );
      },
    );
  }
}
