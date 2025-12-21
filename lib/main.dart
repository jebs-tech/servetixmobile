import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart'; // <--- PAKAI INI
import 'package:servetix/auth/login_page.dart';
import 'package:servetix/utils/toast.dart' show globalNavigatorKey;

// Global NavigatorKey untuk akses context dari mana saja
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Assign navigatorKey ke globalNavigatorKey untuk digunakan di Toast
    globalNavigatorKey = navigatorKey;
    
    return Provider(
      create: (_) {
        CookieRequest request = CookieRequest();
        return request;
      },
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'ServeTix',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: LoginPage(),
      ),
    );
  }
}
