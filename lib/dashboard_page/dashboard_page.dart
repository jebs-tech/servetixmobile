// lib/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:servetixmobile/auth/login_page.dart';
import 'package:servetixmobile/models/dashboard_models.dart';
import 'package:servetixmobile/dashboard_page/edit_profile_page.dart';

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

  // Warna tema sesuai gambar (Cream & Dark Blue)
  final Color _creamColor = const Color(0xFFFFF9E6);
  final Color _darkBlueColor = const Color(0xFF1E293B);
  final Color _activeTabColor = const Color(0xFFFDE68A); // Kuning muda
  final Color _activeTextColor = const Color(0xFF92400E); // Coklat/Orange tua

  @override
  void initState() {
    super.initState();
    final request = Provider.of<CookieRequest>(context, listen: false);
    _refreshData(request);
  }

  void _refreshData(CookieRequest request) {
    setState(() {
      _profileFuture = fetchProfile(request);
      _activeTicketsFuture = fetchActiveTickets(request);
      _historyTicketsFuture = fetchHistoryTickets(request);
    });
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

    return Scaffold(
      backgroundColor: _creamColor, // Background Cream sesuai gambar
      appBar: AppBar(
        backgroundColor: _darkBlueColor,
        title: const Text("SERVE.TIX", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
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
                    _buildMenuChip(3, "Edit Profil", Icons.edit),
                    _buildMenuChip(4, "Hapus Akun", Icons.delete_forever, isDanger: true),
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
    );
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
      case 3: return _buildEditProfileView(userProfile, request); // EDIT PROFILE
      case 4: return _buildDeleteAccountView(); // HAPUS AKUN
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

  // --- VIEW 4: EDIT PROFIL ---
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

  // --- VIEW 5: HAPUS AKUN ---
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