import 'package:flutter/material.dart';
import 'package:servetixmobile/features/match/screens/match_list.dart';
import 'package:servetixmobile/dashboard_page/dashboard_page.dart';
import 'package:servetixmobile/forums/forums_list_page.dart';

class ItemHomepage {
  final String name;
  final IconData icon;
  final Color color;

  ItemHomepage(this.name, this.icon, this.color);
}

class ProductCard extends StatelessWidget {
  final ItemHomepage item;

  const ProductCard(this.item, {super.key});

  String _getEmoji(String name) {
    switch (name) {
      case 'Daftar Pertandingan':
        return '📅';
      case 'Forum Penggemar':
        return '💬';
      case 'Riwayat Tiket':
        return '🎫';
      default:
        return '✨';
    }
  }

  void _handleNavigation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Memuat: ${item.name}'),
        backgroundColor: item.color,
      ),
    );

    if (item.name == "Daftar Pertandingan") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MatchListPage()),
      );
    }
    if (item.name == "Forum Penggemar") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ForumsListPage()),
      );
    }
    if (item.name == "Riwayat Tiket") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleNavigation(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getEmoji(item.name),
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              Text(
                item.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1e2c4f),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
