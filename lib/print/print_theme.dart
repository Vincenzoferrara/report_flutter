import 'package:flutter/material.dart';

/// Spacing scale of the print screens.
class PrintSpacing {
  const PrintSpacing();

  double get xs => 4;
  double get s => 8;
  double get m => 12;
  double get l => 16;
  double get xl => 24;
  double get xxl => 32;

  EdgeInsets get iM => EdgeInsets.all(m);
  EdgeInsets get iL => EdgeInsets.all(l);
  EdgeInsets get iXL => EdgeInsets.all(xl);
}

/// Corner radii of the print screens.
class PrintShapes {
  const PrintShapes();

  BorderRadius get s => BorderRadius.circular(8);
  BorderRadius get m => BorderRadius.circular(12);
  BorderRadius get full => BorderRadius.circular(999);
}

/// Colours of the print screens, taken from the app Material theme so they
/// follow its light/dark mode and primary colour.
class PrintColors {
  const PrintColors(this._scheme);

  final ColorScheme _scheme;

  Color get subtitleColor => _scheme.onSurfaceVariant;
  Color get errorColorStatus => _scheme.error;
}

/// Kind of a short message shown by the print screens.
enum PrintMessageKind { success, warning, error, info }

/// Theme access for the print screens. The names start with `print` so they
/// never clash with the extensions of the app using the library.
extension PrintThemeContext on BuildContext {
  ThemeData get printTheme => Theme.of(this);
  TextTheme get printText => Theme.of(this).textTheme;
  PrintSpacing get printSpacing => const PrintSpacing();
  PrintShapes get printShapes => const PrintShapes();
  PrintColors get printColors => PrintColors(Theme.of(this).colorScheme);

  /// Shows [message] at the bottom of the screen.
  void showPrintMessage(
    String message, {
    PrintMessageKind kind = PrintMessageKind.info,
  }) {
    final scheme = Theme.of(this).colorScheme;
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger == null) return;
    final background = switch (kind) {
      PrintMessageKind.error => scheme.error,
      PrintMessageKind.warning => scheme.tertiary,
      PrintMessageKind.success => scheme.primary,
      PrintMessageKind.info => scheme.inverseSurface,
    };
    final foreground = switch (kind) {
      PrintMessageKind.error => scheme.onError,
      PrintMessageKind.warning => scheme.onTertiary,
      PrintMessageKind.success => scheme.onPrimary,
      PrintMessageKind.info => scheme.onInverseSurface,
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          content: Text(message, style: TextStyle(color: foreground)),
        ),
      );
  }
}

/// Text field look of the print screens: outlined, with its label always
/// above the value, so it reads well whatever the app theme does.
InputDecoration printInputDecoration(String label, {String? helperText}) =>
    InputDecoration(
      labelText: label,
      helperText: helperText,
      border: const OutlineInputBorder(),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
