import 'package:flutter/material.dart';
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
    return Provider(
      create: (_) {
        CookieRequest request = CookieRequest();
        return request;
      },
      child: MaterialApp(
        title: 'ServeTix Mobile',
        theme: ThemeData(
          primaryColor: const Color(0xFFF6CA50),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFF6CA50),
            secondary: Color(0xFF3B528D),
            background: Colors.white,
            surface: Colors.white,
          ),
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF3B528D),
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF6CA50),
              foregroundColor: const Color(0xFF1e2c4f),
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
          useMaterial3: true,
        ),
        home: MyHomePage(),
      ),
    );
  }
}