import 'package:flutter/material.dart';

class AppTheme {
  // ─── Brand Colours ───────────────────────────────────────────────────────
  static const Color primaryColor     = Color(0xFF2A9134); // SevaLink Orange
  static const Color accentColor      = Color(0xFF054A29); // SevaLink Teal

  // ─── Backward-compatible aliases (used by auth screens) ──────────────────
  static const Color textColor            = Color(0xFF1F2937);
  static const Color subtitleColor        = Color(0xFF6B7280);
  static const Color inputBackgroundColor = Color(0xFFF3F4F6);
  static const Color backgroundColor      = Color(0xFFF4F6FB);
  static const Color borderColor          = Color(0xFFE5E7EB);

  // ─── Light palette ───────────────────────────────────────────────────────
  static const Color _lightBg         = Color(0xFFF4F6FB);
  static const Color _lightSurface    = Colors.white;
  static const Color _lightText       = Color(0xFF1F2937);
  static const Color _lightSubtext    = Color(0xFF6B7280);
  static const Color _lightBorder     = Color(0xFFE5E7EB);
  static const Color _lightInputFill  = Color(0xFFF9FAFB);

  // ─── Dark palette ────────────────────────────────────────────────────────
  static const Color _darkBg          = Color(0xFF0F1117);
  static const Color _darkSurface     = Color(0xFF1A1D27);
  static const Color _darkText        = Color(0xFFF1F5F9);
  static const Color _darkSubtext     = Color(0xFF94A3B8);
  static const Color _darkBorder      = Color(0xFF2E3347);
  static const Color _darkInputFill   = Color(0xFF1E2130);

  // ─── Light Theme ─────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: _lightBg,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: _lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _lightText,
        outline: _lightBorder,
      ),
      fontFamily: 'Roboto',
      cardColor: _lightSurface,
      dividerColor: _lightBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: accentColor,
        unselectedItemColor: Color(0xFF9CA3AF),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(double.infinity, 50),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightInputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: _lightSubtext),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: _lightText),
        bodyMedium: TextStyle(color: _lightText),
        bodySmall: TextStyle(color: _lightSubtext),
        titleLarge: TextStyle(color: _lightText, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: _lightText, fontWeight: FontWeight.w600),
      ),
      iconTheme: const IconThemeData(color: _lightSubtext),
      extensions: const [SevaLinkColors.light],
    );
  }

  // ─── Dark Theme ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: _darkBg,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: _darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _darkText,
        outline: _darkBorder,
      ),
      fontFamily: 'Roboto',
      cardColor: _darkSurface,
      dividerColor: _darkBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF141829),
        foregroundColor: _darkText,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: accentColor,
        unselectedItemColor: _darkSubtext,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(double.infinity, 50),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkInputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: _darkSubtext),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: _darkText),
        bodyMedium: TextStyle(color: _darkText),
        bodySmall: TextStyle(color: _darkSubtext),
        titleLarge: TextStyle(color: _darkText, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: _darkText, fontWeight: FontWeight.w600),
      ),
      iconTheme: const IconThemeData(color: _darkSubtext),
      extensions: const [SevaLinkColors.dark],
    );
  }
}

// ─── Custom Theme Extension (semantic colour tokens) ─────────────────────────
@immutable
class SevaLinkColors extends ThemeExtension<SevaLinkColors> {
  const SevaLinkColors({
    required this.cardBg,
    required this.cardBg2,
    required this.bodyBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.inputFill,
    required this.divider,
  });

  final Color cardBg;
  final Color cardBg2;
  final Color bodyBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color inputFill;
  final Color divider;

  static const light = SevaLinkColors(
    cardBg: Colors.white,
    cardBg2: Color(0xFFF4F6FB),
    bodyBg: Color(0xFFF4F6FB),
    textPrimary: Color(0xFF1F2937),
    textSecondary: Color(0xFF6B7280),
    border: Color(0xFFE5E7EB),
    inputFill: Color(0xFFF9FAFB),
    divider: Color(0xFFF3F4F6),
  );

  static const dark = SevaLinkColors(
    cardBg: Color(0xFF1A1D27),
    cardBg2: Color(0xFF232635),
    bodyBg: Color(0xFF0F1117),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    border: Color(0xFF2E3347),
    inputFill: Color(0xFF1E2130),
    divider: Color(0xFF2E3347),
  );

  @override
  SevaLinkColors copyWith({
    Color? cardBg,
    Color? cardBg2,
    Color? bodyBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? inputFill,
    Color? divider,
  }) {
    return SevaLinkColors(
      cardBg: cardBg ?? this.cardBg,
      cardBg2: cardBg2 ?? this.cardBg2,
      bodyBg: bodyBg ?? this.bodyBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      inputFill: inputFill ?? this.inputFill,
      divider: divider ?? this.divider,
    );
  }

  @override
  SevaLinkColors lerp(SevaLinkColors? other, double t) {
    if (other is! SevaLinkColors) return this;
    return SevaLinkColors(
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      cardBg2: Color.lerp(cardBg2, other.cardBg2, t)!,
      bodyBg: Color.lerp(bodyBg, other.bodyBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

// ─── Convenience extension on BuildContext ────────────────────────────────────
extension SevaLinkThemeX on BuildContext {
  SevaLinkColors get sevaColors =>
      Theme.of(this).extension<SevaLinkColors>() ?? SevaLinkColors.light;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
