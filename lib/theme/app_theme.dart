import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// MODO NEÓN — Dark Mode con acentos cian y rojo
// ============================================================
class AppColors {
  static const Color background = Color(0xFF060A14);
  static const Color surface = Color(0xFF0D1526);
  static const Color surfaceElevated = Color(0xFF111E35);
  static const Color surfaceCard = Color(0xFF152035);

  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonCyanDim = Color(0xFF00B8D4);
  static const Color neonCyanGlow = Color(0x2200E5FF);

  static const Color neonYellow = Color(0xFFFFD600);
  static const Color neonYellowGlow = Color(0x33FFD600);

  static const Color alertRed = Color(0xFFFF1744);
  static const Color alertRedDim = Color(0xFFCC0000);
  static const Color alertRedGlow = Color(0x22FF1744);
  static const Color alertRedBorder = Color(0xFFFF1744);

  static const Color warningAmber = Color(0xFFFFAB00);
  static const Color safeGreen = Color(0xFF00E676);

  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF7A8BA8);
  static const Color textMuted = Color(0xFF3D4F6A);

  static const Color borderSubtle = Color(0xFF1A2E4A);
  static const Color borderActive = Color(0xFF00E5FF);
}

// ============================================================
// MODO ESCUDO CLÁSICO — Neumórfico pastel
// ============================================================
class ClassicColors {
  static const Color background = Color(0xFFE8EEF7);
  static const Color backgroundGradientStart = Color(0xFFD6E4F7);
  static const Color backgroundGradientEnd = Color(0xFFEDE8F5);

  static const Color surface = Color(0xFFEFF4FB);
  static const Color surfaceCard = Color(0xFFEFF4FB);

  static const Color shadowDark = Color(0xFFB8C9E0);
  static const Color shadowLight = Color(0xFFFFFFFF);

  static const Color mintGreen = Color(0xFF4DB6AC);
  static const Color mintGreenLight = Color(0xFF80CBC4);
  static const Color mintGreenGlow = Color(0x3380CBC4);

  static const Color alertRed = Color(0xFFE53935);
  static const Color alertOrange = Color(0xFFFF7043);
  static const Color safeGreen = Color(0xFF43A047);
  static const Color warningAmber = Color(0xFFFFB300);

  static const Color textPrimary = Color(0xFF1A2340);
  static const Color textSecondary = Color(0xFF546E8A);
  static const Color textMuted = Color(0xFF90A4AE);

  static const Color cream = Color(0xFFFFF8E1);
  static const Color creamBorder = Color(0xFFE0CC88);
}

class AppTheme {
  // ─── TEMA NEÓN ───────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonCyan,
        secondary: AppColors.alertRed,
        surface: AppColors.surface,
        error: AppColors.alertRed,
        onPrimary: AppColors.background,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.robotoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.neonCyan, letterSpacing: 0.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.neonCyan),
        titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonCyan,
          foregroundColor: AppColors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.neonCyan,
          side: const BorderSide(color: AppColors.neonCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.neonCyanGlow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.neonCyan, size: 24);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.w700);
          }
          return const TextStyle(color: AppColors.textMuted, fontSize: 11);
        }),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borderSubtle, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.neonCyan : AppColors.textMuted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.neonCyanGlow : AppColors.surfaceElevated),
      ),
    );
  }

  // ─── TEMA ESCUDO CLÁSICO (Neumórfico Pastel) ─────────────
  static ThemeData get classicTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ClassicColors.background,
      colorScheme: const ColorScheme.light(
        primary: ClassicColors.mintGreen,
        secondary: ClassicColors.alertRed,
        surface: ClassicColors.surfaceCard,
        error: ClassicColors.alertRed,
        onPrimary: Colors.white,
        onSurface: ClassicColors.textPrimary,
      ),
      textTheme: GoogleFonts.latoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: ClassicColors.textPrimary),
          headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: ClassicColors.textPrimary),
          headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ClassicColors.textPrimary),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ClassicColors.textPrimary),
          bodyLarge: TextStyle(fontSize: 16, color: ClassicColors.textPrimary, height: 1.5),
          bodyMedium: TextStyle(fontSize: 14, color: ClassicColors.textSecondary, height: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ClassicColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: ClassicColors.mintGreen),
        titleTextStyle: TextStyle(color: ClassicColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ClassicColors.mintGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: ClassicColors.shadowDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ClassicColors.surface,
        indicatorColor: ClassicColors.mintGreenGlow,
        shadowColor: ClassicColors.shadowDark,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: ClassicColors.mintGreen, size: 24);
          }
          return const IconThemeData(color: ClassicColors.textMuted, size: 24);
        }),
      ),
      dividerTheme: DividerThemeData(color: ClassicColors.shadowDark.withOpacity(0.4), thickness: 1),
    );
  }
}
