import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const primary = Color(0xFF0E2A47); // deep navy
  const primaryContainer = Color(0xFF10365F);
  const secondary = Color(0xFF2A9DF4); // accent blue
  const surface = Color(0xFF13283D); // card/darker surface
  const background = Color(0xFF0B1E33); // app background
  const onPrimary = Colors.white;
  const onSurface = Color(0xFFE6EEF6);

  final colorScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimary,
    secondary: secondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF0F2236),
    onSecondaryContainer: onSurface,
    tertiary: Color(0xFF5CC8FF),
    onTertiary: Colors.black,
    error: Color(0xFFEF5350),
    onError: Colors.white,
    background: background,
    onBackground: onSurface,
    surface: surface,
    onSurface: onSurface,
    surfaceVariant: Color(0xFF0F2439),
    onSurfaceVariant: onSurface,
    outline: Color(0xFF3D5166),
    shadow: Colors.black,
    scrim: Colors.black54,
    inverseSurface: Colors.white,
    onInverseSurface: Colors.black,
    inversePrimary: secondary,
  );

  final textTheme = Typography.whiteMountainView.copyWith(
    headlineSmall: const TextStyle(fontWeight: FontWeight.w700),
    titleLarge: const TextStyle(fontWeight: FontWeight.w600),
    bodyLarge: const TextStyle(height: 1.3),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      foregroundColor: colorScheme.onSurface,
      centerTitle: false,
      titleTextStyle:
          textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(color: colorScheme.onSurface),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: colorScheme.outline),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.secondary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colorScheme.outline),
        foregroundColor: colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFD32F2F), // SOS red
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    dividerTheme: DividerThemeData(color: colorScheme.outline.withOpacity(0.4)),
    // Indicateurs de chargement en blanc pour le mode sombre
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Colors.white,
      linearTrackColor: Color(0xFF3D5166),
      circularTrackColor: Color(0xFF3D5166),
    ),
  );
}
