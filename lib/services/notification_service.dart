import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class NotificationService {
  static void success(BuildContext context, String message, {String? title, Duration? duration}) {
    _show(
      context,
      message: message,
      title: title ?? 'Succès',
      type: ToastificationType.success,
      duration: duration,
    );
  }

  static void error(BuildContext context, String message, {String? title, Duration? duration}) {
    _show(
      context,
      message: message,
      title: title ?? 'Erreur',
      type: ToastificationType.error,
      duration: duration,
    );
  }

  static void info(BuildContext context, String message, {String? title, Duration? duration}) {
    _show(
      context,
      message: message,
      title: title ?? 'Information',
      type: ToastificationType.info,
      duration: duration,
    );
  }

  static void warning(BuildContext context, String message, {String? title, Duration? duration}) {
    _show(
      context,
      message: message,
      title: title ?? 'Attention',
      type: ToastificationType.warning,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required String title,
    required ToastificationType type,
    Duration? duration,
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.fillColored,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      description: Text(message),
      autoCloseDuration: duration ?? const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 250),
      alignment: Alignment.topRight,
      showProgressBar: true,
      closeOnClick: true,
      dragToClose: true,
    );
  }
}
