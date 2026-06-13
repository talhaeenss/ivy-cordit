import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Neobrutalism renk paleti
class AppColors {
  // Ana renkler
  static const Color bgMain = Color(0xFFF5F5F0);
  static const Color primary = Color(0xFFA855F7);
  static const Color success = Color(0xFF4ADE80);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFBBF24);

  // Nötr renkler
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF6B7280);

  // Mesaj arka plan renkleri
  static const List<Color> messageColors = [
    Color(0xFFFFFFFF), // Beyaz
    Color(0xFFE0F2FE), // Açık mavi
    Color(0xFFDCFCE7), // Açık yeşil
    Color(0xFFF3E8FF), // Açık mor
    Color(0xFFFEF3C7), // Açık sarı
    Color(0xFFFFE4E6), // Açık pembe
  ];

  // Header gradient
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Neobrutalism stil sabitleri
class BrutalStyle {
  static const double borderWidth = 3.0;
  static const double shadowOffset = 4.0;
  static const double borderRadius = 0.0;

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.black, width: borderWidth),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
        ],
      );

  static BoxDecoration cardDecorationWithColor(Color color) => BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.black, width: borderWidth),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
        ],
      );
}

/// Uygulama teması
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgMain,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.black),
          titleTextStyle: TextStyle(
            color: AppColors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(
              color: AppColors.black,
              width: BrutalStyle.borderWidth,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(
              color: AppColors.black,
              width: BrutalStyle.borderWidth,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: BrutalStyle.borderWidth,
            ),
          ),
        ),
      );
}
