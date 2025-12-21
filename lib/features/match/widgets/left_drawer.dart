import 'package:flutter/material.dart';
import 'package:servetixmobile/features/match/screens/menu.dart';
import 'package:servetixmobile/features/match/screens/match_list.dart';

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1e2c4f),
              Color(0xFF3B528D),
            ],
          ),
        ),
        child: ListView(
          children: [
            Container(
              height: 180,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_volleyball,
                      size: 64,
                      color: Color(0xFF1e2c4f),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'ServeTix',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1e2c4f),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sports Ticket Platform',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            _buildDrawerItem(
              context,
              icon: Icons.home,
              title: 'Home',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
              },
            ),
            
            _buildDrawerItem(
              context,
              icon: Icons.schedule,
              title: 'Match Schedule',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MatchListPage()),
                );
              },
            ),
            
            _buildDrawerItem(
              context,
              icon: Icons.forum,
              title: 'Forum Penggemar',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Forum Penggemar Page'),
                    backgroundColor: Color(0xFF3B528D),
                  ),
                );
              },
            ),
            
            _buildDrawerItem(
              context,
              icon: Icons.confirmation_number,
              title: 'My Tickets',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('My Tickets Page'),
                    backgroundColor: Color(0xFF3B528D),
                  ),
                );
              },
            ),
            
            const Divider(color: Colors.white30, height: 40),
            
            _buildDrawerItem(
              context,
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings Page'),
                    backgroundColor: Color(0xFF3B528D),
                  ),
                );
              },
            ),
            
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.white,
      ),
      onTap: onTap,
    );
  }
}