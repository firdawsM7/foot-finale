import 'package:flutter/material.dart';

class AppTheme {
  // MAS de Fès Official Colors
  static const Color masYellow = Color(0xFFE8D21D);
  static const Color masBlack = Color(0xFF000000);
  static const Color masGray = Color(0xFF2C2C2C);
  
  // Gradient for backgrounds
  static const LinearGradient masGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      masBlack,
      masGray,
      masBlack,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Helper method for container decoration
  static BoxDecoration containerDecoration(BuildContext context, {
    double borderRadius = 16,
    double borderWidth = 2,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: masYellow,
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: masYellow.withOpacity(0.1),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ],
    );
  }

  static InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: masYellow),
    );
  }

  static LinearGradient getGradient(BuildContext context, {bool? isDarkOverride}) {
    final isDark = isDarkOverride ?? (Theme.of(context).brightness == Brightness.dark);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark 
        ? [masBlack, masGray, masBlack] 
        : [Colors.white, const Color(0xFFF5F5F5), Colors.white],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  // Dark Theme Data
  static ThemeData get darkTheme {
    return _buildTheme(Brightness.dark);
  }

  // Light Theme Data
  static ThemeData get lightTheme {
    return _buildTheme(Brightness.light);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final backgroundColor = isDark ? masBlack : Colors.white;
    final surfaceColor = isDark ? masGray : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : masBlack;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black87;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: masYellow,
      scaffoldBackgroundColor: backgroundColor,
      
      colorScheme: isDark ? ColorScheme.dark(
        primary: masYellow,
        secondary: masYellow,
        surface: surfaceColor,
        onPrimary: masBlack,
        onSecondary: masBlack,
        onSurface: Colors.white,
      ) : ColorScheme.light(
        primary: masYellow,
        secondary: masBlack,
        surface: surfaceColor,
        onPrimary: masBlack,
        onSecondary: Colors.white,
        onSurface: masBlack,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: isDark ? masYellow : masBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: isDark ? masYellow : masBlack,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        iconTheme: IconThemeData(color: isDark ? masYellow : masBlack),
      ),

      cardTheme: CardThemeData(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: masYellow, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: masYellow,
          foregroundColor: masBlack,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: masYellow.withOpacity(0.3), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: masYellow.withOpacity(0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: masYellow, width: 2),
        ),
        labelStyle: TextStyle(color: secondaryTextColor),
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
        prefixIconColor: isDark ? masYellow : masBlack,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: masYellow,
        unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: masYellow, width: 1),
        ),
        titleTextStyle: TextStyle(
          color: isDark ? masYellow : masBlack,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: textColor,
          fontSize: 14,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: isDark ? masYellow : masBlack, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor),
        bodySmall: TextStyle(color: secondaryTextColor),
      ),

      dividerTheme: DividerThemeData(
        color: masYellow.withOpacity(0.2),
        thickness: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: masYellow,
        textColor: textColor,
      ),
    );
  }
}
