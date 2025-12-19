import 'package:flutter/material.dart';
import 'features/matches/presentation/match_detail_page.dart';

void main() {
  runApp(const ServeTixApp());
}

class ServeTixApp extends StatelessWidget {
  const ServeTixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MatchDetailPage(matchId: 2), // ganti ID sesuai data Django
    );
  }
}
