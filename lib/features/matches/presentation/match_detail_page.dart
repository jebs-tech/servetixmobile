import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Tambahan untuk context.read
import 'package:pbp_django_auth/pbp_django_auth.dart'; // Tambahan untuk CookieRequest

import '../data/match_api.dart';
import '../data/match_detail_model.dart';
import '../../checkout/presentation/checkout_page.dart';
// Import widget denah stadium yang telah dipisahkan
import 'stadium_seating.dart'; 

class MatchDetailPage extends StatefulWidget {
  final int matchId;

  const MatchDetailPage({super.key, required this.matchId});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  // Kita menggunakan Future.wait untuk mengambil Detail Match dan Data Kursi sekaligus
  late Future<List<dynamic>> _combinedFuture;

  // --- KONFIGURASI WARNA SESUAI BASE.HTML DJANGO ---
  static const Color brandDarkBlue = Color(0xFF1A2A4B);
  static const Color navBlue = Color(0xFF1E2C4F); // bg-[#1e2c4f]
  static const Color brandGold = Color(0xFFF6CA50); // #f6ca50
  static const Color brandOrange = Color(0xFFFFA043);
  static const Color brandCream = Color(0xFFFDF4D9); // #fdf4d9
  static const Color gradientStart = Color(0xFFFFFFFF); // to-[#FFFFFF]
  static const Color gradientEnd = Color(0xFFFADF95);   // from-[#FADF95]
  static const Color amber100 = Color(0xFFFFF3C4);

  @override
  void initState() {
    super.initState();
    // Mengambil instance CookieRequest dari Provider
    final request = context.read<CookieRequest>();
    
    // Mengambil data detail dan data kursi secara paralel dengan menyertakan request
    _combinedFuture = Future.wait([
      MatchApi().fetchMatchDetail(request, widget.matchId),
      MatchApi().fetchMatchSeats(request, widget.matchId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- NAVIGATION BAR (APPBAR) SESUAI DJANGO ---
      appBar: AppBar(
        backgroundColor: navBlue,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            children: [
              TextSpan(text: 'SERVE', style: TextStyle(color: brandCream)),
              TextSpan(text: '.', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'TIX', style: TextStyle(color: brandGold)),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        // --- GRADIENT BACKGROUND SESUAI BODY DJANGO ---
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStart, gradientEnd],
          ),
        ),
        child: FutureBuilder<List<dynamic>>(
          future: _combinedFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: brandDarkBlue));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('Data tidak ditemukan'));
            }

            // Data dari Future.wait
            final MatchDetail match = snapshot.data![0];
            final List<dynamic> allSeats = snapshot.data![1];

            // Filter label kursi yang sudah di-book (is_booked == true) dari Django
            final List<String> bookedLabels = allSeats
                .where((s) => s['is_booked'] == true)
                .map((s) => s['label'].toString())
                .toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final isSm = constraints.maxWidth >= 640;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- TITLE SECTION ---
                          Text(
                            match.title,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: brandDarkBlue,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('📍', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text(
                                match.venue,
                                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // --- MATCH CARD ---
                          _matchCard(match, isSm),
                          const SizedBox(height: 24),

                          // --- INFO & BUY SECTION ---
                          isWide
                              ? IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(flex: 2, child: _infoCard(match)),
                                      const SizedBox(width: 20),
                                      Expanded(flex: 1, child: _buyCard(match)),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: [
                                    _infoCard(match),
                                    const SizedBox(height: 20),
                                    _buyCard(match),
                                  ],
                                ),
                          const SizedBox(height: 24),

                          // --- EXPERIENCE & CATEGORY SECTION ---
                          isWide
                              ? IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(flex: 2, child: _experienceCard(match)),
                                      const SizedBox(width: 20),
                                      Expanded(flex: 1, child: _categoryCard()),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: [
                                    _experienceCard(match),
                                    const SizedBox(height: 20),
                                    _categoryCard(),
                                  ],
                                ),
                          const SizedBox(height: 32),

                          // --- SEAT MAP SECTION (Koneksi ke bookedLabels) ---
                          _seatMapCard(bookedLabels),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ==================================================
  // WIDGET HELPERS
  // ==================================================

  Widget _matchCard(MatchDetail match, bool isSm) {
    return Container(
      decoration: BoxDecoration(
        color: brandOrange,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
        ],
      ),
      padding: EdgeInsets.all(isSm ? 24 : 16),
      child: Container(
        decoration: BoxDecoration(
          color: amber100,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: isSm ? 32 : 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _teamBlock(match.teamA, isSm, true),
            Column(
              children: [
                Text(match.formattedDate,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: brandDarkBlue)),
                const SizedBox(height: 4),
                Text(match.formattedTime,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: brandDarkBlue)),
              ],
            ),
            _teamBlock(match.teamB, isSm, false),
          ],
        ),
      ),
    );
  }

  Widget _teamBlock(String name, bool isSm, bool isLeft) {
    final initials = name.isNotEmpty
        ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase()
        : '--';

    final logoWidget = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: brandDarkBlue, width: 2),
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: brandDarkBlue)),
      ),
    );

    final nameWidget = isSm
        ? Text(name,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: brandDarkBlue))
        : const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: isLeft
          ? [nameWidget, if (isSm) const SizedBox(width: 16), logoWidget]
          : [logoWidget, if (isSm) const SizedBox(width: 16), nameWidget],
    );
  }

  Widget _infoCard(MatchDetail match) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
                child: _infoTile(Icons.calendar_today, 'TANGGAL',
                    match.formattedDate, match.formattedTime)),
            const SizedBox(width: 16),
            Expanded(
                child: _infoTile(Icons.location_on, 'LOKASI', match.venue,
                    match.venueAddress)),
          ],
        ),
      ),
    );
  }

  Widget _buyCard(MatchDetail match) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Pesan Sekarang',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: brandDarkBlue)),
            const SizedBox(height: 8),
            Text('Mulai dari', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 6),
            Text('Rp ${match.priceFrom}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: brandOrange)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CheckoutPage(
                              matchId: match.id, selectedSeatIds: const [])));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGold,
                  foregroundColor: navBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                ),
                child: const Text('Beli Tiket',
                    style: TextStyle(
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _experienceCard(MatchDetail match) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detail Pengalaman',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: brandDarkBlue)),
            const SizedBox(height: 10),
            Text(match.description, style: const TextStyle(height: 1.6)),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Kategori Tempat Duduk',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: brandDarkBlue)),
            SizedBox(height: 12),
            _CategoryBadge('Tiket Emas', Color(0xFFA8C5F5), brandDarkBlue),
            SizedBox(height: 8),
            _CategoryBadge('Tiket Perak', Color(0xFFC6E6C3), brandDarkBlue),
            SizedBox(height: 8),
            _CategoryBadge('Tiket Perunggu', Color(0xFFFFF5C0), brandDarkBlue),
          ],
        ),
      ),
    );
  }

  // Method Seat Map yang menerima data bookedLabels dari API
  Widget _seatMapCard(List<String> bookedLabels) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Denah Tempat Duduk',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: brandDarkBlue,
              ),
            ),
          ),
          AspectRatio(
            aspectRatio: 1.2,
            child: StadiumSeatingChart(
              bookedSeatLabels: bookedLabels, // Mengirim data kursi hitam ke denah
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Gunakan pinch untuk zoom denah. Kursi Hitam sudah dipesan.',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String main, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: brandDarkBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 4),
              Text(main, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(color: Colors.grey))
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String title;
  final Color bg;
  final Color textColor;
  const _CategoryBadge(this.title, this.bg, this.textColor);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(title,
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
    );
  }
}