import 'print_template.dart';

/// One line to print: a product, a variant, a person, whatever the app
/// prints. The library does not know what it is: it shows [title] and
/// [subtitle], prints [quantity] copies and asks [dataFor] the fields of the
/// chosen template.
class PrintRow {
  const PrintRow({
    required this.key,
    required this.title,
    this.subtitle = '',
    required this.quantity,
    required this.dataFor,
  });

  /// Identifies the line: a second line with the same key is not added.
  final String key;
  final String title;
  final String subtitle;

  /// Copies printed for this line. Fixed: a line can only be removed.
  final int quantity;

  /// Fields of the line for [template], keyed like the designer fields.
  final Map<String, dynamic> Function(PrintTemplate template) dataFor;
}

/// Lines to print with real data.
class PrintJob {
  const PrintJob(this.rows);

  final List<PrintRow> rows;

  int get totalCopies => rows.fold(0, (sum, row) => sum + row.quantity);

  /// One entry per copy, in print order.
  List<PrintRow> get expanded => [
    for (final row in rows)
      for (var copy = 0; copy < row.quantity; copy++) row,
  ];

  /// The job with the rows of [other] it does not have yet, appended at the
  /// end: a line already in the job is never doubled.
  PrintJob merge(PrintJob other) {
    final known = rows.map((row) => row.key).toSet();
    return PrintJob([
      ...rows,
      for (final row in other.rows)
        if (known.add(row.key)) row,
    ]);
  }

  /// The job without the line [key].
  PrintJob without(String key) => PrintJob([
    for (final row in rows)
      if (row.key != key) row,
  ]);
}
