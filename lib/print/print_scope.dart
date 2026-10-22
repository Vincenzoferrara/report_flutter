import 'package:flutter/widgets.dart';

import 'print_data_provider.dart';
import 'print_library.dart';

/// Gives the print screens below it the library they manage and the data
/// provider of the app. The print center puts it at its root.
class PrintScope extends InheritedWidget {
  const PrintScope({
    super.key,
    required this.library,
    required this.dataProvider,
    required super.child,
  });

  final PrintLibrary library;
  final PrintDataProvider dataProvider;

  static PrintScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PrintScope>();
    assert(scope != null, 'No PrintScope above this print widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(PrintScope oldWidget) =>
      library != oldWidget.library || dataProvider != oldWidget.dataProvider;
}
