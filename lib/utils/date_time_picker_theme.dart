import 'package:flutter/material.dart';

/// Helper pour appliquer un thème cohérent aux DatePickers et TimePickers
/// Textes et chiffres en blanc pour une meilleure lisibilité
Widget buildThemedPicker(BuildContext context, Widget? child) {
  return Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: Theme.of(context).colorScheme.primary,
        onPrimary: Colors.white,
        surface: Theme.of(context).colorScheme.surface,
        onSurface: Colors.white,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        dialTextColor: Colors.white,
        hourMinuteTextColor: Colors.white,
      ),
      datePickerTheme: DatePickerThemeData(
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white;
        }),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white;
        }),
      ),
    ),
    child: child!,
  );
}
