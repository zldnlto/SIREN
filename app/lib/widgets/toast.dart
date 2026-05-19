import 'package:flutter/material.dart';

enum ToastType { info, success, error }

class Toast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
  }) {
    final color = switch (type) {
      ToastType.success => const Color(0xFF388E3C),
      ToastType.error => const Color(0xFFD32F2F),
      ToastType.info => null,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
