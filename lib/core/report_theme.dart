import 'package:flutter/material.dart';

/// Tema personalizzato per il Report Designer
class ReportTheme {
  // Configurazione tema
  static Color _primaryColor = const Color(0xFF2196F3);
  static bool _isDarkMode = false;

  /// Imposta il colore primario del tema
  static void setPrimaryColor(Color color) {
    _primaryColor = color;
  }

  /// Imposta modalità scura
  static void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
  }

  /// Verifica se è in modalità scura
  static bool get isDarkMode => _isDarkMode;

  // Colori principali
  static Color get primary => _primaryColor;
  static Color get primaryDark => HSLColor.fromColor(_primaryColor).withLightness(0.35).toColor();
  static Color get primaryLight => HSLColor.fromColor(_primaryColor).withLightness(0.85).toColor();
  static Color get accent => HSLColor.fromColor(_primaryColor).withLightness(0.55).toColor();

  // Colori di sfondo
  static Color get background => _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
  static Color get surface => _isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
  static Color get canvasBackground => _isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0);

  // Colori pannelli
  static Color get panelBackground => _isDarkMode ? const Color(0xFF252525) : const Color(0xFFFAFAFA);
  static Color get panelHeader => _isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFEEEEEE);
  static Color get panelBorder => _isDarkMode ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0);

  // Colori elementi
  static Color get elementSelected => primary;
  static Color get elementHover => _isDarkMode ? primary.withValues(alpha: 0.3) : const Color(0xFFBBDEFB);
  static Color get elementHandle => primaryDark;

  // Colori testo
  static Color get textPrimary => _isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF212121);
  static Color get textSecondary => _isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF757575);
  static Color get textHint => _isDarkMode ? const Color(0xFF808080) : const Color(0xFF9E9E9E);

  // Colori stato
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static Color get info => primary;

  // Colori righello
  static Color get rulerBackground => _isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
  static Color get rulerLine => _isDarkMode ? const Color(0xFF606060) : const Color(0xFF9E9E9E);
  static Color get rulerText => _isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF616161);

  // Dimensioni
  static const double panelWidth = 220.0;
  static const double propertiesPanelWidth = 280.0;
  static const double toolbarHeight = 48.0;
  static const double iconSize = 20.0;
  static const double smallIconSize = 16.0;
  static const double rulerSize = 25.0; // Dimensione righello

  // Padding e spacing
  static const double paddingSmall = 4.0;
  static const double paddingMedium = 8.0;
  static const double paddingLarge = 12.0;
  static const double paddingXLarge = 16.0;

  // Border radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;

  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: _isDarkMode
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: _isDarkMode
          ? Colors.black.withValues(alpha: 0.4)
          : Colors.black.withValues(alpha: 0.15),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Stile per header dei pannelli
  static BoxDecoration get panelHeaderDecoration => BoxDecoration(
    color: panelHeader,
    border: Border(
      bottom: BorderSide(color: panelBorder, width: 1),
    ),
  );

  /// Stile per i pannelli laterali
  static BoxDecoration get panelDecoration => BoxDecoration(
    color: panelBackground,
    border: Border(
      right: BorderSide(color: panelBorder, width: 1),
    ),
  );

  /// Stile per pannello destro
  static BoxDecoration get rightPanelDecoration => BoxDecoration(
    color: panelBackground,
    border: Border(
      left: BorderSide(color: panelBorder, width: 1),
    ),
  );

  /// Stile per elementi draggabili
  static BoxDecoration draggableElementDecoration({bool isDragging = false}) => BoxDecoration(
    color: isDragging ? primaryLight : surface,
    borderRadius: BorderRadius.circular(borderRadiusSmall),
    border: Border.all(
      color: isDragging ? primary : panelBorder,
      width: 1,
    ),
    boxShadow: isDragging ? cardShadow : null,
  );

  /// Stile per elemento selezionato nel canvas
  static BoxDecoration selectedElementDecoration() => BoxDecoration(
    border: Border.all(color: elementSelected, width: 2),
    borderRadius: BorderRadius.circular(borderRadiusSmall),
  );

  /// Stile per sezione header
  static TextStyle get sectionHeaderStyle => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  /// Stile per label
  static TextStyle get labelStyle => TextStyle(
    fontSize: 12,
    color: textSecondary,
  );

  /// Stile per testo principale
  static TextStyle get bodyStyle => TextStyle(
    fontSize: 13,
    color: textPrimary,
  );

  /// Stile per titoli
  static TextStyle get titleStyle => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Tema completo per MaterialApp
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: _isDarkMode ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 1,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusSmall),
        borderSide: BorderSide(color: panelBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusSmall),
        borderSide: BorderSide(color: panelBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusSmall),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: paddingMedium,
        vertical: paddingSmall,
      ),
      isDense: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: paddingLarge,
          vertical: paddingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
      ),
    ),
    iconTheme: IconThemeData(
      size: iconSize,
      color: textSecondary,
    ),
    dividerTheme: DividerThemeData(
      color: panelBorder,
      thickness: 1,
      space: 1,
    ),
  );
}
