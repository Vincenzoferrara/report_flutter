import 'package:flutter/widgets.dart';

import 'print_job.dart';
import 'print_template.dart';

/// What the app tells the print library about its data. The library knows
/// how to manage, design and print templates; the app knows what the fields
/// mean and where the data comes from.
abstract class PrintDataProvider {
  const PrintDataProvider();

  /// Example fields of [template], used by thumbnails, previews and the
  /// designer (where they also list the draggable fields).
  Map<String, dynamic> sampleData(BuildContext context, PrintTemplate template);

  /// Small text printed at the bottom of every page of [template], e.g. a
  /// notice that the figures are examples. Null prints nothing.
  String? pageNotice(BuildContext context, PrintTemplate template) => null;

  /// Whether the rows of a print job can be printed with [template].
  bool acceptsRows(PrintTemplate template) => true;

  /// Lets the user choose more rows to print ("Add label"). Returns null
  /// when nothing was chosen; returning [canPickRows] false hides the button.
  Future<PrintJob?> pickRows(BuildContext context) async => null;

  /// Whether [pickRows] is available.
  bool get canPickRows => false;

  /// Extra controls shown in the designer bar for the app [PrintTemplate.settings]
  /// of [template] (e.g. how the app formats a field). [onChanged] receives
  /// the template with the new settings.
  Widget? designerSettings(
    BuildContext context,
    PrintTemplate template,
    ValueChanged<PrintTemplate> onChanged,
  ) => null;
}
