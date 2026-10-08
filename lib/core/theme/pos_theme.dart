import 'package:flutter/material.dart';

class PosTheme {
  static const Color _surface = Color(0xFF171B1A);
  static const Color _surfaceRaised = Color(0xFF222927);
  static const Color _mint = Color(0xFF9FE3C0);
  static const Color _coral = Color(0xFFFF9F83);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _mint,
      onPrimary: Color(0xFF102019),
      secondary: _coral,
      onSecondary: Color(0xFF29130D),
      surface: _surface,
      onSurface: Color(0xFFF2F4EF),
      error: Color(0xFFFFB4AB),
      outline: Color(0xFF53615A),
    ),
    scaffoldBackgroundColor: const Color(0xFF101413),
    cardTheme: const CardThemeData(
      color: _surfaceRaised,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF101413),
      foregroundColor: Color(0xFFF2F4EF),
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceRaised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF39433E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _mint, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: _surface,
      indicatorColor: Color(0xFF344940),
      height: 68,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF303A35),
      thickness: 1,
    ),
  );
}
