import 'package:flutter/material.dart';

/// Text styles sesuai dengan Django template
class AppTextStyles {
  // Headings
  static TextStyle heading1(BuildContext context) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF1a237e),
    );
  }
  
  static TextStyle heading2(BuildContext context) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF1a237e),
    );
  }
  
  static TextStyle heading3(BuildContext context) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.grey[700],
    );
  }
  
  // Body text
  static TextStyle bodyLarge(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      color: Colors.grey[800],
    );
  }
  
  static TextStyle bodyMedium(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      color: Colors.grey[600],
    );
  }
  
  static TextStyle bodySmall(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      color: Colors.grey[600],
    );
  }
  
  // Special
  static TextStyle price(BuildContext context) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFF6B35),
    );
  }
  
  static TextStyle orderId(BuildContext context) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFF6B35),
    );
  }
}

