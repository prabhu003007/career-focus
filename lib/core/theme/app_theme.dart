import 'package:flutter/material.dart';

class AppTheme {
  static const Color background =
      Color(0xFF030711);

  static const Color surface =
      Color(0xFF091322);

  static const Color cyan =
      Color(0xFF00E5FF);

  static const Color purple =
      Color(0xFF8B5CF6);

  static ThemeData darkTheme =
      ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,

    scaffoldBackgroundColor:
        background,

    colorScheme:
        ColorScheme.fromSeed(
      seedColor: cyan,
      brightness: Brightness.dark,
    ),

    fontFamily: 'Roboto',

    appBarTheme:
        const AppBarTheme(
      backgroundColor:
          Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),

    cardTheme:
        CardThemeData(
      color: surface,
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
    ),

    inputDecorationTheme:
        InputDecorationTheme(
      filled: true,
      fillColor:
          const Color(0xFF0C1727),
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide:
            const BorderSide(
          color: cyan,
        ),
      ),
    ),

    elevatedButtonTheme:
        ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
        backgroundColor:
            const Color(0xFF075985),
        foregroundColor:
            Colors.white,
        elevation: 0,
        minimumSize:
            const Size.fromHeight(50),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
      ),
    ),

    filledButtonTheme:
        FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
        backgroundColor:
            const Color(0xFF075985),
        foregroundColor:
            Colors.white,
        minimumSize:
            const Size.fromHeight(50),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
      ),
    ),

    snackBarTheme:
        const SnackBarThemeData(
      behavior:
          SnackBarBehavior.floating,
    ),
  );
}