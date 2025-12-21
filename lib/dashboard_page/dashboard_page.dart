// lib/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:servetixmobile/auth/login_page.dart';
import 'package:servetixmobile/models/dashboard_models.dart';
import 'package:servetixmobile/dashboard_page/edit_profile_page.dart';
import 'package:servetixmobile/forums/forums_list_page.dart';
import 'package:servetixmobile/notifications/notifications_page.dart';
import 'package:servetixmobile/utils/toast.dart';
import 'dart:async';
import 'dart:convert';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Index menu yang sedang dipilih (Default: 0 = Tiket Aktif)
  int _selectedIndex = 0;

  // Data Futures
  Future<UserProfile>? _profileFuture;
  Future<List<Ticket>>? _activeTicketsFuture;
  Future<List<Ticket>>? _historyTicketsFuture;
  int _unreadNotificationCount = 0;
  int _previousUnreadCount = 0; // Untuk tracking perubahan
  bool _showNotificationDropdown = false;
  List<Map<String, dynamic>> _latestNotifications = [];
  List<String> _shownNotificationIds = []; // Track notifikasi yang sudah ditampilkan

  // Warna tema sesuai gambar (Cream & Dark Blue)
  final Color _creamColor = const Color(0xFFFFF9E6);
  final Color _darkBlueColor = const Color(0xFF1E293B);
  final Color _activeTabColor = const Color(0xFFFDE68A); // Kuning muda
  final Color _activeTextColor = const Color(0xFF92400E); // Coklat/Orange tua

  // Timer untuk polling notifikasi
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    final request = Provider.of<CookieRequest>(context, listen: false);
    _refreshData(request);
    
    // Setup periodic polling untuk notifikasi baru (setiap 5 detik)
    _notificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        final currentRequest = Provider.of<CookieRequest>(context, listen: false);
        _loadUnreadNotificationCount(currentRequest);
      }
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _refreshData(CookieRequest request) {
    setState(() {
      _profileFuture = fetchProfile(request);
      _activeTicketsFuture = fetchActiveTickets(request);
      _historyTicketsFuture = fetchHistoryTickets(request);
      _loadUnreadNotificationCount(request);
    });
  }

  void _loadUnreadNotificationCount(CookieRequest request) async {
    try {
      final response = await request.get("http://127.0.0.1:8000/notifications/api/notifications/unread_count/");
      if (response['success'] == true) {
        final newCount = response['unread_count'] ?? 0;
        List<Map<String, dynamic>> newLatestNotifications = [];
        
        if (response['latest'] != null) {
          newLatestNotifications = (response['latest'] as List).cast<Map<String, dynamic>>();
        }

        final previousCount = _unreadNotificationCount;
        
        setState(() {
          _previousUnreadCount = _unreadNotificationCount;
          _unreadNotificationCount = newCount;
          _latestNotifications = newLatestNotifications;
        });

        // Tampilkan toast jika ada notifikasi baru (count bertambah)
        // Skip jika ini load pertama kali (previousCount == 0)
        if (previousCount > 0 && newCount > previousCount && newLatestNotifications.isNotEmpty) {
          // Cari notifikasi baru yang belum pernah ditampilkan
          for (var notif in newLatestNotifications) {
            final notifId = notif['id']?.toString() ?? '';
            if (!_shownNotificationIds.contains(notifId) && notifId.isNotEmpty) {
              _shownNotificationIds.add(notifId);
              // Tampilkan toast untuk notifikasi baru
              final message = notif['message']?.toString() ?? 'Anda memiliki notifikasi baru';
              if (message.isNotEmpty) {
                Toast.info(message, duration: const Duration(seconds: 4));
              }
              break; // Hanya tampilkan yang pertama
            }
          }
        } else if (previousCount == 0 && newCount > 0 && newLatestNotifications.isNotEmpty) {
          // Untuk load pertama kali, simpan semua ID yang sudah ada (tidak tampilkan toast)
          for (var notif in newLatestNotifications) {
            final notifId = notif['id']?.toString() ?? '';
            if (notifId.isNotEmpty && !_shownNotificationIds.contains(notifId)) {
              _shownNotificationIds.add(notifId);
            }
          }
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _markAllNotificationsRead(CookieRequest request) async {
    try {
      final response = await request.postJson(
        "http://127.0.0.1:8000/notifications/api/notifications/mark_all_read/",
        '{}',
      );
      if (response['success'] == true) {
        _loadUnreadNotificationCount(request);
        setState(() {
          _showNotificationDropdown = false;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  // --- API CALLS (Sesuai diskusi sebelumnya) ---
  Future<UserProfile> fetchProfile(CookieRequest request) async {
    // Ganti 127.0.0.1 dengan 10.0.2.2 jika di Emulator
    final response = await request.get("http://127.0.0.1:8000/api/dashboard/");
    if (response['status'] == true) {
      return UserProfile.fromJson(response);
    } else {
      throw Exception('Gagal load profil');
    }
  }

  Future<List<Ticket>> fetchActiveTickets(CookieRequest request) async {
    final response = await request.get("http://127.0.0.1:8000/api/tickets/active/");
    if (response['status'] == true) {
      List<dynamic> list = response['active_tickets'];
      return list.map((d) => Ticket.fromJsonActive(d)).toList();
    } else {
      throw Exception('Gagal load tiket aktif');
    }
  }

  Future<List<Ticket>> fetchHistoryTickets(CookieRequest request) async {
    final response = await request.get("http://127.0.0.1:8000/api/tickets/history/");
    if (response['status'] == true) {
      List<dynamic> list = response['history'];
      return list.map((d) => Ticket.fromJsonHistory(d)).toList();
    } else {
      throw Exception('Gagal load history');
    }
  }

  void _handleLogout(CookieRequest request) async {
    final response = await request.logout("http://127.0.0.1:8000/api/logout/");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil Logout")));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _creamColor, // Background Cream sesuai gambar
          appBar: AppBar(
            backgroundColor: _darkBlueColor,
            title: const Text("SERVE.TIX", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.yellowAccent),
                    onPressed: () {
                      setState(() {
                        _showNotificationDropdown = !_showNotificationDropdown;
                      });
                    },
                    tooltip: "Notifikasi",
                  ),
                  if (_unreadNotificationCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _unreadNotificationCount > 9 ? '9+' : '$_unreadNotificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.yellowAccent),
                onPressed: () => _handleLogout(request),
                tooltip: "Logout",
              )
            ],
          ),
          body: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Data user untuk header "Halo, admin!"
          String greetingName = "User";
          if (snapshot.hasData) {
            greetingName = snapshot.data!.username;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER (Dashboard Akun & Halo)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dashboard Akun", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _darkBlueColor)),
                    const SizedBox(height: 4),
                    Text("Halo, $greetingName!", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  ],
                ),
              ),

              // 2. MENU HORIZONTAL (Pengganti Sidebar)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildMenuChip(0, "Tiket Aktif", Icons.confirmation_number_outlined),
                    _buildMenuChip(1, "Riwayat", Icons.history),
                    _buildMenuChip(2, "Tim Favorit", Icons.sports_soccer),
                    _buildMenuChip(3, "Forums", Icons.forum),
                    _buildMenuChip(4, "Notifikasi", Icons.notifications),
                    _buildMenuChip(5, "Edit Profil", Icons.edit),
                    _buildMenuChip(6, "Hapus Akun", Icons.delete_forever, isDanger: true),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. KONTEN (Berubah sesuai menu yang dipilih)
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    child: _buildContentBody(request, snapshot.data),
                  ),
                ),
              ),
            ],
          );
        },
      ),
        ),
        // Backdrop untuk menutup dropdown saat klik di luar (harus di bawah dropdown di Stack)
        if (_showNotificationDropdown)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showNotificationDropdown = false;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
        // Notification Dropdown Popup dengan Animasi (harus di atas backdrop)
        if (_showNotificationDropdown)
          Positioned(
            top: kToolbarHeight + 8,
            right: 16,
            child: Material(
              type: MaterialType.transparency,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.95 + (value * 0.05),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFfdf4d9),
                  child: Container(
                    width: 320,
                    constraints: const BoxConstraints(maxHeight: 400),
                    decoration: BoxDecoration(
                      color: const Color(0xFFfdf4d9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFf6ca50).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFf6ca50).withOpacity(0.1),
                            border: Border(
                              bottom: BorderSide(
                                color: const Color(0xFFf6ca50).withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Notifikasi",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _darkBlueColor,
                                ),
                              ),
                              if (_unreadNotificationCount > 0)
                                TextButton(
                                  onPressed: () => _markAllNotificationsRead(request),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "Tandai semua baca",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _darkBlueColor.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Notifications List
                        Flexible(
                          child: _latestNotifications.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    "Tidak ada notifikasi baru",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _latestNotifications.length,
                                  itemBuilder: (context, index) {
                                    final notif = _latestNotifications[index];
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _showNotificationDropdown = false;
                                        });
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const NotificationsPage(),
                                          ),
                                        ).then((_) => _refreshData(request));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey[200]!,
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (!(notif['is_read'] ?? false))
                                              Container(
                                                width: 8,
                                                height: 8,
                                                margin: const EdgeInsets.only(top: 6, right: 8),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFf6ca50),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    notif['message'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: (notif['is_read'] ?? false)
                                                          ? FontWeight.normal
                                                          : FontWeight.w600,
                                                      color: _darkBlueColor,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatNotificationDate(notif['created_at'] ?? ''),
                                                    style: TextStyle(
                                                      color: Colors.grey[500],
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        // Footer
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFAF0),
                            border: Border(
                              top: BorderSide(
                                color: const Color(0xFFf6ca50).withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _showNotificationDropdown = false;
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationsPage(),
                                ),
                              ).then((_) => _refreshData(request));
                            },
                            child: Center(
                              child: Text(
                                "Lihat semua notifikasi",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFFf6ca50),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatNotificationDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return "${date.day}/${date.month}/${date.year}";
      } else if (difference.inDays > 0) {
        return "${difference.inDays} hari yang lalu";
      } else if (difference.inHours > 0) {
        return "${difference.inHours} jam yang lalu";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes} menit yang lalu";
      } else {
        return "Baru saja";
      }
    } catch (e) {
      return dateString;
    }
  }

  // Widget Tombol Menu (Chip)
  Widget _buildMenuChip(int index, String label, IconData icon, {bool isDanger = false}) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDanger ? Colors.red[50] : _activeTabColor)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? (isDanger ? Colors.red : _activeTextColor)
                  : Colors.grey[300]!,
              width: 1.5
          ),
        ),
        child: Row(
          children: [
            Icon(
                icon,
                size: 18,
                color: isSelected
                    ? (isDanger ? Colors.red : _activeTextColor)
                    : Colors.grey[600]
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDanger ? Colors.red : _activeTextColor)
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Logika Switch Content
  Widget _buildContentBody(CookieRequest request, UserProfile? userProfile) {
    switch (_selectedIndex) {
      case 0: return _buildActiveTicketsView(); // TIKET AKTIF
      case 1: return _buildHistoryView();       // RIWAYAT
      case 2: return _buildFavoriteTeamsView(userProfile); // TIM FAVORIT
      case 3: return _buildForumsView(); // FORUMS
      case 4: return _buildNotificationsView(); // NOTIFIKASI
      case 5: return _buildEditProfileView(userProfile, request); // EDIT PROFILE
      case 6: return _buildDeleteAccountView(); // HAPUS AKUN
      default: return const SizedBox();
    }
  }

  // --- VIEW 1: TIKET AKTIF (Sesuai Gambar Empty State) ---
  Widget _buildActiveTicketsView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_activity, color: _darkBlueColor),
              const SizedBox(width: 8),
              Text("Tiket Aktif Saya", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkBlueColor)),
            ],
          ),
          const Divider(height: 30),

          Expanded(
            child: FutureBuilder<List<Ticket>>(
              future: _activeTicketsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                // Jika kosong, tampilkan Empty State sesuai gambar
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text("Tidak Ada Tiket Aktif", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text("Saat Anda membeli tiket, tiket akan muncul di sini.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                // Jika ada data
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final ticket = snapshot.data![index];
                    return Card(
                      color: Colors.blue[50],
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue[100]!)),
                      child: ListTile(
                        title: Text(ticket.matchTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${ticket.date} • ${ticket.venue}"),
                        trailing: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text("${ticket.totalTickets}", style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- VIEW 2: RIWAYAT ---
  Widget _buildHistoryView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Riwayat Pembelian", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkBlueColor)),
          const Divider(height: 30),
          Expanded(
            child: FutureBuilder<List<Ticket>>(
              future: _historyTicketsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Belum ada riwayat pembelian."));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final ticket = snapshot.data![index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history, color: Colors.grey),
                      title: Text(ticket.matchTitle),
                      subtitle: Text(ticket.date),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- VIEW 3: TIM FAVORIT ---
  Widget _buildFavoriteTeamsView(UserProfile? user) {
    if (user == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tim Favorit", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkBlueColor)),
          const Divider(height: 30),
          user.preferredTeams.isEmpty
              ? const Center(child: Text("Belum memilih tim favorit."))
              : Wrap(
            spacing: 10,
            runSpacing: 10,
            children: user.preferredTeams.map((team) => Chip(
              avatar: const Icon(Icons.sports_soccer),
              label: Text(team.name),
              backgroundColor: Colors.blue[50],
            )).toList(),
          )
        ],
      ),
    );
  }

  // --- VIEW 4: FORUMS ---
  Widget _buildForumsView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.forum, size: 60, color: Colors.blue),
          const SizedBox(height: 16),
          Text("Forum Diskusi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkBlueColor)),
          const SizedBox(height: 8),
          const Text("Diskusikan topik menarik dengan pengguna lain", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _darkBlueColor, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ForumsListPage()),
                );
              },
              child: const Text("Buka Forums"),
            ),
          )
        ],
      ),
    );
  }

  // --- VIEW 5: NOTIFIKASI ---
  Widget _buildNotificationsView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications, size: 60, color: Colors.orange),
          const SizedBox(height: 16),
          Text("Notifikasi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkBlueColor)),
          const SizedBox(height: 8),
          const Text("Lihat semua notifikasi Anda", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _darkBlueColor, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsPage()),
                );
              },
              child: const Text("Buka Notifikasi"),
            ),
          )
        ],
      ),
    );
  }

  // --- VIEW 6: EDIT PROFIL ---
  Widget _buildEditProfileView(UserProfile? user, CookieRequest request) {
    // Pastikan user tidak null sebelum menampilkan tombol
    if (user == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit_note, size: 60, color: Colors.blue),
          const SizedBox(height: 16),
          Text("Ingin mengubah profil Anda?", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white),
              onPressed: () async {
                // Perbaikan: Gunakan variabel 'user' yang diterima fungsi ini
                bool? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Kita kirim objek 'user' ke halaman EditProfilePage
                    builder: (context) => EditProfilePage(userProfile: user),
                  ),
                );

                // Jika user berhasil simpan perubahan, refresh data dashboard
                if (result == true) {
                  _refreshData(request);
                }
              },
              child: const Text("Buka Form Edit Profil"),
            ),
          )
        ],
      ),
    );
  }

  // --- VIEW 7: HAPUS AKUN ---
  Widget _buildDeleteAccountView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            "Apakah Anda yakin ingin menghapus akun?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text("Tindakan ini tidak dapat dibatalkan.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                // Implementasi logika hapus akun di sini
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Hapus Akun belum diimplementasikan di Flutter")));
              },
              child: const Text("Hapus Akun Permanen"),
            ),
          )
        ],
      ),
    );
  }
}