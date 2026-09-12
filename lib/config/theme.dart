import 'package:flutter/material.dart';

class XonaDoshColors {
  XonaDoshColors._();

  // Primary brand colors (Refined Deep Teal / Forest Emerald)
  static const Color emerald = Color(0xFF0D9488);
  static const Color emeraldDark = Color(0xFF0F766E);
  static const Color emeraldDeep = Color(0xFF115E59);
  static const Color emeraldLight = Color(0xFFF0FDFA);
  static const Color emeraldMuted = Color(0xFFCCFBF1);
  static const Color primary = emerald;
  static const Color primaryDark = emeraldDark;
  static const Color primaryDeep = emeraldDeep;
  static const Color primaryLight = emeraldLight;
  static const Color primaryMuted = emeraldMuted;

  // Secondary brand accent (Subtle Indigo)
  static const Color accentPurple = Color(0xFF6366F1);
  static const Color accentPurpleDark = Color(0xFF4F46E5);
  static const Color accentPurpleLight = Color(0xFFEEF2FF);
  static const Color accentPurpleMuted = Color(0xFFE0E7FF);

  // Supporting accent colors
  static const Color amber = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFFEF3C7);
  static const Color sky = Color(0xFF0284C7);
  static const Color skyLight = Color(0xFFE0F2FE);
  static const Color rose = Color(0xFFE11D48);
  static const Color roseLight = Color(0xFFFFE4E6);

  // Neutral tones
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF0B1120);

  // Backgrounds & surfaces
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFF0F172A);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E293B);
  static const Color surfaceContainerDark = Color(0xFF1E293B);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);
}

/// Helper design styles and utilities for clean, human-crafted mobile design
class XonaDoshStyles {
  XonaDoshStyles._();

  static BoxDecoration cardDecoration(
    bool isDark, {
    Color? color,
    double radius = 14,
    bool hasBorder = true,
    bool hasShadow = true,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? (isDark ? XonaDoshColors.cardDark : XonaDoshColors.cardLight),
      borderRadius: BorderRadius.circular(radius),
      border: hasBorder
          ? Border.all(
              color: borderColor ?? (isDark ? XonaDoshColors.borderDark : XonaDoshColors.borderLight),
              width: 1,
            )
          : null,
      boxShadow: hasShadow
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  static List<BoxShadow> subtleShadow(bool isDark) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
        blurRadius: 6,
        offset: const Offset(0, 1),
      ),
    ];
  }
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: XonaDoshColors.emerald,
    brightness: Brightness.light,
    primary: XonaDoshColors.emerald,
    onPrimary: Colors.white,
    secondary: XonaDoshColors.accentPurple,
    onSecondary: Colors.white,
    surface: Colors.white,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF8FAFC),
    surfaceContainer: const Color(0xFFF1F5F9),
    outlineVariant: const Color(0xFFE2E8F0),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: XonaDoshColors.bgLight,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Colors.white,
      foregroundColor: XonaDoshColors.slate900,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: XonaDoshColors.slate900,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: XonaDoshColors.borderLight, width: 1),
      ),
      shadowColor: const Color(0x050F172A),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: XonaDoshColors.slate900,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      elevation: 4,
      showDragHandle: true,
      dragHandleColor: XonaDoshColors.slate300,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: XonaDoshColors.emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: XonaDoshColors.emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: XonaDoshColors.emeraldDark,
        side: const BorderSide(color: XonaDoshColors.borderLight, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: XonaDoshColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: XonaDoshColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: XonaDoshColors.emerald, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      hintStyle: const TextStyle(color: XonaDoshColors.slate400, fontSize: 13),
      labelStyle: const TextStyle(color: XonaDoshColors.slate500, fontSize: 13),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF1F5F9),
      selectedColor: XonaDoshColors.emeraldLight,
      side: const BorderSide(color: XonaDoshColors.borderLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: XonaDoshColors.slate700),
      secondaryLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: XonaDoshColors.emeraldDark),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      elevation: 0,
      backgroundColor: Colors.white,
      indicatorColor: XonaDoshColors.emerald.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? XonaDoshColors.emeraldDark : XonaDoshColors.slate500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 22,
          color: selected ? XonaDoshColors.emerald : XonaDoshColors.slate500,
        );
      }),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: XonaDoshColors.emerald,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: XonaDoshColors.emerald,
    brightness: Brightness.dark,
    primary: XonaDoshColors.emerald,
    onPrimary: Colors.white,
    secondary: XonaDoshColors.accentPurple,
    onSecondary: Colors.white,
    surface: XonaDoshColors.cardDark,
    surfaceContainerLowest: XonaDoshColors.bgDark,
    surfaceContainerLow: XonaDoshColors.cardDark,
    surfaceContainer: XonaDoshColors.surfaceContainerDark,
    outlineVariant: XonaDoshColors.borderDark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: XonaDoshColors.bgDark,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: XonaDoshColors.cardDark,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: XonaDoshColors.cardDark,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: XonaDoshColors.borderDark, width: 1),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: XonaDoshColors.cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: XonaDoshColors.cardDark,
      elevation: 6,
      showDragHandle: true,
      dragHandleColor: XonaDoshColors.slate600,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: XonaDoshColors.emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: XonaDoshColors.emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: XonaDoshColors.emerald,
        side: const BorderSide(color: XonaDoshColors.borderDark, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: XonaDoshColors.cardDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: XonaDoshColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: XonaDoshColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: XonaDoshColors.emerald, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      hintStyle: const TextStyle(color: XonaDoshColors.slate500, fontSize: 13),
      labelStyle: const TextStyle(color: XonaDoshColors.slate400, fontSize: 13),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: XonaDoshColors.cardDark,
      selectedColor: XonaDoshColors.emerald.withValues(alpha: 0.18),
      side: const BorderSide(color: XonaDoshColors.borderDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0)),
      secondaryLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: XonaDoshColors.emerald),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: XonaDoshColors.cardDark,
      indicatorColor: XonaDoshColors.emerald.withValues(alpha: 0.22),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? XonaDoshColors.emerald : XonaDoshColors.slate400,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 22,
          color: selected ? XonaDoshColors.emerald : XonaDoshColors.slate400,
        );
      }),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: XonaDoshColors.emerald,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
