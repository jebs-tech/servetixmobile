// lib/utils/toast.dart
// Toast Notification System - Seperti Django Messages
// 
// Usage:
//   Toast.success("Operasi berhasil!");
//   Toast.error("Terjadi kesalahan!");
//   Toast.warning("Peringatan!");
//   Toast.info("Informasi");
// 
// Bisa dipanggil dari mana saja tanpa context:
//   Toast.success("Pesan sukses");
// 
// Atau dengan context jika tersedia:
//   Toast.success("Pesan sukses", context: context);
//
// Toast akan muncul di bagian atas layar dan auto-hide setelah beberapa detik

import 'package:flutter/material.dart';

// NavigatorKey global, harus di-assign di main.dart
GlobalKey<NavigatorState>? globalNavigatorKey;

class Toast {
  static void show(
    BuildContext? context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Gunakan context yang diberikan atau ambil dari globalNavigatorKey
    final ctx = context ?? globalNavigatorKey?.currentContext;
    if (ctx == null) {
      debugPrint('Toast: Tidak ada context yang tersedia');
      return;
    }

    // Gunakan ScaffoldMessenger yang lebih reliable
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(ctx);
    if (scaffoldMessenger == null) {
      debugPrint('Toast: ScaffoldMessenger tidak ditemukan, coba lagi...');
      // Retry dengan delay
      Future.delayed(const Duration(milliseconds: 200), () {
        final retryCtx = globalNavigatorKey?.currentContext ?? context;
        if (retryCtx != null) {
          final retryScaffoldMessenger = ScaffoldMessenger.maybeOf(retryCtx);
          if (retryScaffoldMessenger != null) {
            _showSnackBar(retryScaffoldMessenger, message, type, duration);
          }
        }
      });
      return;
    }

    _showSnackBar(scaffoldMessenger, message, type, duration);
  }

  static void _showSnackBar(
    ScaffoldMessengerState scaffoldMessenger,
    String message,
    ToastType type,
    Duration duration,
  ) {
    // Tentukan warna berdasarkan type
    Color backgroundColor;
    Color textColor;
    IconData iconData;

    switch (type) {
      case ToastType.success:
        backgroundColor = const Color(0xFF4CAF50); // Green
        textColor = Colors.white;
        iconData = Icons.check_circle;
        break;
      case ToastType.error:
        backgroundColor = Colors.red;
        textColor = Colors.white;
        iconData = Icons.error;
        break;
      case ToastType.warning:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        iconData = Icons.warning;
        break;
      case ToastType.info:
      default:
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        iconData = Icons.info;
        break;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: textColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Helper methods untuk convenience (context optional)
  static void success(String message, {BuildContext? context, Duration? duration}) {
    show(context, message, type: ToastType.success, duration: duration ?? const Duration(seconds: 3));
  }

  static void error(String message, {BuildContext? context, Duration? duration}) {
    show(context, message, type: ToastType.error, duration: duration ?? const Duration(seconds: 4));
  }

  static void warning(String message, {BuildContext? context, Duration? duration}) {
    show(context, message, type: ToastType.warning, duration: duration ?? const Duration(seconds: 3));
  }

  static void info(String message, {BuildContext? context, Duration? duration}) {
    show(context, message, type: ToastType.info, duration: duration ?? const Duration(seconds: 3));
  }
}

enum ToastType {
  success,
  error,
  warning,
  info,
}
