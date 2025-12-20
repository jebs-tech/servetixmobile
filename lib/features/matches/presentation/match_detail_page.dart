import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/match_api.dart';
import '../data/match_detail_model.dart';
import '../../checkout/presentation/checkout_page.dart'; // ⬅️ SESUAIKAN PATH

class MatchDetailPage extends StatefulWidget {
  final int matchId;

  const MatchDetailPage({super.key, required this.matchId});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  late Future<MatchDetail> _future;

  static const Color brandDarkBlue = Color(0xFF1A2A4B);
  static const Color brandOrange = Color(0xFFFF8C00);
  static const Color amber100 = Color(0xFFFFF3C4);

  @override
  void initState() {
    super.initState();
    _future = MatchApi().fetchMatchDetail(widget.matchId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: brandDarkBlue),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Detail Pertandingan',
          style: TextStyle(
            color: brandDarkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<MatchDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Match not found'));
          }

          final match = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildMainColumn(match)),
                              const SizedBox(width: 24),
                              SizedBox(
                                width: 360,
                                child: _buildAsideCard(match),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMainColumn(match),
                              const SizedBox(height: 20),
                              _buildAsideCard(match),
                            ],
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ===================== MAIN COLUMN =====================

  Widget _buildMainColumn(MatchDetail match) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.arrow_back_ios,
                  size: 16, color: brandDarkBlue),
              SizedBox(width: 6),
              Text(
                'Kembali',
                style: TextStyle(
                  color: brandDarkBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Text(
          match.title ?? '${match.teamA} vs ${match.teamB}',
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: brandDarkBlue,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            const Text('📍', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                match.venue ?? '',
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Match card
        Container(
          decoration: BoxDecoration(
            color: brandOrange,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 6),
              )
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: amber100,
              borderRadius: BorderRadius.circular(10),
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _teamBlock(match.teamA),
                Column(
                  children: [
                    Text(
                      match.formattedDate,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(match.formattedTime),
                  ],
                ),
                _teamBlock(match.teamB),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Seat map
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Denah Tempat Duduk',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: brandDarkBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/images/denah_seating.svg',
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) =>
                          const CircularProgressIndicator(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===================== ASIDE =====================

  Widget _buildAsideCard(MatchDetail match) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pesan Sekarang',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: brandDarkBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Mulai dari',
                    style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 6),
                Text(
                  'Rp ${match.priceFrom}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: brandOrange,
                  ),
                ),
                const SizedBox(height: 12),

                /// ✅ NAVIGASI KE CHECKOUT
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutPage(
                            matchId: match.id,
                            selectedSeatIds: const [],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandDarkBlue,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Beli Tiket',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===================== HELPERS =====================

  Widget _teamBlock(String name) {
    final short = name.isNotEmpty
        ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase()
        : '--';

    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white,
          child: Text(
            short,
            style: const TextStyle(
              color: brandDarkBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
