import 'package:flutter/material.dart';

class AppThemes {
  // 1. Definisi Warna Dasar (Konstanta)
  static const Color royalBlue = Color(0xFF2563EB); // Primary
  static const Color slateGrey = Color(0xFF64748B); // Secondary Text
  static const Color ebony = Color(0xFF4A5043); // Main Text (Dark Accent)
  static const Color platinum = Color(0xFFF1F5F9); // Surface/Border
  static const Color goldenPollen = Color(0xFFFFCB47); // Warning/Highlight
  static const Color pureWhite = Color(0xFFFFFFFF); // Background/Card

  // 2. Pengaturan ThemeData (Light Theme - Default)
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Scaffold Background: Pure White
    scaffoldBackgroundColor: pureWhite,

    // ColorScheme
    colorScheme: const ColorScheme.light(
      primary: royalBlue,
      onPrimary: pureWhite,
      surface: platinum,
      onSurface: ebony,
      secondary: slateGrey,
      error:
          goldenPollen, // Using golden pollen as 'error' or highlight equivalent for now
    ),

    // AppBarTheme
    appBarTheme: const AppBarTheme(
      backgroundColor: royalBlue,
      foregroundColor: pureWhite, // Teks & Ikon Putih
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: pureWhite),
    ),

    // CardTheme
    cardTheme: const CardThemeData(
      color: pureWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: platinum, width: 1.5),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      margin: EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 0,
      ), // Optional default margin
    ),

    // FloatingActionButton
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: royalBlue,
      foregroundColor: pureWhite,
      elevation: 2,
    ),

    // CheckboxTheme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.selected)) {
          return royalBlue;
        }
        return pureWhite; // Unchecked is white
      }),
      checkColor: WidgetStateProperty.all(pureWhite),
      // Ensure the border is visible when unchecked (Slate Grey)
      side: const BorderSide(color: slateGrey, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Tipografi
    textTheme: const TextTheme(
      // Teks Utama (Ebony)
      bodyLarge: TextStyle(color: ebony),
      bodyMedium: TextStyle(color: ebony),
      titleLarge: TextStyle(color: ebony, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: ebony, fontWeight: FontWeight.bold),

      // Teks Sekunder (Slate Grey)
      bodySmall: TextStyle(color: slateGrey),
      labelSmall: TextStyle(color: slateGrey),
      titleSmall: TextStyle(color: slateGrey),
    ),

    // Icon Theme Global
    iconTheme: const IconThemeData(color: royalBlue),

    // Divider
    dividerTheme: const DividerThemeData(color: platinum, thickness: 1.5),
  );

  // --- TEMA LAIN (Untuk Gamifikasi - Tetap Disimpan agar tidak error) ---

  // Dark Theme (Simple Adaptation)
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: royalBlue,
    scaffoldBackgroundColor: const Color(0xFF1E293B), // Dark Grid color
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      foregroundColor: pureWhite,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark(
      primary: royalBlue,
      surface: Color(0xFF1E293B),
      // background: Color(0xFF0F172A), // Deprecated in recent Flutter, using scaffoldBackgroundColor
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF334155),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
    ),
    // Define TextTheme explicitly for Dark Mode
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: pureWhite),
      bodyMedium: TextStyle(color: platinum),
      titleLarge: TextStyle(color: pureWhite, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: pureWhite, fontWeight: FontWeight.bold),
      bodySmall: TextStyle(color: Color(0xFF94A3B8)), // Lighter Slate
      labelSmall: TextStyle(color: Color(0xFF94A3B8)),
      titleSmall: TextStyle(color: Color(0xFF94A3B8)),
    ),
  );

  // Midnight Blue Theme (Premium)
  static final ThemeData midnightBlueTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF191970), // Midnight Blue
    scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E293B), // Slate 800
      foregroundColor: Colors.white,
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6), // Blue 500
      secondary: Color(0xFF60A5FA), // Blue 400
      surface: Color(0xFF1E293B),
      onSurface: pureWhite,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF334155), // Slate 700
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    // Define TextTheme explicitly for Midnight Mode
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: pureWhite),
      bodyMedium: TextStyle(color: platinum),
      titleLarge: TextStyle(color: pureWhite, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: pureWhite, fontWeight: FontWeight.bold),
      bodySmall: TextStyle(color: Color(0xFF94A3B8)), // Lighter Slate
      labelSmall: TextStyle(color: Color(0xFF94A3B8)),
      titleSmall: TextStyle(color: Color(0xFF94A3B8)),
    ),
  );
}
