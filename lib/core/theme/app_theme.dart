import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor =
      Color.fromARGB(255, 18, 108, 136);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
    ),
    scaffoldBackgroundColor: const Color(0xffF5F7F9),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}