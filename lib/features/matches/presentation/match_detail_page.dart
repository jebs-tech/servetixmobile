import 'package:flutter/material.dart';
import '../data/match_api.dart';
import '../data/match_detail_model.dart';

class MatchDetailPage extends StatefulWidget {
  final int matchId;

  const MatchDetailPage({super.key, required this.matchId});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  late Future<MatchDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = MatchApi().fetchMatchDetail(widget.matchId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Detail Pertandingan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<MatchDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final match = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== TITLE & VENUE =====
                Text(
                  '${match.teamA} vs ${match.teamB}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2A4B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('📍'),
                    const SizedBox(width: 4),
                    Text(
                      match.venue,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ===== ORANGE MATCH CARD =====
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 8,
                        color: Colors.black12,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3C4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _teamCircle(match.teamA),
                        Column(
                          children: [
                            Text(
                              match.formattedDate,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(match.formattedTime),
                          ],
                        ),
                        _teamCircle(match.teamB),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ===== INFO GRID =====
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _infoRow(
                          icon: Icons.calendar_today,
                          title: 'Tanggal',
                          value: match.formattedDate,
                          sub: match.formattedTime,
                        ),
                        const Divider(),
                        _infoRow(
                          icon: Icons.location_on,
                          title: 'Lokasi',
                          value: match.venue,
                          sub: match.venueAddress,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ===== DESCRIPTION =====
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detail Pengalaman',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2A4B)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match.description,
                          style: const TextStyle(height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ===== CHECKOUT CARD =====
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pesan Sekarang',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2A4B)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mulai dari Rp ${match.priceFrom}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: checkout
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF1A2A4B),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'Beli Tiket',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _teamCircle(String name) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white,
          child: Text(
            name.substring(0, 2).toUpperCase(),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2A4B)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
    String? sub,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF1A2A4B)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (sub != null)
              Text(sub, style: const TextStyle(color: Colors.grey)),
          ],
        )
      ],
    );
  }
}
