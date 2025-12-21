import 'package:flutter/material.dart';
import 'package:servetixmobile/auth/login_page.dart';
import 'package:servetixmobile/features/match/screens/menu.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Menggunakan Provider untuk menyediakan CookieRequest ke seluruh aplikasi
    return Provider(
      create: (_) {
        CookieRequest request = CookieRequest();
        return request;
      },
      child: MaterialApp(
        title: 'ServeTix Mobile',
        debugShowCheckedModeBanner: false, // Menghilangkan banner debug
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          
          // Konfigurasi Warna
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B528D),
            primary: const Color(0xFFF6CA50),
            secondary: const Color(0xFF3B528D),
            surface: Colors.white,
          ),

          // Tema AppBar
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF3B528D),
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
          ),

          // Tema Button
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF6CA50),
              foregroundColor: const Color(0xFF1E2C4F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        // Halaman Utama
        home: LoginPage(),
      ),
    );
  }
}