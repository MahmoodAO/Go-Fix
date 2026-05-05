import 'dart:collection';
import 'package:flutter/material.dart';

class _PremiumShadowList extends ListBase<BoxShadow> {
  final List<BoxShadow> _light;
  final List<BoxShadow> _dark;

  _PremiumShadowList({
    required List<BoxShadow> light,
    required List<BoxShadow> dark,
  })  : _light = List<BoxShadow>.from(light),
        _dark = List<BoxShadow>.from(dark);

  List<BoxShadow> call([bool isDark = false]) {
    return isDark ? _dark : _light;
  }

  List<BoxShadow> get _base => _light;

  @override
  int get length => _base.length;

  @override
  set length(int newLength) {
    _base.length = newLength;
  }

  @override
  BoxShadow operator [](int index) => _base[index];

  @override
  void operator []=(int index, BoxShadow value) {
    _base[index] = value;
  }
}

class AppTheme {
  AppTheme._();

  // ─── Brand Colors (Teal / Petrol Blue Identity) ───────────────────
  static const Color primaryColor = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryLight = Color(0xFF99F6E4);

  // Accent – warm amber, used ONLY for highlights / emphasis
  static const Color accentColor = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFBBF24);

  // Status colors
  static const Color successColor = Color(0xFF22C55E);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);

  // ─── Dark Mode Palette (Navy / Slate – NOT black) ─────────────────
  static const Color darkScaffoldBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkElevated = Color(0xFF243447);
  static const Color darkDivider = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // ─── Light Mode Palette ───────────────────────────────────────────
  static const Color lightScaffoldBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightSecondarySurface = Color(0xFFEEF6F5);
  static const Color lightDivider = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // ─── Backward-compatible aliases (light-only, prefer helpers) ─────
  static const Color scaffoldBg = lightScaffoldBg;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textHint = lightTextSecondary;
  static const Color dividerColor = lightDivider;

  // ─── Gradients ────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryDark,
      primaryColor,
    ],
  );

  static const LinearGradient onboardingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF99F6E4), // teal light
      primaryColor,
      primaryDark,
    ],
  );

  // ─── Common Spacing & Radius ──────────────────────────────────────
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 28;
  static const double radiusFull = 999;

  // ─── Shadows ──────────────────────────────────────────────────────
  static final _PremiumShadowList premiumShadow = _PremiumShadowList(
    light: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
    dark: [
      BoxShadow(
        color: Colors.black.withOpacity(0.40),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static List<BoxShadow> get premiumShadowDark => premiumShadow(true);
  static List<BoxShadow> get premiumShadowLight => premiumShadow(false);

  static final List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> getPremiumShadow(bool isDark) {
    return premiumShadow(isDark);
  }

  // ─── Helpers ──────────────────────────────────────────────────────
  static Color getScaffoldBg(bool isDark) =>
      isDark ? darkScaffoldBg : lightScaffoldBg;

  static Color getSurface(bool isDark) =>
      isDark ? darkSurface : lightSurface;

  static Color getElevatedSurface(bool isDark) =>
      isDark ? darkElevated : lightSecondarySurface;

  static Color getTextPrimary(bool isDark) =>
      isDark ? darkTextPrimary : lightTextPrimary;

  static Color getTextSecondary(bool isDark) =>
      isDark ? darkTextSecondary : lightTextSecondary;

  static Color getTextHint(bool isDark) =>
      isDark ? darkTextSecondary.withOpacity(0.7) : lightTextSecondary;

  static Color getDividerColor(bool isDark) =>
      isDark ? darkDivider : lightDivider;

  static Color getPrimary(bool isDark) =>
      isDark ? const Color(0xFF14B8A6) : primaryColor;

  static Color getAccent(bool isDark) =>
      isDark ? accentLight : accentColor;

  // ─── Input Decoration ─────────────────────────────────────────────
  static InputDecoration inputDecoration({
    String label = '',
    bool isDark = false,
    IconData? prefixIcon,
    Widget? suffix,
    String? hintText,
  }) {
    final hintColor = isDark
        ? darkTextSecondary.withOpacity(0.5)
        : lightTextSecondary.withOpacity(0.5);

    final borderColor = isDark ? darkDivider : lightDivider;
    final primary = getPrimary(isDark);

    return InputDecoration(
      labelText: label.isEmpty ? null : label,
      hintText: hintText,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      labelStyle: TextStyle(
        color: hintColor,
        fontFamily: 'ElMessiri',
        fontSize: 15,
      ),
      hintStyle: TextStyle(
        color: hintColor,
        fontFamily: 'ElMessiri',
        fontSize: 15,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: hintColor, size: 22)
          : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark ? darkSurface : lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: errorColor, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
    );
  }

  // ─── ThemeData Generators ─────────────────────────────────────────
  static ThemeData getTheme(bool isDark) {
    final bg = getScaffoldBg(isDark);
    final surface = getSurface(isDark);
    final primaryText = getTextPrimary(isDark);
    final secondaryText = getTextSecondary(isDark);
    final primary = getPrimary(isDark);

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'ElMessiri',
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        brightness: isDark ? Brightness.dark : Brightness.light,
        seedColor: primaryColor,
        primary: primary,
        surface: surface,
        onSurface: primaryText,
        error: errorColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkSurface : primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'ElMessiri',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      dividerColor: getDividerColor(isDark),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: 'ElMessiri',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: secondaryText.withOpacity(0.6),
        elevation: 8,
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          fontFamily: 'ElMessiri',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: primaryText,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'ElMessiri',
          fontSize: 16,
          color: primaryText,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'ElMessiri',
          fontSize: 14,
          color: secondaryText,
        ),
      ),
    );
  }

  static ThemeData get lightTheme => getTheme(false);
  static ThemeData get darkTheme => getTheme(true);
}