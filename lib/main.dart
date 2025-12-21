import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'features/matches/presentation/match_detail_page.dart'; // Sesuaikan path ini

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
        title: 'ServeTix',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A2A4B)),
        ),
        // Ganti dengan halaman awal aplikasi Anda (misal Login atau Homepage)
        home: const MatchDetailPage(matchId: 2), 
      ),
    );
  }
}