import 'package:flutter/material.dart';

import '../l10n/report_l10n.dart';
import 'print_theme.dart';
import 'print_controller.dart';
import 'print_data_provider.dart';
import 'print_job.dart';
import 'print_library.dart';
import 'print_scope.dart';
import 'print_tab.dart';
import 'template_tab.dart';

/// The print center: the Print tab prints labels, signs and reports; the
/// Template tab manages templates, categories and paper formats.
///
/// [library] is loaded the first time the center is shown. Rows to print
/// with real data can be handed over through [pendingJob]: the center takes
/// the job, clears the notifier and opens the Print tab on it.
class PrintCenter extends StatefulWidget {
  const PrintCenter({
    super.key,
    required this.library,
    required this.dataProvider,
    this.title,
    this.pendingJob,
  });

  final PrintLibrary library;
  final PrintDataProvider dataProvider;

  /// App bar title; the library title when null.
  final String? title;
  final ValueNotifier<PrintJob?>? pendingJob;

  @override
  State<PrintCenter> createState() => _PrintCenterState();
}

class _PrintCenterState extends State<PrintCenter>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final PrintController _controller = PrintController(
    library: widget.library,
    dataProvider: widget.dataProvider,
  );
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.library.addListener(_controller.syncWithLibrary);
    widget.pendingJob?.addListener(_takePendingJob);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.library.load(context);
      _takePendingJob();
    });
  }

  @override
  void dispose() {
    widget.library.removeListener(_controller.syncWithLibrary);
    widget.pendingJob?.removeListener(_takePendingJob);
    _controller.dispose();
    _tabs.dispose();
    super.dispose();
  }

  /// A job handed over from outside opens the Print tab on it.
  void _takePendingJob() {
    final notifier = widget.pendingJob;
    final job = notifier?.value;
    if (notifier == null || job == null) return;
    notifier.value = null;
    _controller.startJob(job);
    _tabs.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.reportL10n;
    final library = widget.library;
    return PrintScope(
      library: library,
      dataProvider: widget.dataProvider,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.title ?? l10n.printPrintCenterTitle),
          actions: [
            IconButton(
              tooltip: l10n.printReload,
              icon: const Icon(Icons.refresh),
              onPressed: () => library.load(context, force: true),
            ),
          ],
          bottom: TabBar(
            controller: _tabs,
            tabs: [
              Tab(
                icon: const Icon(Icons.print_outlined),
                text: l10n.printTabPrint,
              ),
              Tab(
                icon: const Icon(Icons.dashboard_customize_outlined),
                text: l10n.printTabTemplates,
              ),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: Listenable.merge([library, _controller]),
          builder: (context, _) {
            if (!library.loaded) {
              return _LoadState(
                loading: library.loading || library.error == null,
                onRetry: () => library.load(context, force: true),
              );
            }
            return TabBarView(
              controller: _tabs,
              children: [
                PrintTab(controller: _controller),
                TemplateTab(library: library),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoadState extends StatelessWidget {
  const _LoadState({required this.loading, required this.onRetry});

  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.reportL10n;
    if (loading) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: context.printSpacing.iXL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: context.printColors.subtitleColor,
            ),
            SizedBox(height: context.printSpacing.m),
            Text(l10n.printLoadError, textAlign: TextAlign.center),
            SizedBox(height: context.printSpacing.m),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.printReload),
            ),
          ],
        ),
      ),
    );
  }
}
