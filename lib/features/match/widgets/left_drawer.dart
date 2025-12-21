import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Tambahkan ini
import 'package:pbp_django_auth/pbp_django_auth.dart'; // Tambahkan ini
import 'package:servetixmobile/auth/login_page.dart';
import 'package:servetixmobile/features/match/screens/menu.dart';
import 'package:servetixmobile/features/match/screens/match_list.dart';
import 'package:servetixmobile/forums/forums_list_page.dart';
import 'package:servetixmobile/dashboard_page/dashboard_page.dart';

class LeftDrawer extends StatelessWidget { // Ubah jadi StatelessWidget karena status diatur Provider
  const LeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Membaca status login dari pbp_django_auth
    final request = context.watch<CookieRequest>();

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1e2c4f), Color(0xFF3B528D)],
          ),
        ),
        child: ListView(
          children: [
            // --- HEADER DRAWER ---
            _buildHeader(),

            const SizedBox(height: 20),

            _buildDrawerItem(
              context,
              icon: Icons.home,
              title: 'Home',
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage())),
            ),

            _buildDrawerItem(
              context,
              icon: Icons.schedule,
              title: 'Match Schedule',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MatchListPage())),
            ),

            _buildDrawerItem(
              context,
              icon: Icons.forum,
              title: 'Forum Penggemar',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForumsListPage())),
            ),

            // Item ini biasanya hanya muncul kalau sudah login
            if (request.loggedIn)
              _buildDrawerItem(
                context,
                icon: Icons.confirmation_number,
                title: 'Profile Dashboard',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardPage())),
              ),

            const Divider(color: Colors.white30, height: 40),

            // --- TOMBOL DINAMIS LOGIN/LOGOUT ---
            _buildDrawerItem(
              context,
              icon: request.loggedIn ? Icons.logout : Icons.login,
              title: request.loggedIn ? 'Logout' : 'Login',
              onTap: () async {
                if (request.loggedIn) {
                  // LOGIKA LOGOUT
                  final response = await request.logout("http://127.0.0.1:8000/auth/logout/"); // Sesuaikan URL logout Django kamu
                  if (response['status']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Berhasil Logout'), backgroundColor: Colors.red),
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                  }
                } else {
                  // LOGIKA LOGIN
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper Header
  Widget _buildHeader() {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_volleyball, size: 64, color: Color(0xFF1e2c4f)),
            SizedBox(height: 12),
            Text('servetixmobile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1e2c4f))),
            Text('Sports Ticket Platform', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // Helper Item
  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white, size: 18),
      onTap: onTap,
    );
  }
}