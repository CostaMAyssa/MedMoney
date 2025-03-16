import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cores principais conforme especificação
  static const Color primaryColor = Color(0xFF48B7A2); // Verde Água para botões e filtros
  static const Color secondaryColor = Color(0xFFB9A6F5); // Lilás para painel de destaque
  static const Color backgroundColor = Color(0xFF0A0A3E); // Azul Escuro para fundo principal
  static const Color surfaceColor = Color(0xFFFFFFFF); // Branco para texto e detalhes
  static const Color errorColor = Color(0xFFFF6B6B); // Vermelho para erros
  static const Color successColor = Color(0xFF16A34A);
  static const Color warningColor = Color(0xFFD97706);
  static const Color cardBackgroundColor = Color(0xFF1A1A4F); // Cor para cards e containers
  
  // Cores para texto
  static const Color textPrimaryColor = Color(0xFFFFFFFF); // Branco para texto principal
  static const Color textSecondaryColor = Color(0xFFE0E0E0); // Cinza claro para texto secundário
  static const Color textTertiaryColor = Color(0xFFB0B0B0); // Cinza mais claro para texto terciário
  
  // Cores para status financeiro
  static const Color incomeColor = Color(0xFF48B7A2); // Verde Água para receitas
  static const Color expenseColor = Color(0xFFFF6B6B); // Vermelho para despesas
  static const Color neutralColor = Color(0xFFB9A6F5); // Lilás para neutro

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      fontFamily: GoogleFonts.montserrat().fontFamily,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: backgroundColor,
        surface: Color(0xFF1A1A4F), // Um pouco mais claro que o fundo principal
        onBackground: textPrimaryColor,
        onSurface: textPrimaryColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.montserrat(
          color: textPrimaryColor,
          fontSize: 57,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.montserrat(
          color: textPrimaryColor,
          fontSize: 45,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.montserrat(
          color: textPrimaryColor,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: GoogleFonts.montserrat(
          color: textPrimaryColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.montserrat(
          color: textPrimaryColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: GoogleFonts.montserrat(
          color: textPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.montserrat(
          color: textPrimaryColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.montserrat(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.montserrat(
          color: textSecondaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.montserrat(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: GoogleFonts.montserrat(
          color: textSecondaryColor,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: GoogleFonts.montserrat(
          color: textTertiaryColor,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: GoogleFonts.montserrat(
          color: textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: GoogleFonts.montserrat(
          color: textSecondaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: GoogleFonts.montserrat(
          color: textTertiaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1A1A4F), // Um pouco mais claro que o fundo principal
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: TextStyle(color: textSecondaryColor.withOpacity(0.7)),
        labelStyle: TextStyle(color: textPrimaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: Color(0xFF1A1A4F), // Um pouco mais claro que o fundo principal
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A5F), // Um tom intermediário
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF1A1A4F),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        side: BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return textSecondaryColor;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
      ),
    );
  }

  // Tema escuro (igual ao tema claro, já que o design já é escuro)
  static ThemeData get darkTheme => lightTheme;
} 